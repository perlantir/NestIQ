# Session 5R — Summary

Session 5R was a pre-TestFlight correctness + UX sweep: close the
duplicate-field UX gap on TCA refi, audit every calculator's math
against its stated convention, remove stale hard-coded values,
smoke-test edge cases across all calculators, and add the missing
Edit affordance on saved-scenario detail screens. One new
architectural decision (D11) the work surfaced.

## What shipped per sub-task

### 5R.1 — TCA refi duplicate-field prefill + hints

`currentMortgage.currentBalance` and `propertyValueToday` overlap
the form-level `loanAmount` and `homeValue` fields on TCA refi.
Previously the LO re-typed values from the mortgage card into the
form fields. Fixed by auto-prefilling on hydration when the form
field is still 0, with a dynamic "Pre-filled from current mortgage"
hint label. LOs customizing a cash-out refi or non-standard
appraisal keep their override (prefill only fires when the form
field is 0). Commit `527f6b8`.

### 5R.2 — Calculation correctness audit (3 real bugs fixed)

Swept every calculator's `scenarioInputs()` / `toLoan()` / DTI /
break-even path against its documented convention. Three
substantive bugs found and fixed:

1. **TCA double-counted points.** `TCAInputs.scenarioInputs()`
   added `pointsCost = principal × points / 100` to
   `s.closingCosts` before passing to the engine — but the 5B.5
   convention is that `closingCosts` is already all-in INCLUDING
   points. Bought-down scenarios appeared more expensive than they
   were (inflated break-even, unrecoverable costs, horizon totals).
   Fix: removed the re-add; aligns TCA with the
   `RefinanceInputs.scenarioInputs()` pattern that was always
   correct. Regression test `testScenarioInputsDoesNotDoubleChargePoints`
   pins the contract.

2. **IncomeQual DTI double-subtraction + dead code.** `maxPITI`
   already nets out `totalMonthlyDebt`, but
   `IncomeQualInputs.frontEndDTI` subtracted it a second time
   before dividing by qualifying income — understating front-end
   DTI. The screen/PDF only consumed the ViewModel's DTI
   properties, so the buggy `IncomeQualInputs.frontEndDTI` +
   `backEndDTI` were dead code but a footgun for future callers.
   Fix: removed the dead properties; simplified
   `IncomeQualViewModel.frontEndDTI` to
   `maxPITI / qualifyingIncome`; tombstone comment prevents
   re-introduction.

3. **Monthly MI never reached the amortization engine.** TCA + Refi
   both collected a `monthlyMI` field per scenario and displayed
   it in the results/PDF, but neither passed it to
   `AmortizationOptions.pmiSchedule`. `schedule.cumulativeMI(...)`
   was always 0 for those calculators, understating unrecoverable
   costs for FHA / low-down-payment scenarios by the full MI
   dollar amount. Fix: `amortizationOptionsForMI(scenario:)` on TCA
   and `miOptions(monthlyMI:loanAmount:)` on Refi build a
   `PMISchedule` with HPA 78% dropoff semantics (fallback to
   `isPermanent=true` when no appraised value). TCAInputs.swift
   extracted to a second file (`TCAInputs+Engine.swift`) to stay
   under SwiftLint's 600-line cap.

Commit `0ec501e`.

### 5R.3 — Hard-coded values sweep

Grepped every calculator for numeric literals that should derive
from inputs or LenderProfile. Three fake / stale values replaced
with real derivations. Commit `89b33af`.

### 5R.4 — Regression + edge-case smoke coverage

Added `AppTests/SmokeEdgeCasesTests.swift` — 15 test cases covering
the save/reload Codable round-trip for all five calculator
FormInputs types plus edge-case computes (0% rate, 40-year term,
high LTV, $0 closing costs) for Amortization, Refinance, TCA,
HELOC, and Income Qualification. Catches crashes, divide-by-zero,
and silent field drops that the happy-path view model tests don't
exercise. All 15 pass; joined to the existing 116-test unit bank
without regression.

### 5R.6 — Edit affordance on saved-scenario detail screens (D11)

LOs opening a saved Refinance / IncomeQual / TCA / HELOC scenario
landed on the Results screen with no path back to the Inputs
screen to modify any value. (Amortization + Self-Employment
already routed to their Inputs screens via
`ScenarioDestinationView`.) Fixed by adding:

