# Session 5M — Summary

Session 5M is a major APR rollout across every rate-taking calculator
plus a deep Total Cost Analysis expansion — cash-to-close, interest
vs principal breakdown, unrecoverable costs, break-even chart,
reinvestment strategy (invest vs. extra principal), and equity
buildup. Nine sub-tasks, all shipped; this is the last dev work
before Session 6 (TestFlight admin).

## Pre-work

Baseline failed on first run: SwiftLint `--strict` blocked the build
on three violations. All repaired before 5M.1 touched code:

- **Session 5L.4** (three uncommitted Settings files) committed as its
  own commit: `Licensed states — Settings row + Per-State Disclosures
  button + shared picker`.
- **Session 5L rollup** landed with the session summary
  (SESSION-5L-SUMMARY.md — previously missing) + four DECISIONS.md
  entries.
- **Session 5K.2 follow-up**: collapsed the else-if chain in
  QuotientNarration into a switch statement so SwiftLint
  statement_position passes.
- **Session 5L.5 follow-up**: extracted `SettingsScreen+Compliance.swift`
  (complianceSection + licensedStatesPreview) to get SettingsScreen
  under the type_body_length cap.
- **Session 5L.2 follow-up**: fixed the flaky
  `testRecentScenarioTapLoadsCalculator` — the 5L.2 brandMark pushed
  the row 56pt below the iPhone 17 Pro viewport, and coordinate-tap
  deliberately skips scroll-to-visible. Swapped to standard `.tap()`
  (scoped DECISIONS #123 in the process to clarify coordinate-tap is
  only for ultraThinMaterial-occluded elements).

## Architectural decisions

All 5M decisions appended to DECISIONS.md:

- **D1. APR is display-only.** Never drives engine math. TILA § 1026.22
  APR math is regulated territory; LOs enter the APR their LOS
  produced and NestIQ surfaces it for borrower-facing compliance
  context.
- **D2. APR display pattern.** When APR == rate (within 0.0005% of
  display precision) or APR is blank, show only the rate. When APR >
  rate (or < rate via credits), show both: "6.750% / 6.812% APR".
- **D3. APR default.** LO-entered; blank stores `nil`. Display treats
  `nil` as "same as rate." Schema: `Optional<Decimal>`.
- **D4. Unrecoverable costs definition.** Interest + MI + Closing
  Costs. Tax / insurance / HOA render separately as "Ongoing housing
  costs (paid regardless)" because they apply whether owning or
  renting. Glossary footnote in the PDF explains the split.
- **D5. Break-even format.** "Month 34 (~2.8 years)" with Swift Charts
  crossover visualization. Refinance-mode only; baseline = scenario
  index 0.
- **D6. Reinvestment defaults.** 7% annualized (conservative S&P long-
  run average), LO-editable per TCA analysis. Disclaimer required on
  every surface: "Illustrative — past performance is not indicative
  of future results."
- **D7 (corrected).** `Scenario.inputsJSON: Data` is JSON-blob Codable,
  NOT SwiftData field-level schema. Migration for new fields is
  Codable-level — `decodeIfPresent(...) ?? default` — no SwiftData
  version bump. Confirmed against prior decodes (TCAScenario already
  uses this pattern from 5E.5 for `loanAmount`, `monthlyMI`, etc.).

## What shipped

### 5M.1 — Schema migration + APR field foundation + display helper

`QuotientFinance/RateDisplay.swift` — `displayRateAndAPR(rate:apr:)`
(Double variant) + `displayRateAndAPR(rate:decimalAPR:)` (Decimal?
bridge). Tolerance 0.0005% absorbs sub-precision drift.

Schema additions (all Decimal? except noted):
- AmortizationFormInputs: `aprRate`
- IncomeQualFormInputs: `aprRate`
- RefiOption: `aprRate`; RefinanceFormInputs: `currentAPR`
- HelocFormInputs: `firstLienAPR`, `helocAPR`, `refiAPR`
- TCAScenario: `aprRate`, `prepaids: Decimal = 0`, `credits: Decimal = 0`
- TCAFormInputs: `reinvestmentRate: Decimal` (String-initialized from
  "0.07" so the default stores exactly as 0.07 instead of the
  0.07000000000000001024 artifact from Decimal-literal routing
  through Double)

Tests: 8 RateDisplayTests + 6 SchemaMigrationTests.

### 5M.2 — APR input field across 5 rate-taking calculators

New shared `APRFieldRow` component with `Decimal?` binding and
"Same as rate" placeholder. Rolled out to every rate-taking Inputs
screen (Self-Employment has no rate input, skipped per spec). Results
+ PDF displays consume the helper at every borrower-facing rate
surface.

