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
