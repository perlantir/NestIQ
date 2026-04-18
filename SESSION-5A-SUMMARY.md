# Session 5A — Summary

**Scope:** Settings audit + Profile Editor rebuild + brand / compliance / support detail screens + HELOC Inputs UI refinements.
**Result:** Every Settings row now either performs a real action or is deliberately removed. Profile editing is complete. Three new brand detail screens (accent / logo / signature) pipe through to the PDF cover + Home greeting. Three new compliance detail screens surface the QuotientCompliance data without letting LOs edit counsel-reviewed text. HELOC Inputs switched to month-granular intro period + margin-over-Prime rate entry; a new 10-year blended-rate hero card sits on the Results view.

Session 5B (finance engine work: `DownPayment` / `MI` propagation) and 5C (side-by-side + PDF landscape pages) are separate sessions per Nick's call to checkpoint after each phase.

---

## Commits

| SHA | Task | Scope |
|---|---|---|
| `613d082` | 5A.1 | Remove deferred Settings rows (Header layout / Density / Text size / Export backup) |
| `a9569a6` | 5A.2 | Schema additions (`pdfLanguage` / `nmlsDisplayFormat` / `ehoLanguage`) + expanded Profile Editor |
| `7d24b8e` | 5A.3 | Brand detail screens (AccentColorPickerScreen / LogoPickerScreen / SignatureBlockEditor) + PDF cover + Home greeting wiring |
| `ba0bbc1` | 5A.4 | Compliance detail screens (PerStateDisclosuresPreview / NMLSDisplayFormatPicker / EqualHousingLanguagePicker) |
| `956eb5e` | 5A.5 | Support detail screens (FeedbackMailSheet / HelpCenterView / LicensesLegalView) + Borrower-PDF language row split |
| `dcd6afe` | 5A.6 | HELOC UI refinements (intro period 1-24 months / margin over Prime / remove stress shock / 10-year blended hero) |

---

## Row-by-row audit

