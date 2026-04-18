# Session 3 — Summary

**Goal:** App shell (AuthGate → Onboarding → RootTabBar), Home + Saved + Settings + Borrower Picker screens, and the Amortization flagship (Inputs + Results) with save/load.
**Result:** All Session 3 sub-session commits landed; 11 new unit tests + 1 UI test green; all Session 1+2 tests still pass (279 + 12 = 291 total).

---

## What shipped

Five layered commits — one per sub-session — plus this summary.

| SHA | Layer | Scope |
|---|---|---|
| `9f05756` | 3.1 · App shell + auth + onboarding | AuthGate + Sign in with Apple + Face ID + SwiftData models + 6-step tour + miniatures + RootTabBar |
| `530c727` | 3.2 · Home + rate snapshot + Saved | HomeScreen per Home.jsx, MockRateService stub, SavedScenariosScreen per Saved.jsx with swipe actions |
| `29cc11f` | 3.3 · Settings + borrower picker | 10-section settings with segmented controls + toggles, CNContactPickerViewController bridge, DEBUG gallery relocation |
| `27cdcfc` | 3.4 · Amortization flagship | Inputs form + Results screen + @Observable view model + save/load/edit through Scenario |
| `…` (this commit) | 3.5 · Tests + summary | Unit tests (SwiftData CRUD + view model), UI test, SESSION-3-SUMMARY.md |

---

### 1. App shell + auth + onboarding (Layer 3.1 — `9f05756`)

- **SwiftData**: `LenderProfile`, `Borrower`, `Scenario` models per DEVELOPMENT.md § Data model. Each exposes the fields the spec requires plus helper enums (`CalculatorType`, `BorrowerSource`, `AppearancePreference`, `DensityPreference`). `QuotientSchema` builds the container; `QuotientApp` installs it in `.modelContainer`.
- **AuthGate**: three-state gate driven by `@Query LenderProfile`. No profile → Sign in with Apple screen (AuthenticationServices) creating a `LenderProfile`. Profile + `faceIDEnabled` + not unlocked → LocalAuthentication biometric prompt. Otherwise pass-through to content.
- **RootView** composes `AuthGate` → `OnboardingFlow` (when `!hasCompletedOnboarding`) → `RootTabBar`. Reads `profile.appearance` and applies `.preferredColorScheme`.
- **RootTabBar** — 3 tabs per Home.jsx (Calculators / Scenarios / Settings).
- **Onboarding 6-step tour** per screens/Onboarding.jsx: progress dots, Skip affordance, step eyebrow + Source Serif 4 32pt title + 14.5pt paragraph + in-situ miniature + N/6 mono counter + Continue/Get-started primary CTA. Miniatures rendered natively: welcome wordmark with serif Q, amortization PITI + balance curve (Path-based Shape), income-qual dual DTI dials, refinance break-even marker with dashed zero-line, TCA row-winner table, HELOC blended-rate composition bar.

### 2. Home + rate snapshot + Saved (Layer 3.2 — `530c727`)

- **MockRateService** returning FRED-ish April-2026 values: 30-yr 6.850, 15-yr 6.120, 5/6 ARM 6.450, FHA30 6.520, VA30 6.280, Jumbo30 7.050 with small signed deltas. `RateService` protocol for Session 5 swap. **Open item:** real Vercel-edge / Cloudflare-workers proxy wiring is Session 5.
- **HomeScreen** per screens/Home.jsx: greeting block (date eyebrow + `display@28/bold` multi-line greeting + 34px avatar circle), horizontal-scroll rate ribbon (product label + 19pt mono rate + move-colored delta chip), numbered 01-05 calculators list (tap → `CalculatorNewScenarioView`), recent scenarios section (top-3 of `@Query Scenario`, non-archived, sorted `updatedAt` desc). Pull-to-refresh fetches the rate snapshot.
- **SavedScenariosScreen** per screens/Saved.jsx: search field + 6 filter chips (All/Amort/Income/Refi/TCA/HELOC), Today/This week/Earlier groupings (per spec — not JSX month buckets, DEVELOPMENT.md wins), `.swipeActions` for Archive / Duplicate / Delete. Tap opens the scenario back in its inputs screen with `initialInputs` decoded and `existingScenario` threaded so Save updates in place.

### 3. Settings + Borrower Picker (Layer 3.3 — `29cc11f`)

