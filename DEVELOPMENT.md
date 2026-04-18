# Quotient — Development Prompt (SwiftUI-native, iOS 18+)

> This doc is the single source of truth for the build. Designer delivered the full screen set in pass 2. Follow this doc end-to-end.

---

## Mission

Build **Quotient** — a native iOS mortgage calculator for licensed loan officers. Five calculators, branded PDF export, AI-narrated summaries, beautiful in light and dark modes. For the App Store. iPhone first, iPad landscape second.

**Five calculators — the whole product:**
1. Amortization (with extra principal, biweekly, recast)
2. Income Qualification (DTI, max qualifying loan, affordability)
3. Refinance Comparison (current loan vs up to 3 refi options)
4. Total Cost Analysis (2–4 scenarios over 5/7/10/15/30yr horizons)
5. HELOC vs Refinance

**Nothing else v1.** No CRM / LOS / e-sign / pricing engines / borrower portal / web app / co-viewing. Just the five calculators, exquisitely well.

---

## Design source of truth

The complete design handoff lives at **`/design/design_handoff_quotient/`**. Before writing any code for any screen:

1. **Read `/design/design_handoff_quotient/README.md` end-to-end.** It is the authoritative spec for visuals, tokens, motion, and interaction. When this development prompt conflicts with the design README, the design README wins.
2. **Read the token definitions** in `/design/design_handoff_quotient/design_files/tokens/`. If the CSS disagrees with the README color table, **the README wins** (the CSS files are earlier-iteration reference).
3. **Read the relevant screen JSX** before building each screen. These are reference prototypes in HTML/JSX — **do not import or transpile**. Recreate natively in SwiftUI, mapping CSS to modifiers, HTML to views, inline SVGs to SF Symbols or `Shape`-based custom drawing.
4. **Consult `Foundations.jsx`** whenever any pattern is ambiguous — it is the authoritative component/token specimen sheet.

### Full screen inventory (all delivered in this pass)

| # | Screen | File |
|---|--------|------|
| 1 | Onboarding (6-step tour) | `screens/Onboarding.jsx` |
| 2 | Home / calculator picker | `screens/Home.jsx` |
| 3 | Saved scenarios | `screens/Saved.jsx` |
| 4 | Settings (10 sections) | `screens/Settings.jsx` |
| 5 | Borrower picker (bottom sheet) | `screens/BorrowerPicker.jsx` |
| 6 | Amortization — Inputs | `screens/Inputs.jsx` |
| 7 | Amortization — Results | `screens/Amortization.jsx` |
| 8 | Income Qualification | `screens/Income.jsx` |
| 9 | Refinance Comparison | `screens/Refinance.jsx` |
| 10 | Total Cost Analysis | `screens/TCA.jsx` |
| 11 | HELOC vs Refinance | `screens/Heloc.jsx` |
| 12 | Share / PDF preview | `screens/Share.jsx` |
| 13 | PDF cover page (816×1056) | `screens/PDF.jsx` |
| 14 | Foundations reference sheet | `screens/Foundations.jsx` |

### What's NOT in the design pass (follow README section "What's NOT in this pass")

- iPad split-view and presentation-mode layouts
- Motion prototypes (behavior documented in README; visual reference not delivered)
- Full EN+ES copy doc, glossary, compliance disclosures
- Empty / error / loading states (follow iOS HIG defaults on top of the tokens)

Handle these during implementation per iOS HIG defaults + the motion specs in the design README. Don't invent token values; use what's established.

---

## Non-negotiable standards

- **Swift 6** with strict concurrency checking enabled
- **SwiftUI first** — UIKit only where SwiftUI cannot reach (e.g., `CNContactPickerViewController`, share sheet hosting, PencilKit)
- **iOS 18+ minimum deployment target**
- **Offline-first** — every calculator works without network. All scenarios on-device via SwiftData.
- **Performance:** 60fps on iPhone 13 (oldest supported with iOS 18); cold launch <1.2s; scenario recalc <30ms on every input change.
- **Accessibility:** WCAG 2.2 AA on all color pairs; full VoiceOver; Dynamic Type up to Accessibility5 without layout breaks; accessible data-table alternatives for all charts.
- **Both modes first-class** (light + dark).
- **Internationalization:** English + Spanish in v1, via `Localizable.xcstrings` catalog.
- **Finance engine tested to production grade:** ≥95% line coverage; ≥95% region coverage on reachable paths (defensive guards against validated inputs exempt when documented); ≥80% mutation score (Muter); property-based invariants; golden fixtures from Freddie Mac / Fannie Mae / CFPB.

---

## Tech stack (use exactly this)

