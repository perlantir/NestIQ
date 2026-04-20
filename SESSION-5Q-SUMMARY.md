# Session 5Q — Summary

Session 5Q closed three pre-TestFlight UX gaps 5P deferred, plus
one new architectural decision (D10) the gaps surfaced. Four
substantive sub-tasks, one regression pass, all shipped.

## What shipped per sub-task

### 5Q.1 — Unified BorrowerForm (create + edit + delete)

`NewBorrowerForm` (5P.7) only handled create. LOs had no path to
fix a typo, add a currentMortgage to an existing borrower, or
remove an outdated contact. Generalized the create layout with a
`Mode` parameter:

- `.create` → fresh state, submit label "Create borrower"
- `.edit(Borrower)` → pre-populated from the record, submit label
  "Save changes", destructive Delete section gated behind a
  confirmation alert.

Caller owns `modelContext.insert / save / delete` via two
closures (`onSubmit`, `onDelete`). The form itself stays free of
SwiftData references — same split 5P.7 set up.

`NewBorrowerForm` absorbed into `BorrowerForm`; `BorrowerPicker`
create-tab updated to `BorrowerForm(mode: .create, ...)`.

Tests: +5 in `AppTests/BorrowerFormTests.swift` covering
create-mode insert, edit-mode mutate-in-place, cancel-preserves-
original, delete removes, and currentMortgage add/modify/clear
round-trip.

### 5Q.2 — BorrowerPicker swipe actions + D10 nullify delete rule

Borrower management in v1 lives entirely inside the BorrowerPicker
bottom sheet — there is no standalone admin screen. 5Q.2 closes
the remaining edit / delete gap without introducing a new nav
surface:

- Recents list migrated `ScrollView` + `LazyVStack` → `List`
  (`.plain` style + per-row background + hidden separators) so
  SwiftUI's `.swipeActions` registers the standard iOS affordances.