FieldRow picked up two additive parameters:
- `placeholder: String = "—"` (preserves pre-5M default)
- `showsInitialValue: Bool = true` (APR rows pass `false` when the
  stored optional is nil so 0 renders as placeholder rather than "0")

Note: deliberately did NOT swap narration facts, compact HELOC tranche
legends, or verdictCopy prose (APR not load-bearing there; layout
overflow risk on narrow surfaces).

### 5M.3 — TCA: approximate cash to close

`TCAFormInputs.approximateCashToClose(for:)`:
- Purchase: Price + Closing + Prepaids − DP − Credits
- Refinance: Closing + Prepaids − Credits
- Clamped >= 0 (credit-heavy scenarios don't paint negative "cash")

Prepaids + Credits inputs added to TCA Inputs per scenario. "Approx
cash" line in each scenario top card + PDF comparison page. Label
intentionally reads "Approximate" so it's not mistaken for a
regulated Loan Estimate.

Tests: 4 in TCAViewModelTests (purchase formula, refi formula, zero-
input safety, credit-clamp).

### 5M.4 — TCA: APR in scenario comparison

Polish sweep — the inline "APR" sub-line under each scenario's rate
(shipped in 5M.2) normalized to always use "%" suffix on both lines
for consistent visual weight. Scenario card format is now "6.750%"
primary / "6.812% APR" tertiary (conditional).

### 5M.5 — TCA: interest vs principal breakdown

Engine primitives on `AmortizationSchedule`:
- `cumulativeInterest(throughMonth:)`
- `cumulativePrincipal(throughMonth:)`

TCAViewModel gains `scenarioSchedules: [AmortizationSchedule]`
populated in `compute()` so breakdown sections read horizon-scoped
cumulative values without re-running amortize.

"Interest vs principal · by horizon" matrix in TCAScreen +
TCAComparisonPage. Cells render split-value text ("82% int / 18%
prin") per D5M.5 (text only — no bar chart, per Nick's 5M.5
decision).

Tests: 7 ScheduleHorizonTests (month-0, negative, beyond-term, sum
invariants, monotonicity, mid-horizon interest sanity, principal +
remaining = original).

### 5M.6 — TCA: unrecoverable costs + ongoing housing

Engine: `cumulativeMI(throughMonth:)` on AmortizationSchedule.

TCAFormInputs helpers:
- `unrecoverableCost(scenario:schedule:years:)` = closing + interest
  + MI (no tax/ins/HOA per D4)
- `ongoingHousingCost(years:)` = (tax + ins + HOA) × months

"Unrecoverable costs · by horizon" matrix on Results ("$X (Y%)"
format — share of total mortgage paid, not total housing cost).
Secondary ongoing-housing line. PDF carries a compact longest-
horizon summary + full glossary footnote in the footer.

Tests: 3 in TCAViewModelTests + 2 in ScheduleHorizonTests for the MI
primitive.

### 5M.7 — TCA: estimated break-even (refinance mode)

TCAFormInputs:
- `breakEvenMonth(scenarioIndex:monthlyPayments:) -> Int?`
  Integer ceiling division: first M where M × savings >= closingCosts.
  `nil` when scenario is baseline, savings ≤ 0, or break-even never
  reached within term.
- `breakEvenGraphData(...) -> [(month, cumulative)]` for the chart.

Swift Charts section with:
- Per-scenario summary ("Month 34 (~2.8 years)" / "Never (within 30yr term)")
- Line chart: LineMark per non-baseline scenario, RuleMark (dashed
  horizontal) at each scenario's closingCosts — crossover = break-
  even month.

PDF: compact one-line break-even summary per scenario. Full chart
on the PDF deferred (page already at density ceiling; dedicated
analytics PDF page is a future-session architectural change).

Tests: 3 in TCAViewModelTests.

### 5M.8 — TCA: reinvestment strategy (invest vs extra principal)

Engine primitive `Reinvestment.swift`:
- `futureValueOfMonthlyDeposits(deposit:annualRate:months:)`
  Ordinary annuity FV formula: PMT × ((1+r)^n − 1) / r.

TCAFormInputs:
- `pathAInvestmentBalance(...)` — invest the savings at
  reinvestmentRate, compounded monthly
- `pathBExtraPrincipal(...)` — apply the savings as extra principal,
  compute interestSaved + monthsAvoided × payment (wealth built)

Inputs: new "Reinvestment assumption" field group (refi mode only).
Results: full per-scenario reinvestment section with horizon-year
invest balances + payoff acceleration line + required D6 disclaimer.
PDF: compact one-line reinvestment summary; glossary footer picks
up the "illustrative" caveat.

Deferred: dedicated "Reinvestment strategy" PDF page with paired
path tables — documented upfront rather than silently cut.

Tests: 6 ReinvestmentTests (engine primitive) + 3 in TCAViewModelTests
(path A/B helpers).

### 5M.9 — TCA: equity buildup

TCAFormInputs `equityAtHorizon(scenarioIndex:schedule:years:)`:
- Purchase mode: scenario.propertyDP.purchasePrice − remainingBalance
- Refinance mode: inputs.homeValue − remainingBalance
- Clamped ≥ 0

"Equity at horizon" matrix on Results. Caption clearly states "flat
home value — appreciation not modeled" (appreciation is a legit
future feature; 5M scope excludes it).