- **SettingsScreen** per screens/Settings.jsx: 10 logical sections grouped into 6 visual headers per the JSX (Profile hero / Brand · PDF export / Disclaimers · compliance / Appearance / Language · haptics / Privacy · data / Support · about). Face ID toggle defaults **off** per Session 3 instruction (override the JSX-on state). `Picker(.segmented)` for Theme (Light/Dark/Auto) and Density (Comfortable/Compact). Haptics and sounds toggles wired. Language toggle (EN ⇄ ES). Erase-local-data clears Scenarios + Borrowers, keeps the LenderProfile.
- **ProfileEditor** sheet with name / NMLS / licensed-states (tokenized text field) / company / phone / email. Uses `@Bindable` for direct two-way binding into the LenderProfile.
- **ComponentGallery** relocated from the `#if DEBUG` TabView to `Settings → Support · about → Component gallery` per DECISIONS.md 2026-04-17 Session 2.4.
- **BorrowerPicker** per screens/BorrowerPicker.jsx: bottom sheet (NavigationStack + large detent + Cancel/New toolbar) with Recents / Contacts / New segmented tabs. Contacts tab invokes `CNContactPickerViewController` via `UIViewControllerRepresentable` bridge (`ContactPickerSheet`) and constructs a `Borrower(source: .contacts, contactIdentifier: …)`. New tab uses an inline `Form` to create borrowers directly. Recents queries all Borrowers sorted by `updatedAt` and filters against the live search string.
- "Replay onboarding tour" surfaces under Support · about, triggers a `confirmationDialog`, flips `profile.hasCompletedOnboarding` to false which kicks the user back into the OnboardingFlow on next render.

### 4. Amortization flagship (Layer 3.4 — `27cdcfc`)

- **AmortizationFormInputs** — Codable struct persisted as `Scenario.inputsJSON`. Seeds from the spec sample ($548K · 30-yr · 6.750% / $6500 tax / $1620 ins).
- **AmortizationViewModel** (`@MainActor @Observable`): wraps the finance engine. `compute()` runs `amortize(loan:options:)`; `hasComputed` flag lets the results view re-compute on any input edit. Yearly balance sampling for the chart, monthly PI/tax/ins/PMI/HOA split, LTV, Codable `ScenarioSnapshot` for persistence.
- **AmortizationInputsScreen** per screens/Inputs.jsx: Loan section (amount $ / rate % / 6-segment term / start date), Property section (annual taxes / insurance / monthly HOA / PMI toggle with hint), Advanced `DisclosureGroup` (extra principal monthly + biweekly toggle), Compute CTA. Borrower chip taps open the BorrowerPicker sheet.
- **AmortizationResultsScreen** per screens/Amortization.jsx: borrower block with GEN-QM badge + mono terms line, hero PITI (`$` prefix + 46pt mono tnum + `.00` suffix), 4-col KPI row with hairline dividers (Total interest / Payoff / Total paid / LTV), Balance over time chart via Swift Charts (`LineMark` + `AreaMark` + year-10 `PointMark` + `RuleMark`), PITI breakdown as stacked `Rectangle` bar + 2-col legend with %-of-total, 8-row sampled schedule table (months 1/12/60/120/180/240/300/end), bottom action dock (Narrate / Save / Share as PDF).
- **Save/load/edit** — `saveScenario()` either updates `existingScenario` in place (from Saved open) or inserts a new one; live-update behavior kicks in via `onChange(of: viewModel.inputs)` in the results screen, so once the user has Computed once, every subsequent edit re-runs the engine and re-renders every derived display.
- **Structural decomposition** — AmortizationBreakdownView and AmortizationScheduleView extracted to separate files to keep the results screen under SwiftLint's 400-line type-body limit and to make each piece independently previewable.

### 5. Tests + summary (Layer 3.5 — this commit)

- **Unit tests** (`AppTests/`, `QuotientTests` target):
  - `SwiftDataModelTests` — 6 tests: profile insert+fetch, profile appearance/density round-trip, borrower↔scenario relationship, archive flag toggle, cascade-delete on borrower, AmortizationFormInputs Codable round-trip.
  - `AmortizationViewModelTests` — 5 tests: compute() populates schedule (360 payments), monthly PITI components sum correctly, yearly balances monotonically non-increasing ending at 0, snapshot serializes inputs+outputs+keyStat, input-edit recompute changes the PI.
- **UI tests** (`AppUITests/`, `QuotientUITests` target): `testLaunchAndTabBarAppears` — smoke test confirming the app launches past the splash without crashing. Full onboarding → scenario → save → re-open → edit happy path is deferred to Session 4 once all five calculators are on device (so the UI flow has actual targets to verify). For Session 3 the unit tests cover the persistence path end-to-end against an in-memory SwiftData container.
- project.yml now declares `QuotientTests` (unit) and `QuotientUITests` (UI) bundles + a `schemes` block that wires both into the `Quotient` scheme's `test` action, unblocking `xcodebuild test`.

