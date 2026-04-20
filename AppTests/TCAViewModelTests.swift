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

    // MARK: - Session 5M.8 — reinvestment strategy

    /// Known annuity check: baseline payment $1,500, scenario payment
    /// $1,400 → savings $100/mo. Invested at 7% for 120 months → per
    /// textbook ~$17,308.
    func testReinvestmentBalanceAt10Years() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.scenarios = [
            TCAScenario(label: "A", name: "Baseline", rate: 7.0, termYears: 30,
                        closingCosts: 0, loanAmount: 300_000),
            TCAScenario(label: "B", name: "Refi", rate: 5.0, termYears: 30,
                        closingCosts: 5_000, loanAmount: 300_000),
        ]
        let payments: [Decimal] = [Decimal(1_500), Decimal(1_400)]
        let balance = inputs.pathAInvestmentBalance(
            scenarioIndex: 1,
            months: 120,
            monthlyPayments: payments
        )
        let balanceDouble = balance.asDouble
        XCTAssertTrue(balanceDouble > 17_300 && balanceDouble < 17_320,
                      "Expected ~17,308, got \(balanceDouble)")
    }

    /// Applying $100/mo extra principal should shorten the payoff by
    /// some number of months > 0. Specific month count depends on
    /// amortize()'s internals; assert the invariant only.
    func testExtraPrincipalShortensLoan() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        let scenario = TCAScenario(
            label: "B", name: "Refi", rate: 5.0, termYears: 30,
            closingCosts: 5_000, loanAmount: 300_000
        )
        inputs.scenarios = [
            TCAScenario(label: "A", name: "Baseline", rate: 7.0, termYears: 30,
                        closingCosts: 0, loanAmount: 300_000),
            scenario,
        ]
        let payments: [Decimal] = [Decimal(1_996), Decimal(1_610)]  // approx
        let schedule = amortize(loan: Loan(
            principal: 300_000,
            annualRate: 0.05,
            termMonths: 360,
            startDate: Date(timeIntervalSince1970: 1_767_225_600)
        ))
        let result = inputs.pathBExtraPrincipal(
            scenarioIndex: 1,
            schedule: schedule,
            monthlyPayments: payments
        )
        XCTAssertNotNil(result)
        if let result {
            XCTAssertTrue(result.newPayoffMonth < result.originalPayoffMonth)
            XCTAssertTrue(result.interestSaved > 0)
            XCTAssertTrue(result.wealthBuilt > 0)
        }
    }

    /// When savings are zero or negative (refi costs more monthly),
    /// both paths return zero / nil — no silent false positives.
    func testBothPathsSameInputsProduceExpectedOutputs() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.scenarios = [
            TCAScenario(label: "A", name: "Baseline", rate: 5.0, termYears: 30,
                        closingCosts: 0, loanAmount: 300_000),
            TCAScenario(label: "B", name: "Worse refi", rate: 7.0, termYears: 30,
                        closingCosts: 5_000, loanAmount: 300_000),
        ]
        // Baseline $1,610/mo, scenario $1,996/mo → savings NEGATIVE.
        let payments: [Decimal] = [Decimal(1_610), Decimal(1_996)]
        let balance = inputs.pathAInvestmentBalance(
            scenarioIndex: 1,
            months: 120,
            monthlyPayments: payments
        )
        XCTAssertEqual(balance, 0)  // no savings to invest
        let schedule = amortize(loan: Loan(
            principal: 300_000,
            annualRate: 0.07,
            termMonths: 360,
            startDate: Date(timeIntervalSince1970: 1_767_225_600)
        ))
        let pathB = inputs.pathBExtraPrincipal(
            scenarioIndex: 1,
            schedule: schedule,
            monthlyPayments: payments
        )
        XCTAssertNil(pathB)  // no savings to apply
    }

    // MARK: - Session 5M.9 — equity buildup

    /// Known equity: 500k home, 400k loan, month 120. Remaining balance
    /// at month 120 on a 30yr/6% schedule is ~$334,732. Equity ≈ 500k −
    /// 334,732 = 165,268. Invariant-only check: equity should be > 0
    /// and < home value.
    func testEquityAtHorizonKnownLoan() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.homeValue = 500_000
        let scenario = TCAScenario(
            label: "A", name: "Conv 30", rate: 6.0, termYears: 30,
            closingCosts: 0, loanAmount: 400_000
        )
        inputs.scenarios = [scenario]
        let schedule = amortize(loan: Loan(
            principal: 400_000, annualRate: 0.06, termMonths: 360,
            startDate: Date(timeIntervalSince1970: 1_767_225_600)
        ))
        let equity = inputs.equityAtHorizon(scenarioIndex: 0, schedule: schedule, years: 10)
        XCTAssertTrue(equity > 150_000 && equity < 180_000,
                      "Expected ~165k equity, got \(equity)")
    }

    /// Same principal / home value, shorter term pays down principal
    /// faster → higher equity at any mid-schedule horizon.
    func testEquityGreaterForFasterAmortization() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.homeValue = 500_000
        inputs.scenarios = [
            TCAScenario(label: "A", name: "15yr", rate: 5.0, termYears: 15,
                        closingCosts: 0, loanAmount: 400_000),
            TCAScenario(label: "B", name: "30yr", rate: 5.0, termYears: 30,
                        closingCosts: 0, loanAmount: 400_000),
        ]
        let loan15 = amortize(loan: Loan(
            principal: 400_000, annualRate: 0.05, termMonths: 180,
            startDate: Date(timeIntervalSince1970: 1_767_225_600)
        ))
        let loan30 = amortize(loan: Loan(
            principal: 400_000, annualRate: 0.05, termMonths: 360,
            startDate: Date(timeIntervalSince1970: 1_767_225_600)
        ))
        let eq15 = inputs.equityAtHorizon(scenarioIndex: 0, schedule: loan15, years: 5)
        let eq30 = inputs.equityAtHorizon(scenarioIndex: 1, schedule: loan30, years: 5)
        XCTAssertTrue(eq15 > eq30)
    }

    /// Purchase mode uses scenario.propertyDP.purchasePrice rather
    /// than the form-level homeValue.
    func testEquityUsesScenarioPriceInPurchaseMode() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .purchase
        inputs.homeValue = 0  // deliberately unset
        var propertyDP = PropertyDownPaymentConfig.empty
        propertyDP.purchasePrice = 600_000
        propertyDP.downPaymentDollar = 120_000
        propertyDP.useDownPaymentDollar = true
        let scenario = TCAScenario(
            label: "A", name: "Conv 30", rate: 6.0, termYears: 30,
            loanAmount: 0, propertyDP: propertyDP
        )
        inputs.scenarios = [scenario]
        let schedule = amortize(loan: Loan(
            principal: 480_000, annualRate: 0.06, termMonths: 360,
            startDate: Date(timeIntervalSince1970: 1_767_225_600)
        ))
        // At month 0 equity = price - full principal = 600k - 480k = 120k.
        let equityAtZero = inputs.equityAtHorizon(scenarioIndex: 0, schedule: schedule, years: 0)
        XCTAssertEqual(equityAtZero, 120_000)
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

    // MARK: - 5P.5 Scenario input isolation

    func testScenariosHaveDistinctUUIDs() {
        let vm = TCAViewModel()
        let ids = vm.inputs.scenarios.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count,
                       "Each scenario must have a unique UUID so SwiftUI can key views per scenario")
    }

    func testScenarioEditDoesNotBleedAcrossIndices() {
        var inputs = TCAFormInputs.sampleDefault
        let originalBRate = inputs.scenarios[1].rate
        let originalBLoan = inputs.scenarios[1].loanAmount
        let originalCRate = inputs.scenarios[2].rate
        inputs.scenarios[0].rate = 4.25
        inputs.scenarios[0].loanAmount = 400_000
        XCTAssertEqual(inputs.scenarios[1].rate, originalBRate,
                       "Editing scenario A rate must not change scenario B rate")
        XCTAssertEqual(inputs.scenarios[1].loanAmount, originalBLoan,
                       "Editing scenario A loan must not change scenario B loan")
        XCTAssertEqual(inputs.scenarios[2].rate, originalCRate,
                       "Editing scenario A rate must not change scenario C rate")
    }

    func testResizeScenariosPreservesExistingEntries() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.scenarios[0].rate = 3.125
        inputs.scenarios[1].rate = 4.75
        let originalA = inputs.scenarios[0].id
        let originalB = inputs.scenarios[1].id
        inputs.resizeScenarios(to: 4)
        XCTAssertEqual(inputs.scenarios[0].id, originalA)
        XCTAssertEqual(inputs.scenarios[1].id, originalB)
        XCTAssertEqual(inputs.scenarios[0].rate, 3.125)
        XCTAssertEqual(inputs.scenarios[1].rate, 4.75)
        XCTAssertEqual(inputs.scenarios.count, 4)
        inputs.resizeScenarios(to: 2)
        XCTAssertEqual(inputs.scenarios[0].id, originalA)
        XCTAssertEqual(inputs.scenarios[1].id, originalB)
        XCTAssertEqual(inputs.scenarios.count, 2)
    }
}