### Core
- **Xcode 16+** with Swift 6
- **Swift Package Manager** for package modularization
- **SwiftUI** for all UI
- **Observation framework** (`@Observable` macro) for view-model state, not `ObservableObject`
- **SwiftData** for persistence (scenarios, borrowers, profile)
- **Swift Charts** (native, iOS 16+) for standard charts
- **SwiftUI `Canvas`** for custom chart primitives (balance-over-time accent marker, cumulative savings break-even dot, HELOC stress paths)
- **PDFKit** + **`ImageRenderer`** for PDF generation (render SwiftUI views directly to PDF pages)
- **Foundation.Decimal** for money math
- **Foundation.FormatStyle** for locale-aware number/currency/date/percentage formatting

### Apple frameworks
- **AuthenticationServices** for Sign in with Apple
- **LocalAuthentication** for Face ID / Touch ID unlock
- **Contacts + ContactsUI** for borrower picker
- **FoundationModels** (iOS 18.2+) for on-device AI narration
- **CoreHaptics** for haptic feedback

### Fonts
- **SF Pro Text / SF Pro Display / SF Mono** — system fonts, `.monospacedDigit()` for all numeric displays (tnum)
- **Source Serif 4** — bundle `.ttf` files (Regular, Italic, 400/500/600) in app resources; register in `QuotientApp.init()`. Used for: Quotient wordmark, onboarding titles, PDF narrative + titles. Never in in-app chrome.

### Testing
- **Swift Testing** (iOS 18+) for new tests
- **XCTest** where Swift Testing doesn't fit (e.g., `measure` benchmarks, UI tests)
- Lightweight property-based harness (write our own or use a stable SPM option)
- **Muter** for mutation testing on the finance package (nightly CI)

**Intentionally no:** third-party analytics, third-party crash reporter v1, third-party AI SDK, Alamofire (URLSession handles the one public API call).

---

## Repo structure

```
/Quotient/                      ← repo root
├── Quotient.xcodeproj
├── App/                        ← main iOS app target
│   ├── QuotientApp.swift
│   ├── Root/
│   │   ├── RootView.swift
│   │   └── AuthGate.swift
│   ├── Features/
│   │   ├── Onboarding/         ← Onboarding.jsx
│   │   ├── Home/               ← Home.jsx
│   │   ├── SavedScenarios/     ← Saved.jsx
│   │   ├── Settings/           ← Settings.jsx
│   │   ├── BorrowerPicker/     ← BorrowerPicker.jsx
│   │   ├── Calculators/
│   │   │   ├── Amortization/   ← Inputs.jsx + Amortization.jsx
│   │   │   ├── IncomeQualification/  ← Income.jsx
│   │   │   ├── Refinance/      ← Refinance.jsx
│   │   │   ├── TotalCostAnalysis/    ← TCA.jsx
│   │   │   └── HelocVsRefinance/     ← Heloc.jsx
│   │   └── Share/              ← Share.jsx
│   ├── Components/             ← reusable SwiftUI primitives
│   ├── Theme/
│   │   ├── Tokens.swift
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   ├── Spacing.swift
│   │   └── Motion.swift
│   ├── Resources/
│   │   ├── Assets.xcassets     ← app icons, ColorSets, custom icons
│   │   ├── Fonts/              ← SourceSerif4 ttf files
│   │   └── Localizable.xcstrings
│   ├── Info.plist
│   └── PrivacyInfo.xcprivacy
├── Packages/
│   ├── QuotientFinance/        ← pure Swift calc engine
│   ├── QuotientCompliance/     ← state disclosures, NMLS helpers, ATR-QM
│   ├── QuotientPDF/            ← PDF generation via ImageRenderer
│   └── QuotientNarration/      ← FoundationModels wrapper + templates
├── design/                     ← design handoff (READ-ONLY REFERENCE)
│   └── design_handoff_quotient/
│       ├── README.md
│       └── design_files/
├── DEVELOPMENT.md              ← this file
├── DECISIONS.md
├── KICKOFF-SESSION-1.md
├── README.md
├── .gitignore
├── .swift-version
└── .github/
    └── workflows/
        └── ci.yml
```

The `design/` directory is **read-only reference** for Claude Code. Never modify it.

---

## `QuotientFinance` — calculation engine

Pure Swift package. Zero dependencies on UIKit or SwiftUI. Deterministic. Exhaustively tested.

### Primitives
All money as `Foundation.Decimal`. All rates as `Double`. Day-count convention stated in doc comments on every function.

