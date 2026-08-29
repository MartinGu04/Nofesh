-- Verification for V1 Slice 1 (trips_and_participants +
-- traveler_member_linking migrations), for the Supabase SQL Editor. Apply
-- both migrations first.
--
-- Same approach as the earlier verification scripts: impersonates two
-- families' worth of throwaway authenticated users via the
-- request.jwt.claim.sub mock, runs entirely inside a transaction that is
-- rolled back at the end, and ends in one consolidated result table.
-- Operations that are SUPPOSED to be blocked are attempted and their
-- exception caught in a DO block, so one blocked operation doesn't abort
-- the rest of the script.
--
-- Run the whole script in one go. If every "passed" is true: create_trip
-- validates family membership, participant family-matching, destination,
-- date range, and non-empty participants; dependent travelers are created
-- correctly (linked_user_id null); direct client writes to travelers and
-- trip_participants are fully closed off; cross-family isolation holds for
-- both tables; and the composite FK enforces traveler/trip family-matching
-- even independent of RLS.

begin;

create temporary table verification_results (
  check_number int,
  description text,
  expected text,
  actual text,
  passed boolean
) on commit drop;
grant all on verification_results to authenticated;

create temporary table fam_a (family_id uuid, invite_code text) on commit drop;
create temporary table fam_b (family_id uuid, invite_code text) on commit drop;
create temporary table fam_b_traveler (traveler_id uuid) on commit drop;
create temporary table trip_a (trip_id uuid) on commit drop;
grant all on fam_a, fam_b, fam_b_traveler, trip_a to authenticated;

insert into auth.users (id, email) values
  ('a1111111-1111-1111-1111-111111111111', 'trip-verify-a@example.invalid'),
  ('b2222222-2222-2222-2222-222222222222', 'trip-verify-b@example.invalid');

-- ---------------------------------------------------------------------------
-- Setup: two families, each via create_family (also exercises the linked-
-- traveler creation from the previous migration as a side effect).
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
insert into fam_a select * from public.create_family('Trip Verify Family A');

reset role;
set local role authenticated;
set local request.jwt.claim.sub = 'b2222222-2222-2222-2222-222222222222';
insert into fam_b select * from public.create_family('Trip Verify Family B');

-- Captured now, while impersonating B (who can see their own traveler row),
-- so check 5 below can reference a *real* cross-family traveler id without
-- needing to read Family B's data while impersonating A (which RLS would
-- correctly hide, making the test accidentally pass for the wrong reason).
insert into fam_b_traveler
select id from public.travelers
where family_id = (select family_id from fam_b)
  and linked_user_id = 'b2222222-2222-2222-2222-222222222222';

-- ---------------------------------------------------------------------------
-- Checks 1-3: User A creates a trip with themselves + one new dependent.
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';

insert into trip_a
select public.create_trip(
  (select family_id from fam_a),
  'Lisbon',
  current_date + 10,
  current_date + 17,
  array[(
    select id from public.travelers
    where family_id = (select family_id from fam_a)
      and linked_user_id = 'a1111111-1111-1111-1111-111111111111'
  )],
  '[{"name": "Kid A", "date_of_birth": "2018-05-01"}]'::jsonb
);

insert into verification_results
select 1, 'User A creates a trip with self + one new dependent', '1 row',
  count(*)::text, count(*) = 1
from trip_a;

insert into verification_results
select 2, 'New dependent traveler "Kid A" was created with linked_user_id NULL',
  'exists, linked_user_id null',
  case when exists (
    select 1 from public.travelers
    where family_id = (select family_id from fam_a) and display_name = 'Kid A'
  ) then coalesce((
    select linked_user_id::text from public.travelers
    where family_id = (select family_id from fam_a) and display_name = 'Kid A'
  ), 'null (correct)') else 'NOT FOUND' end,
  exists (
    select 1 from public.travelers
    where family_id = (select family_id from fam_a)
      and display_name = 'Kid A'
      and linked_user_id is null
  );

