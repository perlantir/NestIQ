# Session 7 — Partial (2026-04-21)

**Status**: Closed mid-stream due to context budget. Work completed is committed and pushed to `origin/main`. Session 8 resumes from the "Next action" below.

## What shipped this session

Commits (all on `main`, all pushed):

| Commit | Scope |
|--------|-------|
| `406f9ba` | **7.1** — Bundled v2.1.1 PDF font pack (Source Serif 4 + JetBrains Mono); renamed 2 existing TTFs to canonical filenames; `UIAppFonts` updated in both `project.yml` and `Info.plist` |
| `3035e93` | **7.2** — Patched all 4 v2.1.1 with-masthead templates; added xcodegen pre-build rsync from `.claude/assets/pdf-v2/` → `App/Resources/PDFTemplates/`; added D12 to DECISIONS.md; created `V0.1.2-BACKLOG.md` |
| `32ce86f` | **7.3a** — Deleted `NestIQPrintRenderer.swift` (CG chrome retired per D12); `HTMLPDFRenderer` rewritten with optional `baseURL` and plain `UIPrintPageRenderer`; new `PDFTemplateLoader.swift` with compliance-trailer helper; refi template gained `<!--{{narrative_body}}-->` sentinel |
| `3b93a6e` | **7.3b** — HELOC data model extensions (11 new `HelocFormInputs` fields, `HelocIndexType` enum, `StressRow` struct, 7 new `HelocViewModel` derivations via a separate `+PDFDerivations.swift` extension file). 10 new passing tests in `HelocPDFDerivationsTests.swift`. Side-fix: `TCAPDFHTMLTests` updated to reflect D12 CG retirement. |

Build: green on iPhone 16 Pro / iOS 18.3.1. `HelocPDFDerivationsTests` passes. `TCAPDFHTMLTests` passes after the D12 follow-up edit.

Path B commitment is underway: all 4 calculators' data models get extended so the v2.1.1 templates render from real ViewModel data, not demo hardcodes.

## What's left in Session 7 (for Session 8 to finish)

**Decided, not started:**

1. **7.3b-ii** — HELOC Inputs Screen: add `Section("Advanced")` with `DisclosureGroup` containing the 11 new fields (3 subsections: first-mortgage history, HELOC product terms, cashout refi alternative). Default-collapsed. Follow existing SwiftUI Form patterns; no DisclosureGroup precedent in codebase so first one. LO can override any field; defaults ship correct for demo flow.

2. **7.3c** — Refinance data model extensions. Audit the 49 v2.1.1 refi tokens (`tokens.schema.json` → `refinance.tokens.properties`) against `RefinanceFormInputs` + `RefinanceViewModel`. Add missing fields with `decodeIfPresent` defaults. Mirror 7.3b's pattern: new `+PDFDerivations.swift` extension, new test file covering JSON migration + derivations.

3. **7.3d** — Amortization data model extensions. Expected small scope — amortization is already data-rich. Still audit against template tokens and add any gaps.

4. **7.3e — PAUSE REQUIRED**. TCA template iOS-local patch to add the 3 orphan sections (interest-vs-principal, unrecoverable cost, reinvestment). **Nick explicitly wants to review the proposed CSS/HTML before the patch commits**. Session 8 must surface a concrete HTML sketch + token list for those 3 sections, wait for approval, then patch + extend TCA data model.

5. **7.3f** — Rewrite all 4 `*PDFHTML.swift` builders to load v2.1.1 templates via `PDFTemplateLoader.load(_:)`, populate tokens from the extended ViewModels, and render via `HTMLPDFRenderer.renderPDF(html:baseURL:)` with `baseURL = PDFTemplateLoader.templatesFolderURL`. Append compliance trailer page from `PDFTemplateLoader.complianceTrailerPage(...)`. Refi gets narrative injection at the `<!--{{narrative_body}}-->` sentinel.

