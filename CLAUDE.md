# CLAUDE.md

Guidance for Claude Code (and any agent) working in this repository.

## Read these first

- `PRODUCT.md` — what Nofesh is, the lifecycle model, terminology, V1 scope.
- `DESIGN.md` — the visual/interaction source of truth. Not advisory.
- `ARCHITECTURE.md` — system shape and the domain model/database foundation.

If a request conflicts with what's in those three files, the files win over
your own judgment about what a "typical" app of this kind should look like.

## What Nofesh is (one line)

A warm, calm, family-oriented companion for the full lifecycle of a vacation
(planning → preparing → packing → departure → during → return). It is not a
booking platform and never processes payments.

## Stack

- Next.js, latest stable, **App Router**, TypeScript, Tailwind CSS.
- Supabase: Auth, Postgres (with RLS), Storage, Realtime.
- Deployed to Vercel.
- Hebrew (default) + English via `next-intl`, `[locale]` route segment.

## Hard rules (non-negotiable)

1. **RLS is mandatory from the first migration.** No table holding family,
   trip, document, task, or packing data ships without Row Level Security
   enabled and a policy that checks family membership. A family must never be
   able to read another family's data. See ARCHITECTURE.md's
   `is_family_member()` pattern — reuse it, don't reinvent per-table checks.
2. **Never expose the Supabase service role key to the client.** Server-only
   env scope. Never referenced in a Client Component, never returned in an
   API response, never logged.
3. **No payments, no card storage, no passport scans/numbers as structured
   data.** If this ever seems necessary for a feature, stop and flag it
   instead of implementing it — it's a deliberate product boundary, not an
   oversight.
4. **Hebrew and English are both first-class.** Every user-facing string goes
   through the i18n layer with a semantic key (`packing.item.addLabel`), never
   the English text as the key. Every new screen gets both locales before
   it's considered done, and gets checked in RTL, not just LTR-then-mirrored-
   in-your-head.
5. **DESIGN.md is the visual source of truth.** The `ui-ux-pro-max` skill is
   advisory — good for accessibility checklists, interaction mechanics,
   implementation patterns for the stack — but its style/color/pattern
   suggestions never override a decision already made in DESIGN.md. If they
   conflict, DESIGN.md wins and you say so rather than quietly blending them.
6. **No SaaS-dashboard UI.** No KPI tiles, no dense admin tables, no
   AI-purple gradients, no generic unthemed shadcn look, no borders as the
   default separator. If a screen you're building starts to look like an
   admin panel, stop and reread DESIGN.md's anti-patterns section before
   continuing.
7. **Home is lifecycle-aware, not feature-complete.** Don't add "just one
   more section" to the Home screen because a feature needs *some* visible
   entry point. Stage-appropriate restraint is the actual feature; route
   less-urgent things to a trip detail screen instead of Home.
8. **Migrations are files, not hand edits.** Every schema change is a SQL
   migration under version control via the Supabase CLI. Never modify a live
   schema by hand, even in dev.
9. **Don't build the deferred list.** Automated screenshot/PDF extraction,
   push notifications, offline/service-worker support, and payments are
   explicitly out of scope until a human asks for them by name (see
   ARCHITECTURE.md's "Deferred" section). Building a stub or a "just in case"
   version of any of these is scope creep, not helpfulness.

## Conventions

- Server Components by default; reach for a Client Component only when you
  need interactivity, browser APIs, or Realtime subscriptions.
- Writes go through Server Actions where reasonable, calling Supabase with
  the user's session (never the service role) so RLS is what actually gates
  the write.
- Timestamps: always `timestamptz`, never naive `timestamp`. Any stored money
  value (rare — Nofesh stores at most a reference amount a user typed, never
  processes payment) uses `numeric`, never `float`.
- Hebrew text columns needing search use `simple` tsvector config, not
  `english` and not an invented `hebrew` config (Postgres has neither a
  dedicated Hebrew dictionary nor an `english` config that helps here).
- CSS: logical properties/Tailwind utilities only (`ms-*`, `me-*`, `ps-*`,
  `pe-*`, `text-start`, `text-end`) — never physical `ml-*`/`mr-*`/`text-left`
  /`text-right`. `space-x-*` does not auto-flip in RTL; use `gap-*`.
- Icons: SVG icon set only (Phosphor or Heroicons, per `ui-ux-pro-max`
  guidance), never emoji as a structural/navigational icon.
- No premature abstraction: three similar lines beat a speculative shared
  component or a config system built for a second use case that doesn't
  exist yet. This applies to schema, too — see ARCHITECTURE.md's "deliberate
  simplicity" notes (e.g. `trip_items.details` as jsonb instead of five
  tables) and don't undo that simplification without a real reason to.

## Before calling a change done

- New/changed UI: check it in both `he` (RTL) and `en` (LTR), and in dark
  mode. Verify against DESIGN.md, not against general "looks fine" instinct.
- New/changed table: verify RLS with an actual cross-family access attempt,
  not just a same-family happy path.
- Any dependency change or new secret-adjacent code: consider the
  `israeli-appsec-scanner` checklist before merging (parameterized queries,
  no secrets in git, CSP headers where relevant).
- Don't claim a UI change is verified without actually running the app and
  looking at it (or saying explicitly that you couldn't).

## Skills available in this repo

Installed under `.claude/skills/`: `ui-ux-pro-max` (advisory UI/UX
intelligence), `hebrew-i18n` (RTL/bidi/plural implementation patterns),
`hebrew-content-writer` (Hebrew copywriting), `israeli-postgres-toolkit`
(Postgres/Supabase patterns for Hebrew text, NIS, Asia/Jerusalem timezone),
`israeli-appsec-scanner` (OWASP + Israeli-specific security checklist),
`israeli-privacy-shield` (Israeli Privacy Protection Law / Amendment 13
compliance guidance — not legal advice), plus general `design`,
`design-system`, `brand`, `banner-design`, `ui-styling`, and `slides` skills
for supporting design work. Use them as intelligence sources; none of them
override PRODUCT.md, DESIGN.md, or this file.

## What NOT to do

- Don't scaffold the app, create migrations, install dependencies, or write
  product code until a human has reviewed and approved the plan in
  PRODUCT.md/ARCHITECTURE.md.
- Don't invent booking, payment, or price-comparison features "since we're
  already touching trips" — it's a repeated temptation for a trip app and a
  hard product boundary here.
- Don't treat this CLAUDE.md as exhaustive engineering doc for a codebase
  that doesn't exist yet — once Phase 0 lands real code, extend this file
  with concrete folder-structure and command references rather than
  speculating about them now.
