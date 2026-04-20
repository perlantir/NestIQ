# Session 5O — Summary

Last dev session before Session 6 (TestFlight admin). Nine sub-tasks:
a full PDF pipeline rewrite across all six calculator PDFs (driven
by repeated multi-page pagination failures in 5J / 5M / 5N and a
misaligned design language with nestiq.mortgage), plus the 5O.9
break-even chart bounds fix from Nick's 5N QA. All shipped.

## Architectural shift — D8

**From** SwiftUI + `ImageRenderer` + `CGContext.pdfContext`
composing fixed 612×792 portrait (or 792×612 landscape) pages, with
each calculator rolling its own header / footer / signature /
disclaimer layout (2,868 LOC across 14 SwiftUI files).

**To** HTML-to-PDF via `UIPrintPageRenderer` +
`WKWebView.viewPrintFormatter()`. Per-calculator body HTML (5
`*PDFHTML.swift` modules + 1 `PDFBuilder+SelfEmployment.swift`
wrapper) interpolates into a shared `base.html` template; a
`NestIQPrintRenderer` subclass draws the wordmark header + per-page
"Page N of M · nestiq.mortgage" footer in Core Graphics. Charts
render as inline SVG (`BreakEvenChartSVG`).

**Why the pivot off the original plan.** The 5O kickoff plan called
for `WKWebView.createPDF(configuration:)` with CSS `@page` running
headers + `counter(page)`. WebKit does not implement CSS Paged
Media Level 3 running elements — the headers would render once
inline in the body, not per page, and the counters would resolve
to empty strings. Confirmed before writing any code; Option B
(`UIPrintPageRenderer` + `viewPrintFormatter`) is the canonical
iOS approach for paginated document rendering (used by Encompass,
Blend, and other production LO apps).

## Pre-work baseline

- `QuotientFinance` 307, `QuotientCompliance` 40,
  `QuotientNarration` 10, `QuotientPDF` 2, `QuotientTests` 61,
  `QuotientUITests` 18 — all green pre-session.

## What shipped per sub-task

### 5O.1 — HTML template + UIPrintPageRenderer foundation

- `App/Resources/PDFTemplates/base.html` — body-only template with
  NestIQ design tokens (Ink `#17160F`, Paper `#FAF9F5`, Accent
  `#1F4D3F`, Muted `#85816F`), Georgia / SF Pro Text / SF Mono font
  cascade, signature / content-card / KPI-grid / data-table /
  chart-container / disclaimer classes, `page-break-inside: avoid`
  helpers.
- `App/Resources/PDFTemplates/SignatureBlock.html` — partial with
  `{{NAME}}` / `{{TITLE_LINE}}` / `{{COMPANY_LINE}}` /
  `{{CONTACT_LINE}}` / `{{PHOTO_TAG}}` slots.
- `HTMLPDFRenderer` — off-screen `WKWebView`, `viewPrintFormatter`
  wired into a `UIPrintPageRenderer`, renders page-by-page via
  `UIGraphicsPDFContext`. Async `renderPDF(html:) -> Data` and
  `renderPDF(html:to:)` entry points.
- `NestIQPrintRenderer` — subclass with `headerHeight=54` /
  `footerHeight=40`. `drawHeaderForPage` renders "Nest" (Georgia,
  ink) + italic "IQ" (accent green) wordmark centered over a
  hairline divider; `drawFooterForPage` renders "Page N of M" (SF
  Mono, muted) left-aligned and "nestiq.mortgage" right-aligned
  above a hairline.
- `HTMLPDFRendererTests` (+6): bundle loading, interpolation
  (missing keys stay visible), single-page smoke, 60-row multi-page
  pagination with per-page counter assertion.

### 5O.2 — Amortization PDF

- `AmortizationPDFHTML.buildHTML`: signature + "For {Borrower}"
  title + loan summary + monthly PITI hero + KPIs (total interest /
  payoff / total paid) + summary narrative + payment breakdown
  table + yearly or monthly schedule table (granularity param) +
  disclaimers appendix. Monthly mode marks the MI-dropoff row.
