-- Additive fix on top of the two already-applied migrations -- neither is
-- edited, this only adds new DDL and CREATE OR REPLACEs two functions.
--
-- Closes the gap PRODUCT.md's own glossary already implies but nothing
-- enforced: "Traveler: Anyone going on a trip -- a family member or a
-- dependent without an account." Today, becoming a family member (via
-- create_family or join_family_by_invite_code) never creates a matching
-- travelers row, so no adult is selectable as a trip participant at all.
--
-- Also hardens travelers.linked_user_id, which the first migration left
-- writable by any family member via a blanket INSERT/UPDATE policy -- an
-- authenticated user could set linked_user_id to an arbitrary auth.users id
-- on insert, or repoint an existing traveler's linked_user_id on update.
-- After this migration, linked_user_id can only ever be set by the trusted
-- SECURITY DEFINER RPCs (create_family / join_family_by_invite_code for a
-- linked adult; create_trip, added in the next migration, always inserts
-- dependents with linked_user_id null) -- there is no longer any direct
-- client-side insert or update path to travelers at all. A future
-- traveler-editing feature adds its own narrowly-scoped policy or RPC
-- additively; this migration doesn't try to guess its shape.

-- ---------------------------------------------------------------------------
-- 1. Required for the composite foreign keys the next migration adds from
--    trip_participants -- a composite FK must reference a unique
--    constraint/index on the parent, and (id, family_id) isn't one yet
--    even though id alone is the primary key.
-- ---------------------------------------------------------------------------
alter table public.travelers
  add constraint travelers_id_family_id_key unique (id, family_id);

-- Belt-and-suspenders against ever double-linking the same person to the
-- same family (the RPCs below guard against it too, with ON CONFLICT).
create unique index travelers_family_linked_user_unique
  on public.travelers (family_id, linked_user_id)
  where linked_user_id is not null;

-- ---------------------------------------------------------------------------
-- 2. Remove the direct insert/update/delete policies from the first
--    migration. Least privilege: nothing in the product writes to
--    travelers directly from the client anymore (creation goes through
--    create_family / join_family_by_invite_code / create_trip; there is no
--    edit- or delete-traveler UI yet). Select is untouched -- families can
--    still see their own travelers.
--
--    Delete is included deliberately, not just insert/update: the original
--    "travelers are deletable by family members" policy let any
--    authenticated family member delete ANY traveler in the family,
--    including a linked adult -- and because trip_participants.traveler_id
--    is ON DELETE CASCADE, that could silently drop an adult from existing
--    trips too. That's exactly the kind of direct, unscoped client write
--    this migration's least-privilege model exists to close off. No
--    replacement delete policy is added here; a future dedicated
--    delete-dependent RPC can enforce that a linked adult traveler is never
--    deleted this way (only removable by leaving the family, a different,
--    already-guarded path).
-- ---------------------------------------------------------------------------
drop policy if exists "travelers are insertable by family members"
  on public.travelers;
drop policy if exists "travelers are updatable by family members"
  on public.travelers;
drop policy if exists "travelers are deletable by family members"
  on public.travelers;

-- ---------------------------------------------------------------------------
-- 3. create_family(): also creates the caller's own linked traveler row,
--    so its creator immediately shows up as a trip participant candidate.
-- ---------------------------------------------------------------------------
create or replace function public.create_family(p_name text)
returns table (family_id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := trim(both from p_name);
  v_family_id uuid;
  v_invite_code text;
  v_display_name text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if v_name is null or v_name = '' then
    raise exception 'Family name is required';
  end if;

  insert into public.families (name)
  values (v_name)
  returning id, families.invite_code into v_family_id, v_invite_code;

  insert into public.family_members (family_id, user_id, role)
  values (v_family_id, auth.uid(), 'owner');

  select coalesce(p.display_name, split_part(u.email, '@', 1))
  into v_display_name
  from auth.users u
  left join public.profiles p on p.user_id = u.id
  where u.id = auth.uid();

  insert into public.travelers (family_id, linked_user_id, display_name)
  values (v_family_id, auth.uid(), coalesce(v_display_name, 'Me'));

  return query select v_family_id, v_invite_code;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. join_family_by_invite_code(): same addition -- also links the joiner's
--    own traveler row, idempotently (matches the family_members insert's
--    existing ON CONFLICT DO NOTHING, for the same re-join case).
-- ---------------------------------------------------------------------------
create or replace function public.join_family_by_invite_code(p_invite_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_family_id uuid;
  v_display_name text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select id into v_family_id
  from public.families
  where invite_code = lower(trim(p_invite_code));

  if v_family_id is null then
    raise exception 'Invalid invite code';
  end if;

  insert into public.family_members (family_id, user_id, role)
  values (v_family_id, auth.uid(), 'member')
  on conflict (family_id, user_id) do nothing;

  select coalesce(p.display_name, split_part(u.email, '@', 1))
  into v_display_name
  from auth.users u
  left join public.profiles p on p.user_id = u.id
  where u.id = auth.uid();

  insert into public.travelers (family_id, linked_user_id, display_name)
  values (v_family_id, auth.uid(), coalesce(v_display_name, 'Me'))
  on conflict (family_id, linked_user_id) where linked_user_id is not null
  do nothing;

  return v_family_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. Backfill: existing family_members rows (created before this migration
--    existed, including real data from Phase 0 testing) have no matching
--    travelers row yet. One-time, guarded by NOT EXISTS so it's safe even
--    if this migration were somehow re-applied.
-- ---------------------------------------------------------------------------
insert into public.travelers (family_id, linked_user_id, display_name)
select
  fm.family_id,
  fm.user_id,
  coalesce(p.display_name, split_part(u.email, '@', 1), 'Me')
from public.family_members fm
join auth.users u on u.id = fm.user_id
left join public.profiles p on p.user_id = fm.user_id
where not exists (
  select 1 from public.travelers t
  where t.family_id = fm.family_id
    and t.linked_user_id = fm.user_id
);
