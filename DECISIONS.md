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
