// DisclaimerTests.swift
// Unit tests for `requiredDisclaimer(context:locale:)` and
// `equalHousingOpportunityStatement(locale:)`.

import Testing
import Foundation
@testable import QuotientCompliance

@Suite("requiredDisclaimer")
struct RequiredDisclaimerTests {

    private static let en = Locale(identifier: "en_US")
    private static let es = Locale(identifier: "es_MX")

    @Test("Every DisclaimerContext case has EN + ES copy registered")
    func everyContextRegistered() {
        for c in DisclaimerContext.allCases {
            let enText = requiredDisclaimer(context: c, locale: Self.en)
            let esText = requiredDisclaimer(context: c, locale: Self.es)
            #expect(!enText.isEmpty, "Missing EN for \(c)")
            #expect(!esText.isEmpty, "Missing ES for \(c)")
            #expect(enText != esText, "EN and ES identical for \(c)")
        }
    }

    @Test("marketingGeneral copy mentions illustrative")
    func marketingGeneralCopy() {
        let en = requiredDisclaimer(context: .marketingGeneral, locale: Self.en)
        #expect(en.lowercased().contains("illustrative"))
    }

    @Test("pdfCoverFooter EN is the short 'Not a Loan Estimate' wording")
    func coverFooterWording() {
        let en = requiredDisclaimer(context: .pdfCoverFooter, locale: Self.en)
        #expect(en.contains("Loan Estimate"))
        #expect(en.contains("commitment to lend"))
    }

    @Test("narrationGenerated and narrativeRegenerated differ in wording")
    func generatedVsRegeneratedDiffer() {
        let generated = requiredDisclaimer(context: .narrationGenerated, locale: Self.en)
        let regenerated = requiredDisclaimer(context: .narrativeRegenerated, locale: Self.en)
        #expect(generated != regenerated)
    }

    @Test("Non-EN non-ES locale falls back to EN")
    func nonEnNonEsFallsBackToEn() {
        let fr = Locale(identifier: "fr_FR")
        let frText = requiredDisclaimer(context: .marketingGeneral, locale: fr)
        let enText = requiredDisclaimer(context: .marketingGeneral, locale: Self.en)
        #expect(frText == enText)
    }
}

@Suite("equalHousingOpportunityStatement")
struct EHOTests {

    @Test("EN statement mentions federal fair housing + equal credit acts")
    func enWording() {
        let stmt = equalHousingOpportunityStatement(locale: Locale(identifier: "en_US"))
        #expect(stmt.contains("Equal Housing Opportunity"))
        #expect(stmt.contains("Fair Housing"))
    }

    @Test("ES statement provided and non-empty")
    func esProvided() {
        let stmt = equalHousingOpportunityStatement(locale: Locale(identifier: "es_MX"))
        #expect(!stmt.isEmpty)
        #expect(stmt.contains("Igualdad"))
    }

    @Test("EN and ES differ")
    func enEsDiffer() {
        let en = equalHousingOpportunityStatement(locale: Locale(identifier: "en_US"))
        let es = equalHousingOpportunityStatement(locale: Locale(identifier: "es_MX"))
        #expect(en != es)
    }
}
