-- Verification for the create_family() RPC + family_members hardening
-- migration (20260829120338_family_creation_rpc_and_membership_hardening),
-- for the Supabase SQL Editor. Apply that migration first.
--
-- Same approach as phase0_rls_check.sql: impersonates several throwaway
-- authenticated users via the request.jwt.claim.sub mock Supabase's own
-- RLS testing docs use, runs entirely inside a transaction that is rolled
-- back at the end (nothing persists), and ends in one consolidated result
-- table instead of scattered per-statement output.
--
-- Checks an operation that's SUPPOSED to be blocked by attempting it and
-- catching the resulting exception in a DO block -- an uncaught RLS
-- violation would otherwise abort the whole script.
--
-- Run the whole script in one go. If every "passed" is true, both fixes
-- are working: family creation no longer races its own RLS, and direct
-- client-side inserts into family_members are fully closed off.

begin;

create temporary table verification_results (
  check_number int,
  description text,
  expected text,
  actual text,
  passed boolean
) on commit drop;
grant all on verification_results to authenticated;

-- Stash tables for what create_family() hands back, since its family_id
-- and invite_code are server-generated and can't be hardcoded up front.
create temporary table test_family_a (family_id uuid, invite_code text) on commit drop;
create temporary table test_family_c (family_id uuid, invite_code text) on commit drop;
grant all on test_family_a to authenticated;
grant all on test_family_c to authenticated;

-- Three throwaway users, verification-only.
insert into auth.users (id, email) values
  ('a1111111-1111-1111-1111-111111111111', 'verify-creator-a@example.invalid'),
  ('b2222222-2222-2222-2222-222222222222', 'verify-joiner-b@example.invalid'),
  ('c3333333-3333-3333-3333-333333333333', 'verify-creator-c@example.invalid');

-- ---------------------------------------------------------------------------
-- Checks 1-3: User A creates a family via the RPC, becomes owner, and can
-- immediately read it back (the exact sequence that used to fail).
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';

insert into test_family_a
select * from public.create_family('Verify Family A');

insert into verification_results
select 1, 'User A can create a family through create_family()', '1 row returned',
  count(*)::text, count(*) = 1
from test_family_a;

-- Written as scalar subqueries (no FROM/WHERE driving row count) so this
-- always inserts exactly one row, even if no matching membership row
-- exists at all -- a plain `select role from family_members where ...`
-- would silently insert zero rows in that case, making the check vanish
-- from the results instead of showing up as a clear failure.
insert into verification_results
select 2, 'Creator (User A) becomes owner in family_members', 'owner',
  coalesce((
    select role from public.family_members
    where family_id = (select family_id from test_family_a)
      and user_id = 'a1111111-1111-1111-1111-111111111111'
  ), 'NOT A MEMBER'),
  coalesce((
    select role from public.family_members
    where family_id = (select family_id from test_family_a)
      and user_id = 'a1111111-1111-1111-1111-111111111111'
  ) = 'owner', false);

insert into verification_results
select 3, 'Creator (User A) can immediately read the new family', '1',
  count(*)::text, count(*) = 1
from public.families
where id = (select family_id from test_family_a);

-- ---------------------------------------------------------------------------
-- Checks 4-5: User B cannot directly INSERT into Family A's membership,
-- neither as a regular member nor by choosing role = 'owner'.
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
set local request.jwt.claim.sub = 'b2222222-2222-2222-2222-222222222222';

do $$
declare
  v_family_id uuid;
begin
  select family_id into v_family_id from test_family_a;
  insert into public.family_members (family_id, user_id, role)
  values (v_family_id, 'b2222222-2222-2222-2222-222222222222', 'member');
  insert into verification_results values (
    4, 'User B cannot directly INSERT itself into Family A as member',
    'blocked (RLS exception)', 'NOT BLOCKED -- insert succeeded', false
  );
exception when others then
  insert into verification_results values (
    4, 'User B cannot directly INSERT itself into Family A as member',
    'blocked (RLS exception)', 'blocked: ' || sqlerrm, true
  );
end $$;

do $$
declare
  v_family_id uuid;
begin
  select family_id into v_family_id from test_family_a;
  insert into public.family_members (family_id, user_id, role)
  values (v_family_id, 'b2222222-2222-2222-2222-222222222222', 'owner');
  insert into verification_results values (
    5, 'User B cannot directly INSERT itself into Family A as owner',
    'blocked (RLS exception)', 'NOT BLOCKED -- insert succeeded', false
  );
exception when others then
  insert into verification_results values (
    5, 'User B cannot directly INSERT itself into Family A as owner',
    'blocked (RLS exception)', 'blocked: ' || sqlerrm, true
  );
end $$;

-- ---------------------------------------------------------------------------
-- Check 6: the legitimate path still works -- a valid invite code joins
-- User B as a regular member (not owner).
-- ---------------------------------------------------------------------------
select public.join_family_by_invite_code((select invite_code from test_family_a));

insert into verification_results
select 6, 'User B joins Family A via a valid invite code, as member', 'member',
  coalesce((
    select role from public.family_members
    where family_id = (select family_id from test_family_a)
      and user_id = 'b2222222-2222-2222-2222-222222222222'
  ), 'NOT A MEMBER'),
  coalesce((
    select role from public.family_members
    where family_id = (select family_id from test_family_a)
      and user_id = 'b2222222-2222-2222-2222-222222222222'
  ) = 'member', false);

-- ---------------------------------------------------------------------------
-- Check 7: an invalid invite code is still rejected.
-- ---------------------------------------------------------------------------
do $$
begin
  perform public.join_family_by_invite_code('this-code-does-not-exist');
  insert into verification_results values (
    7, 'An invalid invite code is rejected', 'blocked (exception)',
    'NOT BLOCKED -- join succeeded', false
  );
exception when others then
  insert into verification_results values (
    7, 'An invalid invite code is rejected', 'blocked (exception)',
    'blocked: ' || sqlerrm, true
  );
end $$;

-- ---------------------------------------------------------------------------
-- Check 8: cross-family isolation still holds after these changes, checked
-- in both directions against a freshly RPC-created second family.
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
set local request.jwt.claim.sub = 'c3333333-3333-3333-3333-333333333333';

insert into test_family_c
select * from public.create_family('Verify Family C');

insert into verification_results
select 8, 'Cross-family isolation: User C cannot see Family A', '0',
  count(*)::text, count(*) = 0
from public.families
where id = (select family_id from test_family_a);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';

insert into verification_results
select 9, 'Cross-family isolation: User A cannot see Family C', '0',
  count(*)::text, count(*) = 0
from public.families
where id = (select family_id from test_family_c);

reset role;

-- One consolidated result: every check together.
select * from verification_results order by check_number;

-- Nothing above is kept -- this is a read-only check of your real schema.
rollback;
