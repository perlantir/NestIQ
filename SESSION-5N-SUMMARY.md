# Session 5N — Summary

Last dev session before Session 6 (TestFlight upload). Eight sub-tasks:
delete-account flow (Apple 5.1.1(v) requirement), PDF page-header
rollout across every page of every calculator, PDF signature-block
single-source-of-truth fix, break-even chart redesign, reinvestment
messaging for zero/negative savings, PDF APR audit, regression
catchall pass, and a PDF data-integrity audit. All shipped.

## Pre-work

Baseline test run clean across all packages:

| Surface | Baseline |
|---|---|
| QuotientFinance | 307 |
| QuotientCompliance | 40 |
| QuotientNarration | 10 |
| QuotientPDF | 2 |
| QuotientTests | 53 |
| QuotientUITests | 18 |

Green-light decisions from Nick before code touched:

- **SIWA revocation** — Option 1: local-only wipe + 7-day remote-clear
  disclosure copy + `// TODO(server):` for the future JWT-signing
  endpoint
- **PDF header rollout** — split into six incremental commits
  (5N.2a–f), one per PDF surface
- **5N.3 signature fix** — confirmed kill the `tagline` field entirely;
  rebuild the signature block with company on its own line + email ·
  phone joined
- **5N.4 break-even PDF** — 90-min time-box; if PDF chart rendering
  exceeds budget, ship on-screen redesign alone and defer PDF to 5O

## Architectural decisions (all appended to DECISIONS.md)

- **Delete account (5N.1)** — local-only v1 wipe; server-side SIWA
  revocation queued via `// TODO(server):` marker; 7-day remote-clear
  disclosure copy on success screen
- **PDF page header (5N.2)** — shared `PDFPageHeader` component
  (centered Wordmark-A @18pt, Page N of M / date row, 0.5pt divider)
  on every PDF page; global page count pre-computed once and threaded
  into each page's `pageIndex` / `pageCount` params
- **PDF signature block (5N.3)** — root cause: `LenderProfile.tagline`
  was being rendered as a second signature block. Field removed from
  model; signature block rebuilt with one data source
- **Break-even chart (5N.4)** — y-axis clamped non-negative; scenarios
  without savings excluded (routed to 5N.5); neutral dashed reference
  line; crossover PointMark + "Break-even · Month N" label; per-
  scenario description paragraph below chart
- **Reinvestment messaging (5N.5)** — three-way classification
  (positive / zero / negative) on monthly savings delta; explainer
  replaces misleading $0 projections
- **PDF APR audit (5N.6)** — every rate-taking PDF surface now routes
  through `displayRateAndAPR` or its inline D2-tolerance equivalent;
  TCA scenario cards + HELOC comparison rows retrofitted

## What shipped per sub-task

### 5N.1 — Delete account

- `DeleteAccountFlow.swift` — sheet with `.confirm` / `.finalConfirm`
  / `.success` states. Step 1 bulleted confirmation; Step 2
  "Are you sure?" with destructive Delete; Success screen with 7-day
  remote-clear disclosure and Done button.
- `AccountDeletion.performLocalWipe(context:preservingProfile:)` —
  free function, unit-testable. Per-row deletion of Scenario →
  Borrower → LenderProfile (batch delete warned on the Scenario ↔
  Borrower inverse relationship).
- New ACCOUNT section in Settings between PRIVACY · DATA and
  SUPPORT · ABOUT: "Erase local data" (existing behavior, moved) +
  "Delete account" (new, `Palette.loss` label).
- `SettingsRow` gained additive `labelColor: Color` parameter (default
  `Palette.ink`).
- Keychain + UserDefaults scopes audited empty — no NestIQ-prefixed
  keys anywhere in the app. Wipe scope is SwiftData only.
- 4 new `AccountDeletionTests`: full wipe clears all models; preserve-
  profile variant keeps the profile record; idempotent across re-
  runs; photoData clears transitively with the profile record.

### 5N.2a — Shared PDFPageHeader + cover + disclaimers

- `PDFPageHeader.swift` — centered 18pt Wordmark-A, SF Mono "Page N of
  M" / long-form date row, 0.5pt muted divider. Static helper
  `PDFPageHeader.formatDate(_:)` canonicalizes the "April 20, 2026"
  format used everywhere.
- `PDFCoverPage` + `PDFDisclaimersPage` — prepend `PDFPageHeader`,
  drop redundant per-page footer counter, accept `pageIndex` /
  `pageCount` params.
- `PDFBuilder.buildPDF` — computes `total = 1 + extraPages.count + 1`
  once, passes to both cover and disclaimers.
- `PDFBuilder+Pages.swift` — extracted cover + disclaimers page
  composition helpers so the main enum body stays under SwiftLint's
  400-line `type_body_length` cap.
