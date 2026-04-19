# Session 5E — Summary

**Scope:** five issues from Nick's round-2 QA after Session 5D — a critical save/load regression, Income Qualification purchase/refi toggle, licensed-states picker, Amortization PDF full schedule pages, and TCA refinance-mode aggregate-debts consolidation.

**Deferred, by design:** Spanish localization (still its own pre-TestFlight session). Onboarding-flow nudge for empty licensed states (spec calls it out as future). No other deferrals; every listed issue shipped.

---

## Commits (5E.1 → 5E.5)

| SHA | Task | Scope |
|---|---|---|
| `23d155b` | 5E.1 | Scenario save/load regression fixed + 5 round-trip UI tests |
| `e00f41e` | 5E.2 | Income Qualification Purchase/Refinance toggle |
| `68301ef` | 5E.3 | Licensed states picker — grouped (Full / Fallback) + badged |
| `1baca36` | 5E.4 | Amortization PDF full schedule pages + MI dropoff marker |
| `2ed4451` | 5E.5 | TCA refinance mode — aggregate OtherDebts + savings display |

---

## 5E.1 — Scenario save/load bug, root cause

**Symptom:** every user-visible "Save" across all 5 calculators produced nothing in the Saved tab. The LO workflow was fully broken.

**Two compounding root causes:**

1. **`CalculatorDock` layout pathology (the observable bug).** The Share button carried `.layoutPriority(1)` in an HStack where all three buttons' labels used `.frame(maxWidth: .infinity)`. SwiftUI gave Share its ideal width first, which effectively consumed the full HStack — collapsing Narrate and Save to near-zero pt. The buttons remained in the AX tree (their identifiers and labels resolved cleanly), so `XCUIElement.tap()` happily reported a successful tap — but the visible / tappable region belonged to Share. A user's finger tap on "Save" actually hit the Share button, which presents the PDF share sheet; they dismiss it thinking nothing happened. Fix: remove `.layoutPriority(1)`. An inline comment warns future authors not to re-add it.

2. **CoreData materialization error on `LenderProfile.licensedStates: [String]` (the latent bug).** On container init, SwiftData logged `Could not materialize Objective-C class named "Array" from declared attribute value type "Array<String>"`. The container still constructed, but in a degraded state that made every subsequent `try modelContext.save()` vulnerable. 4 of 5 calculator Results screens used `try?`, so even if the layout bug hadn't blocked the tap, the save would have failed silently. Fix: store as `licensedStatesCSV: String` (comma-joined, uppercased, deduped). `licensedStates: [String]` becomes a computed property on the model — every existing read/write site keeps its API.

**UI test coverage added:** `ScenarioSaveLoadTests.swift` — one round-trip test per calculator (Amort, IncomeQual, Refi, TCA, HELOC). Each opens the calculator, computes, saves, switches to the Scenarios tab, and asserts the saved row exists. 5 new tests, all green. These would have caught the regression at Session 5A had they existed.

---

## 5E.2 — Income Qualification Purchase/Refinance toggle

- `IncomeQualMode` enum (`.purchase` default) on `IncomeQualFormInputs`. Refinance-mode fields: `currentHomeValue`, `currentLoanBalance`, `refiMonthlyMI`. Codable is backward-compatible via `decodeIfPresent` — saved scenarios without the mode key decode as `.purchase`.
- Inputs screen: segmented toggle below the borrower chip. Purchase mode keeps `PropertyDownPaymentSection` as-is; refinance mode swaps to a "Current loan & property" section with home value, current balance, MI, and a live current-LTV readout.
- Results screen (`IncomeQualScreen`): refinance mode adds a Qualified / Short status line comparing current balance to max qualifying loan, and swaps the "Max purchase" KPI for "Current LTV". Purchase mode untouched.
- PDF: mode-aware title (`Income qualification · refinance`), summary (`Refi · rate%`), secondary KPI (Current LTV vs Max purchase), and narrative (Qualifies at / vs / Short by).
- Shared Inputs helpers moved to an extension to stay under SwiftLint's type_body_length.

