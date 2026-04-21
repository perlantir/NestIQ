# Session 7 — Partial (2026-04-21, updated 12:47 CDT)

**Status**: Path B prep work complete. All 4 calculators' data models extended + TCA template patched iOS-locally. 7.3f (Swift builder rewrite) + 7.4–7.7 remain. Committed work is pushed to `origin/main`.

## What shipped this session

Commits on `main`, all pushed:

| Commit | Scope |
|--------|-------|
| `406f9ba` | **7.1** — v2.1.1 PDF font pack bundled (Source Serif 4 + JetBrains Mono), UIAppFonts updated |
| `3035e93` | **7.2** — All 4 v2.1.1 templates patched; pre-build rsync; D12 added to DECISIONS.md; V0.1.2-BACKLOG.md created |
| `32ce86f` | **7.3a** — NestIQPrintRenderer deleted; HTMLPDFRenderer baseURL fix; PDFTemplateLoader scaffolded |
| `3b93a6e` | **7.3b** — HELOC data model +11 fields + 7 derivations + 10 tests; TCAPDFHTMLTests D12 fix |
| `1faf0d6` | **7.3c** — Refi data model +3 option fields + 3 form fields + 8 derivations + 10 tests; 4 more D12 test fixes |
| `7c53fed` | **7.3d** — Amort data model +2 fields + 8 derivations + 11 tests |
| `8ef946e` | **7.3e** — TCA template iOS-local page 4 added (3 orphan sections restored); schema 2.1.3; 4 sentinels + 3 tokens + 7 HTML emitters + 10 tests |
| `3826d1d` | Handoff doc (previous version) |

Build: xcodebuild green. Total new passing tests in Session 7: **51** across 5 new test files. Pre-existing failures documented: `CalculatorIncomeTests.testIncomeQualFullFlow` (5S.2 orphan, swept in 7.4) + `FREDRateServiceTests.testFetchSnapshotReturnsCachedValueWhenFresh` (flaky, unrelated).

## What's left — immediate next actions

### 7.3f — Rewrite 4 PDF builders against v2.1.1 templates (largest remaining piece)

Four Swift files to rewrite:

1. **`App/Features/Share/HelocPDFHTML.swift`** — pilot (simplest: no narrative, no row generation, ~60 tokens all scalar). Load `pdf-heloc-with-masthead` via `PDFTemplateLoader.load("pdf-heloc-with-masthead")`, fill tokens from `HelocViewModel` + new `+PDFDerivations` properties (stressPathMatrix → per-row tokens for stress_today/flat/plus1/plus2/plus3_*), interpolate, render via `HTMLPDFRenderer.shared.renderPDF(html:baseURL:to:)` with `baseURL = PDFTemplateLoader.templatesFolderURL`. Append `PDFTemplateLoader.complianceTrailerPage(...)` before passing HTML to renderer.

2. **`App/Features/Share/AmortizationPDFHTML.swift`** — load template, fill 17 scalar tokens from `AmortizationViewModel` + new `+PDFDerivations` properties, **Swift emits the full `<div class="schedule-split">` grid HTML** for both sentinels: `{{schedule_page_1_rows}}` (years 1–15 split 8/7 into two tables) and `{{schedule_page_2_rows}}` (years 16–30 split 8/7 + 30-year totals `<tfoot>`). Use `viewModel.yearlyBalances` + schedule data.

3. **`App/Features/Share/RefinancePDFHTML.swift`** — load template, fill 49 tokens covering matrix + hero + assumptions (reference `RefinanceViewModel+PDFDerivations.swift` for each). Inject AI narrative at `<!--{{narrative_body}}-->` sentinel: split `narrative` parameter on `\n\n` and wrap each paragraph in `<p class="lead">` for the first, `<p>` for the rest (or similar — match refi demo prose style).

4. **`App/Features/Share/TCAPDFHTML.swift`** — load template, fill 12 scalar tokens + 4 page-4 sentinels (call `TCAPDFHTML.interestSplitHeader(...)`, `.interestSplitRows(...)`, `.unrecoverableRows(...)`, `.reinvestmentSectionHTML(...)` from `+V2Derivations`). Plus page-2 `{{matrix_rows}}` sentinel: emit `<tr>` rows per scenario/horizon in the existing 4×5 shape. Can reuse `TCAPDFHTML.horizonMatrixSection` logic or port into a new emitter.

**PDFBuilder.swift signature changes (7.3f):**
- `buildAmortizationPDF(profile:borrower:viewModel:narrative:scheduleGranularity:)` → drop `narrative` param
- `buildHelocPDF(profile:borrower:viewModel:narrative:)` → drop `narrative` param
- `buildRefinancePDF(...)` keeps `narrative` — it's injected at the new sentinel
- `buildTCAPDF(...)` keeps `narrative` for now (TCA migration in 7.3f also strips its narrative param — template has no slot; flag to v0.1.2 like Amort/HELOC)

Wait — Nick's B2 decision was: "AI narrative inject ONLY in refi template's narrative div. Amort/HELOC builders drop the narrative: String parameter." TCA wasn't explicitly called out since TCA was Option 3 (deferred) at the time. Now that 7.3e migrated TCA to the extended template (which doesn't have a narrative slot either), **TCA should also drop `narrative` param** to match Amort/HELOC, with TCA narrative added to the V0.1.2-BACKLOG alongside Amort/HELOC narrative work.

