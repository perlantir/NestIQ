# Session 1 Kickoff — Paste this into Claude Code

> **Before pasting:** make sure you've put the `Quotient/` folder under `~/Projects/` so the paths below exist:
> - `~/Projects/Quotient/DEVELOPMENT.md`
> - `~/Projects/Quotient/DECISIONS.md`
> - `~/Projects/Quotient/design/design_handoff_quotient/README.md`
>
> Also: `cd ~/Projects/Quotient && git init && git add . && git commit -m "initial handoff"` — then launch Claude Code in that directory.

---

## Copy from here to the end of this file and paste into Claude Code as your first message:

---

You are starting work on **Quotient**, a native iOS mortgage calculator for licensed loan officers. This is Session 1 of 5. Before writing any code, complete this reading order:

**Read in this exact order and confirm you've done so before proceeding:**

1. `/DEVELOPMENT.md` — the complete build spec. This is the authoritative source for tech stack, scope, testing requirements, and build order.
2. `/DECISIONS.md` — my authoritative answers to architectural and vendor choices. Where entries are blank or marked `TBD`, pause and ask me rather than picking defaults silently.
3. `/design/design_handoff_quotient/README.md` — the design handoff from our designer. Read it end-to-end. This is the authoritative spec for visual design, tokens, motion, and interaction. The designer has delivered the full screen set in this pass. When `DEVELOPMENT.md` and the design README conflict, the design README wins.
4. `/design/design_handoff_quotient/design_files/tokens/colors_and_type.css` and `/design/design_handoff_quotient/design_files/tokens/app.css` — token definitions. If these conflict with the design README, the README wins (the README is the final pass; the CSS files are earlier-iteration reference).
5. Skim `/design/design_handoff_quotient/design_files/screens/Foundations.jsx` — the authoritative component/token specimen sheet. You'll reference it throughout the project.

**Do not read the other screen JSX files yet** — they're for Sessions 3 and 4 when we build those screens. Delivered screens in the bundle (for your awareness, don't implement yet): Onboarding, Home, Saved, Settings, BorrowerPicker, Inputs, Amortization, Income, Refinance, TCA, Heloc, Share, PDF.

## Session 1 scope

Your deliverables for this session, in order:

### 1. Xcode project scaffold
- New Xcode project at repo root, iOS 18+ deployment target, SwiftUI lifecycle, Swift 6 with strict concurrency enabled
- Bundle ID per `DECISIONS.md`
- Product name: **Quotient**
- Source Serif 4 font files bundled in `App/Resources/Fonts/` (Regular, Italic, 400/500/600 weights). Download from Google Fonts if an SPM option isn't stable. Register in `QuotientApp.init()` so it's available before the first view renders.
- Local Swift Package Manager packages under `/Packages`: create all four with minimal scaffolds:
  - `QuotientFinance` — this session builds the full implementation here
  - `QuotientCompliance` — placeholder target only; Session 2 fills it in
  - `QuotientPDF` — placeholder target only; Session 4
  - `QuotientNarration` — placeholder target only; Session 4
- SwiftLint installed and enforced as a build phase
- `.gitignore` appropriate for Xcode + Swift
- `.swift-version` pinned
- GitHub Actions workflow at `.github/workflows/ci.yml`: build + test + lint + coverage upload + nightly mutation tests via Muter

### 2. `QuotientFinance` package — all core primitives

Implement and test every function listed in `DEVELOPMENT.md` section "QuotientFinance — calculation engine → Primitives":

- `amortize`, `calculateAPR`, `calculateAPOR`, `isHPML`, `isHPCT`
- `calculatePITI`, `calculatePMI`
- `calculateLTV`, `calculateCLTV`, `calculateHCLTV`
- `calculateDTI`, `calculateMaxQualifyingLoan`
- `calculateQMStatus`
- `npv`, `irr`, `xnpv`, `xirr`
- `paymentFor`, `presentValue`, `futureValue`, `compoundGrowth`
- `blendedRate`, `breakEvenMonth`
- `effectiveRate`, `nominalToEffective`, `effectiveToNominal`

Every public function:
- Full doc comment stating day-count convention (30/360 default for conv/FHA/VA/USDA; actual/365 for HELOC; per-index for ARMs)
- Uses `Foundation.Decimal` for money, `Double` for rates
- Deterministic, pure — no I/O, no `Date()` calls (pass dates in as parameters)
- Public type signatures per `DEVELOPMENT.md`

### 3. Golden fixtures

Embed fixtures in `Packages/QuotientFinance/Tests/QuotientFinanceTests/Fixtures/` from these public sources (cite each in code comments with source URL + retrieval date):

- **Freddie Mac Exhibit 5** — sample amortization schedule for a 30-year fixed loan
- **Fannie Mae Selling Guide** — APR calculation examples
- **CFPB Regulation Z Appendix J** — APR computation worked examples
- **Bankrate** — any published amortization schedule for cross-check
- **VA funding fee table** — current-year values from va.gov
- **FHA MIP table** — UFMIP + annual MIP schedule from HUD

For each fixture: raw input values, expected output values, source URL + retrieval date, and a test verifying our implementation matches within documented tolerance.

### 4. Property-based tests

Write a lightweight property-based testing harness (~50 lines of Swift, or use `swift-testing-property-based` if stable) and verify these invariants with 1000+ random inputs per invariant:

- `sum(principal) == loanAmount` for fully amortized fixed-rate
- `sum(principal) + sum(interest) == sum(payment)` within 0.01 tolerance
- Balance monotonically non-increasing without extras
- `APR >= noteRate` when closing costs > 0
- Biweekly yields exactly 26 payments/year
- PMI drops at 78% LTV per original schedule
- Recast reduces monthly payment and total interest

### 5. Performance benchmarks

XCTest `measure` blocks:
- `amortize(360 months)` < 5ms
- `compareScenarios(4 × 30yr)` < 50ms

### 6. Mutation testing

Configure Muter for `QuotientFinance`. Do not run it in this session (it's slow — runs nightly in CI). Verify the config is correct and would run.

## Gate for proceeding to Session 2

Do not consider Session 1 complete until:

- [ ] Xcode project builds cleanly with strict concurrency and zero warnings
- [ ] All listed primitives implemented with full doc comments
- [ ] Golden fixture tests pass with documented tolerance
- [ ] Property-based invariant tests pass
- [ ] Performance benches within budget
- [ ] Line coverage on `QuotientFinance` ≥ 95% (report the number in your summary)
- [ ] Branch coverage ≥ 95%
- [ ] CI workflow runs green on GitHub Actions
- [ ] `README.md` at repo root explains: how to build, how to run tests, how to run Muter, what's in each package, and the 5-session build plan at a high level
- [ ] A `SESSION-1-SUMMARY.md` at repo root summarizing what you built, what tests exist, what the coverage numbers are, any decisions you made that should go into `DECISIONS.md`

## Rules of engagement

- **Strict Swift.** No `Any` casts unless absolutely required. No force-unwraps outside tests. No `!` operator in production code without a doc comment justifying it.
- **No shortcuts on testing.** The finance engine is the moat. Over-test it.
- **Don't touch UI this session.** No SwiftUI views, no app-target screens. Just the package and its tests.
- **When the design handoff is ambiguous, ask.** Better to pause than to invent a token value.
- **Document deviations.** If you deviate from `DEVELOPMENT.md` or the design README, log it in `DECISIONS.md` with rationale.

Begin by reading the files listed above in order. Confirm each is read before moving to the next. Then summarize what you understand the goal of Session 1 to be, what gates apply, and any clarifying questions for me before you start writing code.