- `amortize(loan:options:) -> AmortizationSchedule`
- `calculateAPR(loan:closingCosts:) -> Double` (Reg Z Appendix J)
- `calculateAPOR(loanType:lockDate:) -> Double` (embedded quarterly table)
- `isHPML`, `isHPCT`
- `calculatePITI(loan:taxes:insurance:hoa:pmi:) -> Decimal`
- `calculatePMI(ltv:creditScore:loanAmount:loanType:paymentType:) -> Decimal`
- `calculateLTV / CLTV / HCLTV`
- `calculateDTI(monthlyDebts:grossMonthlyIncome:frontEnd:) -> Double`
- `calculateMaxQualifyingLoan(income:debts:rate:term:taxes:insurance:hoa:dtiCap:loanType:) -> Decimal` (inverse amortization)
- `calculateQMStatus(loan:borrowerProfile:) -> QMDetermination`
- `npv`, `irr`, `xnpv`, `xirr`
- `paymentFor`, `presentValue`, `futureValue`, `compoundGrowth`
- `blendedRate(loans:) -> Double`
- `breakEvenMonth(refiScenario:currentLoan:) -> Int`
- `effectiveRate`, `nominalToEffective`, `effectiveToNominal`

### Specialized handlers
- `applyExtraPrincipal`, `applyRecast`, `convertToBiweekly`
- `compareScenarios(_:horizons:) -> ComparisonResult` — backbone of Refi Comparison + TCA
- `simulateHelocPath(firstLien:helocParams:ratePath:) -> HelocSimulation` — HELOC vs Refi

### Conventions
- 30/360 default for conventional/FHA/VA/USDA
- actual/365 for HELOC
- Per-index for ARMs (SOFR=actual/360, Treasury=actual/actual)
- Every function JSDoc-style comment declares its convention

### Testing gate
- ≥95% line coverage
- ≥95% region coverage on reachable paths (defensive guards against validated inputs exempt when documented in the session summary)
- ≥80% Stryker/Muter mutation score
- Golden fixtures from Freddie Mac Exhibit 5, Fannie Mae Selling Guide, CFPB Reg Z Appendix J examples, Bankrate schedules, VA funding fee, FHA MIP
- Property-based invariants (write a small PBT harness):
  - `sum(principal) == loanAmount` fully amortized
  - `sum(principal) + sum(interest) == sum(payment)` ± 0.01
  - Balance monotonically non-increasing without extras
  - `APR >= noteRate` when closing costs > 0
  - Biweekly = exactly 26 payments/year
  - PMI drops at 78% LTV per original schedule
  - Recast reduces monthly payment and total interest
- Performance: `amortize(360)` < 5ms; `compareScenarios(4 × 30yr)` < 50ms

**Gate: no app UI code until `QuotientFinance` passes everything above.**

---

## `QuotientCompliance`

Public API:
```swift
public func requiredDisclosures(for scenarioType: ScenarioType, propertyState: USState, ruleVersion: ComplianceRuleVersion = .current) -> [Disclosure]
public func nmlsConsumerAccessURL(for nmlsId: String) -> URL
public func equalHousingOpportunityStatement(locale: Locale) -> String
public func requiredDisclaimer(context: DisclaimerContext, locale: Locale) -> String
```

### State disclosure library
- `Sources/QuotientCompliance/Disclosures/{StateCode}.swift` — one file per state
- Populate top 10 + IA first: CA, TX, FL, NY, IL, PA, OH, GA, NC, MI, IA
- Remaining stubbed with generic disclosure + `needsCounselReview = true` flag
- Compliance counsel review cycle during Session 5

### Rule versioning
Every saved scenario records its rule version so old scenarios reproduce identically when regenerated later.

---

## `QuotientNarration`

Two paths, unified by capability check at runtime.

### Primary: Apple Foundation Models (iOS 18.2+)
```swift
import FoundationModels

public func narrateScenario(
    scenarioType: ScenarioType,
    facts: ScenarioFacts,
    audience: NarrationAudience,  // .borrower | .loInternal
    locale: Locale
) -> AsyncThrowingStream<String, Error>
```

- System prompt: "You are a mortgage advisor summarizing analysis for a borrower. Use plain English. The numbers provided are authoritative — never invent numbers."
- Uses `@Generable` structured output where possible for hallucination safety
- Post-processing: regex-check any numeric mention against a known-facts allowlist; strip or warn on unknown numbers
- Streams token-by-token
- Max ~200 words (borrower summary), ~400 words (PDF narrative)

### Fallback: template-based narration
For devices without Foundation Models (pre-A17 Pro on iOS ≤18.1 or API unavailable):
- `Sources/QuotientNarration/Templates/{ScenarioType}.swift` — Swift string interpolation
- Indistinguishable quality for structured financial summaries
- EN + ES variants

### Capability detection
```swift
public var hasFoundationModels: Bool {
    if #available(iOS 18.2, *) {
        return SystemLanguageModel.default.isAvailable
    }
    return false
}
```

Both paths produce the same output contract. UI auto-selects silently.

---

## `QuotientPDF`

SwiftUI views rendered to PDF via `ImageRenderer` + `CGContext.pdfContext`, assembled with PDFKit's `PDFDocument`.

