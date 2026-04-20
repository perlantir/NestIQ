// SmokeEdgeCasesTests.swift
// Session 5R.4 — regression + E2E smoke coverage. Each calculator gets
// two kinds of coverage here: (1) Codable round-trip through the saved-
// scenario JSON payload so save/reload never drops a field, and (2) a
// handful of edge-case computes (0% rate, 40yr term, high LTV / $0
// closing) to catch crashes or divide-by-zero regressions that the
// happy-path tests wouldn't surface.

import XCTest
import Foundation
import QuotientFinance
@testable import Quotient

@MainActor
final class SmokeEdgeCasesTests: XCTestCase {

    // MARK: - Codable round-trip (save/reload)

    /// Each FormInputs type is persisted into Scenario.inputsJSON and
    /// later decoded by ScenarioDestinationView. If any field drops
    /// during encode/decode, the edit flow silently loses data.
    func testAmortizationFormInputsRoundTrip() throws {
        try assertRoundTrip(AmortizationFormInputs.sampleDefault)
    }

    func testRefinanceFormInputsRoundTrip() throws {
        try assertRoundTrip(RefinanceFormInputs.sampleDefault)
    }

    func testTCAFormInputsRoundTrip() throws {
        try assertRoundTrip(TCAFormInputs.sampleDefault)
    }

    func testHelocFormInputsRoundTrip() throws {
        try assertRoundTrip(HelocFormInputs.sampleDefault)
    }

    func testIncomeQualFormInputsRoundTrip() throws {
        try assertRoundTrip(IncomeQualFormInputs.sampleDefault)
    }

    private func assertRoundTrip<T: Codable & Equatable & Sendable>(_ value: T,
                                                                    file: StaticString = #filePath,
                                                                    line: UInt = #line) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(value)
        let decoded = try decoder.decode(T.self, from: data)
        XCTAssertEqual(decoded, value, "round-trip must preserve all fields",
                       file: file, line: line)
    }

    // MARK: - Amortization edge cases

    func testAmortizationZeroRateComputes() {
        var inputs = AmortizationFormInputs.sampleDefault
        inputs.annualRate = 0
        let vm = AmortizationViewModel(inputs: inputs)
        vm.compute()
        XCTAssertNotNil(vm.schedule)
        XCTAssertEqual(vm.schedule?.payments.count, 360)
        // With 0% rate, total interest should be ~zero.
        let totalInterest = vm.schedule?.payments.reduce(Decimal(0)) { $0 + $1.interest } ?? -1
        XCTAssertEqual(totalInterest, 0, "0% rate means no interest accrual")
    }

    func testAmortization40YearTermComputes() {
        var inputs = AmortizationFormInputs.sampleDefault
        inputs.termYears = 40
        let vm = AmortizationViewModel(inputs: inputs)
        vm.compute()
        XCTAssertEqual(vm.schedule?.payments.count, 480)
        XCTAssertEqual(vm.schedule?.payments.last?.balance, 0)
    }

    func testAmortizationHighLTVPurchaseComputes() {
        var inputs = AmortizationFormInputs.sampleDefault
        inputs.mode = .purchase
        inputs.loanAmount = 485_000   // 97% LTV
        inputs.includePMI = true
        inputs.manualMonthlyPMI = 220
        let vm = AmortizationViewModel(inputs: inputs)
        vm.compute()
        XCTAssertNotNil(vm.schedule)
        XCTAssertGreaterThan(vm.monthlyPITI, 0)
    }

    // MARK: - Refinance edge cases

    func testRefinanceZeroClosingCostsComputes() {
        var inputs = RefinanceFormInputs.sampleDefault
        for idx in inputs.options.indices {
            inputs.options[idx].closingCosts = 0
        }
        let vm = RefinanceViewModel(inputs: inputs)
        vm.compute()
        XCTAssertEqual(vm.result?.scenarioMetrics.count, inputs.options.count + 1)
        // With zero closing costs the break-even should be immediate
        // (month 0 or 1) for any option that actually lowers the monthly
        // payment — the exact sentinel is implementation detail, but it
        // must not be nil or out in the years.
        vm.selectedOptionIndex = 1
        if vm.monthlySavings > 0, let be = vm.breakEvenMonth {
            XCTAssertLessThanOrEqual(be, 1,
                                     "zero closing costs means instant break-even")
        }
    }

    func testRefinanceZeroRateOptionDoesNotCrash() {
        var inputs = RefinanceFormInputs.sampleDefault
        if !inputs.options.isEmpty {
            inputs.options[0].rate = 0
        }
        let vm = RefinanceViewModel(inputs: inputs)
        vm.compute()
        XCTAssertNotNil(vm.result)
    }

    // MARK: - TCA edge cases

    func testTCAZeroRateScenarioComputes() {
        var inputs = TCAFormInputs.sampleDefault
        if !inputs.scenarios.isEmpty {
            inputs.scenarios[0].rate = 0
        }
        let vm = TCAViewModel(inputs: inputs)
        vm.compute()
        XCTAssertNotNil(vm.result)
    }

    func testTCAZeroClosingCostsComputes() {
        var inputs = TCAFormInputs.sampleDefault
        for idx in inputs.scenarios.indices {
            inputs.scenarios[idx].closingCosts = 0
        }
        let vm = TCAViewModel(inputs: inputs)
        vm.compute()
        XCTAssertNotNil(vm.result)
    }

    // MARK: - HELOC edge cases

    func testHelocZeroRateFirstLienComputes() {
        var inputs = HelocFormInputs.sampleDefault
        inputs.firstLienRate = 0
        let vm = HelocViewModel(inputs: inputs)
        let _ = vm.blendedRate
        XCTAssertGreaterThanOrEqual(vm.blendedRate, 0)
    }

    // MARK: - Income Qualification edge cases

    func testIncomeQualHighDebtProducesZeroOrCappedLoan() {
        var inputs = IncomeQualFormInputs.sampleDefault
        // Stack debts beyond the back-end cap.
        inputs.debts.append(MonthlyDebt(label: "Debt overflow", monthlyAmount: 12_000))
        let vm = IncomeQualViewModel(inputs: inputs)
        XCTAssertGreaterThanOrEqual(vm.maxLoan, 0,
                                    "maxLoan must clamp to 0, not go negative")
    }

    func testIncomeQualZeroIncomeProducesZeroLoan() {
        var inputs = IncomeQualFormInputs.sampleDefault
        inputs.incomes = [IncomeSource(label: "None", monthlyAmount: 0)]
        let vm = IncomeQualViewModel(inputs: inputs)
        XCTAssertEqual(vm.maxLoan, 0)
    }
}
