# Session 5P — Summary

Session 5P bundled one architectural rework (D9 — current mortgage
on `Borrower`) with seven bug fixes + UX polish items Nick surfaced
during the 5O QA round. Fifteen sub-tasks, all shipped.

## Architectural shift — D9

**Current mortgage lives on `Borrower` as a JSON blob.**

Per the option-1 decision made at session start after the initial
audit discovered `Borrower` is a SwiftData `@Model` (not a JSON-blob
Codable struct as the session plan's stop-condition caught):

- `Borrower.currentMortgageJSON: Data?` stored attribute.
- `Borrower.currentMortgage: CurrentMortgage?` computed accessor
  (getter decodes, setter encodes / clears) — matches
  `licensedStatesCSV` / `licensedStates` precedent at
  `Models.swift:98-106, :179-187`.
- `CurrentMortgage` lives in `App/Storage/CurrentMortgage.swift` as a
  Codable/Hashable/Sendable value struct with 7 fields.
- `CurrentMortgageCalculations` helpers in `QuotientFinance`
  (`Primitives/CurrentMortgage.swift`) operate on primitives —
  `monthsPaid`, `monthsRemaining`, `ltvToday`, `equityToday`.

Refinance-mode calculators (TCA refi / Refinance Comparison / HELOC
vs Refi) pull the mortgage from the selected borrower. Scenarios
snapshot it into their inputsJSON so loading a saved scenario
restores the status-quo baseline even if the borrower's live
`currentMortgage` later changes.

## What shipped per sub-task

### 5P.1 — Amortization extra principal in schedule + chart + totals

Engine correctly applied `extraPeriodicPrincipal`; bug was in the
display layer. Three fixes:

- `AmortizationViewModel.yearlyBalances` padded the chart to
  `(termYears, 0)` whenever the loan paid off before the scheduled
  term. Now anchors on the actual payoff year using the engine's
  final payment row.
- `AmortizationBreakdownView.monthlyRow` — "Pmt" and "Prin" columns
  showed `p.payment` (scheduled P&I only) and `p.principal`
  (scheduled principal only). Balance dropped faster than the
  displayed payment accounted for. Now shows `payment +
  extraPrincipal` and `principal + extraPrincipal` so the row
  reconciles.
- `AmortizationPDFHTML.monthlyScheduleHTML` — same fix applied to
  the monthly-granularity PDF schedule table.

Yearly tables (on-screen + PDF) were already correct —
`yearlyAggregate` sums `extraPrincipal` into per-year totals.

Tests: +3 in `AmortizationViewModelTests`.

### 5P.2 — PDF text contrast

Primary section labels were bleeding into cream paper at
`--muted: #85816F`. Introduced `--label: #444038` (mid-tone between
ink and muted) and redirected `hero-label`, `kpi-label`, `table.data
th`, and generic `.label` to it. Muted preserved for truly ancillary
text (meta, contact, disclaimer, chart-caption).

### 5P.3 — PDF empty tan rectangle on disclosures

Root cause: WKWebView paints the body cream background inside its
content rect, but the surrounding PDF page was default white. On
short pages the WebKit rect showed as a visible cream rectangle on
white paper. Fix: fill each PDF page with the paper color
(`#FAF9F5`) before `printRenderer.drawPage` so the WebKit rect
blends seamlessly into the page.

### 5P.4 — Reserves input moves from Results → Inputs

The reserves-months stepper originally lived on Income Qualification
Results (5F.6). Nick flagged this in QA — LOs expect to set
qualification knobs before compute, not after. Moved to
`IncomeQualInputsScreen` under DTI caps via a new
`IncomeQualInputsScreen+Reserves.swift` extension (SwiftLint
type-body cap). Results now shows a read-only summary card with the
selected months + dollar total. Same 5F.6 default (2 months) and
5J.2 range (0-36). Tests: +3 in `IncomeQualViewModelTests`.

### 5P.5 — TCA scenario input isolation

When the LO edited rate or loan amount in scenario A and switched to
B/C/D, the same typed value appeared in the new tab. Root cause:
`FieldRow` owns an internal `@State text: String` buffer (lifted
from 5B for free-typing). SwiftUI reuses `FieldRow` instances at the
same structural position when the tab index changes — the Decimal
binding swaps to a different scenario's field, but the `@State` text
buffer survives. Fix: attach
`.id(viewModel.inputs.scenarios[clampedTab].id)` to the scenario
card. SwiftUI sees a new identity per scenario UUID and
destroys/recreates the FieldRow children on tab switch. Tests: +3 in
`TCAViewModelTests`.

### 5P.6 — CurrentMortgage model + Borrower integration

Per D9:

- `App/Storage/CurrentMortgage.swift` — Codable/Hashable/Sendable
  value struct, 7 fields.
- `Borrower.currentMortgageJSON: Data?` + computed
  `currentMortgage: CurrentMortgage?` accessor.
- `Packages/QuotientFinance/Sources/QuotientFinance/Primitives/CurrentMortgage.swift`
  — `CurrentMortgageCalculations` enum with four primitive helpers.

Tests: +9 in `CurrentMortgageTests` (SPM), +3 in
`SwiftDataModelTests` (app).

### 5P.7 — Current Mortgage section UI + draft model

Reusable form component usable both from `NewBorrowerForm` (at
borrower-create time) and from the 5P.12 / 5P.13 refi calculators
(when the attached borrower has no persisted mortgage).
`CurrentMortgageSection` is a `DisclosureGroup` with the 7 fields +
validation hint; `CurrentMortgageDraft` is the scratch-space model
(distinct from the final `CurrentMortgage` value type) that tracks
typing state and exposes `isBlank` / `isValid` / `toMortgage()`.
Validation rules: all currency > 0, rate > 0, term > 0, start date
in past, currentBalance ≤ originalLoanAmount. Tests: +6 in
`CurrentMortgageDraftTests`.

### 5P.8 — TCA refi mode: current mortgage as anchor

- `TCAFormInputs.currentMortgage: CurrentMortgage?` (snapshot field)
  with Codable backward-compat for legacy scenarios.
- `CurrentMortgage` gained `Hashable` conformance to satisfy
  `TCAFormInputs`'s synthesized Hashable.
- `TCAInputsScreen` (refi mode only) surfaces a Current Mortgage
  section at the top. Hydrates from
  `viewModel.inputs.currentMortgage` (loaded scenarios) or
  `selectedBorrower.currentMortgage` (fresh session). Extracted into
  `TCAInputsScreen+CurrentMortgage.swift`.
- Draft lives in view-local `@State`; commits into
  `inputs.currentMortgage` only when fully valid or fully blank —
  partial drafts don't corrupt downstream math.

### 5P.9 — Break-even vs current mortgage baseline

- `breakEvenBaselinePayment(monthlyPayments:)` — returns
  `currentMortgage.currentMonthlyPaymentPI` when set (refi mode),
  else `monthlyPayments[0]` for backward compat.
- `breakEvenTermMonths(scenarioIndex:)` — clamps break-even horizon
  at the current mortgage's remaining term so a proposed refi only
  has the remaining life of the old loan to recoup closing.
- `breakEvenMonth` / `breakEvenGraphData` guard relaxed: scenario A
  can participate in break-even when the current mortgage is the
  baseline (legacy "A is baseline, skip it" preserved when no
  currentMortgage).
- `TCAScreen+BreakEven.breakEvenSeries` +
  `breakEvenDescriptionLines` updated to include all scenarios when
  current mortgage is the baseline.

Tests: +7 in `TCAViewModelTests` (baseline-selection + term-clamp +
Codable round-trip + legacy-JSON backward compat).

### 5P.10 — Current mortgage anchor card on TCA Results

Refi-only Results section above the scenario legend showing 6 stat
tiles across two rows: Current balance / Current P&I / Current rate
— Months remaining / Equity today / LTV today. Computed via
`CurrentMortgageCalculations`. Extracted into
`TCAScreen+CurrentMortgage.swift`.

Scope note: a full "Current · A · B · C" horizon matrix would
require reworking `horizonMatrix` / `scenarioTotalCosts` in
`TCAScreen+BreakdownSections` plus adding a current-mortgage
amortization path through each horizon month. The anchor card lands
the essential story without the entanglement risk the 5P stop
conditions call out.

### 5P.11 — TCA PDF: Current mortgage anchor card

PDF mirror of 5P.10. Inserts a "Status quo · current mortgage"
content-card between the cover and scenario specs on refi-mode TCA
PDFs. Same six stats. Extracted into
`TCAPDFHTML+CurrentMortgage.swift` (TCAPDFHTML enum body was already
at the 400-line cap).

### 5P.12 + 5P.13 — Refinance + HELOC prefill from borrower.currentMortgage

Both calculators already carry their own current-loan fields:

- Refinance: `currentBalance`, `currentRate`,
  `currentRemainingYears`, `homeValue`.
- HELOC: `firstLienBalance`, `firstLienRate`,
  `firstLienRemainingYears`, `homeValue`.

Both screens gained a `applyBorrowerCurrentMortgage` helper that
runs on borrower-picker select and on `.onAppear`. Prefill is
conditional: only overwrites when the form's balance is 0 — respects
edits the LO has already made and never clobbers values from an
`existingScenario`.

### 5P.14 — Regression audit

Full test suite run across all packages + app tests + UI tests.

| Surface | Before | After | Delta |
|---|---|---|---|
| QuotientFinance | 307 | 316 | +9 (CurrentMortgageTests) |
| QuotientCompliance | 40 | 40 | 0 |
| QuotientNarration | 10 | 10 | 0 |
| QuotientPDF | 2 | 2 | 0 |
| QuotientTests | 77 | 102 | +25 (Amort +3, IncomeQual +3, SwiftDataModel +3, CurrentMortgageDraft +6, TCA +10) |
| QuotientUITests | 18 | 18 | 0 |

**Total: 488 tests, 1 conditionally skipped (5O.7 SE PDF), 0 failures.**

### 5P.15 — Wrap-up

This document + D9 appended to `DECISIONS.md` + final rollup commit.

## Files added

- `App/Storage/CurrentMortgage.swift`
- `App/Features/BorrowerPicker/CurrentMortgageSection.swift`
- `App/Features/Calculators/IncomeQualification/IncomeQualInputsScreen+Reserves.swift`
- `App/Features/Calculators/TotalCostAnalysis/TCAInputsScreen+CurrentMortgage.swift`
- `App/Features/Calculators/TotalCostAnalysis/TCAScreen+CurrentMortgage.swift`
- `App/Features/Share/TCAPDFHTML+CurrentMortgage.swift`
- `Packages/QuotientFinance/Sources/QuotientFinance/Primitives/CurrentMortgage.swift`
- `Packages/QuotientFinance/Tests/QuotientFinanceTests/Unit/CurrentMortgageTests.swift`
- `AppTests/CurrentMortgageDraftTests.swift`

## Commits

```
Session 5P.1  — Amortization extra principal in schedule + chart + totals
Session 5P.2  — PDF text contrast (label token)
Session 5P.3  — PDF page background fills with paper color
Session 5P.4  — Income Qual reserves selector moves to Inputs
Session 5P.5  — TCA scenario input isolation via UUID .id()
Session 5P.6  — CurrentMortgage model + Borrower integration + finance helpers
Session 5P.7  — Borrower editor Current mortgage section
Session 5P.8+9 — TCA refi current mortgage anchor + break-even baseline fix
Session 5P.10 — TCA Results Current mortgage anchor card
Session 5P.11 — TCA PDF Current mortgage anchor card
Session 5P.12+13 — Refinance + HELOC prefill from borrower.currentMortgage
Session 5P    — complete rollup (this commit)
```

## Deferred

- **Inline save-to-borrower toggle on refi calculators** — the session
  plan sketched a "if no currentMortgage, prompt inline entry with
  optional save-to-borrower" UX. Shipped a simpler cut: 5P.7's
  `CurrentMortgageSection` in `NewBorrowerForm` handles the
  create-time path; refi calculators prefill from borrower when
  available. An inline calculator-screen entry flow that saves back
  to the borrower model is future work.
- **Full "Current · A · B · C" horizon matrix** — anchor card lands
  the essential comparison; expanding the TCA horizon matrix to
  include a current-mortgage path through each horizon month would
  touch `horizonMatrix` / `scenarioTotalCosts` / unrecoverable /
  equity and PDF mirrors. Deferred per the 5P stop-condition
  guidance.
- **Borrower editor for existing borrowers** — no standalone editor
  exists in v1. Editing a persisted `currentMortgage` requires
  recreating the borrower or editing via a future UI path.
- **Home value appreciation modeling** — `propertyValueToday` is the
  LO's static estimate applied uniformly across refi scenarios.

## What's next — Session 6 (TestFlight admin)

1. Remove DEBUG AuthGate bypass (`AuthGate.swift:84-91`) once the
   UI-test bypass path is satisfied by alternative means.
2. Info.plist usage descriptions — `NSPhotoLibraryUsageDescription`,
   `NSFaceIDUsageDescription`.
3. Wire real URLs — `https://nestiq.mortgage/privacy` / `/terms` /
   `/support` — into Settings + onboarding.
4. Wire `support@nestiq.mortgage` into Send Feedback.
5. Apple Developer team ID, enable App Store signing, archive +
   TestFlight upload.
