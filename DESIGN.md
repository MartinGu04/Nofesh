---
name: Nofesh
version: 0.1.0
description: >
  Nofesh's own visual language — warm, calm, premium family travel companion.
  Sunset-over-water palette, editorial Hebrew-first typography, restrained
  wave motif. Written from scratch for this product; DESIGN.YAM.REFERENCE.md
  (Coast) was read for inspiration only and is not the source of truth here.
colors:
  navy: "#122C42"
  navy-deep: "#0B1E30"
  teal: "#3E8A96"
  teal-light: "#8FC3C9"
  terracotta: "#D97B4F"
  terracotta-deep: "#B75F38"
  sand: "#EFE1C8"
  cream: "#FAF5EB"
  ink: "#1E2A33"
colors-dark:
  background: "#0B1E30"
  surface: "#122C42"
  surface-raised: "#17364F"
  text: "#F6EFDF"
  text-muted: "#C9D6DC"
  teal: "#7BB6BE"
  terracotta: "#E79A6D"
typography:
  display:
    fontFamily: "Frank Ruhl Libre, Georgia, serif"
    weight-latin: 400
    weight-hebrew-min: 500
  body:
    fontFamily: "Assistant, -apple-system, sans-serif"
    weight: 400
  ui-label:
    fontFamily: "Assistant, -apple-system, sans-serif"
    weight: 600
spacing:
  xs: 8px
  sm: 12px
  md: 20px
  lg: 32px
  xl: 56px
  2xl: 96px
radius:
  sm: 10px
  md: 16px
  lg: 24px
  pill: 999px
---

## Why this document exists, and how it differs from the Coast reference

`DESIGN.YAM.REFERENCE.md` (Coast) is a good Mediterranean/Hebrew-first design
system — but it was written for boutique hospitality and editorial travel
content, not for a daily-use family companion that has to work calmly across
six very different emotional states of a trip. This document borrows Coast's
*discipline* (Hebrew-first typography rules, logical CSS, real bidi handling)
but makes its own decisions on color, type, shape, and — most importantly —
on what the UI is allowed to look like. Where the two disagree, **this
document wins for Nofesh.**

## Brand essence

Warm. Calm. Premium. Family-oriented. **Never childish, never a SaaS
dashboard.** The reference feeling is a boutique travel brand or a beautifully
shot hospitality app — not a project-management tool that happens to be about
trips. If a screen could be mistaken for an admin panel, it's wrong, no matter
how useful the data on it is.

The brand symbol — a sunset over flowing waves with a small bird — is not
redesigned here. It appears as-is in the product; this document only governs
the surrounding visual system, and the palette below is chosen so the mark
sits naturally on it (deep navy night sky, terracotta sunset light, teal
water).

## Color

| Token | Hex | Role |
|---|---|---|
| `navy` | `#122C42` | Primary text on light surfaces, primary UI chrome, deep-sky brand color |
| `navy-deep` | `#0B1E30` | Dark-mode background, night-sky moments (Today view at night, Return/Memory) |
| `teal` | `#3E8A96` | Secondary accent — links, secondary actions, water/current-trip signal |
| `teal-light` | `#8FC3C9` | Subtle fills, tags, calm-state indicators |
| `terracotta` | `#D97B4F` | Primary CTA, warmth, urgency-with-care (Departure Assistant, "do this now") |
| `terracotta-deep` | `#B75F38` | Pressed/hover state for terracotta, warning-adjacent (never used for destructive/error red) |
| `sand` | `#EFE1C8` | Warm neutral surface — cards, secondary backgrounds |
| `cream` | `#FAF5EB` | App background (light mode) |
| `ink` | `#1E2A33` | Body text, slightly softer than pure navy for long reading |

Signature move: the **horizon gradient** — a soft navy-to-terracotta diagonal
wash, evoking the logo's sunset over water — used sparingly and only at
emotionally significant moments: the hero of a new trip, the Departure
Assistant's header, the Return/Memory screen. It never appears on
functional chrome, buttons, or anywhere it would compete with content
(no "AI purple gradient" energy, ever — this is a specific, literal horizon,
not a decorative blur).

Functional colors (error, success, warning) are deliberately **not** part of
the brand palette above — define them as a small, separate semantic set
(e.g. a muted red for destructive actions, a muted green for confirmation)
so `terracotta` never gets read as "danger" just because it's warm.