| Row | Before | After | Rationale |
|---|---|---|---|
| **Profile hero → Edit** | sheet with First name / Last name / NMLS / States (text) / Company / Phone / Email | sheet with Name + NMLS (live-validated via `nmlsConsumerAccessURL`) + Licensed states (multi-select from `USState.allCases` via `LicensedStatesPicker`) + Company · Phone · Email + App language picker | 5A refinement: spec called for NMLS validation via `ComplianceError.invalidNMLS` + multi-select states (11 named + 40 fallback + DC = `USState.allCases`) + currency language picker. App language stays here; PDF language lives in its own section below. |
| **Brand · Accent color** | `onTap: {}` placeholder, trailing "Ledger green" | push into `AccentColorPickerScreen`: 8-swatch curated palette + custom `ColorPicker`. Live preview mirrors the PDF cover styling. Persists `LenderProfile.brandColorHex`. Applied to the PDF cover accent + the Home greeting `Eyebrow`. | Default **(c)** per Nick's confirmation: PDF cover + Home greeting only. Global CTA tinting stays out of scope. |
| **Brand · Logo** | `onTap: {}` placeholder | push into `LogoPickerScreen`: SwiftUI `PhotosPicker` (iOS 16+, out-of-process — no Info.plist permission needed). Persists `LenderProfile.companyLogoData`. PDF cover renders it in the brand strip when set. | Logo renders on PDF brand strip. `PhotosPicker` keeps the Info.plist clean. |
| **Brand · Header layout** | `onTap: {}` placeholder, trailing "Editorial" | **REMOVED** | Only the Editorial layout exists in `design/screens/PDF.jsx`. No second option to pick. |
| **Brand · Signature block** | `onTap: {}` placeholder, trailing "Default" | push into `SignatureBlockEditor`: multi-line `TextField` (axis: .vertical), 200-char cap, persists `LenderProfile.tagline`. Rendered beneath the name + NMLS on the PDF cover as italic serif. | Single-line free-form signature addendum. |
| **Disclaimers · Per-state disclosures** | `onTap: {}` placeholder, trailing "N of N" | push into `PerStateDisclosuresPreview`: read-only preview per licensed state, EN + ES side-by-side, counsel-review badges (Pending review / Approved / Needs revision). No edit capability. | Preserves the Session 2 `CounselReviewStatus` architecture — LOs see what will render on the PDF but cannot edit the counsel-reviewed text. |
| **Disclaimers · NMLS display** | `onTap: {}` placeholder, trailing just the NMLS ID | push into `NMLSDisplayFormatPicker`: three-option radio list (ID only / ID + Consumer Access / Omit), each previewing its render inline. Persists `LenderProfile.nmlsDisplayFormat`. | Spec called for 3 formats, consumed by the PDF renderer. |
| **Disclaimers · Equal Housing language** | `onTap: {}` placeholder, trailing "English" | push into `EqualHousingLanguagePicker`: EN / ES radio + live preview via `equalHousingOpportunityStatement(locale:)`. Persists `LenderProfile.ehoLanguage`. | Independent of app language so an EN-speaking LO can still issue ES statements. |
| **Appearance · Theme** | segmented (Light / Dark / System) wired to `AppearancePreference` | unchanged | Already wired per `commit a877183`. Verified during audit. |
| **Appearance · Density** | segmented (Comfortable / Compact) wired to `DensityPreference` | **REMOVED** (field stays on `LenderProfile`) | **Deferred**: threading a density multiplier through every `Spacing.s*` usage site is a large blast-radius refactor. Revisit when iPad optimization is prioritized. `densityPreferenceRaw` field stays on `LenderProfile` so we don't need another schema change when we ship it. |
| **Appearance · Text size** | `onTap: {}` placeholder | **REMOVED** | iOS Dynamic Type handles this system-wide; no app-level override needed. |
| **Language · App language** | trailing "English / Español" toggling `preferredLanguage` | unchanged (verified wired) | Already wired; just now co-exists with a distinct PDF-language row. |
| **Language · Borrower-facing PDF** | placeholder "EN · ES" with `onTap: {}` | toggle row bound to new `LenderProfile.pdfLanguage` field (EN / ES), separate from `preferredLanguage`. | Spec-critical: LOs in the US often work EN in-app but issue ES borrower-facing PDFs. |
| **Language · Haptics on calculate** | toggle wired to `hapticsEnabled` | unchanged (verified wired) | Already wired. |
| **Language · Sound on share** | toggle wired to `soundsEnabled` | unchanged (verified wired) | Already wired. |
| **Privacy · Face ID to open** | toggle wired to `faceIDEnabled` | unchanged (verified wired) | Already wired. `AuthGate` consumes it for biometric lock. |
| **Privacy · Export backup** | `onTap: {}` placeholder, trailing "iCloud" | **REMOVED** | **Deferred**: iCloud Documents integration is out of scope for Session 5A. Don't ship a non-working option. Adds to deferred list below. |
| **Privacy · Erase local data** | wired (`eraseData` deletes Scenario + Borrower) | unchanged (verified wired) | Already works. |
| **Support · Send feedback** | `onTap: {}` placeholder | sheet presenting `FeedbackMailSheet`: `MFMailComposeViewController` prefilled to `support@quotient.app`, subject `"Quotient feedback - v{version} build {build}"`. Fallback to `mailto:` deep link + copy-address button when Mail isn't configured. | Nick-blocker: real email address. `// TODO: real support email before TestFlight` inline. |
| **Support · Help center** | `onTap: {}` placeholder | push into `HelpCenterView`: `WKWebView` on placeholder URL. | Nick-blocker: real help URL. `// TODO: real help center URL before TestFlight` inline. |
| **Support · Licenses & legal** | `onTap: {}` placeholder | push into `LicensesLegalView`: static attributions (Source Serif 4 OFL 1.1 + SF Pro/Mono system-font note) + Privacy policy / Terms of service `Link`s + copyright + calculation-tool disclaimer. | Nick-blockers: real Privacy + Terms URLs. `// TODO: ... before TestFlight` inline on both. |
| **Support · Replay onboarding tour** | `onTap: { showingReplayConfirmation = true }` | unchanged (verified wired) | Already wired. Confirmation dialog → `replayOnboarding()` flips `hasCompletedOnboarding = false`. |
| **Support · Component gallery (DEBUG)** | `NavigationLink` into `ComponentGallery` | unchanged | Already wired. DEBUG-conditional. |
| **Support · Version** | static "1.0.0 · build 1" | `Bundle.main` read (`CFBundleShortVersionString` + `CFBundleVersion`) | Small win — stays accurate as we bump versions. |