- Leading swipe → Edit (accent-tinted, pushes
  `BorrowerForm(mode: .edit)` onto the sheet's NavigationStack).
- Trailing swipe → Delete (destructive red, confirmation alert
  with borrower-name + scenario-survival copy).
- Existing tap-to-select gesture preserved.
- Post-delete toast ("Borrower deleted") surfaces at the top of
  the sheet for 2s.

#### D10 — Borrower→Scenario relationship uses `.nullify`

The plan's "saved scenarios remain intact" promise conflicted with
the existing `@Relationship(deleteRule: .cascade, ...)` rule.
Stopped, flagged, switched to `.nullify` per Nick's green light.
When a borrower is deleted their scenarios survive with
`.borrower == nil`; the 5P.8 `currentMortgage` snapshot + the
scenario's own `inputsJSON` / `outputsJSON` preserve calculator
correctness without the live borrower link.

No schema migration — `Scenario.borrower` was already `Optional`.
Nil-safety audit confirmed every surface that reads
`scenario.borrower` / `viewModel.borrower` uses
`?.fullName ?? fallback` or pass-through optional — no
changes required.

Tests: `testCascadeDeleteOnBorrower` renamed to
`testNullifyDeleteOnBorrower` and flipped to assert scenarios
survive + `.borrower == nil` after delete. New
`testSavedScenarioSurvivesBorrowerDeletion` pins end-to-end:
save TCA refi scenario with `currentMortgage` snapshot, delete
borrower, scenario reloads with inputs JSON + snapshot intact.

DECISIONS.md appended with D10.

### 5Q.3 — TCA refi inline currentMortgage save-to-borrower toggle

TCA refi is the only calculator that captures the full 7-field
`CurrentMortgage` shape inline. A new "Save to borrower profile"
toggle surfaces below the `CurrentMortgageSection`:

- Default ON when a borrower is attached.
- Disabled (grayed) when no borrower is selected; helper text
  reads "Select a borrower to enable."
- Helper personalizes to the borrower's first name when attached.
- On Compute, if toggle ON + borrower + valid mortgage, writes
  `borrower.currentMortgage = inputs.currentMortgage` and saves
  the context.

Persistence logic lives in `TCACurrentMortgagePersistence` — a
pure helper with no SwiftUI dependency — so the write semantics
are unit-testable.

**Refinance Comparison + HELOC vs Refi NOT changed.** Their
current-loan sections capture a narrower 3-4 field shape that
cannot round-trip to a full `CurrentMortgage`. Those screens
continue one-way prefill from `borrower.currentMortgage`
(5P.12 / 5P.13) without a reverse save path. Deferring inline
save-back to v0.2 is a deliberate scope call — see "Deferred to
v0.2" below.

Tests: +4 in `AppTests/TCACurrentMortgagePersistenceTests.swift`
— toggle ON writes, toggle OFF is no-op, no-borrower is no-op,
nil-mortgage preserves any persisted mortgage (a partial inline
edit must not clear an existing one).

### 5Q.4 — TCA horizon matrix Current column (Results + PDF)

Refi mode now renders a "Current" baseline column across four
sections so LOs can narrate "stay put vs refinance" across every
horizon, not just the 5P.10 anchor-card summary:

- Total cost by horizon: first column per row = status-quo
  cumulative P&I through that horizon, capped at remaining term.
- Interest vs principal: status-quo int/prin split per horizon.
- Unrecoverable costs @ longest horizon: prepended "Current" row
  showing cumulative interest only (no closing, no MI on the
  existing loan).
- Equity buildup @ longest horizon: prepended "Current" row
  showing propertyValueToday minus amortized remaining balance.

Purchase mode unchanged — no status quo to anchor against.
Winner highlighting stays scoped to the proposed scenarios; the
Current column never carries a checkmark.

PDF mirrors the same treatment via `TCAPDFHTML` edits — horizon
matrix + interest vs principal gain a leading Current column,
unrecoverable + equity gain a "Current / Status quo" row.

Helpers (`TCAInputs+CurrentMortgage.swift`):

- `buildCurrentMortgageSchedule()` amortizes the status-quo loan
  forward through its remaining term. Returns nil in purchase
  mode / no mortgage / past-term edge cases.
- `currentHorizonCost(years:)` uses the borrower's stated monthly
  P&I (not the amortized figure) so the display matches what the
  borrower actually sends the lender. Capped at remaining months.
- `currentHorizonUnrecoverable(schedule:years:)` — cumulative
  interest from the schedule.
- `currentHorizonEquity(schedule:years:)` — propertyValueToday
  minus balance at horizon; clamped non-negative.

`TCAViewModel.compute()` populates `currentMortgageSchedule`
alongside `scenarioSchedules`. New `showsCurrentColumn` flag on
the viewModel is the single source of truth for downstream UI.

SwiftLint caps forced three extractions:

- `TCAInputs+CurrentMortgage.swift` — current-mortgage helpers.
- `TCAScreen+Matrix.swift` — the horizon matrix view.
- `TCAPDFHTML+HorizonDetails.swift` — interest / unrecoverable /
  equity HTML builders.

Tests: +4 in `TCAPDFHTMLTests` — refi mode renders Current
column header / Status quo rows, purchase mode omits them,
currentHorizonCost math produces expected totals, purchase-mode
guard returns zero.

### 5Q.5 — Regression + wrap-up

Full test suite run across all packages + app + UI tests.

| Surface | Before 5Q | After 5Q | Delta |
|---|---|---|---|
| QuotientFinance | 316 | 316 | 0 |
| QuotientCompliance | 40 | 40 | 0 |
| QuotientNarration | 10 | 10 | 0 |
| QuotientPDF | 2 | 2 | 0 |
| QuotientTests | 102 | 116 | +14 (BorrowerForm +5, TCACurrentMortgagePersistence +4, SwiftDataModel +1, TCAPDFHTML +4) |
| QuotientUITests | 18 | 18 | 0 |

**Total: 502 tests, 1 conditionally skipped (5O.7 SE PDF), 0 failures.**

## Architectural decisions

One new decision surfaced:

### D10 — Borrower→Scenario delete rule is `.nullify`, not `.cascade`

Scenarios are time-sensitive historical artifacts with legal /
audit value — deleting a contact record shouldn't destroy evidence
of analysis work done for them. LOs cleaning up stale borrower
records need a safe path that doesn't take their scenarios with
it. Flipped the relationship rule; `Scenario.borrower` was already
`Optional` so no schema migration required. All UI + PDF surfaces
already tolerate a nil borrower.

## Files added

- `App/Features/BorrowerPicker/BorrowerForm.swift`
- `App/Features/Calculators/TotalCostAnalysis/TCAInputs+CurrentMortgage.swift`
- `App/Features/Calculators/TotalCostAnalysis/TCAScreen+Matrix.swift`
- `App/Features/Share/TCAPDFHTML+HorizonDetails.swift`
- `AppTests/BorrowerFormTests.swift`
- `AppTests/TCACurrentMortgagePersistenceTests.swift`

## Commits

```
Session 5Q.1  — BorrowerForm unified create + edit + delete
Session 5Q.2  — BorrowerPicker swipe edit + swipe delete, nullify delete rule (D10)
Session 5Q.3  — TCA refi inline currentMortgage save-to-borrower toggle
Session 5Q.4  — TCA horizon matrix Current column (Results + PDF)
Session 5Q    — wrap-up rollup (this commit)
```

## Deferred to v0.2

- **Refi + HELOC inline save-to-borrower.** These calculators
  capture a narrower current-loan shape (4-5 fields) than
  `CurrentMortgage` requires (7 fields). Upgrading their input
  forms to capture the full shape is scope expansion worth its own
  dedicated session, not squeezed into 5Q. Today's one-way flow is:
  `borrower.currentMortgage` prefills these calcs. Reverse flow
  (save-back) remains a v0.2 item. Doesn't block TestFlight — LOs
  who want borrower-level persistence capture the mortgage via TCA
  refi (with 5Q.3's toggle) or via the Borrower edit form (5Q.1).

- **Standalone Borrowers admin screen.** Currently editing happens
  via the BorrowerPicker swipe affordance. If beta LOs ask for a
  dedicated borrowers tab with search / sort / grouping we'll build
  it in v0.2 based on real feedback — but the v1 workflow is
  contextual (encounter borrowers during calculations), which
  matches how LOs actually operate.

## What's next — Session 6 (TestFlight admin)

Unchanged from 5P's "What's next" — 5Q didn't touch any 5P-deferred
Session 6 items:

1. Remove DEBUG AuthGate bypass (`AuthGate.swift:84-91`) once the
   UI-test bypass path is satisfied by alternative means.
2. Info.plist usage descriptions —
   `NSPhotoLibraryUsageDescription`, `NSFaceIDUsageDescription`.
3. Wire real URLs — `https://nestiq.mortgage/privacy` / `/terms` /
   `/support` — into Settings + onboarding.
4. Wire `support@nestiq.mortgage` into Send Feedback.
5. Apple Developer team ID, enable App Store signing, archive +
   TestFlight upload.