insert into verification_results
select 3, 'New dependent "Kid A" is a participant of the created trip', 'true',
  exists (
    select 1 from public.trip_participants tp
    join public.travelers t on t.id = tp.traveler_id
    where tp.trip_id = (select trip_id from trip_a) and t.display_name = 'Kid A'
  )::text,
  exists (
    select 1 from public.trip_participants tp
    join public.travelers t on t.id = tp.traveler_id
    where tp.trip_id = (select trip_id from trip_a) and t.display_name = 'Kid A'
  );

-- ---------------------------------------------------------------------------
-- Check 4: create_trip rejects a family_id the caller doesn't belong to.
-- ---------------------------------------------------------------------------
do $$
begin
  perform public.create_trip(
    (select family_id from fam_b), 'Should Fail', current_date, current_date + 1,
    '{}'::uuid[], '[]'::jsonb
  );
  insert into verification_results values (
    4, 'create_trip rejects a family_id the caller does not belong to',
    'blocked (exception)', 'NOT BLOCKED', false
  );
exception when others then
  insert into verification_results values (
    4, 'create_trip rejects a family_id the caller does not belong to',
    'blocked (exception)', 'blocked: ' || sqlerrm, true
  );
end $$;

-- ---------------------------------------------------------------------------
-- Check 5: create_trip rejects a real traveler_id from a different family.
-- ---------------------------------------------------------------------------
do $$
begin
  perform public.create_trip(
    (select family_id from fam_a), 'Should Fail Cross Traveler',
    current_date, current_date + 1,
    array[(select traveler_id from fam_b_traveler)], '[]'::jsonb
  );
  insert into verification_results values (
    5, 'create_trip rejects a traveler_id from a different family',
    'blocked (exception)', 'NOT BLOCKED', false
  );
exception when others then
  insert into verification_results values (
    5, 'create_trip rejects a traveler_id from a different family',
    'blocked (exception)', 'blocked: ' || sqlerrm, true
  );
end $$;

-- ---------------------------------------------------------------------------
-- Checks 6-8: basic field validation.
-- ---------------------------------------------------------------------------
do $$
begin
  perform public.create_trip(
    (select family_id from fam_a), '   ', current_date, current_date + 1,
    '{}'::uuid[], '[{"name": "X"}]'::jsonb
  );
  insert into verification_results values (
    6, 'create_trip rejects an empty/blank destination',
    'blocked (exception)', 'NOT BLOCKED', false
  );
exception when others then
  insert into verification_results values (
    6, 'create_trip rejects an empty/blank destination',
    'blocked (exception)', 'blocked: ' || sqlerrm, true
  );
end $$;

do $$
begin
  perform public.create_trip(
    (select family_id from fam_a), 'Bad Dates', current_date + 5, current_date,
    '{}'::uuid[], '[{"name": "X"}]'::jsonb
  );
  insert into verification_results values (
    7, 'create_trip rejects end_date before start_date',
    'blocked (exception)', 'NOT BLOCKED', false
  );
exception when others then
  insert into verification_results values (
    7, 'create_trip rejects end_date before start_date',
    'blocked (exception)', 'blocked: ' || sqlerrm, true
  );
end $$;

do $$
begin
  perform public.create_trip(
    (select family_id from fam_a), 'No Travelers', current_date, current_date + 1,
    '{}'::uuid[], '[]'::jsonb
  );
  insert into verification_results values (
    8, 'create_trip rejects zero participants', 'blocked (exception)',
    'NOT BLOCKED', false
  );
exception when others then
  insert into verification_results values (
    8, 'create_trip rejects zero participants', 'blocked (exception)',
    'blocked: ' || sqlerrm, true
  );
end $$;

