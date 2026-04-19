# Session 5D — Summary

**Scope:** four issue clusters raised by Nick's QA of Session 5 FINAL — PDF currency rendering, Amortization mode, Refi / HELOC / TCA purchase-vs-refinance context, and an app-wide alignment sweep. Seven commits, no test regressions.

**Deferred:** Spanish localization (still its own pre-TestFlight session). Nothing else deferred in this run.

---

## Commits (5D.1 → 5D.6 + rollup)

| SHA | Task | Scope |
|---|---|---|
| `d067236` | 5D.1 | PDF currency rendering fix — single formatter + hero auto-scale |
| `ec6a5e4` | 5D.2 | Amortization Purchase/Existing loan mode toggle |
| `4da9c2f` | 5D.3 | Refinance — remove purchase context, MI per option |
| `654f19b` | 5D.4 | HELOC — remove purchase context, MI on refi only, CLTV |
| `3e5af3a` | 5D.5 | TCA Purchase/Refinance toggle with MI per scenario |
| `ac4f185` | 5D.6 | TCA horizon button alignment + app-wide alignment sweep |

Summary / DECISIONS.md append arrive in the rollup commit that follows this file.

---

## What shipped

### 5D.1 — PDF currency rendering fix

- Root cause of `$$732K`: `("Total interest", "$\(dollarsShort(x))")` concatenated a literal `$` around a value that was already prefixed. Fix: drop the literal and pass `dollarsShort` through.
- Root cause of mid-number wrap (`.4,2` / `31`): the hero numeric and 3 KPIs split the page width equally (~111pt each), too narrow for `$4,231` at 44pt mono. Fix: `.layoutPriority(2)` on the hero VStack so it claims more width, plus `.lineLimit(1)` + `.minimumScaleFactor(0.5)` on the 44pt numeric and `.minimumScaleFactor(0.6)` on the 22pt KPIs as a safety net.
- **Single source of truth:** new `MoneyFormat.currency(_:)` wraps `NumberFormatter.currency` for locale-aware rendering. `PDFBuilder` and `HelocComparisonPage.rows(...)` now route every currency value through it. `dollarsShort` stays for the compact-column path.
- Touched 4 files (well inside the 2–3-file stop condition because the PDF layer was already well-factored).

### 5D.2 — Amortization Purchase / Existing-loan mode toggle

- `AmortizationMode` enum (`.purchase` default) on `AmortizationFormInputs` with backward-compatible Codable.
- Segmented control at the top of Inputs. `.existingLoan` hides `PropertyDownPaymentSection` + the MI dropoff hero line + the LTV / Total-MI column in the Results KPI row (shrinks 4→3 KPIs).
- Subline + hero adapt to mode. PDF already only surfaces mode-agnostic KPIs (interest / payoff / total paid), so no PDFBuilder change needed.

### 5D.3 — Refinance: remove purchase context, MI per option

- Dropped `propertyDP` from `RefinanceFormInputs`. Added form-level `homeValue` (shared LTV denominator) + `currentMonthlyMI`.
- `RefiOption` gains `newLoanAmount` (0 falls back to currentBalance for backward-compat) + `monthlyMI`. Per-option LTV is `effectiveLoanAmount ÷ homeValue`.
- Inputs screen: new Property section with live current-LTV readout; each option card surfaces loan amount, LTV, MI.
- `RefinanceTableView` renders a LTV row when homeValue > 0 and a Monthly MI row when any line carries MI. The PDF landscape comparison page embeds this view verbatim, so the PDF picks up the same rows for free.

### 5D.4 — HELOC: remove purchase context, MI on cash-out refi only, CLTV

