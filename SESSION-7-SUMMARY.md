# Session 7 Summary — v0.1.1 PDF Editorial Migration

**Date**: 2026-04-21
**Scope**: Migrate iOS app from bespoke HTML builders to designer-supplied v2.1.1 Mustache templates. Retire Core Graphics PDF chrome (D12). Ship haptics + sound toggles. Remove non-compliant PDF exports.

## What shipped

### PDF rendering pipeline (D12)

All four LO-facing calculators now render their PDFs by loading a template from the app bundle, filling a token dictionary via `HTMLPDFRenderer.shared.interpolate`, and appending an inline compliance trailer. The legacy Core Graphics chrome (NestIQPrintRenderer — masthead + page footer) is retired. Templates carry their own masthead, pagefoot, and counters.

| Template | Tokens | Sentinels |
|----------|--------|-----------|
| `pdf-amortization-with-masthead.html` | 17 scalars (PITI dollars/cents, rate, LTV, payoff date, etc.) | `<!--{{schedule_page_1_rows}}-->`, `<!--{{schedule_page_2_rows}}-->` |
| `pdf-refinance-with-masthead.html` | 49 tokens (3 option columns × break-even/rate/lifetime/NPV rows) | `<!--{{narrative_body}}-->` (AI narrative) |
| `pdf-heloc-with-masthead.html` | ~60 scalars + 5-row stress matrix | none |
| `pdf-tca-with-masthead.html` | 12 scalars | `<!--{{matrix_rows}}-->`, page 4 sentinels (`interest_split_header`, `interest_split_rows`, `unrecoverable_rows`, `reinvestment_section`) |

### Data model extensions (7.3b–7.3d)

Each FormInputs struct gained the v0.1.1 fields that the templates require but the previous schema didn't carry — all with `decodeIfPresent` + defaults so pre-7.3 Saved Scenarios JSON still decodes:

- **HELOC** (+11): first-mortgage origination/amount, HELOC closing costs, lifetime cap, index type + margin, draw/repay period, cash-out refi closing costs + rate + term.
- **Refi** (+3 form, +3 option): current loan original amount + term + origination date; per-option lender name + lender fees + third-party fees.
- **Amortization** (+2): rate lock descriptor, combined monthly income.

### ViewModel derivations (7.3b–7.3d)

New `+PDFDerivations.swift` files deliver computed properties that the 7.3f builders pull from:

- `HelocViewModel`: `tenYearCumulativeInterestHELOC/Refi`, `tenYearPrincipalPaydownHELOC/Refi`, `tenYearNetCostDelta`, `breakEvenMonthsHELOCvsRefi`, `stressPathMatrix` (5 rows).
- `RefinanceViewModel`: `currentMonthlyPI`, per-option `metrics`, `paymentDelta`, `paymentDeltaPct`, `interestOverTerm`, `discountPointsAmount`, `lifetimeSavings`, `breakEvenMonth`.
- `AmortizationViewModel`: `pitiDollarsPart`, `pitiCentsPart`, `firstPaymentDate`, `productBadge`, `pmiNote`, `year10Balance`, `extraPaydownMonthsSaved`, `extraPaydownInterestSaved`, `quarterPointSavingsMonthly/Lifetime`.
- `TCAViewModel` (via `TCAPDFHTML+V2Derivations`): `longestHorizonYears`, `ongoingHousingFormatted`, `reinvestmentRateFormatted`, plus page-4 sentinel emitters.

### Signature + call-site cleanup (7.3f)

`PDFBuilder.swift`:
- `buildAmortizationPDF`, `buildHelocPDF`, `buildTCAPDF` — dropped `narrative: String` param; templates don't carry a narrative slot.
- `buildRefinancePDF` — keeps `narrative: String`; injected at `<!--{{narrative_body}}-->`.
- All builders now pass `baseURL: try PDFTemplateLoader.templatesFolderURL` so `<link rel="stylesheet" href="tokens.css">` resolves.

Call sites updated: `AmortizationResultsScreen`, `HelocScreen`, `TCAScreen+Actions`.

