// AmortizationViewModelTests.swift
// Session 3 unit coverage for the @Observable view model that wraps
// the finance engine.

import XCTest
import Foundation
import QuotientFinance
@testable import Quotient

@MainActor
final class AmortizationViewModelTests: XCTestCase {

    func testComputePopulatesSchedule() {
        let vm = AmortizationViewModel()
        XCTAssertNil(vm.schedule)
        vm.compute()
        XCTAssertNotNil(vm.schedule)
        XCTAssertEqual(vm.schedule?.payments.count, 360)
        XCTAssertTrue(vm.hasComputed)
    }

    func testMonthlyPITIIncludesAllComponents() {
        let vm = AmortizationViewModel()
        vm.compute()
        let pi = vm.monthlyPI
        let tax = vm.monthlyTax
        let ins = vm.monthlyInsurance
        let total = vm.monthlyPITI
        // PITI should be at least the P&I + taxes + insurance components.
        XCTAssertGreaterThanOrEqual(total, pi + tax + ins - Decimal(1))
    }

    func testYearlyBalancesMonotonicallyDecreasing() {
        let vm = AmortizationViewModel()
        vm.compute()
        let years = vm.yearlyBalances
        XCTAssertGreaterThan(years.count, 25, "Should have ~30 yearly samples for a 30-year loan")
        for i in 1..<years.count {
            XCTAssertLessThanOrEqual(years[i].balance, years[i - 1].balance)
        }
        XCTAssertEqual(years.last?.balance, 0)
    }

    func testSnapshotSerializes() {
        let vm = AmortizationViewModel()
        vm.compute()
        let snap = vm.buildScenario()
        XCTAssertFalse(snap.inputsJSON.isEmpty)
        XCTAssertNotNil(snap.outputsJSON)
        XCTAssertTrue(snap.keyStat.contains("30-yr"))
    }

    func testInputEditTriggersRecomputeWhenHasComputed() {
        let vm = AmortizationViewModel()
        vm.compute()
        let firstPI = vm.monthlyPI
        // Bump rate — simulate what the UI does via @Observable.
        vm.inputs.annualRate = 7.5
        vm.compute() // caller triggers after input edit (view binds this)
        XCTAssertNotEqual(firstPI, vm.monthlyPI)
    }

    // MARK: - 5P.1 Extra principal regression

    func testExtraPrincipalReducesTotalInterestVsBaseline() {
        let baseline = AmortizationViewModel()
        baseline.compute()
        let baselineInterest = baseline.totalInterest
        let baselinePayoff = baseline.payoffDate

        let accelerated = AmortizationViewModel()
        accelerated.inputs.extraPrincipalMonthly = 500
        accelerated.compute()

        XCTAssertLessThan(accelerated.totalInterest, baselineInterest,
                          "Extra principal must reduce total interest")
        guard let basePayoff = baselinePayoff,
              let accelPayoff = accelerated.payoffDate else {
            return XCTFail("Both schedules must produce a payoff date")
        }
        XCTAssertLessThan(accelPayoff, basePayoff,
                          "Extra principal must retire the loan earlier")
        XCTAssertLessThan(accelerated.schedule?.numberOfPayments ?? .max,
                          baseline.schedule?.numberOfPayments ?? 0,
                          "Accelerated schedule must have fewer payments")
    }

    func testYearlyBalancesTerminatesAtActualPayoffWithExtraPrincipal() {
        let vm = AmortizationViewModel()
        vm.inputs.extraPrincipalMonthly = 500
        vm.compute()
        let years = vm.yearlyBalances

        XCTAssertEqual(years.last?.balance, 0, "Chart must end at 0 balance")
        guard let lastYear = years.last?.year else {
            return XCTFail("Expected at least one yearly sample")
        }
        XCTAssertLessThan(lastYear, vm.inputs.termYears,
                          "$500/mo extra on a 30-yr loan should terminate well before year 30")
        // No trailing pad point at termYears: the final sample is the
        // actual payoff year, not (30, 0).
        XCTAssertFalse(years.contains(where: { $0.year == vm.inputs.termYears && $0.balance == 0 }) && lastYear < vm.inputs.termYears && years.dropLast().last?.year == lastYear,
                       "Must not pad out to scheduled termYears after early payoff")
    }

    func testNoExtraPrincipalMatchesBaseline() {
        let vm = AmortizationViewModel()
        XCTAssertEqual(vm.inputs.extraPrincipalMonthly, 0)
        vm.compute()
        let years = vm.yearlyBalances
        // 30-yr loan, no extras: last sample must be year 30 with 0 balance.
        XCTAssertEqual(years.last?.year, vm.inputs.termYears)
        XCTAssertEqual(years.last?.balance, 0)
        // payments.count equals full term * 12 (within rounding residual).
        XCTAssertEqual(vm.schedule?.numberOfPayments, vm.inputs.termYears * 12)
    }
}