- `PDFHTMLComposition` (new shared helpers): base.html /
  SignatureBlock.html caching, `signatureHTML` (5N.3 single-source
  rules), `disclaimersHTML` (state-aware via `requiredDisclosures`),
  `heroCardHTML`, `kpiGridHTML`, `titleBlockHTML`, `formatDate`,
  `escape` (HTML entity safe).
- `PDFBuilder.buildAmortizationPDF` → `async throws` via
  `HTMLPDFRenderer`. `AmortizationResultsScreen` caller wrapped in
  `Task { @MainActor in try await … }`.
- Existing `PDFBuilderTests` (7) migrated to `async throws`. The
  5N.8 page-counter, missing-company, and missing-photo regression
  tests all pass against the new pipeline.

### 5O.3 — TCA PDF + break-even SVG chart

- `BreakEvenChartSVG` (new, shared by TCA and Refi): pure inline
  SVG. X-axis hard-clamped to `termMonths`; y-axis non-negative,
  ticks at 25/50/75/100% of max; savings polyline in accent green;
  dashed reference line at `closingCosts` with trailing "Closing
  $X" label; crossover marker (circle + "Break-even · Month N")
  when savings cross within term, no marker otherwise.
  `firstCrossover` helper exposed for tests.
- `TCAPDFHTML.buildHTML`: cover (signature + title + hero +
  KPIs) → per-scenario spec cards (rate / APR via 0.0005% delta
  rule / term / loan / LTV / MI / pts / closing / monthly P&I /
  cash to close) → horizon × total-cost matrix (winner ✓, refi
  debts overlay) → interest vs principal split → unrecoverable
  costs @ longest horizon + ongoing-housing explainer →
  per-scenario break-even SVG → reinvestment section with 5N.5
  three-way classification → equity buildup @ longest horizon →
  disclaimers appendix.
- `TCAPDFHTMLTests` (+4 in new file): full TCA PDF integrity;
  break-even SVG domain matches term (30yr → '30yr' terminal tick
  + crossover at month 120); no crossover case; `firstCrossover`
  helper unit test.

### 5O.4 — Refinance Comparison PDF

- `RefinancePDFHTML.buildHTML`: cover + comparison table (Cur + N
  option columns × 12 rows: loan amt, rate, APR when any, term,
  points, closing, payment, break-even, NPV, lifetime Δ, LTV, MI)
  with ✓ winner marks on payment / break-even / NPV / lifetime
  rows → per-option break-even SVG (reuses `BreakEvenChartSVG`) →
  disclaimers.
- `RefinancePDFHTMLTests` (+1): borrower, comparison section,
  Loan amt / Break-even / NPV rows, disclaimers, page counter.

### 5O.5 — HELOC vs Refinance PDF

- `HelocPDFHTML.buildHTML`: cover + 10-year blended-rate card
  (HELOC blended vs cash-out refi + verdict badge) + 14-row
  comparison table sourced from a now-local
  `HelocPDFHTML.rows(for:)` builder (moved from the deleted
  `HelocComparisonPage.rows(for:)`) + disclaimers.
- `HelocPDFHTMLTests` (+1): borrower, comparison heading, rate
  structure row, disclaimers, page counter.

### 5O.6 — Income Qualification PDF

- `IncomeQualPDFHTML.buildHTML`: mode-aware (purchase vs
  refinance) cover with max-loan hero + 4 KPIs + qualification
  breakdown table (qualifying income, total monthly debts,
  front/back DTI, max PITI, max loan, current balance + home
  value + LTV in refi mode, max purchase in purchase mode) +
  disclaimers.
- `IncomeQualPDFHTMLTests` (+1): borrower, breakdown heading, key
  rows, disclaimers.

### 5O.7 — Self-Employment PDF