### Public API
```swift
public func generatePDF(
    scenario: any Scenario,
    profile: LenderProfile,
    narrative: String,
    ruleVersion: ComplianceRuleVersion = .current
) async throws -> URL
```

Returns a temp file URL; caller shares via `ShareLink` or `UIActivityViewController`.

### Pages
- **Cover** — exactly per `screens/PDF.jsx` spec (816×1056, 48pt margins, Source Serif 4 wordmark, LO contact right block, hero strip, narrative paragraphs, mini chart preview, compliance footer)
- **Body** pages per calculator type (schedule for Amortization, comparison tables for Refi/TCA, stress paths for HELOC, etc.)
- **Disclaimers** appendix — state-specific from `QuotientCompliance` based on borrower property state
- Every page: footer with "Page X of Y" in mono 9.5pt, compliance line

---

## App target — screens

Every screen maps to a delivered JSX file. Implement in SwiftUI. Match pixel values, type scale, surfaces, borders, motion from the JSX + `Foundations.jsx` specimen sheet.

### 1. Onboarding (`screens/Onboarding.jsx`)
6-step tour. Step 1 = welcome; steps 2–6 = one per calculator. Top: "N / 6" mono counter + dotted progress. Per step: eyebrow + Source Serif 4 title + paragraph + lower-60% in-situ miniature of that calculator's signature output (KPI card / chart sparkline / table fragment). Dock: Skip (left) / Next (primary accent). Crossfade 260ms between steps; progress dots animate left-to-right. First-launch only; Settings → About → Replay tour.

### 2. Home (`screens/Home.jsx`)
Greeting block with date eyebrow + avatar; rate ribbon (horizontal scroll: 30yr / 15yr / ARM / FHA / VA / Jumbo); numbered calculators list (01–05); recent scenarios vertical stack; tab bar (Calculators / Scenarios / Settings). Translucent tab bar with backdrop blur.

### 3. Saved Scenarios (`screens/Saved.jsx`)
Search + filter chips (All / Amort / Refi / TCA / HELOC / Income); list grouped by date bucket (Today / This week / Earlier). Row: calculator label pill (mono) + borrower name 16pt 600 + mono key stat + right-aligned timestamp. Swipe actions: Archive / Share / Duplicate / Delete.