---

## Tests + coverage

| Target | Tests | Runtime | Notes |
|---|---|---|---|
| QuotientFinance (package) | **239** | ~17s | Unchanged; all Session 1+2 property invariants + golden fixtures + perf benches still green. |
| QuotientCompliance (package) | **40** | <0.01s | Unchanged. |
| QuotientTests (app unit) | **11** (new) | ~0.06s | SwiftData CRUD + VM + Codable. |
| QuotientUITests (app UI) | **1** (new) | ~2.2s | Launch smoke test. Broader UI flows in Session 4. |
| **Total** | **291** | ~20s wall | |

Coverage numbers are unchanged for the finance + compliance packages (they weren't touched); App target tests exercise the newly-added storage + view-model code.

---

## Coverage accounting — continuation of Sessions 1 + 2

Session 3 did not add any finance-engine or compliance-library code — all new surface is App target (SwiftUI views + @Observable view model + SwiftData models). Session 1 + 2 coverage exemptions (24 + 10 + 10 = 44 regions) remain as enumerated in `SESSION-1-SUMMARY.md` and `SESSION-2-SUMMARY.md` respectively. No new defensive guards were added to the finance or compliance packages in this session.

**Running totals:**
- Session 1: 24 exemptions
- Session 2.1: +10 exemptions
- Session 2.2: +10 exemptions
- Session 3: +0 exemptions
- **Total through Session 3: 44 exemptions** (all defensive guards, enumerated in prior summaries).

---

## Decisions made this session

Logged in `DECISIONS.md` under 2026-04-17 (appended to Session 2 entries):

1. **Face ID default: off** — per Session 3 orchestration instructions, override the JSX's "on" default. Rationale: iOS HIG prefers explicit opt-in for biometric gating on cold launch; LO can flip it to on in Settings → Privacy · data.
2. **Saved Scenarios date buckets: Today / This week / Earlier** — spec wins over the JSX's "This week / Earlier in April / March" demo bucketing. DEVELOPMENT.md and CLAUDE.md both reference Today/This week/Earlier explicitly.
3. **Settings 10 sections ↔ 6 visual headers** — JSX groups adjacent sections into joined headers ("Language · haptics", "Privacy · data", "Support · about"). Implementation keeps 10 logical rows under 6 visual section headers to honor both the spec count and the JSX grouping.
4. **Scenario editing UX: navigationDestination + initialInputs** — tapping a saved scenario pushes the same Inputs screen with its inputsJSON decoded into the form, and the existing `Scenario` threaded through so Save updates in place (vs. duplicating). Duplicate is a separate swipe action.
5. **Results screen: extracted subviews** — `AmortizationBreakdownView` and `AmortizationScheduleView` live in their own files to keep the main screen under SwiftLint's 400-line type-body limit and so the PITI breakdown + schedule table can be reused by the PDF body page in Session 4 without duplication.
6. **Rate snapshot: stubbed for Session 3** — MockRateService hardcodes plausible April-2026 values. Real proxy lands in Session 5. Documented as an open item below.
7. **UI happy-path test scope: deferred** — Session 3's UI tests verify launch smoke only. The full onboarding → new Amortization → Compute → Save → re-open → edit flow will land in Session 4 alongside the other four calculators' happy-path tests, so they can share setup/teardown and run as one pass.

---

## Open items deferred

- **Rate snapshot live call** — `MockRateService` replaced by a real fetch against the Vercel-edge / Cloudflare-workers proxy in Session 5. `RateService` protocol already abstracts the call site, so the swap is one-line in `HomeScreen`.
- **Broader UI happy-path tests** — full scenario-lifecycle UI test covering onboarding → scenario creation → save → re-open → edit lands in Session 4 once the four other calculators are present.
- **Accessibility / Dynamic Type / VoiceOver on new screens** — Session 5 does the full a11y pass. Components from Session 2 already handle Accessibility5 at the primitive level; screens in Session 3 consume those primitives and should inherit the behavior, but a QA pass is pending.
- **Session 4 scope (next)** — Income Qualification, Refinance Comparison, Total Cost Analysis, HELOC vs Refinance, QuotientNarration (FoundationModels + templates), QuotientPDF, Share / PDF preview carousel.

---

## What's next

Session 4 builds the four remaining calculators against the Amortization flagship's patterns (view-model + inputs form + results screen + Scenario save/load), then layers QuotientNarration (FoundationModels wrapper with streaming + template fallback) and QuotientPDF (ImageRenderer + PDFKit) on top. The Share preview carousel binds everything to the native iOS share sheet. Gate: all 5 calculators functional; narration streams + falls back; PDFs generate + share works; Share carousel matches design.
