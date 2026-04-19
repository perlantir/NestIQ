# Session 5F — Summary

Round-3 QA bug-fix + small-feature pass after Nick's review of 5E.
Six sub-tasks landed as six per-unit commits plus this rollup.

## What shipped

### 5F.1 · Amortization biweekly toggle → accelerated engine (commit `71c4465`)

**Root cause discovered during the read pass.** `convertToBiweekly(schedule:)`
re-slices a monthly schedule into biweekly cadence *over the same calendar
term* — it only saves ~1 month of payoff and ~$500 of interest vs monthly.
The toggle's existing test `retiresEarlier` passed only because 780 × 14 days
(29.92 yr) < 360 monthly advances (30.04 yr). Nick's QA was right: "identical
numbers to a monthly schedule."

Per Nick's Option A directive:

- Keep `convertToBiweekly()` semantically unchanged (it's the neutral cadence
  re-slicer) but rewrite its docstring to describe what it actually does.
- Add `biweeklyAccelerated(schedule:)` — monthlyPMT/2 paid every 14 days,
  actual/365 14-day interest accrual, loops until balance=0. Retires a
  conventional 30-yr in ~22-26 years with materially lower interest.
- Relax existing `convertToBiweekly` tests from strict `<` to
  near-equality (payoff within ~45 days; interest within $500).
- New `BiweeklyAcceleratedTests` suite: ≥24mo earlier payoff, ≥$20k
  interest saved on 30yr / 6% / $250k, half-monthly PMT, $1 zero-ending
  tolerance, conservation of totals, 14-day cadence, extras/PMI dropped,
  zero-principal/zero-rate edge cases.
- UI: `AmortizationFormInputs.toLoan()` always returns `.monthly`. The
  biweekly flag is now a post-processing overlay in
  `AmortizationViewModel.compute()` which preserves `monthlyScheduleForReference`
  so the Results view can show "monthly equivalent" + "retires N yr earlier"
  + "saves $X interest" beside the biweekly payment.
- Toggle moved from the Advanced disclosure to the primary Loan section,
  directly below Term.

### 5F.2 · Saved scenarios delete (commit `40a91d2`)

The prior `.swipeActions` modifier was inside a LazyVStack — a List-specific
modifier that silently no-ops outside a List. Nick's QA: "Saved tab has no
way to delete scenarios."

- Refactored body from `ScrollView`/`LazyVStack` to a plain-style `List`
  with sections. Header/search/filter in a top section; date buckets
  become List sections with native swipe actions.
- Swipe-to-delete opens a confirmation alert. New
  `.alert(isPresented:presenting:)` pattern with distinct destructive
  button text so XCUITest can target the alert Delete unambiguously.
- Edit-mode toolbar button + bottom dock. Edit-mode shows circle
  checkboxes per row, "Select all" toolbar, "Delete (N)" destructive
  button, confirmation alert. Edit-mode helpers extracted to
  `SavedScenariosScreen+EditMode.swift` (type_body_length cap).
- New `SavedScenariosDeleteTests.swift`: single-swipe-delete and
  multi-select-three rows round-trip tests. Both green.

### 5F.3 · Refinance 2/3/4 scenarios selector (commit `ceba1ae`)

- `RefinanceFormInputs.scenarioCount: Int` (default 2, persisted via
  `decodeIfPresent`).
- `RefinanceFormInputs.blankOption(label:)` factory — term=30 fixed,
  every other field zero.
- `RefinanceFormInputs.resizeOptions(to:)` — clamp 2-4, preserve
  existing options by position, relabel A/B/C/D.
- New segmented control above the options section. Changes animate
  `.easeInOut(0.2)`.
- Default Inputs state: 2 blank options at term=30. Previously shipped
  3 options pre-filled with sample data — per 5F.3 spec the LO fills
  in just what matters.
- `optionCard` + `loanAmountHint` + `optionLTVRow` moved to shared
  helpers extension (type_body_length cap).

