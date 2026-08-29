-- V1 Slice 1 ("First Trip"): trips + trip_participants, and the create_trip
-- RPC that's the only way either table is ever written to from the client.
--
-- Deliberate departures from ARCHITECTURE.md's conceptual sketch (validated,
-- not blindly copied):
--   * No `title` or `destination_country` column -- the create flow asks one
--     question ("where are you going?"), destination is the display name,
--     and nothing in this slice reads either field. Additive later if a
--     real feature needs them (e.g. country-keyed climate defaults).
--   * No `cover_image_path` -- Storage is out of scope for this slice.
--   * trip_participants has no surrogate id: (trip_id, traveler_id) is
--     already the natural key and doubles as the uniqueness constraint.

-- ---------------------------------------------------------------------------
-- trips
-- ---------------------------------------------------------------------------
create table public.trips (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  destination text not null,
  start_date date not null,
  end_date date not null,
  status text not null default 'active' check (status in ('draft', 'active', 'archived')),
  created_by uuid not null references auth.users (id),
  created_at timestamptz not null default now(),
  check (end_date >= start_date),
  -- Required so trip_participants can declare a composite FK below that
  -- ties a participant row to the SAME family as its trip, not just to
  -- some trip and some family independently.
  unique (id, family_id)
);

alter table public.trips enable row level security;

-- Least privilege: creation (and, later, editing) goes entirely through
-- SECURITY DEFINER RPCs (create_trip today), which bypass RLS for their own
-- writes the same way create_family/join_family_by_invite_code already do.
-- Only what this slice genuinely uses gets a policy -- reading a trip.
-- Future trip editing/archiving adds its own policy or RPC additively; this
-- migration doesn't pre-grant write access "for later."
create policy "trips are readable by family members"
  on public.trips for select
  to authenticated
  using (public.is_family_member(family_id));

-- ---------------------------------------------------------------------------
-- trip_participants: who is going on a given trip.
-- ---------------------------------------------------------------------------
create table public.trip_participants (
  trip_id uuid not null,
  traveler_id uuid not null,
  family_id uuid not null, -- denormalized, matching trip_items' pattern in ARCHITECTURE.md
  created_at timestamptz not null default now(),
  primary key (trip_id, traveler_id),
  -- Both composite FKs together are what make "a trip's participants must
  -- belong to the trip's own family" a structural guarantee rather than
  -- something only application code (or an RLS policy) checks: a row here
  -- literally cannot reference a trip and a traveler from different
  -- families, even for a user who legitimately belongs to more than one.
  foreign key (trip_id, family_id)
    references public.trips (id, family_id) on delete cascade,
  foreign key (traveler_id, family_id)
    references public.travelers (id, family_id) on delete cascade
);

alter table public.trip_participants enable row level security;

-- Select only, same reasoning as trips above -- every write goes through
-- create_trip.
create policy "trip participants are readable by family members"
  on public.trip_participants for select
  to authenticated
  using (public.is_family_member(family_id));

-- ---------------------------------------------------------------------------
-- create_trip(): atomically creates a trip and its participants -- both
-- existing travelers (by id) and newly-added dependents (name + optional
-- date of birth, always linked_user_id null; see the previous migration
-- for why that's the only place a linked adult ever gets created).
--
-- p_family_id is required and explicit, not inferred: a user can belong to
-- more than one family (see ARCHITECTURE.md "Multi-family membership"), so
-- there is no single "the caller's family" to default to safely.
-- ---------------------------------------------------------------------------
create function public.create_trip(
  p_family_id uuid,
  p_destination text,
  p_start_date date,
  p_end_date date,
  p_traveler_ids uuid[] default '{}',
  p_new_travelers jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_destination text := trim(both from p_destination);
  v_traveler_ids uuid[] := coalesce(p_traveler_ids, '{}');
  v_new_travelers jsonb := coalesce(p_new_travelers, '[]'::jsonb);
  v_trip_id uuid;
  v_total_participants int;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_family_member(p_family_id) then
    raise exception 'Not a member of this family';
  end if;

  if v_destination is null or v_destination = '' then
    raise exception 'Destination is required';
  end if;

  if p_start_date is null or p_end_date is null then
    raise exception 'Start and end dates are required';
  end if;

  if p_end_date < p_start_date then
    raise exception 'End date must be on or after the start date';
  end if;

  if jsonb_typeof(v_new_travelers) is distinct from 'array' then
    raise exception 'New travelers must be a JSON array';
  end if;

  if exists (
    select 1 from unnest(v_traveler_ids) as tid
    where not exists (
      select 1 from public.travelers
      where id = tid and family_id = p_family_id
    )
  ) then
    raise exception 'One or more selected travelers do not belong to this family';
  end if;

  if exists (
    select 1 from jsonb_array_elements(v_new_travelers) as elem
    where trim(coalesce(elem ->> 'name', '')) = ''
  ) then
    raise exception 'Traveler name is required';
  end if;

  select coalesce(array_length(v_traveler_ids, 1), 0) + jsonb_array_length(v_new_travelers)
  into v_total_participants;

  if v_total_participants = 0 then
    raise exception 'At least one traveler is required';
  end if;

  insert into public.trips (family_id, destination, start_date, end_date, created_by)
  values (p_family_id, v_destination, p_start_date, p_end_date, auth.uid())
  returning id into v_trip_id;

  insert into public.trip_participants (trip_id, traveler_id, family_id)
  select v_trip_id, d.tid, p_family_id
  from (select distinct tid from unnest(v_traveler_ids) as tid) as d;

  with new_travelers as (
    insert into public.travelers (family_id, linked_user_id, display_name, date_of_birth)
    select
      p_family_id,
      null,
      trim(elem ->> 'name'),
      nullif(elem ->> 'date_of_birth', '')::date
    from jsonb_array_elements(v_new_travelers) as elem
    returning id
  )
  insert into public.trip_participants (trip_id, traveler_id, family_id)
  select v_trip_id, id, p_family_id from new_travelers;

  return v_trip_id;
end;
$$;

revoke all on function public.create_trip(uuid, text, date, date, uuid[], jsonb) from public;
grant execute on function public.create_trip(uuid, text, date, date, uuid[], jsonb) to authenticated;
