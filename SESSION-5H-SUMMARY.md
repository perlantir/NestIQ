# Session 5H — Summary

Round-4 QA fix pass after 5F + 5G. Seven sub-tasks, each landed as a
discrete commit plus this rollup.

## What shipped

### 5H.1a · SE year field no longer shows thousands separator (`8458fe4`)

`FieldRow` gains `usesGroupingSeparator: Bool = true`. Self-Employment
tax-year rows pass `false` so 2023 renders as "2023" instead of
"2,023". Results + PDF already used direct Int interpolation —
unaffected.

### 5H.1b · SE addback UX clarity, no math changes (`978900e`)

**Math unchanged.** Verified against Fannie Selling Guide B3-3.6-03.

Input hints: every addback row gets an "added back" tertiary hint;
subtraction rows get a "subtracted" hint. An info icon above the first
addback in each Year-1 card opens a popover explaining the 1084
methodology ("Addbacks increase qualifying income… Selling Guide
B3-3.6-03").

Results per-year expandable detail replaces the flat addback/deduction
list with a full signed math trace:
- Schedule C: Net profit → signed addbacks/subtractions → Cash flow.
- 1120S: K-1 pass-through lines → Business cash flow → × Ownership →
  Borrower share → + W-2 wages → Cash flow.
- 1065: same as 1120S but with Guaranteed payments instead of W-2.
- Kickout case (< 25% + no distribution history) shows a B3-3.6-07
  note and collapses to W-2 / guaranteed payments only.

Three new property tests in `SelfEmploymentTests.swift` prove the
math:
- Fannie published example: $60k net profit + $5k depreciation →
  $65k.
- Property (500 random cases): net profit X + depreciation Y alone
  equals X + Y.
- Loss year addback: -$50k + $10k = -$40k, sign preserved.

QuotientFinance suite: 281 → 284 tests.

### 5H.1c · SE sheet nav-bar actions + Cancel (`c2b2c55`)

When opened as a sheet from IncomeQual, Self-Employment screens now
surface their primary actions in the navigation bar — leading Cancel,
trailing "Use this income" on Results. Title reads "Self-Employment
Income." The bottom import dock is removed.

`testSelfEmploymentImportToIncomeQual` hardened to assert the primary
income hint flips to "imported from Self-Employment analysis" after
the sheet returns — proves the monthly actually rode back through the
`onImportMonthly` closure, not just that the button existed.

### 5H.2 · TCA top cards + horizon table column alignment (`4f1230e`)

Wrapped `scenarioSpecGrid` in an HStack with a 52-pt leading gutter
matching the horizon matrix's horizon-label column. Scenario A's card
now sits directly above column A of the by-horizon table at every
scenario count, on every device width.

### 5H.3 · IncomeQual reserves stepper tightening (`12ef0a1`)

5F.6 already shipped the stepper (0-12, step 1, Int binding, default
2). This pass re-labels the card to "Reserves: N months" and drops the
redundant "N mo" chip to the right of the stepper. Added a
legacy-decode fallback — if a saved scenario carries `reservesMonths`
as a Double (pre-5F.6 schema, e.g. 2.5), it rounds to the nearest
0-12 Int instead of failing the whole decode. Likely explains the
"2.5" sighting in Nick's round-4 QA.

### 5H.4 · TCA 2/3/4 scenarios selector (`90f0dc9`)

`TCAFormInputs` gains `scenarioCount: Int` + `resizeScenarios(to:)` +
`blankScenario(label:)` — same pattern as Refi 5F.3. Inputs screen
renders a segmented 2/3/4 picker above the scenario tabs; changing it
grows or shrinks the scenarios array with an animated transition and
keeps the active tab in range. Saved scenarios persist the count.
Results grid, horizon table, and PDF comparison page all iterate
`scenarios.count` so they adapt automatically.

Fresh-launch default drops from 4 pre-filled demo scenarios to 2 blank
ones at term=30.

### 5H.5 · HELOC blank-slate inputs (`9875203`)

`HelocInputsScreen.defaultInputs` zeros every numeric field except
`firstLienRemainingYears=30` and `refiTermYears=30`. Matches the Refi
5F.3 + TCA 5H.4 blank-slate pattern. Saved HELOC scenarios still load
their stored values unchanged.

## Stop conditions — none fired

- Session 1-5G tests: green. QuotientFinance 281 → 284 (+3 property
  tests on 5H.1b). App UI test count unchanged (1 existing test
  hardened in 5H.1c).
- SE math not touched on 5H.1b — verified against Fannie 1084 formulas
  at `cashFlowScheduleC`, `cashFlowForm1120S`, `cashFlowForm1065`.
- TCA alignment fix: 1-file change (container gutter, not a Grid
  rewrite).
- Reserves migration: Int stays Int; legacy Double inputs decode with
  fallback. No saved-scenario breakage.

## Tests

| Suite                      | After 5G | After 5H | Δ    |
|----------------------------|----------|----------|------|
| QuotientFinance            | 281      | 284      | +3   |
| App UI (QuotientUITests)   | 17       | 17       | 0    |
| App Unit (QuotientTests)   | unchanged | unchanged | —   |

Full iOS build green on iPhone 16 simulator (iOS 18.3.1).

## Decisions

Six new entries in `DECISIONS.md`:

1. SE sheet primary actions moved to nav bar (5H.1c).
2. SE addback UX clarity — hints + info icon + signed breakdown,
   math unchanged (5H.1b).
3. TCA scenario count selector pattern (5H.4).
4. Blank-slate fresh-launch defaults across calculators
   (5F.3 / 5H.4 / 5H.5).
5. TCA column alignment via leading gutter (5H.2).

## What's next

No open 5H blockers. Round-4 QA fixes all addressed. Standing by for
Nick's next QA pass, or Session 6 scope decisions (ES localization,
live FRED rate endpoint, SE scope deferrals, FHA MIP matrix, Apple
Developer enrollment work).