PDF: compact longest-horizon equity summary per scenario.

Tests: 3 in TCAViewModelTests (known loan, 15yr > 30yr invariant at
mid-schedule, purchase mode uses scenario price).

## Engine primitives added to QuotientFinance

| File | Added |
|---|---|
| `RateDisplay.swift` | `displayRateAndAPR` (Double + Decimal? variants) |
| `Schedule.swift` | `cumulativeInterest`, `cumulativePrincipal`, `cumulativeMI` throughMonth |
| `Reinvestment.swift` | `futureValueOfMonthlyDeposits` |

## Schema migration

Every new field lands via `decodeIfPresent(...)` with a sentinel
default. Pre-5M saved scenarios decode cleanly — proven by
SchemaMigrationTests covering all 5 calculator FormInputs. No
SwiftData version bump. See DECISIONS.md D7 (corrected) for the
rationale.

## Tests

| Surface | Before | After | Delta |
|---|---|---|---|
| QuotientFinance | 284 | 307 | +23 |
| QuotientCompliance | 40 | 40 | 0 |
| QuotientNarration | 10 | 10 | 0 |
| QuotientPDF | 2 | 2 | 0 |
| QuotientTests (app) | 31 | 53 | +22 |
| QuotientUITests | 18 | 18 | 0 |

New tests spread across:
- RateDisplayTests (+8)
- SchemaMigrationTests (+6, new file)
- ScheduleHorizonTests (+9, new file)
- ReinvestmentTests (+6, new file)
- TCAViewModelTests (+16: cash-to-close 4, unrecoverable 3, break-
  even 3, reinvestment 3, equity 3)

## Commits

```
Session 5L.4  — Licensed states Settings row + Per-State button + picker
Session 5L    — rollup (summary + DECISIONS)
Session 5K.2  — follow-up: narration switch
Session 5L.5  — follow-up: SettingsScreen+Compliance extraction
Session 5L.2  — follow-up: recent-row .tap() (post-wordmark layout)
Session 5M.1  — schema migration + APR foundation + displayRateAndAPR
Session 5M.2  — APR input + display across 5 rate-taking calculators
Session 5M.3  — TCA approximate cash-to-close top-card + PDF
Session 5M.4  — TCA APR column polish in scenario comparison
Session 5M.5  — TCA interest vs principal breakdown per scenario per horizon
Session 5M.6  — TCA unrecoverable costs per scenario per horizon
Session 5M.7  — TCA estimated break-even analysis (refinance mode)
Session 5M.8  — TCA reinvestment strategy (invest vs extra principal)
Session 5M.9  — TCA equity buildup per scenario per horizon
Session 5M    — complete rollup
```

## What's next — Session 6 (TestFlight admin)

Remaining blockers before TestFlight:

1. Remove DEBUG AuthGate bypass (`-uitestReset` + `-uitestSeedProfile`
   launch-arg gating must continue to compile only under DEBUG).
2. Info.plist usage descriptions — contacts, camera (if Photos picker
   hits camera), Face ID.
3. Wire real URLs: `https://nestiq.mortgage/privacy`, `/terms`,
   `/support`.
4. Wire `support@nestiq.mortgage`.
5. Apple Developer team ID, enable App Store signing, archive +
   TestFlight upload.

Nice-to-haves deferred to 5M-follow-ups or Session 7:
- Dedicated TCA analytics PDF page (break-even chart + full
  reinvestment tables + full equity matrix). Current PDF comparison
  page delivers compact per-surface summaries.
- Home-value appreciation modeling on equity buildup (5M.9 caption
  flags this as out-of-scope).
- Earnest money on TCA cash-to-close (Nick's 5M decision to omit —
  can add later if LOs request it).