---

## 5E.3 — Licensed states picker

`LicensedStatesPicker` rewritten with two sections:

- **Full disclosure** — the 11 jurisdictions whose Disclosure carries `DisclosureProvenance.stateSpecific` (CA, TX, FL, NY, IL, PA, OH, GA, NC, MI, IA).
- **Fallback** — the remaining 40 + DC, rendering the generic fallback text.

Each row shows the USPS abbreviation in monospaced caps, state name, a "Full text available" / "Generic disclaimer" badge, and a selection checkmark. `searchable` filters both sections by name or abbreviation.

Wiring unchanged — Done commits `profile.licensedStates` via the existing path. Combined with 5E.1's CSV storage fix, selections now persist across launches, and `PerStateDisclosuresPreview` renders the one-card-per-state list it was designed for.

AuthGate DEBUG bypass stays at `["IA"]`. Sign in with Apple still starts with an empty list; the onboarding nudge in Nick's spec lives in a future session.

---

## 5E.4 — Amortization PDF full schedule pages

- New `App/Features/Share/AmortizationSchedulePages.swift`:
  - `AmortizationYearlyPage` — landscape 792×612, one table with year / calendar-range / total paid / principal / interest / year-end balance columns. Fits a full 30-year term on one page.
  - `AmortizationMonthlyPage` — same orientation, denser table (~30 rows per page), with running header + "Schedule · page N of M" footer.
  - `AmortizationSchedulePages.monthlyChunks(_:)` helper slices flat payments into page-sized groups.
- MI dropoff row highlight: green-tinted background + accent-colored leading rule on the row where `AmortizationViewModel.miDropoffPeriod` matches the payment number. Only in purchase mode (existing-loan mode has no purchase-price anchor).
- Granularity state lifted from `AmortizationScheduleView` up to `AmortizationResultsScreen` so the PDF can read it. Enum promoted to file-level `AmortScheduleGranularity` with a `default(termYears:)` helper that preserves the ≤15yr-monthly / >15yr-yearly UX default.
- `PDFBuilder.buildAmortizationPDF` takes a `scheduleGranularity` parameter (defaults to `.yearly` for external callers). Schedule-page composition lives in `PDFBuilder+ComparisonPages.swift` to keep the main enum under SwiftLint's type_body_length cap.
- Page order: cover (portrait) → schedule page(s) (landscape) → disclaimers (portrait). Uses `renderMixed` from Session 5B.4.b.
- Scope: Amortization only per spec; Refi / Income / TCA / HELOC PDFs stay unchanged.

---

## 5E.5 — TCA refinance mode: aggregate other-debts

- New QuotientFinance primitive `OtherDebts { totalBalance, monthlyPayment }`. Aggregate only; itemization is out of v1 scope. Ships with `OtherDebts.zero()` + `isZero` check.
- `TCAFormInputs` picks up `currentOtherDebts: OtherDebts?` (today's debts); `TCAScenario` picks up `otherDebts: OtherDebts?` (remaining after this scenario's cash-out consolidates some/all). Both Codable-optional.
- `TCAInputsScreen` (refinance mode): new "Other debts · today" section at the bottom of Scenarios. Each scenario card adds "Debts remaining · balance" + "Debts remaining · monthly" rows. Purchase mode hides all debt fields. Helpers extracted to `TCAInputsScreen+DebtsAndLTV.swift` to stay under SwiftLint's file_length + type_body_length caps.
- `TCAScreen` scenario spec grid + `TCAComparisonPage` PDF grid: when refinance-mode debts are set, each scenario surfaces "Mo total" (PITI + debts.monthlyPayment) + a signed savings line ("Saves $X/mo vs current" in gain color, or "Costs $X/mo more" in loss color). Baseline uses scenario A's PITI + current debts, since TCA doesn't carry a distinct "current" PITI.
- **Engine untouched.** `compareScenarios` + `scenarioInputs()` keep their current contract. The monthly-payment-impact math is display-only in the view layer — no projection of OtherDebts into the engine run. A property test locks the invariant: `nil` debts → pre-5E.5 behavior; set debts → delta exactly equals `debts.monthlyPayment`.

