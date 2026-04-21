# NestIQ

Native iOS mortgage calculator for licensed loan officers. Professional-grade
scenario analysis, borrower-facing PDF exports, and compliance-aware outputs —
the tool LOs actually use with clients, not a consumer-rate Zillow calculator.

![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![Platform](https://img.shields.io/badge/iOS-18%2B-blue)
![License](https://img.shields.io/badge/License-Proprietary-red)

---

## Status

**v0.1.0 (Build 2)** — live on internal TestFlight as of 2026-04-20.

Bundle ID: `mortgage.nestiq` · Team: Uber Kiwi LLC (7JL22TDB44) · Domain:
[nestiq.mortgage](https://nestiq.mortgage)

## What it does

- **Six calculators**: Amortization, Income Qualification, Refinance
  Comparison, Total Cost Analysis (TCA), HELOC vs Refinance, and
  Self-Employment (Fannie Form 1084 cash flow)
- **Borrower persistence** with SwiftData — save borrower profiles with full
  current-mortgage context, reuse across calculators and scenarios
- **HTML-to-PDF export** — borrower-facing documents rendered via
  UIPrintPageRenderer with inline SVG charts; cream paper, ledger-green
  accent, TILA safe-harbor disclosure on every page
- **Live market rates** — Freddie Mac PMMS 30- and 15-year fixed averages
  pulled weekly from FRED, displayed with "market average, not an offer of
  credit" attribution
- **Sign in with Apple** authentication with Associated Domains
- **Scenario comparisons** — multi-scenario break-even, reinvestment, and
  equity-buildup analysis over 5/7/10/15/30-year horizons

## Codebase naming

User-facing brand is **NestIQ**. Internal code, module names, Xcode target,
and git repository stay **Quotient** — preserved to maintain git history
through the rebrand. Bundle ID (`mortgage.nestiq`) and display name
(`NestIQ`) are the only product-facing identifiers.

When reading the codebase, `QuotientFinance`, `QuotientPDF`, etc. are NestIQ
modules — the names are legacy.

## Architecture

### Packages

Four Swift packages, all local to the repo:

| Package | Purpose |
|---|---|
| `QuotientFinance` | Calculation engine — amortization math, Fannie 1084 primitives, break-even, current-mortgage helpers. Pure Swift, fully tested. |
| `QuotientCompliance` | LO compliance content and TILA-aligned disclosure text |
| `QuotientNarration` | AI-assisted scenario summaries |
| `QuotientPDF` | PDF inspector utilities (rendering itself lives in `App/Features/Share/`) |

### Persistence

SwiftData with a JSON-blob + computed-accessor pattern for Codable value
types. Native SwiftData bridging for non-primitive types proved unreliable
(see D7/D9 in `DECISIONS.md`), so Codable payloads are stored as `Data?`
with a computed property handling encode/decode:

```swift
// Storage field (what SwiftData sees)
public var currentMortgageJSON: Data? = nil

// Computed accessor (what code uses)
public var currentMortgage: CurrentMortgage? {
    get {
        guard let data = currentMortgageJSON else { return nil }
        return try? JSONDecoder().decode(CurrentMortgage.self, from: data)
    }
    set {
        currentMortgageJSON = newValue.flatMap { try? JSONEncoder().encode($0) }
    }
}
```

This pattern is used for `Borrower.currentMortgage`,
`Borrower.licensedStates`, and `Scenario.inputs` / `Scenario.outputs`.

### PDF pipeline

`UIPrintPageRenderer` + `WKWebView.viewPrintFormatter()` + Core Graphics
header/footer callbacks + inline SVG for charts. The older SwiftUI
`ImageRenderer` and `WKWebView.createPDF` approaches both hit
dealbreakers — see D8 in `DECISIONS.md` for the full rationale.

Shared design tokens (cream `#FAF9F5`, ledger green `#1F4D3F`, Georgia
headings, SF Mono data) are defined in `App/Resources/PDFTemplates/base.html`
and reused across all six calculators.

### Rate data

Live Freddie Mac Primary Mortgage Market Survey (PMMS) rates via the
[Federal Reserve Economic Data (FRED) API](https://fred.stlouisfed.org/),
series `MORTGAGE30US` and `MORTGAGE15US`. PMMS publishes weekly on Thursdays;
the widget displays Freddie's observation date, not the fetch timestamp.
24-hour cache with offline fallback.

## Build

**Required tooling:**

```bash
brew install xcodegen swiftlint xcbeautify
```

**Build and run:**

```bash
xcodegen generate
open Quotient.xcodeproj
# Then ⌘R from Xcode
```

`project.yml` is authoritative — all signing, capabilities, entitlements,
Info.plist contents, and build settings live there. **Edits through the
Xcode UI will be overwritten on the next `xcodegen generate`.** Change
`project.yml`, regenerate, commit both.

A valid FRED API key must be set in `project.yml` under `FREDAPIKey`. Free
to register at
[fredaccount.stlouisfed.org](https://fredaccount.stlouisfed.org/apikeys).
Without it, the rate widget falls back to hardcoded values with an
"offline" label — the rest of the app functions normally.

## Testing

```bash
# Full suite via Xcode
⌘U

# Or via xcodebuild
xcodebuild -project Quotient.xcodeproj -scheme Quotient \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Six test surfaces: `QuotientTests` (app), `QuotientFinance`,
`QuotientCompliance`, `QuotientNarration`, `QuotientPDF`, and
`QuotientUITests`. SwiftLint runs as a strict pre-build phase;
`SWIFT_TREAT_WARNINGS_AS_ERRORS` is on in both Debug and Release.

Current count: **502+ tests, 0 failures, 1 conditional skip.**

Package-level testing (fastest iteration for finance engine work):

```bash
cd Packages/QuotientFinance
swift test
```

## Project structure

```
.
├── App/                  Main app target — views, features, services, models
├── Packages/             Four local Swift packages
├── AppTests/             App-level unit tests
├── AppUITests/           UI tests
├── brand/                Logo pack and brand assets
├── design/               Design tokens, mockups (read-only)
├── Quotient.entitlements SIWA + Associated Domains
├── project.yml           XcodeGen manifest — source of truth
├── DECISIONS.md          Architectural decisions log (D1–D10 locked)
├── DEVELOPMENT.md        Internal build spec and conventions
└── SESSION-*.md          Per-sprint summaries, chronological build history
```

## Decisions

All architectural, vendor, and scope calls are recorded in `DECISIONS.md`
with dated rationale. D1 through D10 are **locked** — they have
implementations depending on them and should not be revisited without
explicit cause.

Highlights:

- **D1** APR is display-only, never drives calculations (TILA § 1026.22 out of scope)
- **D7** Scenario persistence via JSON-blob Codable payloads
- **D8** PDF rendering via `UIPrintPageRenderer` + `WKWebView` + inline SVG
- **D9** `CurrentMortgage` lives on `Borrower` via JSON-blob + computed accessor
- **D10** `Borrower`→`Scenario` relationship uses `.nullify` delete rule

When `DEVELOPMENT.md` and `DECISIONS.md` disagree, `DECISIONS.md` wins.

## Session log

Each sprint is captured in a `SESSION-*-SUMMARY.md` file committed at
session close. These serve as the project's changelog and are the best
source for understanding how the codebase arrived at its current shape.

Most recent: `SESSION-6-SUMMARY.md` (TestFlight admin prep + live FRED
rates).

## License

Copyright © 2026 Uber Kiwi LLC. All rights reserved.
See [LICENSE](./LICENSE) for details.

## Acknowledgments

Mortgage rate data courtesy of Freddie Mac Primary Mortgage Market Survey®
(PMMS®) via [Federal Reserve Economic Data (FRED)](https://fred.stlouisfed.org/),
Federal Reserve Bank of St. Louis. PMMS is a registered trademark of
Freddie Mac. Source Serif 4 typeface is licensed under the SIL Open Font
License.