### HELOC Inputs UI (A.2)

| Field | Before | After |
|---|---|---|
| Intro period | Stepper, 0-60 months, **6-month** step | Stepper, **1-24 months**, 1-month step |
| Rate margin | `FieldRow` "Fully-indexed rate" as an absolute %, free numeric entry | Stepper-driven `Prime + X.XX%` row, 0.25% increments (0 to 6). Prime is an assumed 7.50% constant (UI-side only); backing field `helocFullyIndexedRate` still stores the combined value so the engine is unchanged. Row caption shows the fully-indexed equivalent live. |
| Stress shock (bps) | Stepper, 0-500 bps, 25-bps step | **REMOVED from Inputs.** Field stays on `HelocFormInputs` for Codable compatibility with prior scenario blobs. |

### HELOC Results UI (A.2)

| Block | Before | After |
|---|---|---|
| Blended rate hero | at-origination blended rate, "vs refi X.XXX%" subline | unchanged |
| **10-year blended card** | — | **NEW** compact card directly below the hero. `HelocViewModel.blendedRateAtTenYears` runs `simulateHelocPath(firstLien:, product:, drawSchedule:, ratePath: .flat)` and reads `HelocSimulation.blendedRateAtHorizon`. Initial draw = `helocAmount`, 120/240 draw/repay window, interest-only minimums, flat rate path. Falls back to at-origination blend if simulator returns nil. |
| Stress paths chart | three curves (base / +2pt shock / −1pt relief) + refi reference line | **REMOVED.** The engine-side `simulateHelocPath` in QuotientFinance is untouched (property tests depend on it). `HelocViewModel.stressPath(kind:)` / `StressKind` helpers left in place so a future session can replot elsewhere. |

---

## Tests + coverage

| Target | Before 5A | After 5A | Delta |
|---|---|---|---|
| QuotientFinance | 239 | 243 | — (+4 was the prior 4.5.X yearly-aggregate commit, pre-5A) |
| QuotientCompliance | 40 | 40 | — |
| QuotientNarration | 6 | 6 | — |
| QuotientPDF | 2 | 2 | — |
| QuotientTests (app unit) | 26 | 26 | — |
| QuotientUITests (app UI) | 6 | 6 | — |
| **Total** | **319** | **323** | **+4** (yearly-aggregate carry-over) |

No new tests added in Session 5A — scope was UI + schema, not engine. Engine behavior for HELOC is unchanged (same `helocFullyIndexedRate` field path; same `simulateHelocPath` call-shape). Coverage at the metric level is unchanged because every new file is UI-shell rendering SwiftData-backed values.

Full QuotientFinance property-test suite (including the 1000+/case invariants) passed post-5A: `Test run with 243 tests passed after 21.2s`.

---

## Decisions to propagate into DECISIONS.md