**Call sites (3 — refi unchanged):**
- `AmortizationResultsScreen.swift:412` — drop `narrative:` argument
- `HelocScreen.swift:502` — drop `narrative:` argument
- `TCAScreen+Actions.swift:16` — drop `narrative:` argument
- `RefinanceScreen.swift:437` — keep `narrative:`

Expected LOC delta per builder: current ~200-350 LOC → new ~100-150 LOC (templates do the heavy lift).

**Tests to update:** `PDFBuilderTests`, `AmortizationPDFHTMLTests`, `RefinancePDFHTMLTests`, `TCAPDFHTMLTests`, `HelocPDFHTMLTests` — the existing tests assert against HTML content. After rewrite, assertions need to check for v2.1.1-specific classes/text (e.g., `rc-compare`, `schedule-split`, `stress_` tokens substituted). Update expected strings; don't delete test intent.

### 7.4 — Delete orphan IncomeQual + SelfEmployment PDF (Reg B / ECOA)

- Delete `App/Features/Share/IncomeQualPDFHTML.swift`
- Delete `App/Features/Share/SelfEmploymentPDFHTML.swift`
- Delete `App/Features/Share/PDFBuilder+SelfEmployment.swift`
- Remove `PDFBuilder.buildIncomeQualPDF` function body from `PDFBuilder.swift`
- Delete `AppTests/IncomeQualPDFHTMLTests.swift`
- Delete `AppTests/SelfEmploymentPDFHTMLTests.swift`
- Update `AppUITests/UITestHelpers.swift` / `CalculatorIncomeTests.swift` — remove the `dock.share absent after compute for incomeQualification` assertion (pre-existing failure gets resolved). SelfEmployment UI test likely needs the same treatment.
- xcodegen regen, build, tests pass.

### 7.5 — Haptic-on-calculate toggle wiring

`LenderProfile` already stores the toggle (per obs 1784). Compute sites identified but not yet wired. Find the Compute buttons across 4 calculators (Amort/Refi/TCA/HELOC) and call `UIImpactFeedbackGenerator(.medium).impactOccurred()` if `profile.hapticOnCalculate` is true.

### 7.6 — Sound-on-share toggle wiring

Same pattern for Share button. Use `AudioServicesPlaySystemSound` (`1008` = camera/snap) if `profile.soundOnShare` is true.

### 7.7 — Full regression + version bump + session summary

- CFBundleShortVersionString 0.1.0 → 0.1.1
- CFBundleVersion 2 → 3 (Info.plist + project.yml)
- Full test suite clean (baseline 502+ before Session 7; +51 from data model extensions; expect more from 7.3f + 7.4 cleanups)
- Visual QA on sample PDFs (cream vs white paper — decide)
- Write `SESSION-7-SUMMARY.md`, delete this PARTIAL file

## Open decisions + known issues

- **Cream vs white PDF paper**: tokens.css `--paper: #FAF9F5` (cream). 5S session's "white background" ask was for legacy base.html. v2.1.1 design ships cream. Decide at first visual QA in 7.7 whether to override via tokens.css or accept designer intent.
- **TCA iOS-local template divergence**: Page 4 added iOS-locally in 7.3e. Flagged as v2.2 upstream-sync candidate. V0.1.2-BACKLOG notes the TCA template migration entry becoming partly obsolete — update when v2.2 lands.
- **7.3f TCA narrative drop**: Treat TCA like Amort/HELOC — drop `narrative` param, add to V0.1.2-BACKLOG alongside the other narrative-slot work. Template has no narrative section (page 4 is data-only).
- **Pre-existing failures**: Income UI test (5S.2 orphan, fixed in 7.4); FRED cache flake (unrelated, logged for session summary).

## Guardrails (unchanged)

- Do NOT add PDF export back to IncomeQual or SelfEmployment (compliance, permanent)
- Do NOT modify QuotientFinance engine math
- Do NOT modify FRED rate service or SIWA/AuthGate
- Do NOT use fake/demo values in rendered PDFs — add field or flag
- Do NOT ship silent regressions
- Do NOT modify test expectations to make failures pass (exception: D12-triggered retirement, with commit-message disclosure)

## Stop conditions

- Any parity regression in existing calculator outputs beyond known interim TCA chrome gap (closes in 7.3f)
- Any form field addition breaks existing Saved Scenarios JSON decode (D7)
- Any iOS-local template divergence that isn't already Nick-approved (7.3e was approved; further divergence needs re-approval)
- Any test failure not already documented as pre-existing
- Context exhaustion — commit what's stable, update this PARTIAL file, exit cleanly

## Commits frequency check

Every sub-task commits independently + pushes. If context hits the wall mid-rewrite of, say, HelocPDFHTML.swift, commit the partial file with a `// TODO(session-8): finish v2.1.1 token filling` marker AND update this PARTIAL file with the exact next line to pick up. Don't leave uncommitted edits.

---

**Session 7 current state: `8ef946e` on `main`. All prep for 7.3f is in place.**

Next Session 8 action: **`/Users/perlantir/Projects/Quotient/App/Features/Share/HelocPDFHTML.swift`** — rewrite as the 7.3f pilot. Existing file uses `PDFHTMLComposition.wrap(body:)` pattern; new shape loads template via `PDFTemplateLoader.load("pdf-heloc-with-masthead")`, interpolates with token dict populated from HelocViewModel (reference `tokens.schema.json` refi entries for HELOC token names), appends compliance trailer, and hands to `HTMLPDFRenderer.shared.renderPDF(html:baseURL:to:)` with `baseURL = PDFTemplateLoader.templatesFolderURL`. Target under 150 LOC.
