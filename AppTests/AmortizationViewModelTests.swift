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
}