6. **7.4** — Delete `IncomeQualPDFHTML.swift` + `SelfEmploymentPDFHTML.swift` + `PDFBuilder+SelfEmployment.swift` + `PDFBuilder.buildIncomeQualPDF` (Reg B / ECOA — no PDF export from pre-qualification workflows). Delete matching `AppTests/IncomeQualPDFHTMLTests.swift` + `SelfEmploymentPDFHTMLTests.swift`. The pre-existing `CalculatorIncomeTests.testIncomeQualFullFlow` UI-test failure (orphaned from 5S.2) gets resolved here when the Share button path is fully removed.

7. **7.5** — Wire haptic-on-calculate toggle. `LenderProfile` already stores the toggle (per obs 1784); compute sites identified but not yet wired. Find + wire.

8. **7.6** — Wire sound-on-share toggle. Same shape as 7.5.

9. **7.7** — Full regression + version bump + session summary:
   - CFBundleShortVersionString 0.1.0 → 0.1.1
   - CFBundleVersion 2 → 3 (Info.plist + project.yml)
   - Full test suite clean (baseline 502+; expect +60-100 from Session 7 data model extensions)
   - Visual QA on generated PDFs (white vs cream paper background — v2.1.1 ships `--paper: #FAF9F5` cream; Nick's 5S ask was white. Flag if this needs tokens.css override.)
   - Write `SESSION-7-SUMMARY.md` and delete this PARTIAL file.

## Immediate next action (Session 8 kickoff)

**Start with 7.3c (Refinance data model extensions)** — 7.3b-ii HELOC UI can piggyback onto the same pattern and doesn't block anything downstream, so roll it into the last commit before 7.3f if context allows, otherwise defer to Session 8's tail.

Before coding:

1. Read `App/Features/Calculators/Refinance/RefinanceInputs.swift` + `RefinanceViewModel.swift`.
2. Cross-reference `.claude/assets/pdf-v2/tokens.schema.json` → `refinance.tokens.properties` (49 new tokens as of schema 2.1.2).
3. Enumerate which tokens map to existing ViewModel outputs and which need new `RefinanceFormInputs` fields or new derivations.
4. Mirror the pattern from `HelocViewModel+PDFDerivations.swift`: new extension file, JSON migration test, derivation tests.

## Open decisions + known issues

- **Cream vs white PDF background**: v2.1.1 ships `--paper: #FAF9F5` (cream) in tokens.css. Nick's 5S ask was white. Flagged in 7.1 commit and session-opening context. Defer decision until first visual QA in 7.7 unless Nick preempts.
- **TCA interim PDF regression**: During 7.3b → 7.3e, TCA PDFs render without masthead/pagination (CG chrome retired in 7.3a, TCA not migrated to v2.1.1 yet). No TestFlight push between these commits — internal only. Test was updated in 7.3b side-fix.
- **D12**: CG chrome retirement. Both `drawHeaderForPage` + `drawFooterForPage` gone. If a future session needs per-page chrome, it lives in HTML templates, not CG.
- **Pre-existing IncomeQual UI-test failure**: `dock.share absent` — orphaned from 5S.2, gets swept in 7.4 when the builder is deleted.

## Guardrails (unchanged from Nick's 7.3b directive)

- Do NOT add PDF export back to IncomeQual or SelfEmployment (compliance, permanent).
- Do NOT modify QuotientFinance engine math.
- Do NOT modify FRED rate service or SIWA/AuthGate.
- Do NOT use fake/demo/placeholder values in a rendered PDF — either add the field now or flag in backlog.
- Do NOT ship silent regressions.
- Do NOT modify test expectations to make failures pass (exception: tests asserting against intentionally-retired functionality per a new decision, with commit-message disclosure).

## Stop conditions

- Any parity regression in existing calculator outputs beyond the known-interim TCA chrome gap.
- Any form field addition breaks existing Saved Scenarios JSON decode (D7).
- Any TCA template patch for 7.3e must surface CSS/HTML proposal before committing.
- Any test failure not already documented as pre-existing.
- Context exhaustion — commit what's stable, update this PARTIAL file, exit.

---

**Session 7 closed at `3b93a6e`. Session 8 picks up here.**
