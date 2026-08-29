# Nofesh — Architecture

This document covers system shape and the database foundation. It describes
what Phase 0/V1 will build; it does not itself scaffold the app or create
migrations — see PRODUCT.md's Roadmap for sequencing.

## System overview

```
                     ┌───────────────────────────┐
                     │        Vercel (Next.js)    │
                     │  App Router, RSC-first      │
                     │  Server Actions for writes   │
                     └──────────────┬───────────────┘
                                    │ (server: service calls via
                                    │  user JWT, RLS enforced)
                                    ▼
                     ┌───────────────────────────┐
                     │          Supabase           │
                     │  Postgres + RLS              │
                     │  Auth                        │
                     │  Storage (documents)         │
                     │  Realtime (family sync)      │
                     └───────────────────────────┘
```

- **Next.js (App Router, TypeScript, Tailwind)**, deployed on Vercel. Server
  Components by default; Client Components only where interaction requires
  it (forms, packing checkboxes, realtime-driven UI).
- **Supabase** is the entire backend: Postgres for data, Supabase Auth for
  identity, Storage for documents, Realtime for family-shared live updates
  (e.g. one parent checks off a packing item, the other sees it update).
  No separate backend service in V1 — Server Actions and Route Handlers call
  Supabase directly with the user's session; Postgres RLS is the actual
  authorization boundary, not application code.
- No queueing/worker infrastructure, no separate API gateway, no OCR/LLM
  pipeline in Phase 0/V1 — deliberately deferred (see "Deferred" below).

## Auth model

Supabase Auth handles identity (email/password to start; magic link and/or
Google OAuth are easy additions later — flagged as an open decision). A
signed-in user is a **family member**. On first sign-up, a user either
creates a new family or accepts an invite into an existing one. A user
belongs to at least one family; the schema allows belonging to more than one
(see `family_members` below) to cover blended-family and grandparent cases,
even though V1 UI may only actively exercise the single-family path.

**Travelers without accounts are not Supabase Auth users.** They are rows the
family manages, optionally linked to a real account later (e.g. a teenager
gets their own login and the family links their existing traveler record to
it) — that linking is a Phase 2 concern, not V1.

## Row Level Security strategy

Every family-owned table carries a `family_id`. RLS policies check that
`auth.uid()` is a member of that `family_id` via `family_members`, using a
`SECURITY DEFINER` helper function (not a policy subquery that hits the
`family_members` table directly from every other table's policy, to keep
plans simple and avoid recursive policy evaluation):

```sql
create or replace function is_family_member(target_family_id uuid)
returns boolean
language sql security definer stable as $$
  select exists (
    select 1 from family_members
    where family_id = target_family_id
      and user_id = auth.uid()
  );
$$;
```