1. **Brand accent color scope = PDF cover + Home greeting only.** Global CTA / hero-number tinting is a separate architectural project (would require threading a `Theme` through Environment or replacing `Palette` with an `@Observable AppTheme`). Deferred until there's an explicit UX task for it.
2. **Density preference row removed from Settings (field retained on LenderProfile).** Multiplier plumbing through `Spacing.s*` tokens is a large blast-radius refactor; revisit when iPad optimization or a dedicated density task comes up. `densityPreferenceRaw` stays on the schema so the eventual re-introduction is not a migration.
3. **Borrower-facing PDF language is distinct from app language.** Separate `LenderProfile.pdfLanguage` field (not `preferredLanguage`). Supported by a dedicated row in Settings and a footer reminder inside the Profile Editor's "Language" section.
4. **NMLS display format: three presets (ID only / ID + Consumer Access / Omit).** Used exclusively by the PDF footer; the in-app display + Profile card are always "ID only." Default = ID + Consumer Access.
5. **Equal Housing language is a PDF-layer setting, not an app-layer one.** Distinct field (`ehoLanguage`), independent of both `preferredLanguage` and `pdfLanguage`, so counsel can pin the EHO statement's language regardless of the rest of the PDF.
6. **HELOC rate entry switched from absolute fully-indexed rate to margin-over-Prime.** Backing field (`helocFullyIndexedRate`) unchanged; UI recomposes. Assumed Prime is a 7.50% constant in the UI — when a live Prime-rate source lands (Session 6 or 7 rate endpoint), swap the constant.
7. **Stress-shock chart removed from HELOC Results.** Engine `simulateHelocPath` + property tests untouched. The UI decision is purely "not on this screen" — if it resurfaces elsewhere, the `HelocViewModel.stressPath` helper is still there.
8. **LenderProfile schema additions are additive with defaults** — no SwiftData migration path needed pre-TestFlight. Three new fields: `pdfLanguage` (defaults "en"), `nmlsDisplayFormatRaw` (defaults "idAndURL"), `ehoLanguageRaw` (defaults "en").

---

## Nick-blockers surfaced

Grep the repo for `TODO: ... before TestFlight` to find these in-code:

1. **`support@quotient.app`** — placeholder email address for Send feedback. `App/Features/Settings/SupportDetailScreens.swift`.
2. **`https://quotient.app/help-placeholder`** — placeholder Help center URL. Same file.
3. **`https://quotient.app/privacy-placeholder`** — placeholder Privacy policy URL. Same file.
4. **`https://quotient.app/terms-placeholder`** — placeholder Terms of service URL. Same file.

None of these ship-block Session 5A — the UI flows are wired and the fallback behaviors (copy-to-clipboard, `mailto:` deep link) degrade gracefully. Real values are TestFlight pre-reqs alongside Apple Developer enrollment.

---

## Deferred to Session 5B / 5C

Replacing the Session 4.5 open-items list with 5A's view:

1. **Density multiplier threading** — Settings row removed; field retained. Waiting on iPad optimization task.
2. **Global CTA / hero-number brand tinting** — opt-in architectural project; not in 5A scope.
3. **`DownPayment` / `LTV` / `MI` primitive gap** — extending existing `calculatePMI` / `PMISchedule` rather than duplicating; surfacing "MI drops off month X" on Results; adding Property & down payment input sections across all 5 calculators. → **Session 5B**.
4. **Closing-cost + points convention** (`ClosingCostBreakdown` with `pointsAmount` derivation) → **Session 5B**.
5. **Side-by-side comparison UI** (Refi / TCA / HELOC) + PDF landscape pages → **Session 5C**.
6. **ES narration template fixes** from 4.5.7 self-review (five template gaps + three terminology flags). → any future session with a native speaker on hand.
7. **FHA MIP matrix** — conventional-only this session; FHA is Session 7.
8. **Live rate endpoint** — `MockRateService` stub stays. Session 6 or 7.
9. **iPad landscape layouts + empty/error/loading states + Accessibility5 + VoiceOver audit.**
10. **Apple Developer enrollment + privacy / terms URLs + compliance counsel review of state disclosures + real support email.** External blockers.
11. **Reopen-from-Saved UI test coverage** — blocked on iOS 18 simulator AX reliability.
12. **iCloud Documents export backup** — Settings row removed; needs CloudKit or iCloud Documents plumbing decision.

---

## What's next

Session 5B is the finance-engine work: a `DownPayment` primitive + `MIProfile` extension of the existing PMI system, the "Property & down payment" inputs section propagated across all 5 calculators, and the MI-drop-off month surfaced as a display value on every Results screen. Blast radius includes all 5 calculator `…Inputs` / `…Screen` files, so 5B gets its own session.
