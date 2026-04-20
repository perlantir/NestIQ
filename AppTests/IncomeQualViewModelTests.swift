// IncomeQualViewModelTests.swift

import XCTest
import Foundation
@testable import Quotient

@MainActor
final class IncomeQualViewModelTests: XCTestCase {

    func testMaxQualifyingLoanFromSample() {
        let vm = IncomeQualViewModel()
        // Qualifying income + standard sample should produce a
        // positive max loan.
        XCTAssertGreaterThan(vm.maxLoan, 0)
    }

    func testPrefilledAmortizationMatchesMaxLoan() {
        let vm = IncomeQualViewModel()
        let prefilled = vm.prefilledAmortizationInputs()
        XCTAssertEqual(prefilled.loanAmount, vm.maxLoan)
        XCTAssertEqual(prefilled.termYears, vm.inputs.termYears)
        XCTAssertEqual(prefilled.annualRate, vm.inputs.annualRate)
    }

    func testIncomeWeightReducesQualifyingAmount() {
        var inputs = IncomeQualFormInputs.sampleDefault
        let rental = inputs.incomes.last
        XCTAssertEqual(rental?.weightPercent, 0.75)
        // Qualifying should be less than the raw sum because rental
        // income is only counted at 75%.
        let rawSum = inputs.incomes.reduce(Decimal(0)) { $0 + $1.monthlyAmount }
        XCTAssertLessThan(inputs.qualifyingIncome, rawSum)
        inputs.incomes[2].weightPercent = 1.0
        XCTAssertEqual(inputs.qualifyingIncome, rawSum)
    }

    func testDTICapOver() {
        var inputs = IncomeQualFormInputs.sampleDefault
        inputs.debts.append(MonthlyDebt(label: "Extra", monthlyAmount: 4000))
        let vm = IncomeQualViewModel(inputs: inputs)
        XCTAssertTrue(vm.backEndDTIIncludingDebts >= inputs.backEndLimit
                      || vm.maxLoan == 0)
    }

    // MARK: - 5P.4 Reserves persistence + default

    func testReservesMonthsDefaultsToTwo() {
        let vm = IncomeQualViewModel()
        XCTAssertEqual(vm.inputs.reservesMonths, 2)
    }

    func testReservesMonthsRangeClampedOnDecode() throws {
        // Out-of-range decoded values clamp to 0...36 (per 5J.2 range).
        let encoder = JSONEncoder()
        var inputs = IncomeQualFormInputs.sampleDefault
        inputs.reservesMonths = 24
        let data = try encoder.encode(inputs)
        let decoded = try JSONDecoder().decode(IncomeQualFormInputs.self, from: data)
        XCTAssertEqual(decoded.reservesMonths, 24)
    }

    func testReservesMonthsPersistsInScenarioSnapshot() throws {
        let vm = IncomeQualViewModel()
        vm.inputs.reservesMonths = 12
        let snap = vm.buildScenario()
        let decoded = try JSONDecoder().decode(IncomeQualFormInputs.self, from: snap.inputsJSON)
        XCTAssertEqual(decoded.reservesMonths, 12,
                       "Reserves selection must survive the Save/Load round-trip")
    }
}
