// BreakEvenChartTests.swift
// Session 5O.9 — unit coverage for the on-screen break-even chart
// data layer. The Swift Chart view itself isn't testable, but
// TCAScreen.breakEvenSeries(monthlyPayments:) is a pure function on
// the view model + inputs — we exercise its filtering and domain
// behavior end-to-end here.

import XCTest
import SwiftUI
import QuotientFinance
@testable import Quotient

@MainActor
final class BreakEvenChartTests: XCTestCase {

    /// Scenario that breaks even within its term is included in the
    /// series and its points span 0…termMonths exactly.
    func testSeriesDomainMatchesScenarioTerm() throws {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        // Baseline: high rate. Option A: significant rate drop → big
        // monthly savings that will cross closing cost within term.
        inputs.scenarios = [
            TCAScenario(label: "A", name: "Current",
                        rate: 7.500, termYears: 30,
                        loanAmount: 400_000),
            TCAScenario(label: "B", name: "Refi 30",
                        rate: 5.500, termYears: 30,
                        closingCosts: 8_000,
                        loanAmount: 400_000)
        ]
        let vm = TCAViewModel(inputs: inputs)
        vm.compute()
        let monthlyPayments = vm.result?.scenarioMetrics.map(\.payment) ?? []

        let series = TCAScreen.breakEvenSeries(
            inputs: vm.inputs,
            monthlyPayments: monthlyPayments,
            colorForIndex: { _ in .black }
        )
        XCTAssertEqual(series.count, 1, "Only scenario B should produce a series")
        let item = try XCTUnwrap(series.first)
        XCTAssertEqual(item.termMonths, 360,
                       "Series termMonths should reflect scenario.termYears * 12")
        XCTAssertEqual(item.points.last?.month, 360,
                       "Series x-axis should span to termMonths")
        XCTAssertNotNil(item.crossover,
                        "Significantly-lower-rate scenario must cross closing costs")
    }

    /// Scenario that never crosses closing within term is excluded
    /// from the series (the chart is empty), but its description line
    /// still surfaces via breakEvenDescriptionLines.
    func testSeriesExcludesNonCrossingScenario() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        // Tiny rate delta + huge closing costs → no crossover in 30yr.
        inputs.scenarios = [
            TCAScenario(label: "A", name: "Current",
                        rate: 7.000, termYears: 30,
                        loanAmount: 400_000),
            TCAScenario(label: "B", name: "Refi 30",
                        rate: 6.990, termYears: 30,
                        closingCosts: 100_000,
                        loanAmount: 400_000)
        ]
        let vm = TCAViewModel(inputs: inputs)
        vm.compute()
        let monthlyPayments = vm.result?.scenarioMetrics.map(\.payment) ?? []

        let series = TCAScreen.breakEvenSeries(
            inputs: vm.inputs,
            monthlyPayments: monthlyPayments,
            colorForIndex: { _ in .black }
        )
        XCTAssertTrue(series.isEmpty,
                      "Non-crossing scenario should be excluded from chart series")

        // Description should still carry a text line describing the
        // non-crossing result.
        let lines = TCAScreen.breakEvenDescriptionLines(
            inputs: vm.inputs,
            monthlyPayments: monthlyPayments
        )
        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines.first?.contains("do not exceed closing costs") ?? false,
                      "Non-crossing scenario should get a 'do not exceed' text line. Got: \(lines)")
    }

    /// Mixed case: one scenario crosses, another doesn't. Chart series
    /// contains only the crossing one; description covers both.
    func testSeriesFiltersOutNonCrossingInMixedScenarios() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.scenarios = [
            TCAScenario(label: "A", name: "Current",
                        rate: 7.500, termYears: 30,
                        loanAmount: 400_000),
            TCAScenario(label: "B", name: "Refi 30",
                        rate: 5.500, termYears: 30,
                        closingCosts: 8_000,
                        loanAmount: 400_000),
            TCAScenario(label: "C", name: "Refi 15",
                        rate: 7.400, termYears: 15,
                        closingCosts: 50_000,
                        loanAmount: 400_000)
        ]
        let vm = TCAViewModel(inputs: inputs)
        vm.compute()
        let monthlyPayments = vm.result?.scenarioMetrics.map(\.payment) ?? []

        let series = TCAScreen.breakEvenSeries(
            inputs: vm.inputs,
            monthlyPayments: monthlyPayments,
            colorForIndex: { _ in .black }
        )
        XCTAssertEqual(series.count, 1,
                       "Only the crossing scenario should be in the chart")
        XCTAssertEqual(series.first?.seriesKey, "B")
    }

}