- `SelfEmploymentPDFHTML.buildHTML`: cover (qualifying monthly
  income hero + Year 1 / Year 2 / Trend KPIs + narrative from
  `output.trendNotes` or fallback) + year-by-year Fannie 1084
  cards (addback rows labeled `+$X — added back` per 5H.2,
  deduction rows labeled `-$X — deducted`, bold Net cash flow
  total) + two-year average block + disclaimers.
- `SelfEmploymentPDFHTMLTests` (+2, 1 conditionally skipped): full
  SE PDF integrity; 5H.2 addback-label regression pin.

### 5O.8 — Legacy cleanup

- Deleted 10 SwiftUI PDF files from `App/Features/Share/`:
  `PDFPages`, `PDFBuilder+Pages`, `PDFBuilder+ComparisonPages`,
  `PDFPageHeader`, `AmortizationSchedulePages`,
  `RefinanceComparisonPage`, `HelocComparisonPage`,
  `TCAComparisonPage`, `TCAComparisonPage+Helpers`,
  `SelfEmploymentPDFPages`.
- `PDFBuilder.swift` slimmed to 6 HTML entry points (Payload /
  `buildPDF` / page composition helpers all gone).
- `QuotientPDF` package stripped: legacy `PDFRenderer` enum
  (ImageRenderer + CGContext.pdfContext) removed; package now
  exposes only `PDFInspector` for PDFKit-based readback.
  `QuotientPDFTests` replaced with 2 new `PDFInspector` tests.
- `HelocScreen`'s on-screen side-by-side table now references
  `HelocPDFHTML.Row` / `.rows(for:)` (moved from the deleted
  `HelocComparisonPage`).
- Legacy `testPDFCoverRenders` + `testPDFSignatureBlockShowsNameOnce`
  removed — they drove the deleted `PDFCoverPage` directly. 5N.3
  single-source signature regression coverage preserved in
  `TCAPDFHTMLTests.testTCAPDFRendersAllSections` which pins
  `coverOccurrences == 1` on the cover page text layer.

### 5O.9 — Break-even chart bounds fix (on-screen + PDF)

- On-screen chart in `TCAScreen+BreakEven.swift`: x-axis now
  `.chartXScale(domain: 0...xMax)` where xMax is the longest
  included scenario's term in months. Fixes the -500…+500
  auto-domain bug from Nick's 5N QA.
