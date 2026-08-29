-- Phase 0 manual RLS verification, for the Supabase SQL Editor.
--
-- The SQL Editor runs as the `postgres` superuser, which BYPASSES RLS --
-- so a plain `select * from families` there would tell you nothing about
-- what a real user can see. This script instead impersonates two different
-- authenticated users (via the same request.jwt.claim.sub mock that
-- Supabase's own RLS testing docs use) and runs everything inside a
-- transaction that is rolled back at the end, so no test data is left
-- behind in your project.
--
-- Run the whole script in one go. The final statement returns one
-- consolidated table with all 7 checks. If every "passed" is true,
-- cross-family isolation is working. If anything is false, RLS is not
-- doing its job and this needs attention before any real feature is built
-- on top of it.

begin;

-- Collects every check's result so the script ends in a single consolidated
-- SELECT instead of 7 separate result sets. Granted explicitly to
-- `authenticated` because Supabase's default privileges only cover the
-- `public` schema, not a session-local temp table's pg_temp schema.
create temporary table verification_results (
  check_number int,
  description text,
  expected text,
  actual text,
  passed boolean
) on commit drop;
grant all on verification_results to authenticated;

-- Two throwaway families/users, verification-only.
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'verify-a@example.invalid'),
  ('22222222-2222-2222-2222-222222222222', 'verify-b@example.invalid');

insert into public.families (id, name) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Verify Family A'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'Verify Family B');

insert into public.family_members (family_id, user_id, role) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'owner'),
  ('bbbbbbbb-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'owner');

insert into public.travelers (id, family_id, display_name) values
  ('aaaaaaaa-1111-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'Traveler A'),
  ('bbbbbbbb-1111-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'Traveler B');

-- Impersonate Family A's owner.
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

insert into verification_results
select 1, 'Family A owner sees Family A', '1', count(*)::text, count(*) = 1
from public.families where id = 'aaaaaaaa-0000-0000-0000-000000000001';

insert into verification_results
select 2, 'Family A owner does NOT see Family B', '0', count(*)::text, count(*) = 0
from public.families where id = 'bbbbbbbb-0000-0000-0000-000000000002';

insert into verification_results
select 3, 'Family A owner does NOT see Family B membership', '0', count(*)::text, count(*) = 0
from public.family_members where family_id = 'bbbbbbbb-0000-0000-0000-000000000002';

insert into verification_results
select 4, 'Family A owner sees Family A traveler', '1', count(*)::text, count(*) = 1
from public.travelers where family_id = 'aaaaaaaa-0000-0000-0000-000000000001';

insert into verification_results
select 5, 'Family A owner does NOT see Family B traveler', '0', count(*)::text, count(*) = 0
from public.travelers where family_id = 'bbbbbbbb-0000-0000-0000-000000000002';

-- Attempted cross-family write, still as Family A's owner. Under correct
-- RLS this silently affects 0 rows rather than erroring, because the
-- UPDATE's USING clause filters the target row out entirely -- Family A
-- cannot even see the row exists, let alone change it.
update public.travelers set display_name = 'Hijacked'
  where family_id = 'bbbbbbbb-0000-0000-0000-000000000002';

-- Check 6 has to be read as postgres, not as Family A: if RLS is correct,
-- Family A cannot SELECT Family B's traveler at all, so re-reading it while
-- still impersonating Family A would prove nothing either way (0 rows back
-- looks identical whether the UPDATE was blocked or the row just isn't
-- visible). Dropping back to postgres bypasses RLS so we can see the row's
-- real, current value and confirm the earlier UPDATE never touched it.
reset role;

insert into verification_results
select 6, 'Family B traveler unchanged after Family A owner tried to edit it', 'Traveler B', display_name, display_name = 'Traveler B'
from public.travelers where id = 'bbbbbbbb-1111-0000-0000-000000000002';

-- Switch to Family B's owner and confirm the same isolation in reverse.
set local role authenticated;
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

insert into verification_results
select 7, 'Family B owner does NOT see Family A', '0', count(*)::text, count(*) = 0
from public.families where id = 'aaaaaaaa-0000-0000-0000-000000000001';

reset role;

-- One consolidated result: all 7 checks together.
select * from verification_results order by check_number;

-- Nothing above is kept -- this is a read-only check of your real schema.
rollback;
