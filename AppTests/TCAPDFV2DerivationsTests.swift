// TCAPDFV2DerivationsTests.swift
// Session 7.3e — coverage for the v2.1.1 TCA page-4 HTML emitters that
// back the iOS-local template patch (interest-split / unrecoverable /
// reinvestment sections).

import XCTest
@testable import Quotient

@MainActor
final class TCAPDFV2DerivationsTests: XCTestCase {

    // MARK: - Scalar tokens

    func testLongestHorizonYearsIsMaxOfConfigured() {
        let vm = TCAViewModel()
        vm.compute()
        let expected = vm.inputs.horizonsYears.max() ?? 30
        XCTAssertEqual(TCAPDFHTML.longestHorizonYears(viewModel: vm), expected)
    }

    func testOngoingHousingFormattedIsNonEmptyDollarShort() {
        let vm = TCAViewModel()
        vm.compute()
        let formatted = TCAPDFHTML.ongoingHousingFormatted(viewModel: vm)
        XCTAssertFalse(formatted.isEmpty)
        // MoneyFormat.dollarsShort renders "$NNNK" or "$N.NM" — should
        // contain a "$" prefix.
        XCTAssertTrue(formatted.contains("$"), "Got: \(formatted)")
    }

    func testReinvestmentRateFormattedMatchesPercent() {
        let vm = TCAViewModel()
        let pct = TCAPDFHTML.reinvestmentRateFormatted(viewModel: vm)
        XCTAssertTrue(pct.hasSuffix("%"))
        // Default reinvestment rate ≈ 5.25% — expect "5.25%" or similar.
        let expected = String(format: "%.2f%%", vm.inputs.reinvestmentRate.asDouble * 100)
        XCTAssertEqual(pct, expected)
    }

    // MARK: - Interest-split

    func testInterestSplitHeaderIncludesScenarioLabels() {
        let vm = TCAViewModel()
        vm.compute()
        let header = TCAPDFHTML.interestSplitHeader(viewModel: vm)
        XCTAssertTrue(header.hasPrefix("<tr>"))
        XCTAssertTrue(header.contains("Horizon"))
        // At least one scenario label (upper-cased) appears.
        XCTAssertTrue(
            vm.inputs.scenarios.contains { header.contains($0.label.uppercased()) },
            "Header missing any scenario label. Got: \(header)"
        )
    }

    func testInterestSplitRowsHasOneTrPerHorizon() {
        let vm = TCAViewModel()
        vm.compute()
        let rows = TCAPDFHTML.interestSplitRows(viewModel: vm)
        let trCount = rows.components(separatedBy: "<tr>").count - 1
        XCTAssertEqual(trCount, vm.inputs.horizonsYears.count)
    }

    func testInterestSplitRowsEmptyWhenNoSchedules() {
        let vm = TCAViewModel()
        // Don't call compute() — scenarioSchedules stays empty.
        let rows = TCAPDFHTML.interestSplitRows(viewModel: vm)
        XCTAssertEqual(rows, "")
    }

    // MARK: - Unrecoverable rows

    func testUnrecoverableRowsIncludesAllScenarios() {
        let vm = TCAViewModel()
        vm.compute()
        let rows = TCAPDFHTML.unrecoverableRows(viewModel: vm)
        for scenario in vm.inputs.scenarios {
            XCTAssertTrue(
                rows.contains(scenario.label.uppercased()),
                "Scenario \(scenario.label.uppercased()) missing from unrecoverable rows"
            )
        }
    }

    func testUnrecoverableRowsEmptyWhenNoSchedules() {
        let vm = TCAViewModel()
        XCTAssertEqual(TCAPDFHTML.unrecoverableRows(viewModel: vm), "")
    }

    // MARK: - Reinvestment section

    func testReinvestmentSectionEmptyInPurchaseMode() {
        let vm = TCAViewModel()
        vm.inputs.mode = .purchase
        vm.compute()
        XCTAssertEqual(
            TCAPDFHTML.reinvestmentSectionHTML(viewModel: vm), "",
            "Reinvestment section must render as empty in purchase mode"
        )
    }

    func testReinvestmentSectionEmptyBeforeCompute() {
        let vm = TCAViewModel()
        vm.inputs.mode = .refinance
        // Don't compute — result is nil, section should still be empty.
        XCTAssertEqual(
            TCAPDFHTML.reinvestmentSectionHTML(viewModel: vm), ""
        )
    }
}