- `testPDFCoverRenders` updated to assert NMLS + borrower + "Page 1
  of 1" anchors (Wordmark is a raster image; removed "NestIQ Mortgage
  Intelligence" footer text anchor).

### 5N.2b — Amortization schedule pages

- `AmortizationYearlyPage` + `AmortizationMonthlyPage` — prepend
  `PDFPageHeader`, drop local "Schedule · page N of M" footer string
  (now in global header).
- `AmortSchedulePageHeader` renamed to `AmortScheduleTitleBand` — its
  role narrowed to title + borrower + loan-summary band below the
  global header.
- Monthly pages gained a "slice N of M" sub-label in the title band
  so readers still see the local slice index within the monthly
  schedule.
- `AmortizationSchedulePages.pageCount(schedule:granularity:)` helper
  computes the schedule's page count before construction so
  `buildAmortizationPDF` can thread the correct global `pageIndex` to
  every page.

### 5N.2c — TCA comparison page

- `TCAComparisonPage` gains `pageIndex` / `pageCount`; title band's
  `generatedDate` row removed (header owns it).
- Builder passes `pageIndex: 2, pageCount: 3` (cover + comparison +
  disclaimers).

### 5N.2d — Refinance comparison page

- Same pattern as 5N.2c. `refinanceComparisonPage` helper signature
  extended; title band's date row removed.

### 5N.2e — HELOC comparison page

- Same pattern. `helocComparisonPage` helper signature extended.

### 5N.2f — Self-Employment pages

- `SelfEmploymentCashFlowPage` retrofitted. Completes the 5N.2 series
  — every PDF page in the document now renders the identical
  `PDFPageHeader` at the top with a correct global "Page N of M"
  counter.

### 5N.3 — PDF signature block

- **Root cause**: `LenderProfile.tagline` was passed into
  `PDFCoverPage.signatureLine` and rendered as a second italic serif
  block below the main signature. Nick had typed a multi-line name
  into the tagline field (Settings → Brand → Signature block).
- Removed: `tagline: String?` on LenderProfile; `SignatureBlockEditor`
  struct + Settings nav row; `signatureLine` param + render from
  PDFCoverPage; `profile.tagline` pass-through in PDFBuilder+Pages.
- Signature block rewritten: serif 16pt name (up from 12pt sans);
  title · NMLS; company on its own line (hidden when empty or "—");
  email · phone joined by middot; photo bumped from 44pt → 56pt.
- `testPDFSignatureBlockShowsNameOnce` — pins the single-block
  rendering against a regression.

### 5N.4 — Break-even chart redesign (on-screen)

- Extracted to new `TCAScreen+BreakEven.swift` (~240 lines) to keep
  the breakdown file under the 600-line cap after the chart's added
  complexity.
