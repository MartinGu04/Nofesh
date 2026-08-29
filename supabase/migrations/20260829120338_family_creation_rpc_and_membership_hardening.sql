-- Additive fix on top of 20260829103639_init_core_schema.sql (already
-- applied to the real project -- this migration is new, not a rewrite).
--
-- Two related bugs at the database layer:
--
-- 1. Family creation raced its own RLS. The server action did
--    `insert into families ... returning id`, but the families SELECT
--    policy requires is_family_member(id), and at the moment the INSERT's
--    RETURNING clause is evaluated the creator is not yet a member (that
--    insert into family_members happened as a separate, later statement).
--    Postgres applies SELECT-policy visibility rules to RETURNING output,
--    so the insert appeared to return no row and the client-side flow
--    failed with a generic error. Fixed by moving both inserts into one
--    SECURITY DEFINER RPC (create_family), which -- like the existing
--    join_family_by_invite_code -- runs as the function owner and so isn't
--    subject to the caller's RLS on its own internal operations.
--
-- 2. The family_members INSERT policy from the first migration,
--    `with check (user_id = auth.uid())`, only constrained *who* a row
--    could be inserted for, not *which family* or *which role*. Any
--    authenticated user who knew (or enumerated) a family_id could insert
--    themselves into it, as 'owner' if they chose. Fixed by dropping that
--    policy entirely: the only two ways to become a family member are now
--    the create_family RPC (owner, on creation) and
--    join_family_by_invite_code (member, given a real invite code), both
--    SECURITY DEFINER and neither reachable via a direct client-side
--    table insert.

-- ---------------------------------------------------------------------------
-- 1. Remove the direct-insert policy that allowed self-service membership
--    (and role) escalation. No replacement policy: after this, every
--    family_members row must be created by a SECURITY DEFINER RPC.
-- ---------------------------------------------------------------------------
drop policy if exists "a user may add only themselves as a family member"
  on public.family_members;

-- ---------------------------------------------------------------------------
-- 2. create_family(): atomically creates a family and makes the caller its
--    owner. Mirrors join_family_by_invite_code's shape (security definer,
--    fixed search_path, authenticated-only).
-- ---------------------------------------------------------------------------
create function public.create_family(p_name text)
returns table (family_id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := trim(both from p_name);
  v_family_id uuid;
  v_invite_code text;
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

  return query select v_family_id, v_invite_code;
end;
$$;

-- Functions are executable by PUBLIC by default in Postgres regardless of
-- who they're also granted to -- revoke that first so "authenticated only"
-- is actually true, not just additive.
revoke all on function public.create_family(text) from public;
grant execute on function public.create_family(text) to authenticated;
