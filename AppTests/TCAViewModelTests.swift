// TCAViewModelTests.swift

import XCTest
import Foundation
import QuotientFinance
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

    // MARK: - Session 5M.6 — unrecoverable / ongoing housing

    /// Unrecoverable == closing + cumulative interest + cumulative MI.
    /// Tax/insurance/HOA explicitly excluded.
    func testUnrecoverableCostFormula() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.loanAmount = 300_000
        inputs.monthlyTaxes = 500  // these should NOT leak in
        inputs.monthlyInsurance = 150
        inputs.monthlyHOA = 0
        let scenario = TCAScenario(
            label: "A",
            name: "Conv 30",
            rate: 6.0,
            termYears: 30,
            closingCosts: 10_000,
            loanAmount: 300_000
        )
        inputs.scenarios = [scenario]
        // Build the schedule the same way the view model does.
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: Date(timeIntervalSince1970: 1_767_225_600)
        )
        let schedule = amortize(loan: loan)
        let result = inputs.unrecoverableCost(scenario: scenario, schedule: schedule, years: 10)
        // Should equal closing + cumulative interest@120 + cumulative MI@120.
        let interest = schedule.cumulativeInterest(throughMonth: 120)
        let mi = schedule.cumulativeMI(throughMonth: 120)  // 0 with no PMI
        XCTAssertEqual(result, 10_000 + interest + mi)
    }

    /// Ongoing housing is a separate computation, not folded into
    /// unrecoverable.
    func testOngoingHousingCostsSeparate() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.monthlyTaxes = 500
        inputs.monthlyInsurance = 150
        inputs.monthlyHOA = 100
        // (500 + 150 + 100) × 12 × 10yr = 90k.
        XCTAssertEqual(inputs.ongoingHousingCost(years: 10), 90_000)
    }

    /// Before any payments are made (horizon 0), unrecoverable = just
    /// closing costs. Interest and MI are zero.
    func testUnrecoverableAtHorizonZero() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.loanAmount = 300_000
        let scenario = TCAScenario(
            label: "A",
            name: "Conv 30",
            rate: 6.0,
            termYears: 30,
            closingCosts: 12_500,
            loanAmount: 300_000
        )
        inputs.scenarios = [scenario]
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: Date(timeIntervalSince1970: 1_767_225_600)
        )
        let schedule = amortize(loan: loan)
        XCTAssertEqual(
            inputs.unrecoverableCost(scenario: scenario, schedule: schedule, years: 0),
            12_500
        )
    }

    // MARK: - Session 5M.7 — break-even

    /// Known values: baseline 7%/$300k/30yr vs scenario 5%/$300k/30yr
    /// with $5k closing. Monthly P&I @ 7% on 300k/30yr is ~$1,995.91.
    /// @5%: ~$1,610.46. Monthly savings ~$385.45. Break-even: ceil(5000
    /// / 385.45) = 13 months.
    func testBreakEvenMonthKnownValues() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        let baseline = TCAScenario(
            label: "A", name: "Current", rate: 7.0, termYears: 30,
            closingCosts: 0, loanAmount: 300_000
        )
        let alt = TCAScenario(
            label: "B", name: "Refi 5%", rate: 5.0, termYears: 30,
            closingCosts: 5_000, loanAmount: 300_000
        )
        inputs.scenarios = [baseline, alt]
        // Build monthlyPayments from fresh schedules (mirror compute()).
        let payments: [Decimal] = inputs.scenarios.map { s in
            let loan = Loan(
                principal: 300_000,
                annualRate: s.rate / 100,
                termMonths: s.termYears * 12,
                startDate: Date(timeIntervalSince1970: 1_767_225_600)
            )
            return amortize(loan: loan).scheduledPeriodicPayment
        }
        let month = inputs.breakEvenMonth(scenarioIndex: 1, monthlyPayments: payments)
        XCTAssertNotNil(month)
        XCTAssertEqual(month, 13)
    }

    /// If the refi scenario has a higher monthly payment than baseline,
    /// there is no break-even — return nil.
    func testBreakEvenNeverWhenNoSavings() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.scenarios = [
            TCAScenario(label: "A", name: "Current", rate: 5.0, termYears: 30,
                        closingCosts: 0, loanAmount: 300_000),
            TCAScenario(label: "B", name: "Worse refi", rate: 7.0, termYears: 30,
                        closingCosts: 5_000, loanAmount: 300_000),
        ]
        // Monthly P&I @ 5% is ~$1,610; @ 7% is ~$1,996 — scenario B
        // costs MORE monthly. Savings is negative; no break-even.
        let payments: [Decimal] = [Decimal(1_610), Decimal(1_996)]
        XCTAssertNil(inputs.breakEvenMonth(scenarioIndex: 1, monthlyPayments: payments))
    }

    /// Graph data: monthlyPayments fed in, cumulative grows linearly.
    /// At month 12 with savings of $100/mo, cumulative should be $1,200.
    func testBreakEvenGraphDataPointsCorrect() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.scenarios = [
            TCAScenario(label: "A", name: "Baseline", rate: 7.0, termYears: 30,
                        closingCosts: 0, loanAmount: 300_000),
            TCAScenario(label: "B", name: "Refi", rate: 5.0, termYears: 30,
                        closingCosts: 5_000, loanAmount: 300_000),
        ]
        // Inject flat payments so cumulative math is deterministic.
        let payments: [Decimal] = [Decimal(1_500), Decimal(1_400)]  // 100/mo savings
        let data = inputs.breakEvenGraphData(
            scenarioIndex: 1,
            monthlyPayments: payments,
            maxMonths: 12
        )
        XCTAssertEqual(data.count, 13)  // months 0…12 inclusive
        XCTAssertEqual(data[0].cumulative, 0)
        XCTAssertEqual(data[12].cumulative, 1_200)
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