Dark mode is a real second palette (night sky, not an inverted light mode).
Contrast is checked independently per mode — see Accessibility below.

## Typography

- **Display** — Frank Ruhl Libre. A serif with genuine Hebrew glyph support and
  the editorial warmth the product needs for hero moments, trip titles, and
  the Departure/Return screens. Chosen deliberately for Nofesh (Hebrew
  typography with this much character is a short list, and this is the right
  end of it), not inherited from the reference file.
  - Hebrew display text: minimum weight **500** (400 reads thin in Hebrew at
    large sizes) and line-height **≥1.15** (Hebrew descenders need the room).
  - Latin display text may use weight 400 at line-height 1.1.
  - Letter-spacing: `0` for Hebrew display, `-0.01em` max for Latin display.
- **Body / UI** — Assistant. A humanist sans with full Hebrew + Latin coverage,
  warmer and slightly rounder than a typical UI grotesk, which supports the
  "warm, not childish" brief better than a purely geometric sans (Rubik) or a
  colder workhorse (Heebo) would. 16px minimum body size, line-height 1.6–1.75
  for anything longer than a label.
- Scale: `12 / 14 / 16 / 18 / 22 / 28 / 36 / 48` (px). Only the top two sizes
  use the display serif; everything else is Assistant.
- Keep `kern` and `calt` enabled on every text node; never set
  `font-feature-settings: normal` globally.

## Shape and signature motif

Corners are soft but restrained: `10 / 16 / 24px` across small/medium/large
surfaces. **Pill shapes are reserved for pure actions** (buttons, chips, the
search/add-item field) — not for every card, which is where a system starts
to feel like a toy. Cards use the medium/large radius, not full pill corners.

Nofesh's own signature, replacing Coast's pill-everywhere language, is the
**wave line**: a thin, single-stroke horizontal wave (echoing the logo's
water) used as a quiet section divider or the top edge of a hero/imagery
panel — mask an image's bottom edge with a gentle wave curve instead of a
hard rectangle. Use it once per screen, at most, as punctuation, never as
background texture repeated everywhere.

## Layout

Mobile-first, generous by default: `sm 12 / md 20 / lg 32 / xl 56 / 2xl 96`
(px). Marketing/hero moments breathe at `xl`/`2xl`; dense in-trip screens
(packing list, task list) can tighten to `sm`/`md` — this is the one place
density is allowed to increase, because during Packing/Departure the user
wants to scan a list quickly, not admire whitespace. Even there, avoid
tables: packing items and tasks are rows in a soft list, not a spreadsheet
grid with borders on every cell.

Container widths follow content, not a fixed dashboard shell: imagery and
hero moments can go full-bleed; reading and form content caps around 640px;
lists cap around 720px on larger screens rather than stretching edge to edge.

## Imagery

Destination imagery is a first-class layout element, not decoration bolted
onto a card. Full-bleed photography over a warm color-graded overlay (navy
or terracotta wash at low opacity, never a flat dark scrim that kills the
photo) is the default hero treatment. Avoid generic "stock traveler with
suitcase at airport" photography — prefer place-led imagery (the destination
itself) or, where no real photo exists yet (a trip still being planned), a
warm illustrated placeholder in the brand palette rather than a gray box.

## Components (guidance, not a full spec)

- **Cards**: sand or surface-raised background, no visible border, soft
  shadow only (`0 12px 32px rgba(18,44,66,0.10)` light mode) — never a 1px
  gray border doing the separation work; let color and shadow do it.
- **Buttons**: primary = terracotta, pill, generous padding (12/28);
  secondary = outline or teal-tinted, same pill shape and size so the pair
  reads as a family, not mismatched controls.
- **The "Today" surface**: the single most important component in the
  product. One focused card (or a very short stack of them) — never a grid,
  never more than what's relevant to the next few hours. If During-trip Home
  ever needs a second card to feel complete, that's a signal something
  belongs in a detail screen instead, not that Today needs more surface area.
- **Packing/task lists**: soft rows, not table rows — no header row, no
  vertical rules between "columns." A checkbox, a label, secondary metadata
  as muted text beneath, that's it.
- **Explicitly banned**: KPI/stat tiles, dense data grids or admin-style
  tables, more than two nested card levels, AI-purple gradients, generic
  shadcn defaults left unthemed, hard borders as the primary separator.

## Motion

