// SchemaMigrationTests.swift
// Session 5M.1: exercise the backward-compatible decoding paths on
// every calculator's FormInputs Codable. Each test constructs a JSON
// payload that omits the 5M additions (aprRate, prepaids, credits,
// reinvestmentRate, currentAPR, firstLienAPR / helocAPR / refiAPR)
// and asserts the decoder populates defaults without crashing.
//
// Scenario.inputsJSON is a JSON blob, not a SwiftData schema. Per the
// D7 (corrected) decision, the migration strategy is "new fields
// decode as nil or documented default." These tests are the proof.

import XCTest
@testable import Quotient

final class SchemaMigrationTests: XCTestCase {

    // MARK: - Amortization

    func testAmortizationDecodesWithoutAPRRate() throws {
        let json = """
        {
            "mode": "purchase",
            "loanAmount": 500000,
            "annualRate": 6.75,
            "termYears": 30,
            "startDate": 760147200,
            "annualTaxes": 6500,
            "annualInsurance": 1620,
            "monthlyHOA": 0,
            "includePMI": false,
            "manualMonthlyPMI": 0,
            "extraPrincipalMonthly": 0,
            "biweekly": false
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let inputs = try decoder.decode(AmortizationFormInputs.self, from: json)
        XCTAssertNil(inputs.aprRate)
        XCTAssertEqual(inputs.annualRate, 6.75)
    }

    // MARK: - Income Qualification

    func testIncomeQualDecodesWithoutAPRRate() throws {
        let json = """
        {
            "mode": "purchase",
            "loanType": "conventional",
            "creditScore": 740,
            "frontEndLimit": 0.28,
            "backEndLimit": 0.43,
            "annualRate": 6.75,
            "termYears": 30,
            "annualTaxes": 6500,
            "annualInsurance": 1620,
            "monthlyHOA": 0,
            "downPaymentPercent": 0.2,
            "incomes": [],
            "debts": []
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let inputs = try decoder.decode(IncomeQualFormInputs.self, from: json)
        XCTAssertNil(inputs.aprRate)
        XCTAssertEqual(inputs.reservesMonths, 2)  // existing default
    }

    // MARK: - Refinance

    func testRefinanceDecodesWithoutAPRRates() throws {
        let json = """
        {
            "currentBalance": 412300,
            "currentRate": 7.375,
            "currentRemainingYears": 28,
            "monthlyTaxes": 542,
            "monthlyInsurance": 135,
            "monthlyHOA": 0,
            "options": [
                {
                    "id": "00000000-0000-0000-0000-000000000001",
                    "label": "A",
                    "rate": 6.125,
                    "termYears": 30,
                    "points": 0.5,
                    "closingCosts": 9800
                }
            ],
            "horizonsYears": [5, 10, 30],
            "stressTestHorizonYears": 5
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let inputs = try decoder.decode(RefinanceFormInputs.self, from: json)
        XCTAssertNil(inputs.currentAPR)
        XCTAssertEqual(inputs.options.count, 1)
        XCTAssertNil(inputs.options[0].aprRate)
    }

    // MARK: - TCA

    func testTCADecodesWithoutNewFields() throws {
        let json = """
        {
            "mode": "refinance",
            "loanAmount": 548000,
            "monthlyTaxes": 542,
            "monthlyInsurance": 135,
            "monthlyHOA": 0,
            "scenarios": [
                {
                    "id": "00000000-0000-0000-0000-000000000001",
                    "label": "A",
                    "name": "Conv 30",
                    "rate": 6.75,
                    "termYears": 30,
                    "points": 0,
                    "closingCosts": 0
                }
            ],
            "horizonsYears": [5, 10, 30]
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let inputs = try decoder.decode(TCAFormInputs.self, from: json)
        XCTAssertEqual(inputs.reinvestmentRate, TCAFormInputs.defaultReinvestmentRate)
        XCTAssertEqual(inputs.reinvestmentRate, Decimal(string: "0.07"))
        XCTAssertEqual(inputs.scenarios.count, 1)
        let scenario = inputs.scenarios[0]
        XCTAssertNil(scenario.aprRate)
        XCTAssertEqual(scenario.prepaids, 0)
        XCTAssertEqual(scenario.credits, 0)
    }

    // MARK: - HELOC

    func testHelocDecodesWithoutAPRFields() throws {
        let json = """
        {
            "firstLienBalance": 318000,
            "firstLienRate": 3.125,
            "firstLienRemainingYears": 22,
            "helocAmount": 80000,
            "helocIntroRate": 6.99,
            "helocIntroMonths": 12,
            "helocFullyIndexedRate": 8.75,
            "refiRate": 6.125,
            "refiTermYears": 30,
            "stressShockBps": 200
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let inputs = try decoder.decode(HelocFormInputs.self, from: json)
        XCTAssertNil(inputs.firstLienAPR)
        XCTAssertNil(inputs.helocAPR)
        XCTAssertNil(inputs.refiAPR)
        XCTAssertEqual(inputs.firstLienRate, 3.125)
    }

    // MARK: - Round-trip sanity

    /// Encode-then-decode preserves APR values when present.
    func testAmortizationRoundTripWithAPR() throws {
        var original = AmortizationFormInputs.sampleDefault
        original.aprRate = Decimal(string: "6.812")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AmortizationFormInputs.self, from: encoded)
        XCTAssertEqual(decoded.aprRate, Decimal(string: "6.812"))
    }
}