- Non-crossing scenarios (monthly savings positive but don't
  recoup closing within term) are filtered out of
  `breakEvenSeries` — no flat-line-below-reference visuals. Their
  description line ("savings do not exceed closing costs within
  the N-yr term") still surfaces via `breakEvenDescription`. When
  no scenarios cross, the Chart is hidden via `if !series.isEmpty`.
- `BreakEvenSeries` gained `termMonths` so the chart doesn't fall
  back to the 360-month global default when term differs across
  scenarios.
- Helpers (`breakEvenSeries`, `breakEvenDescriptionLines`) split
  into instance wrappers + static pure functions so tests can
  drive them without constructing a SwiftUI Screen.
- PDF side: `BreakEvenChartSVG` already hard-codes its viewBox to
  `termMonths` (landed in 5O.3).
- `BreakEvenChartTests` (+3 in new file): series domain matches
  scenario term; non-crossing scenario excluded from chart but
  kept in description; mixed-scenario filter keeps only crosser.

## Files added / deleted / renamed

### Added (14)

- `App/Resources/PDFTemplates/base.html`
- `App/Resources/PDFTemplates/SignatureBlock.html`
- `App/Features/Share/HTMLPDFRenderer.swift`
- `App/Features/Share/NestIQPrintRenderer.swift`
- `App/Features/Share/PDFHTMLComposition.swift`
- `App/Features/Share/BreakEvenChartSVG.swift`
- `App/Features/Share/AmortizationPDFHTML.swift`
- `App/Features/Share/TCAPDFHTML.swift`
- `App/Features/Share/RefinancePDFHTML.swift`
- `App/Features/Share/HelocPDFHTML.swift`
- `App/Features/Share/IncomeQualPDFHTML.swift`
- `App/Features/Share/SelfEmploymentPDFHTML.swift`
- 6 new test files covering the HTML pipeline + 5O.9 data layer

### Deleted (10)

All legacy SwiftUI PDF composition files — see 5O.8 list above.

## Font fallback

Source Serif 4 is **not** a built-in iOS system font, so inline
SVGs and HTML rely on the cascade `Georgia, "Source Serif 4",
serif` — WebKit falls to Georgia, visually close and editorial.
The bundled Source Serif 4 ttf resources in `App/Resources/Fonts`
continue to serve the app UI where SwiftUI can load them via
`.custom("SourceSerif4", size:)`.

## Tests

| Surface | Before | After | Delta |
|---|---|---|---|
| QuotientFinance | 307 | 307 | 0 |
| QuotientCompliance | 40 | 40 | 0 |
| QuotientNarration | 10 | 10 | 0 |
| QuotientPDF | 2 | 2 | 0 (tests rewritten) |
| QuotientTests | 61 | 77 | +16 (1 conditionally skipped) |
| QuotientUITests | 18 | 18 | 0 |

Test file changes in `QuotientTests`:

| File | Before | After | Delta |
|---|---|---|---|
| PDFBuilderTests | 8 | 6 | -2 (legacy SwiftUI tests removed) |
| HTMLPDFRendererTests | 0 | 6 | +6 (new) |
| TCAPDFHTMLTests | 0 | 4 | +4 (new) |
| RefinancePDFHTMLTests | 0 | 1 | +1 (new) |
| HelocPDFHTMLTests | 0 | 1 | +1 (new) |
| IncomeQualPDFHTMLTests | 0 | 1 | +1 (new) |
| SelfEmploymentPDFHTMLTests | 0 | 2 | +2 (new, 1 skipped) |
| BreakEvenChartTests | 0 | 3 | +3 (new) |

## Commits

```
Session 5O.1  — HTML-to-PDF foundation (base.html + SignatureBlock + HTMLPDFRenderer + NestIQPrintRenderer)
Session 5O.2  — Amortization PDF migrated to HTML template
Session 5O.3  — TCA PDF migrated to HTML template with break-even SVG chart
Session 5O.4  — Refinance Comparison PDF migrated to HTML template
Session 5O.5  — HELOC vs Refinance PDF migrated to HTML template
Session 5O.6  — Income Qualification PDF migrated to HTML template
Session 5O.7  — Self-Employment PDF migrated to HTML template
Session 5O.8  — Remove legacy SwiftUI-based PDF rendering code
Session 5O.9  — Break-even chart hard-coded domain + hide when no break-even
Session 5O    — complete rollup (this commit)
```

## Deferred

- **Source Serif 4 in PDF serif stack** — Georgia is the active
  serif face; bundling Source Serif 4 into the WebKit render
  context would require data-url embedding or a custom URL scheme
  handler (WKWebView does not pick up `UIFont`-installed fonts
  automatically). Not load-bearing; Georgia is the current brand
  face when SourceSerif4 is unavailable in the rendering pipeline.
- **Server-side SIWA revocation** — carried from 5N, unchanged.

## What's next — Session 6 (TestFlight admin)

1. Remove DEBUG AuthGate bypass (`AuthGate.swift:84-91`) once the
   UI-test bypass path is satisfied by alternative means
2. Info.plist usage descriptions — `NSPhotoLibraryUsageDescription`
   (already present but re-verify copy), `NSFaceIDUsageDescription`
3. Wire real URLs — `https://nestiq.mortgage/privacy`, `/terms`,
   `/support` — into Settings + onboarding
4. Wire `support@nestiq.mortgage` into Send Feedback
5. Apple Developer team ID, enable App Store signing, archive +
   TestFlight upload