1. An `initialInputs: <Name>FormInputs?` parameter to
   `RefinanceInputsScreen`, `TCAInputsScreen`,
   `IncomeQualInputsScreen`, and `HelocInputsScreen`. When
   provided, the view model hydrates from it instead of the
   calculator's built-in `defaultInputs`; `applyBorrowerCurrentMortgage`
   is skipped so loaded scenario values are never clobbered by
   borrower defaults.
2. A conditional "Edit" trailing toolbar button on each of the
   four Results screens. Renders only when `existingScenario !=
   nil` (i.e., the user opened the screen from Saved or Home
   recents; the fresh Inputs → Compute flow already has a
   back-chevron below). Taps push the corresponding
   `<Name>InputsScreen` with `initialInputs = viewModel.inputs`
   and `existingScenario` forwarded so Session 5K.1 smart-save
   still overwrites in-place after editing.

`RefinanceScreen` + `IncomeQualScreen` toolbars extracted to
`@ToolbarContentBuilder` extension properties (`toolbarContent`)
to stay under SwiftLint's 400-line `type_body_length` cap after
the addition.

## New decision

See DECISIONS.md:

**D11 (2026-04-20)** — Saved-scenario detail screens route to
Results-first with a conditional Edit trailing toolbar button,
rather than normalizing all six calculators to Inputs-first. Keeps
LOs' existing one-tap-to-Results flow intact while giving a
discoverable edit path for the four calculators that previously
had none. Edit is present only when `existingScenario != nil` so
fresh-flow Results screens stay uncluttered.

## Tests after 5R

- **QuotientFinance package:** 316 tests in 64 suites — still
  green. (Session 5R did not touch the finance package.)
- **Quotient app unit suite:** 131 tests across 19 test classes —
  all green. 15 new edge-case cases (5R.4) +
  `testScenarioInputsDoesNotDoubleChargePoints` (5R.2).
- **Quotient app UI suite:** 18 tests — all green. The Edit
  toolbar button carries AX identifiers
  (`refinance.edit` / `incomeQual.edit` / `tca.edit` /
  `heloc.edit`) for future UI-test wiring.

## Files modified

- `App/Features/Calculators/Refinance/RefinanceScreen.swift` —
  toolbar extension + Edit button.
- `App/Features/Calculators/Refinance/RefinanceInputsScreen.swift`
  — `initialInputs` param + skip-borrower-prefill guard.
- `App/Features/Calculators/TotalCostAnalysis/TCAScreen.swift` —
  Edit toolbar button.
- `App/Features/Calculators/TotalCostAnalysis/TCAInputsScreen.swift`
  — `initialInputs` param.
- `App/Features/Calculators/IncomeQualification/IncomeQualScreen.swift`
  — toolbar extension + Edit button.
- `App/Features/Calculators/IncomeQualification/IncomeQualInputsScreen.swift`
  — `initialInputs` param.
- `App/Features/Calculators/HelocVsRefinance/HelocScreen.swift` —
  Edit toolbar button.
- `App/Features/Calculators/HelocVsRefinance/HelocInputsScreen.swift`
  — `initialInputs` param.
- `Quotient.xcodeproj/project.pbxproj` — XcodeGen regen.

## Files added

- `AppTests/SmokeEdgeCasesTests.swift` — 15 edge-case + round-trip
  cases for 5R.4.

## Commits

```
Session 5R.1  — TCA refi duplicate-field prefill + hints (527f6b8)
Session 5R.2  — calculation audit: 3 real bugs fixed (0ec501e)
Session 5R.3  — hard-coded values sweep (89b33af)
Session 5R.4  — edge-case smoke suite + 5R.6 Edit affordance + rollup (this commit)
```

## What's next — Session 6 (TestFlight admin)

Unchanged from 5P / 5Q. 5R didn't touch 5P-deferred Session 6
items:

1. Remove DEBUG AuthGate bypass (`AuthGate.swift:84-91`) once the
   UI-test bypass path is satisfied by alternative means.
2. Info.plist usage descriptions —
   `NSPhotoLibraryUsageDescription`, `NSFaceIDUsageDescription`.
3. Wire real URLs — `https://nestiq.mortgage/privacy` / `/terms` /
   `/support` — into Settings + onboarding.
4. Wire `support@nestiq.mortgage` into Send Feedback.
5. Apple Developer team ID, enable App Store signing, archive +
   TestFlight upload.

## Deferred to v0.2

Unchanged from 5Q — no new v0.2 deferrals introduced by 5R.