### 5F.4.a · TCA text wrapping (commit `dafb605`)

- "Debts remaining · balance" / "· monthly" → "Remaining debt balance"
  / "Remaining debt monthly". Flattest single-line labels; no wrap.
- TCA scenario chips: "B · Conv 15" → "B" only. Full product name
  still renders in the scenario spec grid directly below. Chips stay
  one line even at 4-across.

### 5F.4.b · TCA include-debts toggle (commit `441fb5d`)

- `TCAFormInputs.includeDebts: Bool` (default true — preserves 5E.5
  behavior for saved scenarios; persisted via `decodeIfPresent`).
- New "Include consumer debts in analysis" toggle card in refi-mode
  inputs. Off → hides current-debts section + per-scenario
  "Remaining debt" rows.
- Winner determination adapts in both the in-app `TCAScreen.matrixRow`
  and the PDF `TCAComparisonPage.matrixRow`: when toggled on and
  scenarios have non-zero debts, each horizon's cost adds
  debtMonthly × horizonMonths. Off / purchase mode / zero debts →
  identical to pre-5F behavior.
- `TCAScreen.save()` + `generatePDFAndShare()` extracted to
  `TCAScreen+Actions.swift` (type_body_length cap).

### 5F.5 · HELOC PDF prominent blended rate (commit `46a7b41`)

- `HelocComparisonPage` gains `blendedRate10yr`, `refiRate`, `verdict`
  fields.
- New landscape hero between header and table: 40pt mono blended rate
  (accent-tinted when HELOC wins) + 26pt refi rate + verdict chip
  ("KEEP 1ST" / "REFI WINS") outlined in the winner color.
- Existing 13-row comparison table preserved below. Fits at 792×612.

### 5F.6 · Income Qualification reserves (commit `0c05e70`)

- `IncomeQualFormInputs.reservesMonths: Int` (default 2).
- New "Reserves required" section on Results view below Debts:
  stepper 0-12, live `$X (N × PITI)` readout.
- PDF: heroKPIs now includes "Reserves" as a 4th cell; fallback
  narrative appends "Requires N-month reserves: $X (N × PITI)." when
  months > 0.
- Extracted to `IncomeQualScreen+Reserves.swift` (type_body_length cap).

## Structural footprint

Four new extension files landed during 5F to keep Inputs/Results
structs under SwiftLint's 400-line cap — same pattern used by
`TCAInputsScreen+DebtsAndLTV.swift` in 5E.5:

- `AmortizationInputsScreen+Helpers.swift`
- `SavedScenariosScreen+EditMode.swift`
- `TCAScreen+Actions.swift`
- `IncomeQualScreen+Reserves.swift`

Plus the existing Refi extension gained `optionCard` + LTV helpers.

## Tests

| Suite                  | Before | After | Δ   |
|------------------------|--------|-------|-----|
| QuotientFinance        | 251    | 260   | +9  |
| App UI (QuotientUITests) | 11   | 13    | +2  |
| App Unit (QuotientTests) | unchanged | unchanged | —   |

Full iOS build green on iPhone 16 simulator. All tests pass.

New test files:

- `Packages/QuotientFinance/Tests/.../Unit/HandlersTests.swift` —
  `@Suite("biweeklyAccelerated")` with 9 tests.
- `AppUITests/SavedScenariosDeleteTests.swift` — swipe-delete + multi-
  select-three-rows UI tests.

Modified:

- `Packages/QuotientFinance/Tests/.../Unit/HandlersTests.swift` —
  relaxed `convertToBiweekly` retiresEarlier/reducesInterest assertions
  to near-equality with documented tolerance.

## What's next

Session 5G: new Self-Employment Income calculator (#6) following
Fannie Mae Form 1084 methodology — Schedule C, 1120S K-1, 1065 K-1,
two-year averaging with trend analysis. Entry points: standalone home
tile and import-into-Income-Qualification.

No open 5F blockers.
