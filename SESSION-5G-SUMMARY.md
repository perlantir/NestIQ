# Session 5G — Summary

New calculator #6: **Self-Employment Income Analysis** following
Fannie Mae Form 1084 methodology. Eight sub-tasks landed as commits
plus this rollup.

## Scope

**Covered:**

- Schedule C (sole proprietor, 1040 Schedule C)
- Form 1120S S-corporation K-1
- Form 1065 partnership K-1
- 2-year averaging with trend classification (stable / increasing /
  declining / significant decline)
- Fannie B3-3.6-07 eligibility gate — pass-through income zeroed when
  ownership < 25% AND no consistent distribution history
- Standard addbacks (depreciation, depletion, amortization, business
  use of home, mileage depreciation) and deductions (non-deductible
  meals, Schedule L mortgages/notes <1yr, non-deductible travel)
- Two entry points: standalone 06 tile on Home + import into Income
  Qualification

**Explicitly deferred to Session 7+** (per spec):

- Schedule F (farm)
- Schedule E rental (Form 1037 / 1038)
- Form 1120 (C-corporation)
- Business liquidity / quick-ratio analysis
- COVID-era Lender Letter guidance

## Commits

### 5G.1 · QuotientFinance SE primitives (`a919a80`)

- `BusinessType` enum (.scheduleC / .form1120S / .form1065).
- Per-year Codable types: `ScheduleCYear`, `Form1120SYear`,
  `Form1065Year`.
- `cashFlowScheduleC(_:)`, `cashFlowForm1120S(_:)`, `cashFlowForm1065(_:)`
  — direct Fannie 1084 formulae. B3-3.6-07 kickout rule applied in
  1120S + 1065: when ownership < 25% AND no distribution history, the
  pass-through contribution collapses to 0 (W-2 wages and guaranteed
  payments still count).
- `IncomeTrend` enum with `usesLowerYear` computed property.
- `TwoYearAverage` struct + `twoYearAverage(_:_:)` helper. Thresholds:
  ±5% for stable, -20% for significantDecline. Lower-year-on-decline
  qualifying rule. y1 ≤ 0 degenerate case handled.
- `SelfEmploymentTests.swift` — 21 new tests, including 2 property tests
  with 500 random cases each.

### 5G.2 · SelfEmploymentOutput + compute helper (`e421dee`)

- `Addback` / `Deduction` line-item types for PDF math-showing.
- `SelfEmploymentYearResult` — year + cashFlow + addbacks + deductions.
- `SelfEmploymentInput` discriminated union over the three (y1, y2)
  per-type pairs.
- `SelfEmploymentOutput` — businessType + year1 + year2 +
  twoYearAverage + trendNotes + qualifyingMonthlyIncome.
- `compute(input:)` dispatcher + trendNote(for:) auto-generated Results
  line per trend class.

### 5G.3 / 5G.4 / 5G.5 · Inputs + Results + PDF (`f1475af`)

- `SelfEmploymentFormInputs` — Codable payload carrying all three
  subforms' state so switching types doesn't lose the other drafts.
- `SelfEmploymentViewModel` — @Observable, owns inputs + output.
- `SelfEmploymentInputsScreen` — header + borrower chip + segmented
  Sch C / 1120S / 1065 picker + two year cards per type (extracted to
  `SelfEmploymentInputsScreen+Cards.swift` for SwiftLint). Each subform
  has an ownership-% slider (1120S/1065) and a "Consistent distribution
  history" toggle gated by Fannie B3-3.6-07.
- `SelfEmploymentResultsScreen` — borrower header, hero qualifying
  monthly (46pt mono), trend badge, Fannie trendNotes line, per-year
  expandable cards with labeled addbacks (+$green) and deductions
  (−$red), five-row two-year summary table.
- Dock auto-switches: standalone invocation gets the Calculator dock
  (Narrate/Save/Share); sheet invocation from IncomeQual swaps in
  Cancel + "Use this income" (id selfEmployment.useIncome).
