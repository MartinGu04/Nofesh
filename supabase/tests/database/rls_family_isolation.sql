-- Cross-family RLS isolation test, per ARCHITECTURE.md's "RLS strategy" and
-- the Phase 0 definition of done in CLAUDE.md: a family must never be able
-- to read another family's data.
--
-- Run with: supabase test db  (requires the local Postgres stack, i.e.
-- `supabase start`, or a linked project's test database).
--
-- Mocks auth.uid() the way Supabase's own RLS testing guide does: set the
-- `authenticated` role and the request.jwt.claim.sub GUC that auth.uid()
-- reads from, rather than going through real Supabase Auth.

begin;
select plan(8);

-- Two families, each with one owner, set up as postgres (bypasses RLS).
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner-a@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'owner-b@example.com');

insert into public.families (id, name) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Family A'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'Family B');

insert into public.family_members (family_id, user_id, role) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'owner'),
  ('bbbbbbbb-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'owner');

insert into public.travelers (id, family_id, display_name) values
  ('aaaaaaaa-1111-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'Traveler A'),
  ('bbbbbbbb-1111-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'Traveler B');

-- Act as Family A's owner.
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

select is(
  (select count(*)::int from public.families where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  1,
  'Family A owner can read Family A'
);

select is(
  (select count(*)::int from public.families where id = 'bbbbbbbb-0000-0000-0000-000000000002'),
  0,
  'Family A owner cannot read Family B'
);

select is(
  (select count(*)::int from public.family_members where family_id = 'bbbbbbbb-0000-0000-0000-000000000002'),
  0,
  'Family A owner cannot read Family B membership'
);

select is(
  (select count(*)::int from public.travelers where family_id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  1,
  'Family A owner can read Family A travelers'
);

select is(
  (select count(*)::int from public.travelers where family_id = 'bbbbbbbb-0000-0000-0000-000000000002'),
  0,
  'Family A owner cannot read Family B travelers'
);

-- RLS silently filters rows rather than erroring, so this update should
-- succeed as a statement but affect zero rows.
update public.travelers set display_name = 'Hijacked'
  where family_id = 'bbbbbbbb-0000-0000-0000-000000000002';

select is(
  (select display_name from public.travelers where id = 'bbbbbbbb-1111-0000-0000-000000000002'),
  'Traveler B',
  'Family A owner cannot update Family B travelers (0 rows affected)'
);

-- Invite-code join must be self-only: Family A's owner cannot add someone
-- else as a member of Family A.
select throws_ok(
  $$ insert into public.family_members (family_id, user_id) values ('aaaaaaaa-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222') $$,
  '42501',
  null,
  'A user cannot add someone else as a family member'
);

-- Switch to Family B's owner and confirm the same isolation in reverse.
reset role;
set local role authenticated;
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

select is(
  (select count(*)::int from public.families where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  0,
  'Family B owner cannot read Family A'
);

select finish();
rollback;