---

## Tests + coverage

| Target | Before 5E | After 5E | Delta |
|---|---|---|---|
| QuotientFinance | 251 | 256 | **+5** (OtherDebtsTests) |
| QuotientCompliance | 40 | 40 | — |
| QuotientNarration | 6 | 6 | — |
| QuotientPDF | 2 | 2 | — |
| QuotientTests (app unit) | 26 | 26 | — |
| QuotientUITests (app UI) | 6 | 11 | **+5** (ScenarioSaveLoadTests) |
| **Total** | **331** | **341** | **+10** |

All green. `ScenarioSaveLoadTests` validated both the 5E.1 root causes — it fails reliably against the pre-fix build and passes against the post-fix build. `OtherDebtsTests` locks the Codable round-trip + zero-vs-set behavior that the TCA UI depends on.

---

## Decisions added to DECISIONS.md

1. **LenderProfile.licensedStates storage (5E.1).** CSV-backed `licensedStatesCSV: String` + computed `[String]` accessor. SwiftData/iOS 18 doesn't materialize `[String]` generics cleanly; storing as a scalar sidesteps the bridge.
2. **CalculatorDock layout (5E.1).** Removed `.layoutPriority(1)` on Share. Added an in-line warning comment explaining the squashing pitfall.
3. **Round-trip UI tests (5E.1).** Per-calculator SwiftUI-level save/reopen tests as the smallest reliable regression fence around the dock + @Query wiring.
4. **Income Qualification mode (5E.2).** Purchase default; refinance adds a qualifying-against-current-balance path.
5. **LicensedStatesPicker grouping (5E.3).** Two sections — Full / Fallback — driven by Disclosure provenance; each row badged.
6. **Amortization PDF schedule pages (5E.4).** Yearly = one landscape page; monthly = paginated 30-per-page; MI dropoff marker on purchase mode only. Granularity lifted to Results @State so the PDF respects the user's toggle.
7. **Other debts primitive (5E.5).** Aggregate-only in QuotientFinance. TCA refi-mode view-layer math only (engine untouched). Itemization out of v1 scope.

---

## Nick-blockers still open

Unchanged from Session 5D — four TestFlight-gate placeholders (`support@quotient.app`, three `quotient.app/*-placeholder` URLs) + Apple Developer enrollment, compliance counsel review, and the native Spanish reviewer.

---

## Explicitly deferred

- **Full Spanish localization (app + PDF).** Still its own session.
- **Onboarding nudge for empty licensed states.** Mentioned in 5E.3 spec as a future addition.
- **Full-schedule PDFs for Refi / Income / TCA / HELOC.** Per 5E.4 scope — Amortization only.
- **Itemized other-debts entry** (card A + auto + student). TCA stays aggregate-only.
- **OtherDebts projection into `compareScenarios`** — currently display-only in the view layer. The engine contract didn't need to change to deliver the feature.
- **Density multiplier, FHA MIP matrix, live rate endpoint, iCloud Documents export, Component Gallery dev menu, iPad landscape, empty/error/loading states, Accessibility5, VoiceOver audit** — where Sessions 5A–D left them.

---

## Final status

- Branch clean at write time. 341 tests green across every package + app unit + UI.
- CLI build (Quotient scheme, iPhone 16 simulator) → `BUILD SUCCEEDED`.
- All five Nick round-2 issues addressed:
  1. Save/load regression → 5E.1 (layout + SwiftData fix, 5 round-trip tests)
  2. Income Qualification Purchase/Refinance toggle → 5E.2
  3. Licensed states picker + Per-state disclosures wiring → 5E.3
  4. Amortization PDF full schedule pages → 5E.4
  5. TCA debts consolidation → 5E.5
- No stop conditions triggered: ModelContainer fix was surgical (no architectural refactor), no design-token edits, no `compareScenarios` changes, no Session 1–5D test regressions.
- Ready for Nick round-3 QA.