Every subsequent table's policy is then a one-liner:
`using (is_family_member(family_id))`. This is the mandatory pattern from the
first migration onward — **no table holding trip, document, task, or packing
data ships without RLS enabled and this policy in place.** A cross-family
access test (family A cannot read family B's trip) is part of the Phase 0
definition of done, not a nice-to-have.

`travelers` without a linked `user_id` are read/written only through their
owning family's membership — they never authenticate themselves, so their
"access" is entirely mediated by the adult family members' RLS.

## Domain model (Phase 0/V1 minimum)

This is the conceptual model — entity list, key columns, relationships — not
final DDL. Actual migrations are written in Phase 0 and may refine column
types/constraints (e.g. exact enums, check constraints per the
`israeli-postgres-toolkit` and `israeli-appsec-scanner` guidance already
folded into this design: `timestamptz` everywhere, `numeric` for any stored
amount, Hebrew columns get `simple`-config search where needed, RLS
mandatory, no secrets in the client).

```
families
  id, name, created_at

family_members                      -- adults with accounts
  id, family_id → families, user_id → auth.users, role ('owner'|'member'),
  joined_at

profiles                            -- 1:1 with auth.users, display data
  user_id → auth.users (PK), display_name, locale ('he'|'en'), created_at

travelers                           -- anyone a trip/packing list is about
  id, family_id → families, linked_user_id → auth.users (nullable),
  display_name, date_of_birth (nullable), created_at

trips
  id, family_id → families, title, destination, destination_country,
  start_date, end_date, cover_image_url (nullable), status
  ('draft'|'active'|'archived'), created_by → auth.users, created_at

trip_participants                   -- who is going on THIS trip
  id, trip_id → trips, traveler_id → travelers

trip_items                          -- flights, stays, restaurants, activities...
  id, trip_id → trips, family_id → families (denormalized for RLS simplicity),
  item_type ('flight'|'stay'|'restaurant'|'activity'|'transport'|'other'),
  title, starts_at (timestamptz, nullable), ends_at (nullable),
  location_text (nullable), confirmation_code (nullable),
  details jsonb (type-specific structured extras),
  status ('candidate'|'confirmed'), source ('manual'|'pasted'),
  created_by → auth.users, created_at

documents
  id, family_id → families, trip_id → trips (nullable),
  trip_item_id → trip_items (nullable), storage_path, file_name,
  mime_type, uploaded_by → auth.users, created_at

tasks
  id, trip_id → trips, family_id → families, title,
  due_at (timestamptz, nullable), assigned_traveler_id → travelers (nullable),
  is_done boolean default false, created_at

packing_lists
  id, trip_id → trips, traveler_id → travelers, created_at
  -- one list per (trip, traveler)

packing_items
  id, packing_list_id → packing_lists, name, category
  ('clothing'|'documents'|'toiletries'|'electronics'|'medical'|'other'),
  quantity default 1, is_packed boolean default false,
  origin ('manual'|'suggested'|'memory'), created_at

packing_memory_signals                -- the learning loop, kept simple
  id, family_id → families, traveler_id → travelers (nullable = family-wide),
  item_name, category, signal ('forgotten'|'unused'|'always_needed'),
  trip_id → trips (source trip), created_at
```

Notes on deliberate simplicity:

- **Lifecycle stage is computed, not stored.** `trips.status` only
  distinguishes draft/active/archived at a coarse level; the fine-grained
  Planning/Preparing/Packing/Departure/Today/Return presentation is derived
  at render time from `start_date`, `end_date`, today's date, and completion
  signals (tasks done, packing completion). This avoids a stage column that
  can silently drift out of sync with reality. Flagged as an open decision
  in case product testing shows a family needs to *pin* a stage manually.
- **`trip_items.details` is a single `jsonb` column** rather than a table
  per item type. Five item types with mostly-overlapping common fields
  (title/time/location/confirmation code) don't earn five tables yet; jsonb
  holds the type-specific extras (seat number, room type, party size). If
  V1 usage shows a type needs real relational querying, split it out then.
- **`packing_memory_signals` is an append-only log**, not a pre-aggregated
  "family packing profile" table. V1's suggestion logic reads recent signals
  per family/traveler/category at request time; a materialized profile can
  be added later if that read becomes a bottleneck — premature to build now.
- **No `payments`, `cards`, or `passport_scans` tables** — deliberately absent
  per the product's non-goals and data-minimization stance.

## Storage

A single Supabase Storage bucket (e.g. `trip-documents`) with per-family
folder prefixes (`{family_id}/...`) and storage policies mirroring the same
`is_family_member` check used for Postgres RLS. No public buckets for user
documents. Cover images for trips may live in a separate, smaller bucket or
be sourced from a curated set of destination images shipped with the app
(avoids a "which images can users upload publicly" question in V1).

## Realtime

Supabase Realtime on `packing_items` (packed/unpacked toggling) and
`tasks` (done/undone) scoped by `trip_id`, so one family member's phone
reflects another's actions live. This is the only place Realtime is used in
V1 — not a blanket "everything is realtime" approach, since most of the app
(trip items, documents) doesn't need sub-second sync to feel good.

## Internationalization architecture

`next-intl` with `he` (default) and `en` locales, `[locale]` route segment,
`<html lang dir>` set per the resolved locale. Message keys are semantic
(`packing.item.addLabel`), never the English source string, per the
`hebrew-i18n` skill's guidance — this matters doubly for Nofesh since Hebrew
strings are frequently shorter or longer than their English counterparts and
a key-as-string pattern breaks layouts silently. A user's `profiles.locale`
is the source of truth once signed in; anonymous visitors get browser-language
detection with Hebrew as the ultimate fallback (matching the target market).

## Security and privacy posture

- Service role key lives only in server-only environments (never bundled to
  the client, never used in a Client Component or exposed API response).
- RLS is the authorization boundary; application code is a UX convenience on
  top of it, not the thing actually preventing cross-family access.
- Data minimization: only the fields product functionality genuinely needs.
  No card numbers, no passport scans/numbers in V1 — if a document photo of a
  passport is uploaded as a generic "document" attachment, that's the user's
  own file in their own family's storage prefix, not a structured field
  Nofesh parses or indexes.
- Personal data now explicitly includes IP/geolocation/device identifiers
  under Israeli Amendment 13 — any analytics added later needs the consent
  model from `israeli-privacy-shield` before it ships, not retrofitted after.
- A privacy policy (Hebrew + English) is a Phase 0/V1 deliverable, not a
  post-launch afterthought, per the same skill's guidance on notice-at-
  collection duties.
- Standard OWASP posture applies (parameterized queries via
  Supabase client, CSP headers, no secrets in git, dependency scanning in
  CI) — full checklist lives in `israeli-appsec-scanner`, to be run before
  the Phase 0/V1 deploy, not designed from scratch here.

## Deployment

- **Vercel** for the Next.js app: preview deployments per PR, a `staging`
  environment tracking `main`, production promoted manually.
- **Supabase**: separate projects for dev/staging and production (never share
  a database across environments). Environment variables (`NEXT_PUBLIC_
  SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`)
  managed in Vercel's project settings, service role key restricted to
  server-only variable scope.
- Migrations are plain SQL files under version control, applied via the
  Supabase CLI (`supabase migration new`, `supabase db push`) — no hand-edits
  to a live schema.

## PWA readiness (not built yet, architected for)

V1 ships a web app manifest and app icons so "Add to Home Screen" works, and
keeps data-fetching patterns (Server Components + Server Actions) that don't
fight an eventual service worker. It does **not** ship a service worker,
offline caching, or background sync in V1 — that's real, non-trivial work
(especially with Realtime and family-shared writes) and is explicitly
deferred until the core product is proven.

## Deferred (explicitly out of Phase 0/V1)

- Automated extraction from screenshots/PDFs/forwarded text (the eventual
  "Trip Inbox" parsing engine) — needs its own design pass (what model, what
  confidence UX, what happens on a bad extraction) before it's built.
- Push notifications.
- Offline support / service worker / background sync.
- Weather API integration (Departure Assistant references "weather changes"
  conceptually in V1 via manual/simple lookups; a real provider integration
  is a fast-follow, not blocking).
- Multi-family sharing of a single trip (e.g. two families traveling
  together) — the schema's `family_id`-per-trip model would need rework.
- Fine-grained roles beyond adult member / traveler.
