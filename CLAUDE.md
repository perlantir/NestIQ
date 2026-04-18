# CLAUDE.md — Quotient Project Context

> Claude Code reads this automatically every session. Behavioral principles first (how to code), then project context (what to code). Keep this file under 200 lines — compliance drops past that.

---

# Part 1 — Behavioral principles (from Andrej Karpathy's observations)

Bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that YOUR changes orphaned.
- Every changed line should trace directly to Nick's request.

## 4. Goal-Driven Execution

**Define verifiable success criteria. Loop until verified.**

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan with per-step verification checks.

---

# Part 2 — Quotient project context

## What this project is

**Quotient** — native iOS mortgage calculator for licensed loan officers. App Store product. iPhone first, iPad landscape second. Five calculators, nothing else v1: Amortization, Income Qualification, Refinance Comparison, Total Cost Analysis, HELOC vs Refinance. Plus branded PDF export, on-device AI narration, iCloud backup, Face ID, Sign in with Apple, English + Spanish.

**Not in v1:** web app, borrower portal, CRM/LOS/e-sign integrations, multi-tenant, third-party AI, Android.

## Who you're working for

Nick — DTC mortgage finance SVP, founder of Perlantir AI Studio. Former NCAA wrestler. Builds technical products with AI agents, not a professional developer. Values: ship real things. Never "here's how you CAN'T" — always "here's how you CAN."

## Read order at session start

1. This file
2. `DEVELOPMENT.md` — authoritative build spec
3. `DECISIONS.md` change log — anything added since last session
4. Most recent `SESSION-N-SUMMARY.md` at repo root
5. `design/design_handoff_quotient/README.md` — authoritative design spec; wins over any conflict
6. `design/design_handoff_quotient/design_files/screens/Foundations.jsx` — component specimen sheet; consult whenever a pattern is ambiguous
7. Screen JSX files relevant to the current session (don't read all every time)

## Tech stack (locked)

- **iOS 18+**, Swift 6 strict concurrency, SwiftUI first
- **Swift Package Manager** local packages: `QuotientFinance`, `QuotientCompliance`, `QuotientPDF`, `QuotientNarration`
- **SwiftData** persistence, **Swift Charts** + SwiftUI Canvas for custom, **PDFKit + ImageRenderer** for PDF
- **Foundation.Decimal** for money math (no third-party)
- **FoundationModels framework** (iOS 18.2+) for AI narration, template fallback for older devices
- **Swift Testing + XCTest + Muter** for tests
- **XcodeGen** for project generation (commit both `project.yml` and `.xcodeproj`)
- **Fonts**: SF Pro / SF Mono (system) + Source Serif 4 (bundled, SIL OFL 1.1, 400/400i/500/600)

No third-party analytics, crash reporter, or AI SDK in v1.

## Session map (5 total)

1. Xcode scaffold + `QuotientFinance` core + tests + CI + fixtures + property harness + perf + Muter config
2. `QuotientFinance` advanced + `QuotientCompliance` + Theme + Components
3. App shell + Onboarding + Home + Saved + Settings + BorrowerPicker + Amortization (flagship)
4. Income Qual + Refi + TCA + HELOC + `QuotientNarration` + `QuotientPDF` + Share
5. Polish + i18n + a11y + iPad + TestFlight + App Store

See `DEVELOPMENT.md` for per-session gates. Don't advance past a gate without hitting it.

## Non-negotiables

- **Finance engine is the moat.** `QuotientFinance`: ≥95% line coverage; ≥95% region coverage on reachable paths (defensive guards against validated inputs exempt when documented in the session summary); ≥80% mutation score (Muter); all property invariants green; golden fixtures match published values within documented tolerance.
- **Design README wins** conflicts with CSS token files. Ledger-green accent `#1F4D3F` light / `#4F9E7D` dark. SF Pro / SF Mono / Source Serif 4.
- **No force-unwraps in production** without a justifying doc comment. No `Any` casts unless absolutely required.
- **Don't touch UI in Sessions 1 or 2.** Packages, theme, and components only.
- **Ambiguity → ask, don't invent.** Especially for token values, compliance rules, or financial math.

## Resume protocol

When Nick reconnects after time away or starts a fresh session:
1. Read this file
2. Read the most recent `SESSION-*-SUMMARY.md`
3. Read `DECISIONS.md` change log for anything added since the last session
4. Tell Nick in plain English: what was last finished, what's next, any open questions
5. Wait for his green light before writing code

## Session completion

Always write `SESSION-N-SUMMARY.md` at the repo root covering: what was built, tests that exist (with coverage numbers), decisions made to propagate into `DECISIONS.md`, open items deferred to later, and a one-paragraph "what's next." Keep it structural, not narrative — it's for context reload, not a diary.

## Operating philosophy

Quotient is a serious financial instrument for licensed professionals. Every calculation holds up to CFPB scrutiny. Every disclosure is correct per state. Every pixel matches the designer's intent. Every animation has purpose. When in doubt, pick the harder, more rigorous path.

Ship the best mortgage calculator that has ever existed on iOS.

---

## Change log

| Date | Change | Reason |
|------|--------|--------|
| 2026-04-17 | Initial CLAUDE.md (Karpathy principles + Quotient context) | Persistent project brain for session continuity |
