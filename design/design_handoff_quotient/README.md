# Handoff: Quotient — Super Mortgage Calculator (iOS)

## Overview

Quotient is a native iOS mortgage calculator for licensed loan officers. It contains five calculators (Amortization, Income Qualification, Refinance Comparison, Total Cost Analysis, HELOC vs Refinance), supports branded PDF export, and works in light and dark modes. This handoff covers the **full app**: Home, Saved scenarios, Settings, Borrower picker sheet, 6-step Onboarding, all 5 calculators (Inputs + Results where applicable), Share/PDF preview carousel, and the PDF cover page — plus the complete design foundations.

## About the Design Files

The files under `design_files/` are **design references authored in HTML + React/JSX running via in-browser Babel**. They are prototypes to illustrate look and behavior — **not production code to ship**. The task is to **recreate these designs natively in SwiftUI** (the target platform is iOS 18+, iPhone first, iPad landscape second) following Apple's HIG and the project's existing patterns. Where the HTML uses custom CSS or inline SVG, map to SwiftUI native equivalents (SF Symbols, SF Pro, system colors scaled to tokens below).

If there is no existing iOS codebase yet, scaffold one in SwiftUI with Swift Package Manager, target iOS 18.

## Fidelity

**High-fidelity.** All colors, typography, spacing, and component states in these mocks are final. Recreate pixel-perfectly using the token table in "Design Tokens" below. Real data values (numbers, names, dates) are placeholders — wire to the finance engine.

## Screens

Open `design_files/Quotient.html` in a browser. Every screen below has a corresponding artboard on the canvas, grouped by section.

### 1. Onboarding — 6-step tour (`screens/Onboarding.jsx`)
- **Purpose**: teach the 5 calculators with a typographic demo per step. Step 1 = welcome, steps 2–6 = one per calculator.
- **Layout**: full-height warm-paper bg. Top: small "N / 6" mono counter + dotted progress. Editorial body per step — eyebrow (calculator name), Source Serif 4 title, paragraph. Lower 60%: an in-situ miniature of that calculator's signature output (a single KPI card, chart sparkline, or table fragment). Bottom dock: Skip (left) / Next (primary accent CTA).
- **Motion**: 260ms crossfade between steps; progress dots animate left-to-right.

### 2. Home / Calculator picker (`screens/Home.jsx`)
Greeting block, rate ribbon (horizontal-scroll cells with 30-yr / 15-yr / ARM / FHA / VA / Jumbo), numbered calculators list (01–05), recent scenarios, tab bar. Full spec in previous version — unchanged.

### 3. Saved scenarios (`screens/Saved.jsx`)
- **Purpose**: browse and resume every saved scenario.
- **Layout**: search field, filter chips (All / Amort / Refi / TCA / HELOC / Income), grouped list by date bucket (Today / This week / Earlier). Each row: calculator label pill (mono), borrower name 16pt 600, key stat line in mono, timestamp right-aligned. Swipe for Archive / Share / Duplicate / Delete.

### 4. Settings (`screens/Settings.jsx`)
- **Purpose**: LO profile, branding, defaults, preferences, privacy, data, support.
- **Layout**: iOS grouped list (inset cards, 26pt radius). Sections:
  - **Profile**: avatar, Full name, NMLS #, License states
  - **Brand**: Accent color (swatches), Logo, PDF header style
  - **Disclaimers**: per-state compliance text (disclosure with count)
  - **Appearance**: Light / Dark / Auto, Density (Comfortable / Compact)
  - **Language**: English / Español
  - **Haptics & sounds**: toggles
  - **Privacy**: Face ID lock, Share app analytics
  - **Data**: Export scenarios (CSV/JSON), Backup to iCloud
  - **Support**: Contact, Rate app, Feedback
  - **About**: Version, Legal, Licenses
- 17pt row text, value/disclosure right-aligned; section headers eyebrow style.

### 5. Borrower picker (`screens/BorrowerPicker.jsx`)
- Bottom sheet (~78% height), grabber, search, 3 tabs (Recents / Contacts / New). Contact row: initials circle + name + 1-line context. "+ New borrower" sticky bottom.

### 6. Amortization — Inputs (`screens/Inputs.jsx`)
(Unchanged from previous pass — see previous README section.)

### 7. Amortization — Results (`screens/Amortization.jsx`)
(Unchanged.)

### 8. Income qualification (`screens/Income.jsx`)
- Hero: Max qualifying loan (46pt mono). Two dials: Front-end DTI (agency limit 28%) and Back-end DTI (43/45/50% by program). Qualifying income list (W-2, self-employed, rental, other — each with mono value + % weight), debts list (cards, auto, student, other), resulting residual income. "Run scenario" CTA → opens Amortization pre-filled.

