// Session 4 tests: capability detection, template fallback, allowlist
// post-processing for hallucinated numbers.

import Testing
import Foundation
@testable import QuotientNarration

@Suite("QuotientNarration")
struct NarrationTests {

    @Test("Capability detection defaults to false without a probe")
    func testCapabilityDefaultsOff() {
        #expect(NarrationCapability.hasFoundationModels == false)
    }

    @Test("Templates render for every scenario type in EN")
    func testTemplatesEN() {
        let locale = Locale(identifier: "en_US")
        for t in ScenarioType.allCases {
            let facts = ScenarioFacts(
                scenarioType: t,
                borrowerFirstName: "Nick",
                numericFacts: ["$3,284", "6.750%", "30"],
                fields: [
                    "monthlyPITI": "$3,284",
                    "rate": "6.750%",
                    "termYears": "30",
                    "totalInterest": "$560K",
                    "maxLoan": "$612,400",
                    "frontEndDTI": "24.2%",
                    "backEndDTI": "38.1%",
                    "monthlySavings": "$412",
                    "breakEven": "24 mo",
                    "lifeWinner": "Option A",
                    "blendedRate": "4.85%",
                    "refiRate": "6.125%",
                ]
            )
            let out = NarrationTemplates.render(
                facts: facts,
                audience: .borrower,
                locale: locale
            )
            #expect(!out.isEmpty)
        }
    }

    @Test("Templates render for Spanish locale")
    func testTemplatesES() {
        let locale = Locale(identifier: "es_MX")
        let facts = ScenarioFacts(
            scenarioType: .amortization,
            borrowerFirstName: "Maya",
            fields: ["monthlyPITI": "$3,284", "rate": "6.750%", "termYears": "30"]
        )
        let out = NarrationTemplates.render(
            facts: facts,
            audience: .borrower,
            locale: locale
        )
        #expect(out.contains("Maya"))
        #expect(out.contains("años"))
    }

    @Test("Hallucination guard flags numbers not in allowlist")
    func testGuardFlagsUnknown() {
        let text = "The monthly payment is $3,284 and the rate is 6.750%. "
            + "Extra: $9,999 unexpected!"
        let allow = ["$3,284", "6.750%"]
        let flagged = HallucinationGuard.flagUnknownNumbers(in: text, allowlist: allow)
        #expect(flagged.contains("$9,999"))
        #expect(!flagged.contains("$3,284"))
    }

    @Test("Hallucination guard doesn't flag small standalone digits")
    func testGuardSkipsTrivialFragments() {
        let text = "1 of 5 options. The rate is 6.750%."
        let flagged = HallucinationGuard.flagUnknownNumbers(
            in: text,
            allowlist: ["6.750%"]
        )
        #expect(flagged.isEmpty)
    }

    /// Session 5K.2 root cause: narration copy renders compact-currency
    /// values like "$732K" (dollarsShort), but the extractor's regex
    /// stopped at the "K", producing "$732" — which then failed exact
    /// match against the "$732K" allowlist entry and was flagged.
    @Test("Hallucination guard matches compact-currency K/M/B suffix")
    func testGuardMatchesCompactSuffix() {
        let text = "Across the life of the loan, interest totals roughly $732K. "
            + "Lifetime savings scale to $1.24M under extended terms."
        let allow = ["$732K", "$1.24M"]
        let flagged = HallucinationGuard.flagUnknownNumbers(in: text, allowlist: allow)
        #expect(flagged.isEmpty, "K/M suffix must be captured as part of the token")
    }

    /// Normalized comparison absorbs rounding between the narration's
    /// compact-currency display and the allowlist's precise value —
    /// e.g. "$732K" in copy vs "$732,456" in the fact allowlist.
    @Test("Hallucination guard tolerates ±1% normalized delta")
    func testGuardNormalizedTolerance() {
        let text = "Total interest $732K."
        let allow = ["$732,456"]
        let flagged = HallucinationGuard.flagUnknownNumbers(in: text, allowlist: allow)
        #expect(flagged.isEmpty, "values within 1% should match via normalization")
    }

    @Test("Hallucination guard still flags genuinely wrong compact values")
    func testGuardFlagsWrongCompactValue() {
        let text = "Total interest $732K."
        let allow = ["$999K"] // ~36% off — well outside tolerance
        let flagged = HallucinationGuard.flagUnknownNumbers(in: text, allowlist: allow)
        #expect(flagged.contains("$732K"))
    }

    /// Property-ish sweep: every rendered format the calculator screens
    /// produce must round-trip through the extractor + normalizer so the
    /// allowlist match succeeds.
    @Test("Hallucination guard normalizes every rendered money format")
    func testNormalizedRoundTrip() {
        let cases: [(rendered: String, expectedValue: Double)] = [
            ("$732K", 732_000),
            ("$1.24M", 1_240_000),
            ("$4,231", 4_231),
            ("$4,231.50", 4_231.5),
            ("6.750%", 6.75),
            ("$2B", 2_000_000_000),
        ]
        for c in cases {
            let v = HallucinationGuard.normalizedValue(c.rendered)
            #expect(v == c.expectedValue, "failed on \(c.rendered)")
        }
    }

    @Test("Narrator streams non-empty content through template path")
    func testNarratorStreamsTemplates() async throws {
        let facts = ScenarioFacts(
            scenarioType: .refinance,
            borrowerFirstName: "Priya",
            fields: ["monthlySavings": "$412", "breakEven": "24 mo"]
        )
        let narrator = QuotientNarrator()
        let stream = narrator.narrate(
            facts,
            audience: .borrower,
            locale: Locale(identifier: "en_US")
        )
        var assembled = ""
        for try await chunk in stream {
            assembled += chunk.text
        }
        #expect(assembled.contains("Priya"))
        #expect(assembled.contains("$412"))
        #expect(assembled.contains("24 mo"))
    }
}
