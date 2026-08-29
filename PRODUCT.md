# Nofesh — Product

## What Nofesh is

Nofesh (נופש — "vacation / getaway") is a warm, calm, family-oriented companion that
accompanies a family through an entire vacation, from the first idea to the
memories afterward. It exists because the work of a family trip is never really
booking a flight — it's holding a hundred small facts in your head (what time is
check-in, did we pack the kids' medicine, whose passport expires next year) and
usually one parent ends up holding all of it alone.

Nofesh's job is to **carry that mental load with the family**, not to sell them
anything.

## What Nofesh is not

- **Not a booking platform.** Nofesh never searches, compares, or sells flights,
  hotels, restaurants, activities, or rental cars.
- **Not a payments product.** Nofesh never processes a payment or stores a card.
  Money only appears in Nofesh, if at all, as a reference amount the user typed in
  (e.g. "hotel: $412"), never as a transaction.
- **Not a trip-management SaaS dashboard.** No KPIs, no admin tables, no "manage
  your trips" enterprise framing. Nofesh is closer to a trusted travel companion
  than a piece of software.
- **Not an itinerary-builder for planning enthusiasts.** Nofesh organizes what a
  family has already decided or booked elsewhere; it doesn't try to be the place
  where they discover destinations or build day-by-day itineraries from scratch.

## The belief behind the product

A vacation has a shape. It starts as an idea, becomes a set of bookings, becomes a
pile of things to pack, becomes a departure morning, becomes days away from home,
and ends as memories and laundry. Every stage needs different things from the
family, and most tools show the same dashboard the whole time. Nofesh changes
what it shows depending on where the family actually is in that shape — that's
the core product idea, not a feature.

## The lifecycle

```
Planning → Preparing → Packing → Departure → During the trip → Return / Memory
```

| Stage | What's actually happening for the family | What Nofesh surfaces |
|---|---|---|
| **Planning** | Dates are loose, destination might not be locked, bookings are trickling in | Inspiration, the trip card, an easy way to log what's been booked, invite the family |
| **Preparing** | Core bookings are confirmed; visas, insurance, and logistics need attention | Confirmations organized in one place, a short list of things that need doing, weather starting to matter |
| **Packing** | Departure is close enough that packing is real | Packing lists per traveler, suggestions from packing memory, weather- and activity-aware adjustments |
| **Departure** | The final 24–48 hours and the morning of | The Departure Assistant: only what matters *right now* — check-in, final packing check, documents, transport, chargers, medicines |
| **During the trip** | The family is away | Home becomes a calm **Today** view: today's plan, weather, quick access to confirmations — not a management dashboard |
| **Return / Memory** | Just landed home | Unpacking nudge, a two-question reflection ("what did we forget / not use") that feeds packing memory, and the trip settles into an archive |

A family's stage is **derived from trip dates and state**, not chosen from a menu
and never stored/pinned. The system decides what Home *emphasizes*; the family
never has to configure it. Critically, the derived stage only controls
emphasis, not access — packing, tasks, and trip items all stay reachable at
any time regardless of stage; a family can start packing the day a trip is
created if they want to, Home just won't lead with it yet. Home always shows
whichever trip is most relevant right now (soonest departure or currently in
progress); other trips remain one tap away.

## Core product pillars (Phase-ordered, not equal-weight)

### 1. Family Companion (foundational — everything else sits on top of this)
One person should never have to hold the whole vacation in their head. A family
shares one source of truth: trips, documents, tasks, and packing lists are visible
to every adult member. Children and other dependents exist as **travelers**
attached to the family — they have packing lists, ages, and trip participation,
but do not need their own account or login.

### 2. Smart Packing Memory
Packing is the single most repetitive, most forgettable part of a trip, and it's
where Nofesh's memory pays off fastest. What to pack depends on destination,
dates, weather, trip length, who's coming (and their ages), baggage allowance,
whether laundry will be available, and planned activities. After a trip, Nofesh
asks two quiet questions — what did we forget, what did we never use — and
folds the answers into future suggestions for that family. This is heuristic and
transparent in V1 (rules over the family's own history), not a black box.

### 3. Trip Inbox / Chaos-to-Trip
Families don't get their trip information in one clean place — it arrives as
screenshots, forwarded emails, PDFs, and pasted text. This is one of Nofesh's
core differentiators, and V1 ships a real (if intentionally narrow) version of
it: a family can paste text, upload a screenshot/image, or upload a PDF, and
Nofesh proposes candidate flights, stays, restaurants, activities, dates,
times, and confirmation codes from it. **Every extracted fact is a candidate
until a person confirms it** — nothing becomes authoritative trip data without
a human tap; a rejected or edited candidate never silently reappears as-is.
V1's extraction deliberately targets the common cases (flights, accommodation,
restaurant/activity bookings, generic dated confirmations) rather than trying
to understand every travel document that exists. Email forwarding / automatic
mailbox ingestion and link crawling are explicitly out of V1 — see Roadmap.

