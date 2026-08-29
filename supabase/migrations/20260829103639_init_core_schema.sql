-- Phase 0 core schema: profiles, families, family_members, travelers.
-- RLS is mandatory from this first migration onward (CLAUDE.md rule #1 /
-- ARCHITECTURE.md "RLS strategy"). No trips/documents/tasks/packing tables
-- yet -- those are V1, not Phase 0.

create extension if not exists pgcrypto; -- gen_random_uuid()

-- ---------------------------------------------------------------------------
-- profiles: 1:1 with auth.users, minimal display data.
-- ---------------------------------------------------------------------------
create table public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  locale text not null default 'he' check (locale in ('he', 'en')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Auto-create a profile row whenever a new auth user is created (Google
-- OAuth or email OTP both land here). Runs as the function owner, so it
-- bypasses RLS -- this is the one place profile rows are created.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, display_name, locale)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    coalesce(new.raw_user_meta_data ->> 'locale', 'he')
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- families: the unit that owns trips (a household, not a company/tenant).
-- ---------------------------------------------------------------------------
create table public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  -- Short, shareable code for the invite flow. Regenerating it is a V1 UI
  -- concern; the column supports it (just update the value).
  invite_code text not null unique
    default lower(substr(encode(gen_random_bytes(6), 'hex'), 1, 8)),
  created_at timestamptz not null default now()
);

alter table public.families enable row level security;

-- ---------------------------------------------------------------------------
-- family_members: adults with Supabase Auth accounts belonging to a family.
-- Deliberately many-to-many (a user can belong to more than one family) --
-- see ARCHITECTURE.md "Multi-family membership". No UI exposes this in V1,
-- but the schema never assumes "one family per user".
-- ---------------------------------------------------------------------------
create table public.family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  unique (family_id, user_id)
);

alter table public.family_members enable row level security;

-- ---------------------------------------------------------------------------
-- travelers: anyone a trip/packing list is about. May or may not be linked
-- to a real account (children/dependents typically are not).
-- ---------------------------------------------------------------------------
create table public.travelers (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  linked_user_id uuid references auth.users (id) on delete set null,
  display_name text not null,
  date_of_birth date,
  created_at timestamptz not null default now()
);

alter table public.travelers enable row level security;

-- ---------------------------------------------------------------------------
-- RLS helper functions
-- ---------------------------------------------------------------------------

-- The mandatory pattern every family-scoped table's policy reuses (see
-- ARCHITECTURE.md "Row Level Security strategy"). security definer + a
-- fixed search_path so it can't be tricked by a caller-controlled search
-- path, stable so the planner can treat it as cheap/cacheable per statement.
create function public.is_family_member(target_family_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members
    where family_id = target_family_id
      and user_id = auth.uid()
  );
$$;

grant execute on function public.is_family_member(uuid) to authenticated;

-- Two users can see each other's profile only if they share a family.
create function public.shares_family_with(target_user_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members mine
    join public.family_members theirs on theirs.family_id = mine.family_id
    where mine.user_id = auth.uid()
      and theirs.user_id = target_user_id
  );
$$;

grant execute on function public.shares_family_with(uuid) to authenticated;

-- Invite-code redemption. Runs as a definer so a user can resolve an invite
-- code into a family membership without first having SELECT access to the
-- families table (which normal RLS would otherwise require).
create function public.join_family_by_invite_code(p_invite_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_family_id uuid;
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

  return v_family_id;
end;
$$;

grant execute on function public.join_family_by_invite_code(text) to authenticated;

-- ---------------------------------------------------------------------------
-- RLS policies
-- ---------------------------------------------------------------------------

-- profiles
create policy "profiles are readable by self or family members"
  on public.profiles for select
  to authenticated
  using (user_id = auth.uid() or public.shares_family_with(user_id));

create policy "profiles are insertable by self"
  on public.profiles for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "profiles are updatable by self"
  on public.profiles for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- families
create policy "families are readable by members"
  on public.families for select
  to authenticated
  using (public.is_family_member(id));

create policy "any authenticated user may create a family"
  on public.families for insert
  to authenticated
  with check (true);

create policy "families are updatable by members"
  on public.families for update
  to authenticated
  using (public.is_family_member(id))
  with check (public.is_family_member(id));

-- family_members
create policy "family membership is readable by co-members"
  on public.family_members for select
  to authenticated
  using (public.is_family_member(family_id));

-- Self-insert only: covers both "creator becomes owner" and "invite-code
-- join" (the latter actually goes through join_family_by_invite_code, but
-- this policy also allows a family's creator to add themselves as owner
-- right after creating the family row, in the same request).
create policy "a user may add only themselves as a family member"
  on public.family_members for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "a user may remove only their own membership"
  on public.family_members for delete
  to authenticated
  using (user_id = auth.uid());

-- travelers
create policy "travelers are readable by family members"
  on public.travelers for select
  to authenticated
  using (public.is_family_member(family_id));

create policy "travelers are insertable by family members"
  on public.travelers for insert
  to authenticated
  with check (public.is_family_member(family_id));

create policy "travelers are updatable by family members"
  on public.travelers for update
  to authenticated
  using (public.is_family_member(family_id))
  with check (public.is_family_member(family_id));

create policy "travelers are deletable by family members"
  on public.travelers for delete
  to authenticated
  using (public.is_family_member(family_id));