-- ---------------------------------------------------------------------------
-- Check 9: no direct client INSERT into travelers (least privilege --
-- creation only ever happens inside a SECURITY DEFINER RPC).
-- ---------------------------------------------------------------------------
do $$
begin
  insert into public.travelers (family_id, linked_user_id, display_name)
  values ((select family_id from fam_a), null, 'Direct Insert Attempt');
  insert into verification_results values (
    9, 'Direct client INSERT into travelers is blocked (no policy)',
    'blocked (RLS exception)', 'NOT BLOCKED', false
  );
exception when others then
  insert into verification_results values (
    9, 'Direct client INSERT into travelers is blocked (no policy)',
    'blocked (RLS exception)', 'blocked: ' || sqlerrm, true
  );
end $$;

-- ---------------------------------------------------------------------------
-- Check 10: linked_user_id cannot be changed by a direct client UPDATE.
-- There's no UPDATE policy at all on travelers, so (unlike INSERT) this
-- doesn't raise -- RLS's implicit "no matching rows" for an operation with
-- zero applicable policies just makes the UPDATE affect nothing, the same
-- way a WHERE clause matching no rows would. Verified by reading the row
-- back as postgres (bypasses RLS) to confirm it's genuinely unchanged.
-- ---------------------------------------------------------------------------
update public.travelers
set linked_user_id = 'a1111111-1111-1111-1111-111111111111'
where family_id = (select family_id from fam_a) and display_name = 'Kid A';

reset role;

insert into verification_results
select 10, 'Direct client UPDATE cannot set linked_user_id (no UPDATE policy at all)',
  'still null', coalesce(linked_user_id::text, 'null (correct)'), linked_user_id is null
from public.travelers
where family_id = (select family_id from fam_a) and display_name = 'Kid A';

-- ---------------------------------------------------------------------------
-- Check 11: no direct client INSERT into trip_participants either.
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';

do $$
begin
  insert into public.trip_participants (trip_id, traveler_id, family_id)
  values (
    (select trip_id from trip_a),
    (select traveler_id from fam_b_traveler),
    (select family_id from fam_a)
  );
  insert into verification_results values (
    11, 'Direct client INSERT into trip_participants is blocked (no policy)',
    'blocked (RLS exception)', 'NOT BLOCKED', false
  );
exception when others then
  insert into verification_results values (
    11, 'Direct client INSERT into trip_participants is blocked (no policy)',
    'blocked (RLS exception)', 'blocked: ' || sqlerrm, true
  );
end $$;

-- ---------------------------------------------------------------------------
-- Checks 12-13: cross-family isolation for both new tables.
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
set local request.jwt.claim.sub = 'b2222222-2222-2222-2222-222222222222';

insert into verification_results
select 12, 'Family B cannot see Family A''s trip', '0', count(*)::text, count(*) = 0
from public.trips where id = (select trip_id from trip_a);

insert into verification_results
select 13, 'Family B cannot see Family A''s trip participants', '0',
  count(*)::text, count(*) = 0
from public.trip_participants where trip_id = (select trip_id from trip_a);

-- ---------------------------------------------------------------------------
-- Check 14: the composite FK rejects a traveler/family mismatch even for a
-- role that bypasses RLS entirely -- proves this is a structural guarantee,
-- not just something the RPC's application-level check happens to catch.
-- ---------------------------------------------------------------------------
reset role;

do $$
begin
  insert into public.trip_participants (trip_id, traveler_id, family_id)
  values (
    (select trip_id from trip_a),
    (select traveler_id from fam_b_traveler),
    (select family_id from fam_a)
  );
  insert into verification_results values (
    14, 'Composite FK rejects a traveler/family mismatch even bypassing RLS',
    'blocked (FK violation)', 'NOT BLOCKED', false
  );
exception when others then
  insert into verification_results values (
    14, 'Composite FK rejects a traveler/family mismatch even bypassing RLS',
    'blocked (FK violation)', 'blocked: ' || sqlerrm, true
  );
end $$;

-- One consolidated result: every check together.
select * from verification_results order by check_number;

-- Nothing above is kept -- this is a read-only check of your real schema.
rollback;