### 4. Departure Assistant
In the last day or two before leaving, nobody needs the whole app — they need "am
I going to forget something." The Departure Assistant collapses everything down
to the handful of things that are actually time-sensitive right now: check-in
windows, the packing list's remaining items, documents that need to be printed or
downloaded offline, transport to the airport, a last look at the weather, and the
easy-to-forget category (chargers, medicines, kids' items).

### 5. During-trip "Today"
Once the trip starts, Home stops being about preparation and becomes about the
day the family is actually having. It shows what's relevant to *today* — today's
plan, confirmations that might come up (a restaurant reservation, a rental car
pickup), the local weather — and nothing that isn't. This is the clearest place
the product must resist turning into a dashboard: during the trip, less is more.

## Users and roles

- **Account holder / family member (adult, has an account).** Can create and
  manage trips, invite other adults, add travelers, edit shared data. Every adult
  member of a family has equal standing over shared data by default in V1 — see
  Open Decisions in the review response for whether a lighter "viewer" role is
  needed later.
- **Traveler (may or may not have an account).** The person a trip, packing list,
  or document is *about*. A traveler with an account is also a family member. A
  traveler without an account (a child, an elderly parent) is represented as a
  standalone record the family manages on their behalf — they have a name, age,
  and packing list, but never log in.
- **Family.** The unit that owns trips. A family is not a company/tenant in the
  SaaS sense — it's a small, closed group (a household), typically 1–6 adults and
  their dependents.

## Terminology (shared glossary)

| Term | Meaning |
|---|---|
| **Family** | The group that owns trips and shares one source of truth. |
| **Family member** | An adult with a Nofesh account belonging to a family. |
| **Traveler** | Anyone going on a trip — a family member or a dependent without an account. |
| **Trip** | A single vacation: destination(s), dates, and the travelers going. |
| **Trip membership / participation** | Which travelers are actually part of a given trip (not every family member joins every trip). |
| **Trip item** | A single piece of trip information — a flight, a stay, a restaurant booking, an activity, a rental car — confirmed or still a candidate. |
| **Document** | A file attached to a trip or trip item (boarding pass PDF, confirmation email, insurance policy). Never a payment card or passport scan in V1. |
| **Task** | A to-do tied to a trip and, usually, a lifecycle stage (renew a passport, buy insurance). |
| **Packing list** | The set of packing items for one traveler on one trip. |
| **Packing item** | A single thing to pack: name, category, quantity, packed/not packed, and where it came from (manual, suggested, memory). |
| **Packing memory** | What Nofesh has learned about a family's packing patterns over past trips — forgotten items, unused items, missing categories — used to shape future suggestions. |

## V1 scope boundaries

V1 is intentionally narrow. It proves the lifecycle-aware Home, the Family
Companion foundation, manual Trip Items/Documents/Tasks, a narrow-but-real
Trip Inbox extraction loop, a real (if heuristic) Packing Memory loop, and a
first version of the Departure Assistant. It deliberately **excludes**:

- Email forwarding / automatic mailbox ingestion, link crawling, and
  extraction from document types beyond common travel confirmations
  (flights, stays, restaurant/activity bookings, generic dated
  confirmations) — Trip Inbox extraction itself (pasted text, image, PDF) is
  in V1, but stays intentionally narrow rather than general-purpose.
- Payments, price comparison, or booking of anything.
- Passport scans or card storage of any kind.
- Push notifications, offline sync, or a real service worker (PWA-*ready*
  architecture only — see ARCHITECTURE.md).
- Roles beyond "adult family member" and "traveler" (no granular permissions).
- Any UI for switching between multiple families for one user — the data
  model supports a user belonging to more than one family, but V1 doesn't
  need to expose that.

## What "good" looks like

A family opens Nofesh the morning of departure and the only thing on screen is
the four things they actually still need to do. A parent packing for a
7-year-old sees a list that already knows the kid needs a swimsuit because the
destination has a pool, and doesn't need to type "socks" from scratch for the
fifth trip in a row. Nobody feels like they're running a project. It feels like
someone who's been on this trip with them before is quietly keeping track.

## Roadmap: Phase 0 and V1

See the architecture document for the domain model this roadmap is built on.

**Phase 0 — Foundation (no user-facing product yet)**
1. Scaffold Next.js (App Router, TypeScript, Tailwind) + tooling, connect to Vercel.
2. Stand up Supabase project; configure Auth; wire server/browser Supabase clients.
3. i18n scaffolding (Hebrew + English, RTL/LTR switching) and design tokens from
   DESIGN.md wired into Tailwind.
4. First migration: `families`, `family_members`, `travelers`, profile table, RLS
   policies; verify family isolation with a real cross-family access test.
5. Auth flow: Google OAuth as the primary sign-in, email magic link/OTP as
   fallback (no password auth) — create/join a family, invite another adult,
   minimal profile screen.
6. App shell: navigation, empty Home route, shared empty/error/loading patterns.

**V1 — First usable slice**
7. Trips: create trip (destination, dates, participating travelers), trip list,
   trip detail.
8. Home lifecycle logic: derive stage from trip state/dates; build the five
   distinct Home presentations (Planning/Preparing/Packing/Departure/Today).
9. Trip items: manual structured entry (flight, stay, restaurant, activity,
   transport) with confirmation codes; document upload attached to items/trip;
   optional user-uploaded trip cover image with a polished branded fallback
   when none is provided (no stock-image API dependency in V1).
10. Tasks: simple checklist tied to a trip and (usually) a lifecycle stage.
11. Packing lists & items: per traveler, per trip; a first heuristic default list
    generator (by trip length, destination climate signal, traveler age).
12. Packing memory v0: end-of-trip two-question reflection; store as signals;
    feed them into the next trip's default list for that family/traveler.
13. Trip Inbox v0: pasted text, screenshot/image upload, and PDF upload, each
    run through a narrow extraction step (flights, stays, restaurant/activity
    bookings, generic dated confirmations only) that proposes candidate trip
    items; nothing becomes authoritative until the user reviews and confirms
    it. Email ingestion and link crawling are out of scope for V1.
14. Departure Assistant v0: a single surfaced checklist in the final 24–48h
    combining open tasks, remaining packing items, and document readiness.
15. Cross-cutting polish: Hebrew/RTL QA pass, accessibility pass, mobile QA,
    dark mode, PWA manifest + icons (no offline caching yet).
16. Deploy to a Vercel staging environment, RLS/appsec review pass, publish a
    privacy policy stub.
