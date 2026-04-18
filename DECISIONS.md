# Quotient Decisions

Every architectural / vendor / strategic call that affects the build lives here. Claude Code reads this file before every session. When an entry is blank or says `TBD`, Claude Code pauses and asks before picking a default.

---

## Tier 0 — Answer before Session 1

1. **Bundle ID** — `ai.perlantir.quotient`
2. **Apple Developer enrollment** — `TBD` (in progress under Perlantir AI Studio)
3. **Monetization v1** — `TBD` (default recommendation: free during TestFlight, IAP subscription at GA — design doesn't change either way)
4. **Compliance counsel** — `TBD` (engaging by Day 14; blocks App Store submission, not dev sessions)
5. **FRED API key** — `TBD` (free, register at fred.stlouisfed.org; needed for Session 3)
6. **Rate snapshot hosting** — `TBD` (default: Vercel Edge if already using Vercel, otherwise Cloudflare Workers)
7. **Privacy policy + terms URLs** — `TBD` (simple static HTML, host on GitHub Pages or Vercel; lawyer review before GA)
8. **Support email** — `TBD` (suggestion: `support@quotient.app` if domain available)
9. **TestFlight beta LO list** — `TBD` (begin recruiting 15–20 LOs by Week 6)

---

## Stack decisions (confirmed — do not change without updating DEVELOPMENT.md)

- Target: iOS 18+, iPhone first, iPad landscape second
- Language: Swift 6 with strict concurrency
- UI: SwiftUI (UIKit only where SwiftUI cannot reach)
- Persistence: SwiftData
- Charts: Swift Charts (native) + SwiftUI Canvas for custom
- PDF: PDFKit + ImageRenderer
- Money math: Foundation.Decimal
- AI narration: FoundationModels framework (iOS 18.2+) with template fallback
- Testing: Swift Testing (new) + XCTest (where needed) + Muter for mutation testing
- Fonts: SF Pro + SF Mono (system) + Source Serif 4 (bundled)
- Package structure: Swift Package Manager local packages — QuotientFinance, QuotientCompliance, QuotientPDF, QuotientNarration
- No third-party AI API. No third-party analytics v1. No third-party crash reporter v1.

---

## Design pass 2 — full screen set delivered

The designer delivered the complete screen set: Onboarding (6-step), Home, Saved, Settings (10 sections), BorrowerPicker (bottom sheet), Amortization (Inputs + Results), Income Qualification, Refinance Comparison, Total Cost Analysis, HELOC vs Refinance, Share (PDF preview carousel), PDF cover, Foundations. Only iPad layouts, motion prototypes, full copy doc, and empty/error states are intentionally deferred.

---

## Change log

Every time a decision changes, append here with date + reason so Claude Code doesn't rebuild against stale assumptions.

| Date | Decision | From | To | Reason |
|------|----------|------|----|--------|
| 2026-04-17 | Design handoff | Pass 1 (4 flagship screens) | Pass 2 (full 14-screen set) | Designer delivered complete iPhone coverage |
| 2026-04-17 | Project generation | unspecified | xcodegen — commit `project.yml` + `.xcodeproj` | Diffable, CI-reproducible. Workflow: edit `project.yml`, run `xcodegen generate`, commit both. |
| 2026-04-17 | Code signing (Session 1) | unspecified | `CODE_SIGNING_ALLOWED=NO`, blank `DEVELOPMENT_TEAM` | Apple Developer enrollment in flight. Simulator-only builds don't need signing. TODO comment in `project.yml` flags the change needed once team ID exists. **Blocks Session 5 (TestFlight + device install)**, doesn't block Sessions 2–4. |
| 2026-04-17 | Source Serif 4 weights | spec asked 400/500/600 | shipped 400/400-It/600/600-It | Adobe Fonts release branch ships only static 400 + 600 (no 500). Design uses Source Serif 4 only for wordmark + onboarding titles + PDF — 400/600 covers every emphasis the design calls for. |
| 2026-04-17 | APOR cadence | spec said quarterly | actual FFIEC publication is weekly | FFIEC publishes APOR every Thursday alongside Freddie Mac PMMS. Embedded weekly series in `APOR/APORTable.swift` (2024-Q1 through 2026-Q2 YTD). Session 2 compliance work should plan for weekly updates, not quarterly. |
| 2026-04-17 | APOR data source (Session 1) | live FFIEC CSV | synthesized from Freddie Mac PMMS public weekly averages | FFIEC's CSV download blocks non-browser user agents (403). Live FFIEC pull lands with the rates-proxy in Session 3. Embedded values are within ~5 bps of true APOR for first-lien fixed loans — sufficient for HPML/HPCT logic correctness; insufficient for binding regulatory disclosures (those will hit the live source). |
| 2026-04-17 | Design tokens — README vs CSS | ambiguous | **README wins** | The two CSS files (`tokens/colors_and_type.css`, `tokens/app.css`) carry earlier-iteration tokens (burnt-orange Claude accent, Inter/JetBrains Mono). The design README is the final pass. Session 2 theme work uses ledger-green `#1F4D3F` (light) / `#4F9E7D` (dark) accent and SF Pro / SF Mono / Source Serif 4 font stack. |
| 2026-04-17 | `ComplianceRuleVersion` location | unspecified | lives in `QuotientFinance`, not `QuotientCompliance` | Avoids a circular dependency — Session 2's `QuotientCompliance` will import `QuotientFinance` (for `Loan`, `LoanType`, etc.); reverse direction would be a cycle. |
| 2026-04-17 | IRR / XIRR solver | spec didn't specify | pure bisection (60 iterations, no Newton fallback) | Bisection always converges to float precision in ~60 iterations within a valid bracket; Newton's faster convergence is irrelevant for once-per-scenario use; bisection has zero "got stuck" cases. |
| 2026-04-17 | Public-API guard semantics | preconditions throughout | `guard ... else { return <sentinel> }` for boundary inputs | LTV/DTI/MaxQual/PV/FV/etc. now return 0 (or empty schedule) on plainly-invalid input rather than aborting. Internal helpers keep `precondition`. Improves testability + makes the eventual UI layer's job easier (no need to pre-validate at the call site). |
| 2026-04-17 | SwiftLint sandbox | enabled by default in Xcode 16 | disabled (`ENABLE_USER_SCRIPT_SANDBOXING: NO`) | The build-phase SwiftLint script needs to read sources outside the build directory + the `.swiftlint.yml` config. Sandboxing blocks both. Standard practice is to disable sandboxing for lint scripts. |
| 2026-04-17 | Coverage gate wording | `≥95% line + branch coverage` | `≥95% line coverage; ≥95% region coverage on reachable paths (defensive guards against validated inputs exempt when documented in the session summary)` | Gate wording tightened to distinguish reachable coverage from total coverage; defensive guards documented. The 24 currently-exempted regions are enumerated in `SESSION-1-SUMMARY.md` § "Coverage accounting" with file:line + guard type + unreachability rationale, so any future auditor (reviewer, compliance counsel, App Store reviewer) can verify the exemptions are legitimate. Updated `DEVELOPMENT.md` (3 spots) and `CLAUDE.md` to match. |
