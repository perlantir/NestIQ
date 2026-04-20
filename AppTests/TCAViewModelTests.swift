// TCAViewModelTests.swift

import XCTest
import Foundation
@testable import Quotient

@MainActor
final class TCAViewModelTests: XCTestCase {

    func testComputeProducesMatrixForDefault() {
        let vm = TCAViewModel()
        vm.compute()
        let result = vm.result
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.scenarioTotalCosts.count, vm.inputs.scenarios.count)
        XCTAssertEqual(result?.scenarioTotalCosts.first?.count,
                       vm.inputs.horizonsYears.count)
    }

    func testEachHorizonHasAWinner() {
        let vm = TCAViewModel()
        vm.compute()
        let winners = vm.result?.winnerByHorizon ?? []
        XCTAssertEqual(winners.count, vm.inputs.horizonsYears.count)
        for w in winners {
            XCTAssertTrue(w >= 0 && w < vm.inputs.scenarios.count)
        }
    }

    // MARK: - Session 5M.3 — approximate cash-to-close

    /// Purchase: Price + Closing + Prepaids − Down − Credits.
    func testCashToClosePurchase() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .purchase
        var propertyDP = PropertyDownPaymentConfig.empty
        propertyDP.purchasePrice = 500_000
        propertyDP.downPaymentDollar = 100_000
        propertyDP.useDownPaymentDollar = true
        inputs.scenarios = [
            TCAScenario(
                label: "A",
                name: "Conv 30",
                rate: 6.75,
                termYears: 30,
                closingCosts: 12_000,
                propertyDP: propertyDP,
                prepaids: 4_500,
                credits: 2_000
            ),
        ]
        // 500_000 + 12_000 + 4_500 - 100_000 - 2_000 = 414_500
        XCTAssertEqual(
            inputs.approximateCashToClose(for: inputs.scenarios[0]),
            Decimal(414_500)
        )
    }

    /// Refinance: Closing + Prepaids − Credits.
    func testCashToCloseRefinance() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.scenarios[0] = TCAScenario(
            label: "A",
            name: "Conv 30",
            rate: 6.75,
            termYears: 30,
            closingCosts: 9_800,
            prepaids: 3_200,
            credits: 1_000
        )
        // 9_800 + 3_200 - 1_000 = 12_000
        XCTAssertEqual(
            inputs.approximateCashToClose(for: inputs.scenarios[0]),
            Decimal(12_000)
        )
    }

    /// All zero inputs → zero cash, no crash.
    func testCashToCloseZeroWhenEmpty() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.scenarios[0] = TCAScenario(
            label: "A",
            name: "Blank",
            rate: 0,
            termYears: 30
        )
        XCTAssertEqual(
            inputs.approximateCashToClose(for: inputs.scenarios[0]),
            0
        )
    }

    /// Credits exceeding costs clamp at 0 (not negative).
    func testCashToCloseClampsAtZeroWhenCreditsExceedCosts() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.scenarios[0] = TCAScenario(
            label: "A",
            name: "Oversized credit",
            rate: 6.75,
            termYears: 30,
            closingCosts: 5_000,
            prepaids: 0,
            credits: 8_000
        )
        XCTAssertEqual(
            inputs.approximateCashToClose(for: inputs.scenarios[0]),
            0
        )
    }
}
