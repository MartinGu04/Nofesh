# Nofesh

A warm, calm, family-oriented companion for the full lifecycle of a
vacation. See `PRODUCT.md`, `DESIGN.md`, `ARCHITECTURE.md`, and `CLAUDE.md`
for the product, design, and engineering foundation this app is built on.

## Status

Phase 0 (foundation): Next.js + Supabase scaffold, Hebrew/English i18n,
self-hosted brand typography, the core `families`/`family_members`/
`travelers`/`profiles` schema with RLS, and a Google OAuth + email OTP
sign-in and family onboarding flow. No trips, packing, or Trip Inbox yet —
that's V1.

## Setup

1. `npm install`
2. Copy `.env.example` to `.env.local` and fill in your Supabase project's
   URL and anon key (Project Settings → API in the Supabase dashboard).
3. For Google sign-in to work, configure the Google provider under
   Authentication → Providers in the Supabase dashboard, with the redirect
   URI set to `<your-app-origin>/auth/callback`.
4. Apply the database migration: `npx supabase link --project-ref <ref>`
   then `npx supabase db push` (or run the SQL in
   `supabase/migrations/` directly against your project).
5. `npm run dev`

## Database

Migrations live in `supabase/migrations/`, applied via the Supabase CLI —
never hand-edit a live schema (see `CLAUDE.md`). The cross-family RLS
isolation test is a pgTAP test at
`supabase/tests/database/rls_family_isolation.sql`, run with
`npx supabase test db` against a local stack (`npx supabase start`, which
needs Docker) or a linked project's test database.

If the CLI can't reach your project directly (no local Docker, no DB
password shared with an agent), apply a migration by pasting its file's
contents into the Supabase dashboard's SQL Editor instead, in order. After
applying, `supabase/verification/phase0_rls_check.sql` is a read-only,
self-rolling-back script for the SQL Editor that checks cross-family RLS
isolation without needing a real second user or the CLI.