### 9. Refinance comparison (`screens/Refinance.jsx`)
(Unchanged.)

### 10. Total cost analysis (`screens/TCA.jsx`)
- 2–4 scenario columns × rows per horizon (5/7/10/15/30 yr). Each cell = mono total cost; winner per row bolded in `--gain` with check glyph. Option tabs top, per-scenario stripe color, narrative card below.

### 11. HELOC vs refinance (`screens/Heloc.jsx`)
- Blended rate hero (current 1st + new HELOC = blended effective %). Side-by-side: Cash-out refi vs HELOC (draw/repay periods, intro rate, index+margin). Stress paths chart: 3 curves (rate flat / +1% / +2%) for 10-year cost.

### 12. Share / PDF preview (`screens/Share.jsx`)
- **Paged carousel**: Cover / Schedule / Disclaimers with dots indicator top. Each page is a full thumbnail of the generated PDF page, pinch-to-zoom.
- Recipient row top: borrower name + email + "Change". Bottom action dock: Message, Mail, AirDrop, Copy link, Print, Save to Files.

### 13. PDF cover page (`screens/PDF.jsx`, 816×1056)
(Unchanged from previous pass.)

### 14. Foundations sheet (`screens/Foundations.jsx`)
All swatches, type specimens, component samples, principles. Authoritative spec when anything is ambiguous.

## Design Tokens

### Color (light mode)
```
--surface         #FAF9F5   page bg (warm paper)
--surface-raised  #FFFFFE   cards, hero blocks
--surface-sunken  #F0EDE4   segmented track, subtle wells
--surface-deep    #E8E4D7

--border-subtle   #E5E1D5   most hairlines
--border-default  #D3CEBE
--border-strong   #B6B0A0

--ink             #17160F   primary text (never #000)
--ink-secondary   #4A4840
--ink-tertiary    #85816F
--ink-quaternary  #B8B4A3

--accent          #1F4D3F   ledger green — links, primary CTA, active, winners
--accent-hover    #163C30
--accent-fg       #FAF9F5
--accent-tint     #DFE6E0

--gain            #2D6A4E
--gain-tint       #DDE8DF
--loss            #8A3D34
--loss-tint       #EDDAD4
--warn            #8C6A1E
--warn-tint       #EDE2CA

--grid            #ECE8DC   chart gridlines (whispered)

/* 4-color scenario palette, equal L & C, varied hue */
--s1  #1F4D3F  green
--s2  #264B6A  blue
--s3  #6A3F5A  wine
--s4  #73522A  umber
```

### Color (dark mode) — warm near-black, never #000
```
--surface         #17160F
--surface-raised  #1E1D15
--surface-sunken  #121109
--surface-deep    #0B0A04
--border-subtle   #2A281F
--border-default  #3C3A30
--border-strong   #55524A
--ink             #F2EFE2
--ink-secondary   #B4B0A0
--ink-tertiary    #7C7869
--accent          #4F9E7D
--accent-hover    #66AE90
--accent-fg       #0B0A04
--accent-tint     #22322C
--gain            #6FB28D
--loss            #C47566
--warn            #D6A758
--grid            #26241C
--s1 #4F9E7D  --s2 #6A8FB5  --s3 #B07D98  --s4 #BC976B
```

### Typography
- **Sans UI**: SF Pro Text (system) for all chrome, labels, buttons, nav
- **Display**: SF Pro Display (system, ≥20pt) for titles
- **Mono**: SF Mono with `tabular-nums` feature for **every financial number** — KPIs, schedules, KPI subtitles, delta chips, rate cells, percentages. Non-negotiable.
- **Serif**: Source Serif 4 (Google Fonts self-host via @fontsource for privacy) — only for the app wordmark, onboarding titles, and the PDF narrative / titles. Never in in-app chrome.

### Type scale
```
display      34 / 700 / -0.02em       greeting, "New scenario"
title        26–28 / 700 / -0.02em    borrower names
h2           22 / 700 / -0.015em
section      15 / 600 / -0.01em       "Balance over time"
body-lg      14 / 500
body         13 / 400
body-sm      12.5 / 400
eyebrow      11 / 600 / +0.09em tracked, UPPERCASE, --ink-tertiary
micro        10.5 / 600 / +0.08em tracked (KPI labels)
num-hero     46 / mono 500 / -0.02em / tnum
num-lg       22–26 / mono 500 / -0.01em / tnum
num          12–15 / mono / tnum
```

### Spacing — 4pt grid
`0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96`

