// CompareTests.swift
// Unit tests for `compareScenarios` and `ScenarioMetrics`.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("compareScenarios")
struct CompareScenariosTests {

    private static let standardStartDate = date(2026, 1, 1)

    private static func currentLoan() -> ScenarioInput {
        ScenarioInput(
            name: "Current",
            loan: Loan(
                principal: 400_000,
                annualRate: 0.075,
                termMonths: 360,
                startDate: standardStartDate
            ),
            closingCosts: 0
        )
    }

    private static func refiA() -> ScenarioInput {
        ScenarioInput(
            name: "Refi A",
            loan: Loan(
                principal: 400_000,
                annualRate: 0.065,
                termMonths: 360,
                startDate: standardStartDate
            ),
            closingCosts: 7_500
        )
    }

    private static func refiB() -> ScenarioInput {
        ScenarioInput(
            name: "Refi B",
            loan: Loan(
                principal: 400_000,
                annualRate: 0.0625,
                termMonths: 360,
                startDate: standardStartDate
            ),
            closingCosts: 10_000
        )
    }

    @Test("Empty scenarios produces an empty result")
    func emptyIsEmpty() {
        let result = compareScenarios([], horizons: [5, 10])
        #expect(result.scenarioTotalCosts.isEmpty)
        #expect(result.winnerByHorizon.isEmpty)
        #expect(result.scenarioMetrics.isEmpty)
        // Horizons pass through.
        #expect(result.horizons == [5, 10])
    }

    @Test("Shape: parallel-indexed arrays")
    func parallelIndexedArrays() {
        let result = compareScenarios(
            [Self.currentLoan(), Self.refiA(), Self.refiB()],
            horizons: [5, 7, 10, 15, 30]
        )
        #expect(result.scenarioTotalCosts.count == 3)
        #expect(result.scenarioMetrics.count == 3)
        #expect(result.winnerByHorizon.count == 5)
        for row in result.scenarioTotalCosts {
            #expect(row.count == 5)
        }
    }

    @Test("Baseline's monthlyPIDelta is zero")
    func baselineDeltaIsZero() {
        let result = compareScenarios(
            [Self.currentLoan(), Self.refiA()],
            horizons: [5, 10]
        )
        #expect(result.scenarioMetrics[0].monthlyPIDelta == 0)
        #expect(result.scenarioMetrics[0].lifetimeCostDelta == 0)
        #expect(result.scenarioMetrics[0].breakEvenMonth == nil)
    }

    @Test("Refi with lower rate has negative monthlyPIDelta")
    func lowerRateHasNegativeDelta() {
        let result = compareScenarios(
            [Self.currentLoan(), Self.refiA()],
            horizons: [5, 10, 30]
        )
        // refi payment < current payment → delta is negative (borrower pays less).
        #expect(result.scenarioMetrics[1].monthlyPIDelta < 0)
    }

    @Test("Break-even month is positive and finite for a refi with savings")
    func breakEvenIsFinite() {
        let result = compareScenarios(
            [Self.currentLoan(), Self.refiA()],
            horizons: [5, 10, 30]
        )
        let be = result.scenarioMetrics[1].breakEvenMonth
        #expect(be != nil)
        if let months = be {
            #expect(months > 0 && months < 360)
        }
    }

    @Test("Break-even is nil when candidate payment is not lower than baseline")
    func breakEvenNilWhenNoSavings() {
        let pricier = ScenarioInput(
            name: "Pricier",
            loan: Loan(
                principal: 400_000,
                annualRate: 0.09,  // higher rate than current's 7.5%
                termMonths: 360,
                startDate: Self.standardStartDate
            ),
            closingCosts: 5_000
        )
        let result = compareScenarios(
            [Self.currentLoan(), pricier],
            horizons: [5, 30]
        )
        #expect(result.scenarioMetrics[1].breakEvenMonth == nil)
    }

    @Test("lifetimeCostDelta at longest horizon matches totalCosts delta")
    func lifetimeDeltaMatchesTotals() {
        let result = compareScenarios(
            [Self.currentLoan(), Self.refiA()],
            horizons: [5, 10, 30]
        )
        let baselineLongest = result.scenarioTotalCosts[0].last ?? 0
        let refiLongest = result.scenarioTotalCosts[1].last ?? 0
        let expected = refiLongest - baselineLongest
        #expect(result.scenarioMetrics[1].lifetimeCostDelta == expected)
    }