### Orphan deletions (7.4)

Removed per Reg B / ECOA compliance:
- `IncomeQualPDFHTML.swift`
- `SelfEmploymentPDFHTML.swift`
- `PDFBuilder+SelfEmployment.swift`
- `PDFBuilder.buildIncomeQualPDF`
- `IncomeQualPDFHTMLTests.swift`
- `SelfEmploymentPDFHTMLTests.swift`
- `TCAPDFHTML+HorizonDetails.swift` (static-HTML sections replaced by sentinels)
- `TCAPDFHTML+CurrentMortgage.swift` (status-quo anchor now a sentinel row)

`CalculatorIncomeTests.testIncomeQualFullFlow` rewritten to assert `dock.share` is absent (pins the compliance decision).

### Haptic + sound wiring (7.5, 7.6)

New `App/Components/HapticFeedback.swift` exposes two gated helpers:
- `HapticFeedback.fireOnCompute(profile:)` — `UIImpactFeedbackGenerator(.medium)` when `profile.hapticsEnabled`.
- `SoundFeedback.fireOnShare(profile:)` — `AudioServicesPlaySystemSound(1008)` when `profile.soundsEnabled`.

Wired at 4 Compute sites (AmortizationInputsScreen, HelocInputsScreen, RefinanceInputsScreen, TCAInputsScreen) and 4 Share sites (AmortizationResultsScreen, HelocScreen, RefinanceScreen, TCAScreen+Actions).

## Tests

- **Unit suite**: 196 tests, 0 failures (full run at session end).
- New or updated:
  - `HelocPDFDerivationsTests` (10 tests) — stress matrix + 10-yr cost metrics.
  - `RefinancePDFDerivationsTests` (10 tests) — per-option metrics + current P&I.
  - `AmortizationPDFDerivationsTests` (11 tests) — PITI split, year-10 balance, extra-principal derivations.
  - `TCAPDFV2DerivationsTests` (10 tests) — page-4 sentinel emitters.
  - `HelocPDFHTMLTests`, `RefinancePDFHTMLTests`, `TCAPDFHTMLTests` — assertions rewritten for v2.1.1 class names + compliance trailer EHO footer.
- Removed:
  - `IncomeQualPDFHTMLTests`, `SelfEmploymentPDFHTMLTests` (orphan PDF surfaces).
  - `PDFBuilderTests.testPhoto*` (v2.1.1 templates don't include the LO photo; restoration pending v2.2).

The previously-flaky `FREDRateServiceTests.testFetchSnapshotReturnsCachedValueWhenFresh` passed in the final regression run.

## Version bump

- `CFBundleShortVersionString`: `0.1.0` → `0.1.1`
- `CFBundleVersion`: `2` → `3`

Updated in both `project.yml` and `App/Info.plist`.

## Decisions captured

- **D12** — CG chrome retired; PDF chrome lives in templates. Compliance page appended as a trailing `<article class="page">` via `PDFTemplateLoader.complianceTrailerPage`.
- **Template folder flattening** — XcodeGen's `type: folder` created a `PBXGroup` (not a folder reference), so the bundled PDFTemplates directory flattens into the app root. `PDFTemplateLoader.load` rewrites `href="../tokens.css"` → `href="tokens.css"` at load time to compensate.
- **No LO photo in v2.1.1 PDFs** — templates don't include it. Tracked in V0.1.2-BACKLOG for v2.2.
- **IncomeQual / SelfEmployment have no PDF** — permanent; Reg B / ECOA.

## Remaining work (tracked elsewhere)

- V0.1.2-BACKLOG items unchanged from mid-session: AI narrative for Amort/HELOC/TCA templates, LO photo slot (v2.2), break-even SVG programmatic path, savings-by-holding-period grid.
- TCA template page 4 iOS-local divergence — to be synced upstream when Claude Design ships v2.2.

## What's next

Session 8 can focus on non-PDF v0.1.1 polish / TestFlight prep. All Session 7 objectives (7.1 through 7.7) shipped and pushed.