- PDF: `SelfEmploymentCashFlowPage` (portrait 612×792) — two-column
  line-item breakdown merged by label + tinted "Annual cash flow"
  footer. `PDFBuilder+SelfEmployment.swift` hosts
  `buildSelfEmploymentPDF` to keep PDFBuilder under the SwiftLint cap.
- Plumbing: `CalculatorType.selfEmployment` (06 · "Self-employ" short),
  `ScenarioType.selfEmployment` in both QuotientCompliance and
  QuotientNarration. NarrationTemplates adds EN + ES fallback.
  `CalculatorNewScenarioView`, `SavedScenariosScreen.openScenarioDestination`,
  `CalculatorFilter` all extended.

### 5G.6 · Income Qualification SE import (`a0752aa`)

- Pill "or use Self-Employment analysis →" below the Gross monthly
  income field (id incomeQual.openSelfEmployment).
- Tap → SelfEmploymentInputsScreen inside a NavigationStack sheet at
  .large detent, with `onImportMonthly` closure.
- Tap "Use this income" in the sheet → replaces `incomes[0]` with an
  IncomeSource (kind=.selfEmployed, label="Self-employment analysis")
  and dismisses.
- Primary income FieldRow's hint flips to "imported from Self-Employment
  analysis" when the first income is SE-sourced.
- Extracted to `IncomeQualInputsScreen+SelfEmployment.swift` for
  type_body_length.

### 5G.7 · Home tile + routing

No new commit — landed automatically with the type-enum additions in
the 5G.3/.4/.5 commit because HomeScreen's calculatorList iterates
`CalculatorType.allCases` and `CalculatorNewScenarioView` has the
exhaustive switch. The 06 tile renders with "Self-employment income" /
"Fannie 1084 cash flow · Sch C / 1120S / 1065" copy.

### 5G.8 · SE UI tests (`b55b4e4`)

- `testScheduleCHappyPath`, `testForm1120SHappyPath`,
  `testForm1065HappyPath` — open SE from Home, compute, save, verify
  `saved.row.selfEmployment` appears.
- `testSelfEmploymentImportToIncomeQual` — tap the import pill,
  compute in the sheet, tap "Use this income", verify return to
  Income Qualification Inputs.

## Methodology references

- **Fannie Mae Selling Guide B3-3.6-03** — Schedule C cash-flow formula
  (net profit + depletion + depreciation − meals + business use of
  home + amortization).
- **Fannie Mae Selling Guide B3-3.6-07** — K-1 income eligibility:
  ownership ≥ 25% OR consistent distribution history gate on
  pass-through income for both 1120S and 1065.
- **Fannie Form 1084** — 2-year averaging, lower-year-on-decline
  qualifying, significant-decline written-explanation requirement.

## Tests

| Suite                      | Before 5F | After 5F | After 5G | Δ total |
|----------------------------|-----------|----------|----------|---------|
| QuotientFinance            | 251       | 260      | 281      | +30     |
| App UI (QuotientUITests)   | 11        | 13       | 17       | +6      |
| App Unit (QuotientTests)   | unchanged | unchanged | unchanged | — |

Full iOS build green on iPhone 16 simulator. BUILD SUCCEEDED.

## What's next

No open 5G blockers. Session 5 as a whole (5A through 5G) is complete.
Awaiting Nick's round-4 QA pass after exercising the new Self-Employment
calculator and the 5F fixes in the simulator.

Possible Session 6 scope (not committed):

- Spanish (es) localization pass — the infrastructure is in place
  (EHOLanguage on LenderProfile, ES narration templates) but the
  calculator Inputs / Results copy itself is still EN-only.
- Live rate endpoint behind FRED API (currently MockRateService).
- Schedule F / Schedule E rental / Form 1120 — the Self-Employment
  scope deferrals.
- FHA MIP matrix wiring into Amortization.
- Apple Developer enrollment-gated work (provisioning + push/IAP).