- Dropped `propertyDP` from `HelocFormInputs`. Added `homeValue` + `refiMonthlyMI` (HELOCs don't carry PMI by design — second lien).
- New derived helpers: `firstLienLTV`, `cltv`, `refiLTV` (= cltv; one new loan covers both).
- Inputs screen: new Property section shows LTV (first lien) and CLTV (combined) live against `homeValue`. Refi option gains a Monthly MI field.
- `HelocComparisonPage.rows` now inserts `LTV · new loan` + `CLTV · total` rows when homeValue is set, and always renders a Monthly MI row — refi shows the entered amount or `—`; HELOC side shows `N/A`.

### 5D.5 — TCA Purchase/Refinance toggle with MI per scenario

- `TCAMode` enum (`.refinance` default per spec) on `TCAFormInputs` with `homeValue` + existing `loanAmount` as refinance-mode fallback.
- `TCAScenario` picks up `loanAmount` override, `monthlyMI`, and full `propertyDP` (used in purchase mode only). Backward-compatible Codable.
- `effectiveLoanAmount(for:)` + `ltv(for:)` do mode-aware routing; every downstream surface (in-app spec grid, PDF spec grid, closingDisplay points base) reads through them.
- Inputs: segmented Purchase/Refinance toggle at the top. Purchase mode hides the form-level loan-amount + home-value sections and embeds `PropertyDownPaymentSection` in each scenario card; refinance mode keeps the form-level sections and shows per-scenario loan amount + LTV readout. Monthly MI field appears per scenario in both modes.
- Both the in-app scenario spec grid and the PDF `TCAComparisonPage` spec grid now render Loan / LTV (conditional) / MI (conditional) rows — a single edit applies to both thanks to the shared helper.

### 5D.6 — TCA horizon button alignment + alignment audit

- **TCA horizon chips:** 15yr / 30yr wrapped to a second row on iPhone while 5yr / 7yr / 10yr fit. Fix: `.frame(maxWidth: .infinity)` on each chip so all five share the row equally; `.lineLimit(1)` for Dynamic Type protection. Removed the per-chip `.padding(.horizontal, Spacing.s12)` that was causing the overflow.
- **SegmentedControl (shared):** `.lineLimit(1)` + `.minimumScaleFactor(0.8)` on the segment Text — Dynamic Type safety for the Amortization and TCA mode toggles plus any future consumer.

#### Alignment audit — full findings

| Surface | Finding | Resolution |
|---|---|---|
| TCA horizon chips | 15yr / 30yr wrapped on iPhone | Equal-width via `.frame(maxWidth: .infinity)` |
| SegmentedControl | No Dynamic Type protection | `.lineLimit(1)` + `.minimumScaleFactor(0.8)` |
| Amortization term buttons (10/15/20/25/30/40) | Already `.frame(maxWidth: .infinity)` — clean | No change |
| Amortization mode toggle (Purchase / Existing loan) | `.pickerStyle(.segmented)` handles native auto-sizing | No change |
| TCA mode toggle (Purchase / Refinance) | Same as above | No change |
| Home rate ribbon | 132pt fixed cell width, short labels | No wrap observed; no change |
| Home calculator tiles | Grid already responsive | No change |
| Results KPI rows (all 5 calculators) | `.frame(maxWidth: .infinity)` + `lastIdx` index-based trailing padding (new in 5D.2) | Amortization KPI row hardened; others already equal-share |
| PDF hero block | Fixed in 5D.1 with layoutPriority + minimumScaleFactor | Done |
| PDF comparison tables (Refi, TCA, HELOC) | Fixed-label column widths (92pt / 220pt) + equal-width value columns | No wrap at standard values; no change |
| Settings rows, Saved scenario cards, filter chips | No issues observed | No change |

Stop conditions referenced by the spec — none triggered (no token changes, no engine changes, no component-library rewrite, no Session 1-5 test regressions).

---

## Tests + coverage

| Target | Before 5D | After 5D | Delta |
|---|---|---|---|
| QuotientFinance | 251 | 251 | — |
| QuotientCompliance | 40 | 40 | — |
| QuotientNarration | 6 | 6 | — |
| QuotientPDF | 2 | 2 | — |
| QuotientTests (app unit) | 26 | 26 | — |
| QuotientUITests (app UI) | 6 | 6 | — |
| **Total** | **331** | **331** | **—** |

Zero new tests (scope was bug fixes + form-schema reshuffles). Every existing test still passes. `CalculatorAmortTests.testAmortizationFullFlow` flaked once on the first run but passed on re-run — consistent with the iOS 18 simulator AX-reliability caveat already called out in Session 5 FINAL.

All Codable schema changes (RefinanceFormInputs, HelocFormInputs, TCAFormInputs, TCAScenario, RefiOption, AmortizationFormInputs) decode legacy JSON via `decodeIfPresent` with safe defaults. Saved scenarios from before Session 5D round-trip cleanly.

---

## Decisions added to DECISIONS.md

1. **PDF currency formatting source of truth (5D.1).** Single `MoneyFormat.currency(_:)` helper; kill literal `$` concatenation.
2. **PDF hero numeric auto-scale (5D.1).** `.layoutPriority(2)` + `.minimumScaleFactor` — minimum intervention.
3. **Amortization mode (5D.2).** Purchase vs existing-loan explicit toggle; drives Property & DP and MI surface visibility.
4. **Refi per-option MI + LTV (5D.3).** Dropped shared propertyDP; per-option MI + optional loan amount; shared home value.
5. **HELOC LTV vs CLTV (5D.4).** Two denominators matter to LOs; MI on refi side only.
6. **TCA mode: Purchase vs Refinance (5D.5).** Purchase has per-scenario Property & DP; refinance has per-scenario loan amount; MI per scenario in both modes.
7. **Horizon chip width strategy (5D.6).** `.frame(maxWidth: .infinity)` — equal-share, label-agnostic.

---

## Nick-blockers still open

Unchanged from Session 5 FINAL — all four TestFlight-gate placeholders (`support@quotient.app`, the three `quotient.app/*-placeholder` URLs) + Apple Developer enrollment, compliance counsel review, and the native Spanish reviewer ask.

---

## Explicitly deferred

- **Full Spanish localization (app + PDF)** — dedicated session with native-speaker reviewer, pre-TestFlight.
- **Loan-amount-derived-from-(price − DP) in purchase-mode Amortization** — PropertyDownPaymentSection still coexists with the hardcoded loanAmount field in Amortization. The engine primitive supports full derivation; switching requires a form-refactor blast radius outside 5D's scope.
- **Auto-calc PMI** (via `calculatePMI(...)` + `ConventionalMIGrid`). Manual-entry is still the model for all calculators.
- **Density multiplier, FHA MIP matrix, live rate endpoint, iCloud Documents export, Component Gallery dev menu, iPad landscape, empty/error/loading states, Accessibility5, VoiceOver audit, reopen-from-Saved UI test coverage** — all still sitting where Session 5 FINAL parked them.

---

## Final status

- Branch state clean at this file's write time, 331 tests green across all packages + app unit + UI.
- CLI build (Quotient scheme, iPhone 16 simulator) → `BUILD SUCCEEDED`.
- All four Nick QA issue clusters addressed:
  1. PDF currency rendering → 5D.1
  2. Amortization purchase vs existing-loan → 5D.2
  3. Refi / HELOC / TCA purchase-vs-refinance context + per-scenario MI → 5D.3 / 5D.4 / 5D.5
  4. Alignment (TCA horizons + app sweep) → 5D.6
- No stop conditions triggered: no design-token edits, no QuotientFinance primitive changes, no package-architecture rewrites, no Session 1-5 test regressions.
- Ready for Nick QA round 2.