    @Test("NPV @ 5% is negative for every scenario (loans are costs)")
    func npvIsNegative() {
        let result = compareScenarios(
            [Self.currentLoan(), Self.refiA(), Self.refiB()],
            horizons: [30]
        )
        for m in result.scenarioMetrics {
            #expect(m.npvAt5pct < 0)
        }
    }

    @Test("Winner at 30-year horizon picks a refi over current when rate savings dominate")
    func longHorizonWinnerIsRefi() {
        let result = compareScenarios(
            [Self.currentLoan(), Self.refiA(), Self.refiB()],
            horizons: [30]
        )
        let winner = result.winnerByHorizon[0]
        // Current is index 0; refi A/B index 1/2. At a 30yr horizon both refis
        // recoup their closing costs and then some; winner must be 1 or 2.
        #expect(winner == 1 || winner == 2)
    }

    @Test("Carrying costs (taxes + ins + HOA) appear additively in totals")
    func carryingCostsAdditive() {
        let noCarry = ScenarioInput(
            name: "A",
            loan: Loan(
                principal: 300_000,
                annualRate: 0.06,
                termMonths: 360,
                startDate: Self.standardStartDate
            )
        )
        let withCarry = ScenarioInput(
            name: "A",
            loan: noCarry.loan,
            monthlyTaxes: 500,
            monthlyInsurance: 100,
            monthlyHOA: 50
        )
        let resultA = compareScenarios([noCarry], horizons: [10])
        let resultB = compareScenarios([withCarry], horizons: [10])
        // 10 years × 12 months × (500 + 100 + 50) = 78,000
        let delta = resultB.scenarioTotalCosts[0][0] - resultA.scenarioTotalCosts[0][0]
        #expect(delta == 78_000)
    }

    @Test("Zero-horizon total equals closing costs only")
    func zeroHorizonIsClosing() {
        let result = compareScenarios(
            [Self.refiA()],
            horizons: [0]
        )
        #expect(result.scenarioTotalCosts[0][0] == 7_500)
    }

    @Test("Empty horizons produces empty per-scenario totals + empty winners")
    func emptyHorizonsStillProducesMetrics() {
        let result = compareScenarios(
            [Self.currentLoan(), Self.refiA()],
            horizons: []
        )
        #expect(result.scenarioTotalCosts.count == 2)
        #expect(result.scenarioTotalCosts.allSatisfy { $0.isEmpty })
        #expect(result.winnerByHorizon.isEmpty)
        // Metrics still produced for each scenario, with lifetimeCostDelta = 0
        // (no horizon → nothing to sum).
        #expect(result.scenarioMetrics.count == 2)
        #expect(result.scenarioMetrics[1].lifetimeCostDelta == 0)
    }

    @Test("Candidate with lower closing costs than baseline break-evens at month 0")
    func lowerClosingCostsBreakEvenImmediate() {
        let baseline = ScenarioInput(
            name: "Baseline with rolled-in costs",
            loan: Loan(
                principal: 400_000,
                annualRate: 0.075,
                termMonths: 360,
                startDate: Self.standardStartDate
            ),
            closingCosts: 12_000
        )
        let savingsRefi = ScenarioInput(
            name: "No-cost refi",
            loan: Loan(
                principal: 400_000,
                annualRate: 0.065,
                termMonths: 360,
                startDate: Self.standardStartDate
            ),
            closingCosts: 0
        )
        let result = compareScenarios([baseline, savingsRefi], horizons: [5, 30])
        // Candidate saves money AND has lower closing costs → immediate break-even.
        #expect(result.scenarioMetrics[1].breakEvenMonth == 0)
    }

    @Test("Performance benchmark budget: 4 × 30yr under 50 ms (smoke, not measure)")
    func fourScenariosRuns() {
        let inputs: [ScenarioInput] = (0..<4).map { i in
            ScenarioInput(
                name: "S\(i)",
                loan: Loan(
                    principal: 400_000,
                    annualRate: 0.065 + Double(i) * 0.0025,
                    termMonths: 360,
                    startDate: Self.standardStartDate
                ),
                closingCosts: Decimal(5_000 + i * 500)
            )
        }
        let result = compareScenarios(inputs, horizons: [5, 7, 10, 15, 30])
        #expect(result.scenarioMetrics.count == 4)
        #expect(result.winnerByHorizon.count == 5)
    }
}
