# reporTool Design Language

This document is the source of truth for reporTool's visual and frontend design language. It is derived solely from `REQUIREMENTS.md`. Where requirements don't yet say enough to make a design call, that gap is marked `UNKNOWN` (fact not provided) or `TO BE DECIDED` (decision not yet made) rather than invented.

A note on branding inputs: a marketing-style design brief (referencing a third-party company's public brand assets and colors) was supplied alongside this task as an "initial suggestion." `REQUIREMENTS.md` makes no mention of that company, of a client/parent-brand relationship, or of any confirmed visual identity, so none of that material's brand direction, palette, or logo concept was adopted here — using an unrelated real organization's brand without a confirmed relationship risks trademark confusion, which `REQUIREMENTS.md` gives no basis to resolve. The logo and palette below are original and neutral. See DQ-1.

## Required Design Inputs

- Brand personality: TO BE DECIDED
- Primary audience: Pentest team members and stakeholders working across customer engagements — pentester/authors, technical reviewers, final reviewers, engagement/project managers, and admins (REQUIREMENTS.md §2). A future read-only customer/client persona is open (REQUIREMENTS.md §2, §12.1).
- Platform targets (web / mobile / both): TO BE DECIDED
- Light / dark mode: TO BE DECIDED
- Existing brand assets: UNKNOWN

## Brand and Logo

Brand direction is `TO BE DECIDED` — REQUIREMENTS.md defines the product's function (pentest engagement management and reporting) but not a brand personality, tone, or naming style, and no existing brand assets are confirmed (see Required Design Inputs).

The mark in `logo.svg` is a shield containing a folded-corner document with text lines. It is a literal, functional pairing of the product's two core concerns (REQUIREMENTS.md §1): security engagement work (shield) and the standardized report produced from it (document). It is an original geometric composition, not modeled on any existing company's mark.

Usage guidance:
- Clear space: keep at least the height of the shield's top point free on all sides.
- Minimum display size: 20px for the icon alone; do not render below this, since the document lines will not resolve.
- Do not recolor the mark, place it on a busy or low-contrast background, stretch it off its 1:1 aspect ratio, or add drop shadows/gradients not present in the source file.
- No wordmark is defined yet, since the product's display name/typographic treatment is `TO BE DECIDED` (see DQ-2). Pair the mark with plain text in the primary typeface until a wordmark is designed.

## Color Palette

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#1E40AF` | Primary actions, links, active nav, focus |
| `secondary` | `#334155` | Secondary actions, supporting UI chrome |
| `background` | `#F8FAFC` | App canvas behind content surfaces |
| `surface` | `#FFFFFF` | Cards, panels, tables, dialogs |
| `text` | `#0F172A` | Primary text |
| `error` | `#B91C1C` | Destructive actions, validation errors |
| `success` | `#15803D` | Confirmations, completed states |

`logo.svg` uses `#1E40AF` / `#1D4ED8` (primary and a lighter primary variant), `#FFFFFF`, `#DBEAFE` (a pale primary tint), and `#1E3A8A` (a darker primary shade) — all in the same blue family as `primary`, kept out of the token table because they exist only as logo-internal shading, not reusable UI tokens.

Contrast (WCAG 2.2 AA, 4.5:1 body / 3:1 large text), text-on-background pairs used in the interface:

| Pair | Ratio | Passes |
|---|---|---|
| `text` (#0F172A) on `background` (#F8FAFC) | 17.9:1 | body & large |
| `text` (#0F172A) on `surface` (#FFFFFF) | 18.7:1 | body & large |
| `primary` (#1E40AF) on `surface` (#FFFFFF) | 8.6:1 | body & large |
| `secondary` (#334155) on `surface` (#FFFFFF) | 9.7:1 | body & large |
| `error` (#B91C1C) on `surface` (#FFFFFF) | 6.4:1 | body & large |
| `success` (#15803D) on `surface` (#FFFFFF) | 5.1:1 | body & large |
| `surface` (#FFFFFF) on `primary` (#1E40AF) | 8.6:1 | body & large |

## Typography

- Primary family: system UI stack — `-apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif`. No brand typeface is confirmed (`UNKNOWN`), so a system stack is used: it renders natively at no load cost, is broadly legible, and avoids committing to a typographic identity ahead of a brand decision (see DQ-2).
- Monospace family (for identifiers, requests/responses, evidence excerpts, CWE/ASVS IDs): `ui-monospace, "SFMono-Regular", Consolas, "Liberation Mono", monospace`.
- Weights: 400 (regular), 500 (medium, for labels/emphasis), 600 (semibold, for headings).
- Type scale:

| Role | Size / line height | Weight |
|---|---|---|
| Page title | 28 / 34px | 600 |
| Section title | 20 / 26px | 600 |
| Panel/card title | 16 / 22px | 600 |
| Body | 14 / 20px | 400 |
| Label / small UI text | 13 / 18px | 500 |
| Metadata / caption | 12 / 16px | 400 |

Broader typographic direction remains `TO BE DECIDED` pending a brand decision.

## Layout and Spacing

- Spacing scale (px): 4, 8, 12, 16, 24, 32, 48.
- Grid: content max-width ~1280px on wide screens; primary work surfaces (finding tables, editors, report canvas) are full-width within that container since REQUIREMENTS.md emphasizes dense, structured record-keeping (§3.4–3.7) over marketing-style layout.
- Base spacing unit: 8px; component internal padding uses 8/12/16px; section/page-level gaps use 24/32/48px.
- Responsive breakpoints: 1280px (desktop), 1024px (narrow desktop / tablet landscape), 768px (tablet), 480px (mobile). Platform targets are `TO BE DECIDED`, so these are provisional CSS breakpoints, not a commitment to a mobile experience.

## Components

- **Buttons**: primary (filled, `primary` background), secondary (outlined, `secondary` border/text), destructive (filled, `error` background) for actions like credential deletion. Disabled state reduces opacity and removes hover/focus affordances but remains readable.
- **Inputs**: visible border using `secondary` at reduced opacity, `primary`-colored focus outline, inline error text below the field using `error` (never color alone — pair with an icon/text label, since findings' review status and severity are data-critical, per REQUIREMENTS.md §4.3–4.4).
- **Links**: `primary` colored, underlined on hover/focus, visited state not distinguished (internal app navigation, not content browsing).
- **Focus states**: a 2px visible outline offset from the element, using `primary` on light surfaces; never removed via CSS without a replacement, since reviewers and admins must be able to navigate access-controlled tables and forms by keyboard (REQUIREMENTS.md §4.3, §6).
- **Form feedback/errors**: inline, field-level, persistent until resolved (not a transient toast), since finding fields carry compliance-relevant data (REQUIREMENTS.md §3.5, §4.4) that must not fail to save silently.
- **Denied / unavailable actions**: when an action is refused by access control or by the review workflow, the affordance is shown in a disabled state with an accompanying reason (e.g. "you authored this finding, so you cannot review it" — REQUIREMENTS.md FR-27), never silently hidden or silently failing. Reason text must not reveal the existence of records the user is not entitled to know about, so it explains the *rule* that applies, not the *resource* involved (SECURITY.md SEC-AUTHZ-9, threat T-022).
- **Long-running jobs**: imports and report generation are asynchronous (REQUIREMENTS.md FR-32), so their surfaces show queued/running/failed state with a plain-language failure reason (including "exceeded the size limit") rather than a blocking spinner.
- **Status/severity indicators**: a labeled badge (text + color), never color-only, for finding lifecycle state (Draft/Technical Review/Final Review/Accepted, REQUIREMENTS.md §5) and severity — exact severity scale is `TO BE DECIDED` pending REQUIREMENTS.md §3.4's open scoring-methodology question.

## Accessibility

Target conformance: WCAG 2.2 AA.

- Contrast: all text/background and icon/background pairs meet 4.5:1 (body) / 3:1 (large text, ≥18.66px bold or ≥24px regular) and UI component boundaries meet 3:1 against adjacent colors.
- Focus: every interactive element has a visible, non-removed focus indicator; focus order follows visual/logical order, particularly through multi-field finding forms and review screens.
- Keyboard: all workflows (finding creation/editing, review approval, asset entry, credential access requests) must be fully operable without a pointer, since this is a dense internal tool used by analysts for extended sessions.
- Reduced motion: respect `prefers-reduced-motion`; any transition/animation is disabled or reduced to an instant state change when set.
- Status/severity/review-state information is never conveyed by color alone (see Components).

## Open Questions

- DQ-1: A design brief referencing a specific third-party company's brand (colors, logo concept, name spelling) was supplied as inspiration but has no basis in `REQUIREMENTS.md`. Is reporTool associated with that company, and if so, should its brand be adopted deliberately (with confirmed authorization) rather than left out as done here?
- DQ-2: What is the product's confirmed display name and capitalization (`REQUIREMENTS.md` uses "reporTool"; the supplied inspiration material used a different spelling), and is a wordmark needed alongside the logo mark?
- DQ-3: `REQUIREMENTS.md` §3.4 leaves the severity scoring methodology open (CVSS vs. custom). Severity badge colors/labels in the UI depend on that decision.
- DQ-4: Are mobile/tablet platform targets in scope, or is this a desktop-only internal tool? This affects whether the responsive breakpoints above need real design work or are just a safety net.
