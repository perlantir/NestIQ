// RefinanceViewModelTests.swift

import XCTest
import Foundation
@testable import Quotient

@MainActor
final class RefinanceViewModelTests: XCTestCase {

    func testComputePopulatesResult() {
        let vm = RefinanceViewModel()
        XCTAssertNil(vm.result)
        vm.compute()
        XCTAssertNotNil(vm.result)
        // Current + 3 options = 4 scenario metrics.
        XCTAssertEqual(vm.result?.scenarioMetrics.count, 4)
    }

    func testOptionAIsBestForSampleDefault() {
        let vm = RefinanceViewModel()
        vm.compute()
        // Sample default has A at 6.125% vs current 7.375% — should save.
        vm.selectedOptionIndex = 1
        XCTAssertGreaterThan(vm.monthlySavings, 0)
        XCTAssertNotNil(vm.breakEvenMonth)
    }

    func testSelectingCurrentIndexProducesZeroSavings() {
        let vm = RefinanceViewModel()
        vm.compute()
        vm.selectedOptionIndex = 0
        XCTAssertEqual(vm.monthlySavings, 0)
    }

    func testCumulativeSavingsCrossesZeroAtBreakEven() {
        let vm = RefinanceViewModel()
        vm.compute()
        let rows = vm.cumulativeSavings(for: 1, monthsCap: 60)
        XCTAssertTrue(rows.contains { $0.1 >= 0 })
        XCTAssertTrue(rows.contains { $0.1 < 0 })
    }
}