Subtle, and always meaningful — motion should feel like something settling
into place (a card arriving, a list item checking off), not decoration.
Prefer gentle deceleration on arrival, quicker exits (~65% of enter
duration), and respect `prefers-reduced-motion` everywhere without
exception. The horizon-gradient hero moments may carry a very slow ambient
drift (waves), but it must be ignorable — never load-bearing for
understanding the screen, and paused under reduced motion.

## Hebrew and RTL (first-class, not an afterthought)

Nofesh ships Hebrew and English from day one, Hebrew as the default locale.
The practical rules below are adapted from the `hebrew-i18n` skill and apply
across the whole product:

- `<html lang="he" dir="rtl">` (or `en`/`ltr`) set at the `<html>` level, not
  just on `<body>` — layout, scrollbars, and CSS logical properties all key
  off it.
- Logical CSS/Tailwind only: `ms-*`/`me-*`/`ps-*`/`pe-*`/`text-start`/
  `text-end`, never `ml-*`/`mr-*`/`pl-*`/`pr-*`/`text-left`/`text-right`.
  `space-x-*` does not auto-flip in RTL — use `gap-*` with flex/grid instead.
- Direction-aware icons (chevrons, back/next arrows, progress fill direction)
  must mirror in RTL; the "next" affordance points left in Hebrew, not right.
- Mixed-direction content — flight numbers, confirmation codes, phone
  numbers, addresses with a Latin street name, dates — wrap in `<bdi>` so the
  bidi algorithm can't reorder it unpredictably. This matters constantly in
  this product: a trip item is routinely "טיסה LY001 ל-Barcelona ב-14/03".
- Dates: Israeli numeric convention `dd/mm/yyyy`; Hebrew long form
  `12 ביוני 2026`; week starts Sunday. Times are 24-hour, no AM/PM.
- Gershayim (״) and geresh (׳) for Hebrew abbreviations/quoting, not ASCII
  quotes; maqaf (־) for compound Hebrew words. No em dashes anywhere in the
  product's voice, Hebrew or English — use commas, parentheses, or periods.
- `aria-label`s are authored per-locale at build time, never machine
  translated at runtime.

## Voice and microcopy

Direct, warm, a little human — the product talks like someone who's actually
been on the trip with you, not like enterprise software. Short sentences.
Never robotic error codes.

| Moment | HE | EN |
|---|---|---|
| Trip created | הטיול שלכם מתחיל להסתדר | Your trip is starting to take shape |
| Packing suggestion | שמנו לב שבפעם הקודמת שכחתם מטענים — הוספנו אותם | Last time you forgot chargers — we added them |
| Departure day | היום היום! הנה מה שנשאר לבדוק | Today's the day. Here's what's left to check |
| Error (generic) | ‏משהו השתבש. ננסה שוב? | Something went wrong. Try again? |

## Dark mode

Designed together with light mode, not derived by inversion. Dark surfaces
use `navy-deep`/`navy`/`surface-raised`, never a generic near-black; text
uses a warm off-white (`#F6EFDF`), not pure white. Terracotta and teal both
shift slightly lighter/desaturated in dark mode to hold contrast without
turning neon.

## Accessibility baseline (non-negotiable)

- Body text contrast ≥4.5:1 in both themes, checked independently (not
  assumed from light-mode values).
- Touch targets ≥44×44px with ≥8px spacing between adjacent targets.
- Visible focus rings on every interactive element; never removed for
  aesthetics.
- Color is never the only signal (packed/not packed, confirmed/candidate
  trip item both carry an icon or label, not just a color change).
- `prefers-reduced-motion` disables/reduces all decorative motion; state
  changes still happen, just without animation.

## Anti-patterns (explicitly out of bounds for Nofesh)

No KPI cards. No dense admin-table aesthetics. No borders-as-default-
separator. No AI-purple gradients. No generic unthemed shadcn look. No
dashboard framing on the Home screen at any lifecycle stage — even Preparing,
which has the most "stuff" to show, should feel like a well-organized travel
folder, not a project tracker.

## Relationship to `ui-ux-pro-max`

`ui-ux-pro-max` is advisory: use it for accessibility checklists, interaction
mechanics (touch targets, animation timing, form UX, navigation patterns) and
implementation guidance for the chosen stack. It never overrides a decision
made in this document — if its style/color/pattern suggestions conflict with
Nofesh's palette, shape language, or the anti-patterns above, this document
wins.
