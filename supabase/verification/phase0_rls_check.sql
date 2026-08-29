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
-- How to read the results: run the whole script. Each numbered check
-- returns one row with the actual count next to the expected count in its
-- label. If every "actual" matches its "expected", cross-family isolation
-- is working. If anything shows a Family B row while impersonating Family
-- A (or vice versa), RLS is not doing its job and this needs attention
-- before any real feature is built on top of it.

begin;

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

select '1. Family A owner sees Family A (expect 1)' as check, count(*) as actual
from public.families where id = 'aaaaaaaa-0000-0000-0000-000000000001';

select '2. Family A owner does NOT see Family B (expect 0)' as check, count(*) as actual
from public.families where id = 'bbbbbbbb-0000-0000-0000-000000000002';

select '3. Family A owner does NOT see Family B membership (expect 0)' as check, count(*) as actual
from public.family_members where family_id = 'bbbbbbbb-0000-0000-0000-000000000002';

select '4. Family A owner sees Family A traveler (expect 1)' as check, count(*) as actual
from public.travelers where family_id = 'aaaaaaaa-0000-0000-0000-000000000001';

select '5. Family A owner does NOT see Family B traveler (expect 0)' as check, count(*) as actual
from public.travelers where family_id = 'bbbbbbbb-0000-0000-0000-000000000002';

-- Attempted cross-family write: should silently affect 0 rows, not error,
-- because RLS filters the WHERE clause down to nothing this role can touch.
update public.travelers set display_name = 'Hijacked'
  where family_id = 'bbbbbbbb-0000-0000-0000-000000000002';

select '6. Family B traveler unchanged after Family A owner tried to edit it (expect Traveler B)' as check,
  display_name as actual
from public.travelers where id = 'bbbbbbbb-1111-0000-0000-000000000002';

-- Switch to Family B's owner and confirm the same isolation in reverse.
reset role;
set local role authenticated;
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

select '7. Family B owner does NOT see Family A (expect 0)' as check, count(*) as actual
from public.families where id = 'aaaaaaaa-0000-0000-0000-000000000001';

-- Nothing above is kept -- this is a read-only check of your real schema.
rollback;