- Y-axis clamped to non-negative; scenarios with payment ≥ baseline
  excluded from the chart (routed to 5N.5's reinvestment messaging).
- Neutral dashed reference line (`Palette.inkTertiary` @ 0.6 opacity)
  at each scenario's closing costs with "Closing $X" trailing
  annotation.
- `PointMark` at each crossover with "Break-even · Month N" label.
- Per-scenario description paragraph below the chart.
- `BreakEvenPoint` / `BreakEvenCrossover` / `BreakEvenSeries` value
  types pre-compute data so the Chart body fits within Swift's
  type-checker budget (the single-expression version hit the
  breaking point).
- `breakEvenMarks(for:)` `@ChartContentBuilder` extension keeps the
  outer Chart closure minimal.
- **PDF chart deferred** to a fast 5O follow-up per Nick's time-box;
  PDF keeps the compact per-scenario "Month 34" text summary from
  5M.7 intact.

### 5N.5 — Reinvestment zero/negative savings messaging

- Three-way `ReinvestmentDelta` classification on
  `baseline − scenarioPayment`:
  - `.positive`: unchanged horizon projections (Path A invest
    balances + Path B payoff acceleration line)
  - `.zero` (|diff| < $0.01): "Equivalent monthly payment — no
    savings to reinvest."
  - `.negative(costMore:)`: "[LABEL] costs $X/mo more per month
    than baseline — no monthly savings available to invest."
- Applied to both on-screen `reinvestmentScenarioCard` and PDF
  `TCAComparisonPage+Helpers.reinvestmentParts`.
- Penny epsilon absorbs same-P&I-to-the-cent round-trips.
- Engine primitives (`pathAInvestmentBalance`,
  `pathBExtraPrincipal`) unchanged; this is purely a display-layer
  fix.

### 5N.6 — PDF APR display audit

Every rate-taking PDF surface inventoried. Gaps fixed:

- **TCAComparisonPage** scenario cards: was rendering APR
  unconditionally when `s.aprRate` was non-nil. Added the 0.0005%
  tolerance check inline to match D2.
- **HelocComparisonPage** comparison table: was using raw
  `String(format: "%.3f%%")` with no APR reference at all. Routed
  `refiRate` / `helocIntroRate` / `helocFullyIndexedRate` through
  `displayRateAndAPR` so each row now reads "6.750% / 6.812% APR"
  when the LO has entered an APR that differs.

Already correct: Amortization, Income Qualification, Refinance (cover
uses helper; side-by-side table has dedicated APR row).
Self-Employment has no rate field by design.

### 5N.7 — Regression audit

Automated suite run — all green, no functional regressions:

| Surface | Before | After | Delta |
|---|---|---|---|
| QuotientFinance | 307 | 307 | 0 |
| QuotientCompliance | 40 | 40 | 0 |
| QuotientNarration | 10 | 10 | 0 |
| QuotientPDF | 2 | 2 | 0 |
| QuotientTests | 53 | 61 | +8 |
| QuotientUITests | 18 | 18 | 0 |

Spot-check coverage by earlier-session item:

- **5K.1 Smart Save**: `ScenarioSaveLoad*Tests` + smart-save UI tests
  pass
- **5K.2 Narrate flagged numbers**: `QuotientNarration` allowlist +
  ±1% tolerance tests pass
- **5K.4 Recent scenarios tappable**:
  `testRecentScenarioTapLoadsCalculator` passes
- **5M.1 Schema migration**: `SchemaMigrationTests` (6) pass
- **Self-Employment**: `SelfEmploymentViewModelTests` pass
- **5L.1/5L.2/5L.3/5L.4 visual items**: require Nick's QA pass; no
  automated coverage

### 5N.8 — PDF data integrity audit

- `testPDFHeaderRendersPageNofMOnCoverAndDisclaimers` — pins cover
  "Page 1 of N" + disclaimers "Page N of N". Middle landscape pages
  render the same header visually but PDFKit text extraction on
  rotated pages is unreliable, so the assertion anchors on portrait
  anchor pages.
- `testPDFSignatureHandlesMissingCompany` — empty `companyName`
  doesn't render a standalone "—" line in the signature block.
- `testPDFSignatureHandlesMissingPhoto` — `profile.photoData = nil`
  renders cleanly without a phantom empty circle.

## Tests

| File | Before | After | Delta |
|---|---|---|---|
| AccountDeletionTests | 0 | 4 | +4 (new file) |
| PDFBuilderTests | 4 | 8 | +4 |
| **QuotientTests total** | 53 | 61 | +8 |

## Commits

```
Session 5N.1   — Delete account — two-step confirmation + local-only wipe
Session 5N.2a  — PDF page header — shared component + cover + disclaimers
Session 5N.2b  — PDF page header — Amortization schedule pages
Session 5N.2c  — PDF page header — TCA comparison page
Session 5N.2d  — PDF page header — Refinance comparison page
Session 5N.2e  — PDF page header — HELOC comparison page
Session 5N.2f  — PDF page header — Self-Employment pages
Session 5N.3   — PDF signature block — single source of truth
Session 5N.4   — Break-even chart redesign (on-screen)
Session 5N.5   — Reinvestment — contextual messaging for zero / negative savings
Session 5N.6   — PDF APR display audit — TCA + HELOC retrofitted to D2
Session 5N.8   — PDF data integrity audit — signature + header tests
Session 5N     — complete rollup (this commit)
```

## Deferred

- **PDF break-even chart** — on-screen chart shipped; PDF version
  deferred to a fast 5O follow-up per Nick's 5N.4 time-box decision.
  PDF currently carries the compact per-scenario "Month N" text
  summary from 5M.7.
- **Server-side SIWA revocation** — local-only v1 ships with a
  `// TODO(server):` marker; GA requires a backend JWT-signing
  endpoint to complete the `appleid.apple.com/auth/revoke` call.
- **5L.1–5L.3 visual QA** — logo transparency, Home 24pt wordmark,
  Welcome 48pt wordmark all require Nick's QA pass; automated suite
  doesn't cover visual regressions.

## What's next — Session 6 (TestFlight admin)

1. Remove DEBUG AuthGate bypass (`AuthGate.swift:84-91`) once the
   UI-test bypass path is satisfied by alternative means
2. Info.plist usage descriptions — `NSPhotoLibraryUsageDescription`,
   `NSFaceIDUsageDescription`, camera if Photos picker reaches it
3. Wire real URLs — `https://nestiq.mortgage/privacy`, `/terms`,
   `/support` — into Settings + onboarding
4. Wire `support@nestiq.mortgage` into Send Feedback
5. Apple Developer team ID, enable App Store signing, archive +
   TestFlight upload

## Fast follow-ups (5O candidates)

- PDF break-even chart (Core Graphics or ImageRenderer path; needs
  landscape-page integration work)
- Server-side SIWA revocation endpoint (Vercel Edge or Cloudflare
  Worker, out of current session scope)