### Radius
`2 (chart bars), 3 (mono chips), 4 (swatches), 6 (segmented), 8 (default), 10 (list cards), 12 (CTAs / heroes), 14 (grouped list), 26 (iOS grouped list), 999 (pills)`

### Elevation
**Effectively absent.** Use 1pt borders for division. The only real shadow is on phone-frame presentation. Dialogs (not in this pass) should use a flat 35% ink scrim, no blur.

### Motion
Short, never bouncy.
- `fast 120ms` — hover, focus ring
- `default 180ms` — tab, chip, toggle
- `slow 260ms` — sheet present, chart redraw, onboarding step change
- Easing: `cubic-bezier(0.2, 0, 0, 1)` out; `cubic-bezier(0.4, 0, 0.2, 1)` in-out
- Reduced-motion: drop transforms; keep opacity only
- Number tween on input: 400ms cubic-bezier(0.4, 0, 0.2, 1). Reduced-motion = instant.
- Chart first-draw: 600ms stagger; lines draw left-to-right.

### Iconography
- Line only, 1.5pt stroke, 20pt default / 22pt nav / 14pt inline. Never filled. No emoji in UI.
- On iOS, consume **SF Symbols** exclusively (mapped from the HTML's hand-drawn placeholders). Custom icons required for: amortization, recast, biweekly, extra-principal, HELOC, blended-rate, total-cost-analysis.

## Interactions & Behavior

- **Inputs update results live.** No "compute" action in results state; the inputs-screen CTA is for the first scenario only.
- **Segmented term control** updates schedule and chart in ≤400ms tween.
- **Tab switch** in Refinance: 200ms crossfade between option data. Winner badge animates to new tab's color if metric changes.
- **Borrower pill**: taps open the Borrower picker bottom sheet.
- **Share as PDF**: opens the carousel preview → iOS share sheet.
- **Swipe-back** honored throughout. Keyboard-safe insets for input views.
- **Dynamic Type**: layouts must tolerate up to Accessibility5; grids reflow, no truncation on primary content.
- **VoiceOver**: every chart exposes an equivalent `accessibilityRepresentation` as a data table.
- **Onboarding**: first-launch only; Settings → About has "Replay tour".

## State Management

- Per-scenario local state: `{ loanAmount, rate, term, startDate, taxes, insurance, hoa, pmi, extraPrincipal?, lumpSum?, recastAt?, biweekly? }` → finance engine returns `{ monthlyPITI, totalInterest, payoffDate, totalPaid, schedule[], breakdown{p,i,t,ins,pmi,hoa} }`
- Global state: `borrowers[]`, `savedScenarios[]`, `lenderProfile{nmls, brandColor, logo, licensedStates[]}`, `appearance`, `language`, `hapticsEnabled`, `faceIdEnabled`
- Persist to CoreData / SwiftData; Face ID gate optional.
- Today's rates: fetched at app launch + pull-to-refresh.

## Assets

All imagery is typographic or chart-generated — no illustrations, no stock photography, no house icons. The Quotient wordmark is set in Source Serif 4 400 at whatever size needed (tracked `-0.02em`). LO avatars are monogrammed circles on `--surface-sunken` with `--ink-secondary` initials.

## Files

In `design_files/`:
- `Quotient.html` — entry point combining everything in a design canvas
- `tokens/app.css`, `tokens/colors_and_type.css` — token definitions (light + dark)
- `screens/Onboarding.jsx` — 6-step tour
- `screens/Home.jsx` — Home / picker
- `screens/Saved.jsx` — Saved scenarios list
- `screens/Settings.jsx` — Settings (10 sections)
- `screens/BorrowerPicker.jsx` — Borrower bottom sheet
- `screens/Inputs.jsx` — Amortization inputs
- `screens/Amortization.jsx` — Amortization results
- `screens/Income.jsx` — Income qualification
- `screens/Refinance.jsx` — Refinance comparison
- `screens/TCA.jsx` — Total cost analysis
- `screens/Heloc.jsx` — HELOC vs refinance
- `screens/Share.jsx` — Share / PDF preview (paged carousel)
- `screens/PDF.jsx` — PDF cover page
- `screens/Foundations.jsx` — token/component specimen sheet
- `frames/ios-frame.jsx`, `frames/design-canvas.jsx` — presentation wrappers; ignore when implementing

## What's NOT in this pass

- iPad split-view and presentation-mode layouts
- Motion spec prototypes (behavior is documented above but not demo'd in the HTML)
- Full EN+ES copy doc, glossary, compliance disclaimers
- Empty/error/loading states (should follow iOS HIG defaults on top of the token set)

Pattern-match these against the existing screens when the team is ready to expand.
