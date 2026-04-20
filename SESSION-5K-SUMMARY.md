# Session 5K — Summary

Four-item polish pass closing out Nick's round-6 QA before Session 6
(TestFlight admin). Sub-commits per logical unit, rolled up at the end.

## What shipped

### 5K.1 — Smart Save: overwrite when loaded from Saved, prompt when new
`promptSaveScenarioName()` on each of the six calculator results
screens now branches on `existingScenario`. Loaded scenarios overwrite
in place with no alert (the existing save path already had the
overwrite branch; 5J.3's alert was just always fired). Fresh
scenarios keep the Session 5J.3 name prompt. The `justSaved` dock
pulse still confirms either path.

Files: AmortizationResultsScreen, IncomeQualScreen, RefinanceScreen,
TCAScreen, HelocScreen, SelfEmploymentResultsScreen.

Tests: `testSaveOverwriteDoesNotDuplicate` and
`testSaveNewScenarioInserts` in `SwiftDataModelTests` pin the two
branches (in-place update vs. insert-new).

### 5K.2 — QuotientNarration flagged-numbers false positive

**Root cause**: the hallucination guard's number extractor used

    \$?\d{1,3}(?:,\d{3})*(?:\.\d+)?%?|\d+(?:\.\d+)?%?

which captures numeric prefixes but stops at any alphabetic. When the
narration template rendered `"$732K"` (the output of
`MoneyFormat.dollarsShort` for large totals), the extractor produced
`"$732"` and failed the exact-match check against the `"$732K"` entry
the calculator had added to the numericFacts allowlist. Result: a
yellow "Flagged numbers: $732" warning on a value that was in fact
validated — eroding LO trust.

**Fix**: two changes to `HallucinationGuard.flagUnknownNumbers`:
1. Extend the regex with an optional `[KMB]?` before the optional
   percent so `$732K`, `$1.24M`, `$2B` extract as single tokens.
2. Add a ±1% normalized-numeric fallback. Both sides are parsed into
   `Double` (stripping $/,/%, honoring K/M/B multipliers). A token
   escapes flagging when any allowlist entry's normalized value lies
   within 1% — absorbs rounding between the compact-currency display
   form in copy and the precise form in the allowlist.

Short-fragment skip rule now treats K/M/B as context sigils alongside
$/% so `$2B` isn't dropped as trivial.

Tests: four new cases plus a round-trip sweep covering every rendered
money format in use.

### 5K.3 — Welcome screen: small NestIQ monogram above eyebrow
Replaces the 48pt `Wordmark-A` above the welcome step's eyebrow with
a 40pt `Monogram-Accent` (24pt breathing room to the eyebrow). The
WelcomeMiniature card below still carries the wordmark + version
line, so a single smaller mark reads as an anchor rather than a
duplicate masthead.

Files: `OnboardingFlow.swift`.

### 5K.4 — Home: Recent scenarios tappable
Recent-scenario rows on Home were passive cards — tap did nothing.
Extracted the scenario → calculator-screen dispatch out of
`SavedScenariosScreen` into a shared `ScenarioDestinationView` so the
Home recent list can reuse the same deep-link behavior the Saved tab
already had. Each recent row is now a Button + chevron affordance
with accessibility identifier `home.recent.row.{type}`. Tap sets
`$openScenario` which drives a new `navigationDestination(item:)` on
the Home NavigationStack.

Files: `HomeScreen.swift`, `SavedScenariosScreen.swift` (dispatch
removed; delegated to the shared view), new
`SavedScenarios/ScenarioDestination.swift`, project regenerated.

Tests: `testRecentScenarioTapLoadsCalculator` in
`ScenarioSaveLoadTests` — saves an Amortization scenario, pops to
Home, taps the recent row, asserts the Amortization Inputs screen
reopens.

## Tests

Count delta:
- +2 unit tests in `SwiftDataModelTests` (5K.1 branches)
- +4 unit tests in `PlaceholderTests` (5K.2 narration cases)
- +1 UI test in `ScenarioSaveLoadTests` (5K.4 deep link)

Total: +7 new tests this session. No existing tests modified; the
5J.3 `confirmSaveAlert` helper path remains correct because the new
`promptSaveScenarioName` branch only skips the alert when
`existingScenario != nil`, and every UI test that uses
`confirmSaveAlert` saves from a fresh calculator (no loaded
scenario).

## Decisions added to DECISIONS.md

- Smart Save provenance lives on the calculator screen's
  `existingScenario: Scenario?` parameter — no shared/global
  scenario-tracking layer needed.
- QuotientNarration number extraction supports K/M/B compact-currency
  suffixes and uses a ±1% normalized numeric compare as a fallback
  past exact-match.
- Welcome screen onboarding carries a single 40pt monogram at the top;
  the card below provides the wordmark + version lockup.
- Home recent-scenario rows and Saved tab rows share a single
  `ScenarioDestinationView` dispatcher so Save + Share + existingScenario
  semantics are identical across entry points.

## Commits

1. `Session 5K.1: Smart Save — overwrite when loaded from Saved, prompt when new`
2. `Session 5K.2: QuotientNarration flagged-numbers — support K/M/B suffixes + normalized comparison`
3. `Session 5K.3: Welcome screen — small NestIQ monogram above WELCOME eyebrow`
4. `Session 5K.4: Home — Recent scenarios tappable + deep-link to calculator with loaded inputs`
5. Final rollup: `Session 5K complete: smart save + narrate fix + welcome monogram + recent scenarios tappable`

## What's next

Session 6 = TestFlight admin: remove DEBUG AuthGate bypass, set the
Apple Developer team ID, enable App Store signing, push the first
TestFlight build. Session 5K closes the round-6 QA polish; any new QA
before TestFlight admin becomes a round-7 deferral.