### 4. Settings (`screens/Settings.jsx`)
iOS grouped list (inset cards, 26pt radius). 10 sections: **Profile** (avatar, name, NMLS#, license states); **Brand** (accent color swatches, logo, PDF header style); **Disclaimers** (per-state compliance text with count); **Appearance** (Light/Dark/Auto, Density Comfortable/Compact); **Language** (EN/ES); **Haptics & sounds** (toggles); **Privacy** (Face ID lock, share app analytics); **Data** (Export CSV/JSON, Backup to iCloud); **Support** (Contact, Rate app, Feedback); **About** (Version, Legal, Licenses, Replay tour). 17pt row text; values/disclosure right-aligned.

### 5. Borrower Picker (`screens/BorrowerPicker.jsx`)
Bottom sheet (~78% height) with grabber; search field; 3 tabs (Recents / Contacts / New). Contact row: initials circle + name + 1-line context. Sticky "+ New borrower" button at bottom. Contacts tab invokes `CNContactPickerViewController` via UIKit bridge.

### 6–7. Amortization — Inputs + Results (`screens/Inputs.jsx`, `screens/Amortization.jsx`)
Inputs: Back + breadcrumb "01 · Amortization" + title "New scenario"; borrower pill; Loan section (Loan amount, Interest rate, Term 6-segment, Start date); Property section (Taxes, Insurance, HOA, PMI toggle); Advanced accordion. CTA "Compute amortization". Results: borrower block with GEN-QM badge + mono terms; Hero PITI block ($ prefix + 46pt mono tnum + .00 + 4-col KPI row); Balance over time chart 362×170 with area fill + accent line + year-10 marker; PITI breakdown stacked horizontal bar + 2-col legend; 5-col schedule table; bottom dock: Narrate / Save / Share as PDF. After first Compute, inputs edits live-update results.

### 8. Income Qualification (`screens/Income.jsx`)
Hero: Max qualifying loan (46pt mono). Two dials: Front-end DTI (agency limit 28%) and Back-end DTI (43/45/50% by program). Qualifying income list (W-2 / self-employed / rental / other — each with mono value + % weight). Debts list (cards, auto, student, other). Resulting residual income displayed. CTA "Run scenario" → opens Amortization pre-filled with qualifying loan.

### 9. Refinance Comparison (`screens/Refinance.jsx`)
Nav + borrower block. Option tabs (Current / A / B / C) with color swatch + optional "best" tag + active-tab 2pt accent underline. Winner hero on `--surface-raised`: "Save $X/mo" composed row + 3-col KPI (Break-even / Lifetime Δ / NPV @ 5%). Cumulative savings chart 362×190 with zero line, faint non-winning curves, bold accent winner curve, break-even marker. Side-by-side 5-col table (Rate / Term / Points / Closing / Payment / Break-even / Lifetime Δ) with winners in `--gain` 600. Narrative card. Bottom dock: Stress test / Share as PDF.

### 10. Total Cost Analysis (`screens/TCA.jsx`)
2–4 scenario columns × rows per horizon (5/7/10/15/30yr). Each cell = mono total cost; winner per row bolded in `--gain` with check glyph. Option tabs at top with per-scenario stripe colors. Narrative card below. Horizon rows sort vertically.

### 11. HELOC vs Refinance (`screens/Heloc.jsx`)
Blended rate hero (current 1st + new HELOC = blended effective %). Side-by-side columns: Cash-out refi vs HELOC (showing draw/repay periods, intro rate, index+margin). Stress paths chart with 3 curves (rate flat / +1% / +2%) over 10-year cost.

### 12. Share / PDF preview (`screens/Share.jsx`)
Paged carousel: Cover / Schedule / Disclaimers with dots indicator top. Each page is a full PDF-page thumbnail, pinch-to-zoom. Recipient row top: borrower name + email + "Change". Bottom action dock: Message, Mail, AirDrop, Copy link, Print, Save to Files — invokes `UIActivityViewController` with the generated PDF.

### 13. PDF cover page (`screens/PDF.jsx`)
Per spec (unchanged from pass 1): 8.5×11 portrait, 48pt margins, Source Serif 4 wordmark (30pt) + LO contact block header, eyebrow + H1 "For *Name*" Source Serif 4 38pt italic emphasis, hero strip with 4-col KPI hairline dividers, 2 narrative paragraphs Source Serif 4 16pt, mini chart preview, footer with compliance line + page numbers in mono.

### 14. Foundations (`screens/Foundations.jsx`)
Not a product screen — authoritative specimen sheet. Reference throughout implementation.

---

## Rate snapshot endpoint (the one external call)

Single serverless function deployed to **Vercel Edge** or **Cloudflare Workers** (Nick's call in DECISIONS.md).

- Public endpoint: `GET https://rates.quotient.app/api/rates` (or similar)
- Returns: `{ rates: { "30yr": 6.85, "15yr": 6.12, "5_6arm": 6.45, "fha30": 6.52, "va30": 6.28, "jumbo30": 7.05 }, asOf: "2026-04-17T12:00:00Z" }`
- Backed by FRED API (free; server-side key); cached 1 hour in KV
- No per-user logging, no auth, no PII

App hits on launch + pull-to-refresh on Home. Falls back to last cached value on failure.

**Tech:** Hono + TypeScript on Vercel Edge OR simple `fetch` handler on Cloudflare Workers. ~50 lines. Lives in `rates-proxy/` folder in the Quotient repo or a tiny separate repo.

---

## Data model (SwiftData)

```swift
@Model final class LenderProfile {
    @Attribute(.unique) var id: UUID = UUID()
    var appleUserID: String
    var firstName: String
    var lastName: String
    var photoData: Data?
    var nmlsId: String
    var licensedStates: [String]
    var companyName: String
    var companyLogoData: Data?
    var brandColorHex: String
    var phone: String
    var email: String
    var tagline: String?
    var preferredLanguage: String
    var faceIDEnabled: Bool
    var hapticsEnabled: Bool
    var densityPreference: DensityPreference  // .comfortable | .compact
    var appearance: AppearancePreference      // .light | .dark | .system
    var createdAt: Date
    var updatedAt: Date
}

@Model final class Borrower {
    @Attribute(.unique) var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var email: String?
    var phone: String?
    var propertyAddress: String?
    var propertyState: String?   // drives PDF disclosures
    var propertyZip: String?
    var notes: String?
    var source: BorrowerSource   // .contacts | .manual | .recent
    var contactIdentifier: String?
    @Relationship(deleteRule: .cascade) var scenarios: [Scenario] = []
    var createdAt: Date
    var updatedAt: Date
}

@Model final class Scenario {
    @Attribute(.unique) var id: UUID = UUID()
    @Relationship(inverse: \Borrower.scenarios) var borrower: Borrower?
    var calculatorType: CalculatorType  // .amortization | .incomeQual | .refinance | .tca | .heloc
    var name: String
    var inputsJSON: Data
    var outputsJSON: Data
    var narrative: String?
    var notes: String?
    var archived: Bool
    var complianceRuleVersion: String
    var createdAt: Date
    var updatedAt: Date
}
```

iCloud backup on via default iOS mechanism. Defer full CloudKit sync for post-v1.

---

## Theme (App/Theme/)

Map the design tokens from `design/design_handoff_quotient/README.md` to Swift. Use Asset Catalog `ColorSet` for automatic light/dark switching.

### Colors (`Colors.swift`)
Every semantic color defined as a `ColorSet` in `Assets.xcassets` with Any/Dark pair. Reference via `Color("surface")`, `Color("accent")`, etc. Source values from the README Color table — both light and dark variants.

Key tokens:
- Surfaces: `surface`, `surfaceRaised`, `surfaceSunken`, `surfaceDeep`
- Borders: `borderSubtle`, `borderDefault`, `borderStrong`
- Ink: `ink`, `inkSecondary`, `inkTertiary`, `inkQuaternary`
- Accent: `accent` (ledger green #1F4D3F light / #4F9E7D dark), `accentHover`, `accentFG`, `accentTint`
- Semantic: `gain`, `gainTint`, `loss`, `lossTint`, `warn`, `warnTint`
- Chart: `grid`
- 4-color scenario palette: `scenario1` (green), `scenario2` (blue), `scenario3` (wine), `scenario4` (umber)

### Typography (`Typography.swift`)
Type scale exactly per README:
- `display` 34/700/-0.02em
- `title` 26–28/700/-0.02em
- `h2` 22/700/-0.015em
- `section` 15/600/-0.01em
- `bodyLg` 14/500
- `body` 13/400
- `bodySm` 12.5/400
- `eyebrow` 11/600/+0.09em tracked UPPERCASE
- `micro` 10.5/600/+0.08em tracked
- `numHero` 46/mono 500/-0.02em/tnum
- `numLg` 22–26/mono 500/-0.01em/tnum
- `num` 12–15/mono/tnum

Fonts: SF Pro (system) sans; SF Mono `.monospacedDigit()` for all numbers; Source Serif 4 (bundled) for wordmark + onboarding titles + PDF.

### Radius (`Spacing.swift` or `Radius.swift`)
`2 (chart bars), 3 (mono chips), 4 (swatches), 6 (segmented), 8 (default), 10 (list cards), 12 (CTAs/heroes), 14 (grouped list), 26 (iOS grouped list), 999 (pills)`

### Motion (`Motion.swift`)
```swift
enum Motion {
    static let fast: Duration = .milliseconds(120)
    static let `default`: Duration = .milliseconds(180)
    static let slow: Duration = .milliseconds(260)
    static let numberTween: Duration = .milliseconds(400)
    static let chartDraw: Duration = .milliseconds(600)
}
```

Easing: `cubic-bezier(0.2, 0, 0, 1)` out; `cubic-bezier(0.4, 0, 0.2, 1)` in-out. Respect `@Environment(\.accessibilityReduceMotion)` — when true, drop transforms, keep opacity.

---

## Components (App/Components/)

Build these before screens. Every component: light + dark + all states + Dynamic Type tested + reduced-motion variant + `#Preview` block.

1. `PrimaryButton` / `SecondaryButton` / `GhostButton` / `DestructiveButton`
2. `CurrencyField` / `PercentageField` / `NumberField` / `TextField` with prefix/suffix + active/error states
3. `SegmentedControl` (term selection: 10/15/20/25/30/40)
4. `Toggle` (42×24 pill matching design)
5. `Card` (flat + raised)
6. `HairlineDivider`
7. `Eyebrow` (uppercase tracked label)
8. `MonoNumber` (SF Mono + tnum + size variants)
9. `DataRow` (label + value pair)
10. `KPITile` (big number + micro label)
11. `StackedHorizontalBar` (PITI breakdown)
12. `DTIDial` (gauge-style circular progress for Income Qualification)
13. `BalanceOverTimeChart` (Swift Charts wrapper + accent line + year marker)
14. `CumulativeSavingsChart` (Swift Charts + break-even dot marker)
15. `ComparisonGroupedBars` (for TCA row cells)
16. `StressPathsChart` (3-curve overlay for HELOC)
17. `AmortizationScheduleTable` (virtualized `List` with custom row)
18. `BorrowerPill`
19. `ScenarioCard` (for Saved + Home recent)
20. `CalculatorListRow` (for Home 01–05)
21. `RateRibbonCell`
22. `BottomActionDock` (Narrate / Save / Share)
23. `AssumptionsDrawer` (sheet)
24. `NarrationDrawer` (sheet with streaming text)
25. `OnboardingStep` (eyebrow + serif title + paragraph + miniature)
26. `SettingsRow` + `SettingsSection`
27. `FilterChip` (for Saved filters)
28. `DatePill` (for Saved grouped headers: "Today" / "This week" / "Earlier")

Each lives in `App/Components/`, has a `#Preview` block covering light + dark + Dynamic Type variants, token usage in doc comments.

---

## Build order — 5 Claude Code sessions

### Session 1: Xcode scaffold + `QuotientFinance` core
- Xcode project (iOS 18+, SwiftUI lifecycle, Swift 6 strict concurrency)
- Local SPM packages: `QuotientFinance`, `QuotientCompliance`, `QuotientPDF`, `QuotientNarration` (three placeholders + one actual)
- SwiftLint + `.swiftlint.yml`
- GitHub Actions CI: build + test + lint + coverage
- `QuotientFinance` core primitives (all listed above)
- Golden fixtures + property-based tests + perf benches
- Muter configured for nightly mutation testing
- **Gate: ≥95% coverage, all property invariants pass, perf benches green**

### Session 2: `QuotientFinance` advanced + `QuotientCompliance` + Theme + Components
- Specialized handlers: `applyExtraPrincipal`, `applyRecast`, `convertToBiweekly`, `compareScenarios`, `simulateHelocPath`
- `QuotientCompliance`: state disclosure library (top 10 + IA), NMLS helpers, ATR/QM decision tree, HPML/HPCT, disclaimer templates (EN + ES)
- `App/Theme/`: Tokens, Colors (via ColorSet assets), Typography (register Source Serif 4), Spacing/Radius, Motion
- `App/Components/`: all 28 components listed above, each with `#Preview`
- In-app component gallery at Settings → About → Component gallery (debug-only)
- **Gate: all finance tests still green; Theme matches design token table exactly; all Components render in light + dark + Dynamic Type Accessibility5 without breaking**

### Session 3: App shell + Onboarding + Home + Saved + Settings + BorrowerPicker + Amortization (flagship)
- Root view: AuthGate → Onboarding (if profile unset) → Root Tab Bar
- Sign in with Apple (AuthenticationServices)
- Face ID unlock (LocalAuthentication)
- **Onboarding** 6-step tour exactly per `screens/Onboarding.jsx`
- **Home** exactly per `screens/Home.jsx`
- Rate snapshot fetch from Vercel Edge endpoint (+ pull-to-refresh)
- **Saved Scenarios** exactly per `screens/Saved.jsx`
- **Settings** exactly per `screens/Settings.jsx` (all 10 sections)
- **Borrower Picker** bottom sheet exactly per `screens/BorrowerPicker.jsx` with `CNContactPickerViewController` bridge
- **Amortization Inputs** exactly per `screens/Inputs.jsx`
- **Amortization Results** exactly per `screens/Amortization.jsx`
- Save scenario / load from Saved / edit / duplicate / archive
- Xcode UI Tests: onboarding → first scenario → save → re-open → edit
- **Gate: LO can sign up, onboard, manage borrowers, build + save + resume Amortization scenarios. Design QA against JSX references with zero pixel discrepancies.**

### Session 4: Remaining calculators + Narration + PDF + Share
- **Income Qualification** exactly per `screens/Income.jsx`
- **Refinance Comparison** exactly per `screens/Refinance.jsx`
- **Total Cost Analysis** exactly per `screens/TCA.jsx`
- **HELOC vs Refinance** exactly per `screens/Heloc.jsx`
- `QuotientNarration` package: FoundationModels wrapper with streaming API; template fallback; EN + ES variants per calculator
- Narration drawer UI in every calculator (streaming token rendering + regenerate + accept)
- `QuotientPDF` package: cover page per `screens/PDF.jsx` + per-calculator body pages + disclaimers appendix
- **Share preview** exactly per `screens/Share.jsx` (paged carousel + dots indicator + pinch-to-zoom + recipient row + action dock)
- Native share sheet via `UIActivityViewController` / SwiftUI `ShareLink`
- Stress-test toggle on Refinance (3yr / 5yr / 10yr early-sale re-evaluation)
- **Gate: all 5 calculators functional; narration streams and falls back gracefully; PDFs generate + share works; Share carousel matches design**

### Session 5: Polish + i18n + a11y + iPad + TestFlight + App Store
- Full Spanish pass — every string in `Localizable.xcstrings`; native-speaker review
- Accessibility: VoiceOver on every screen (rotor-friendly), Dynamic Type to Accessibility5, reduced motion variants, high contrast mode, accessible data tables for every chart
- iPad landscape layouts (pattern-match against iPhone; split-view: inputs 40% / output 60%). Not delivered in design — apply iOS HIG defaults on top of existing tokens + pattern from iPhone
- Empty / error / loading / offline states (per `"What's NOT in this pass"` — apply iOS HIG defaults)
- App Store assets:
  - App icons (1024 master + iOS 18 light/dark/tinted)
  - Screenshots: iPhone 6.7" + iPad 12.9", 5+ each, EN + ES
  - 30s app preview video
  - Description, keywords, promotional text
  - Privacy Policy + Terms (static HTML hosted somewhere)
- `PrivacyInfo.xcprivacy` declaring data collection (no tracking, no IDFA)
- Info.plist usage strings
- Demo account for App Store reviewer (seeded LenderProfile + 10 sample scenarios across calculator types)
- Compliance counsel final review of state disclosure library
- TestFlight external testing with 10–20 LOs, 4-week minimum
- Hotfix loop + exit criteria
- App Store submission with manual release
- **Gate: App Store approval received; GA date set**

---

## App Store submission essentials

### Apple Developer
- Perlantir AI Studio enrollment, $99/yr, 2FA on Apple ID

### Bundle + metadata
- Bundle ID: `ai.perlantir.quotient` (confirm in DECISIONS.md)
- Category: Finance (primary), Business (secondary)
- Age rating: 4+
- No tracking, no IDFA → ATT not required → faster review

### Privacy manifest
- Data collected (user-entered, local only): NMLS ID, name, email, phone
- Data NOT collected: location, health, third-party analytics, advertising identifiers
- Required reason APIs declared: UserDefaults (CA92.1), FileTimestamp (C617.1), SystemBootTime (35F9.1), DiskSpace (E174.1)
- Third-party SDKs: none

### Info.plist usage strings
- `NSCameraUsageDescription` — "Capture your company logo or your professional photo."
- `NSPhotoLibraryUsageDescription` — "Choose your company logo or professional photo."
- `NSContactsUsageDescription` — "Quickly add borrowers from your contacts."
- `NSFaceIDUsageDescription` — "Unlock Quotient securely with Face ID."

### Compliance framing
- Welcome screen: "Quotient is a professional tool for licensed mortgage loan officers. Not consumer financial advice. Not a commitment to lend."
- Every PDF carries the full compliance footer from `QuotientCompliance`

### Demo account
Seeded `LenderProfile` + 10 sample scenarios across all 5 calculator types. Credentials in submission notes.

---

## Testing gates (before GA)

- [ ] `QuotientFinance` ≥95% line coverage; ≥95% region coverage on reachable paths (defensive guards exempt when documented); ≥80% mutation score
- [ ] All property-based invariants pass
- [ ] All golden fixtures match published values
- [ ] UI Tests: onboarding → build + save scenario (each of 5 types) → share as PDF → all green
- [ ] Performance: 60fps during chart animations on iPhone 13; cold launch <1.2s on iPhone 15 Pro; recalc <30ms
- [ ] Accessibility: VoiceOver every screen, Dynamic Type Accessibility5 without breaking, axe-like audit passes
- [ ] i18n: 100% strings EN + ES, native-speaker review on ES
- [ ] Compliance: state disclosures correct for all 50 states (counsel-reviewed)
- [ ] Design QA: every built screen matches its JSX reference with zero functional deviation — run Figma (or JSX HTML) side-by-side with TestFlight build
- [ ] TestFlight exit: 4 weeks, 10+ beta LOs, no critical bugs final 3 weeks
- [ ] App Store: privacy manifest accurate, screenshots match reality, demo account works, disclaimers everywhere required

---

## Nick-calls (answer in DECISIONS.md before Day 1)

1. **Bundle ID** — default `ai.perlantir.quotient`
2. **Apple Developer enrollment** — Perlantir AI Studio
3. **Monetization v1** — free during TestFlight, IAP subscription at GA (design doesn't change)
4. **Compliance counsel** — engage mortgage compliance attorney by Day 14
5. **FRED API key** — free at fred.stlouisfed.org
6. **Rate snapshot hosting** — Vercel Edge vs Cloudflare Workers
7. **Privacy policy + terms URLs** — host static HTML; lawyer review before GA
8. **Support email** — for App Store metadata
9. **TestFlight beta LO list** — recruit 15–20 LOs by Week 6

---

## Out of scope v1 (do not build)

Web app, borrower portal, interactive share links, real-time co-viewing, video/voice recording, cloud sync beyond iCloud backup, third-party AI API, CRM/LOS/e-sign/pricing/AVM/credit/calendar integrations, fair lending AI model, HMDA capture, multi-tenant features, push notifications beyond user-configured rate alerts, Apple Watch, widgets beyond a simple rate widget, Dynamic Island live activities, Android.

Data model accommodates future expansion without rework.

---

## Operating principle

Quotient is a serious financial instrument for licensed professionals. Every calculation holds up to CFPB scrutiny. Every disclosure is correct per state. Every pixel matches the designer's intent. Every animation has purpose. When in doubt, pick the harder, more rigorous path.

The design handoff is deliberate and complete for iPhone. Respect it. Where the handoff is silent (iPad layouts, empty/error states, motion prototypes), apply iOS HIG defaults on top of the established tokens — don't invent new ones.

Ship the best mortgage calculator that has ever existed on iOS.
