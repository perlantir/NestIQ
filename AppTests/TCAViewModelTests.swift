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

    // MARK: - 5P.9 break-even uses currentMortgage baseline

    private func mortgageWithPayment(
        pi: Decimal,
        termYears: Int = 30,
        monthsPaid: Int = 24
    ) -> CurrentMortgage {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(
            byAdding: .month, value: -monthsPaid, to: Date()
        ) ?? Date()
        return CurrentMortgage(
            currentBalance: 450_000,
            currentRatePercent: 6.500,
            currentMonthlyPaymentPI: pi,
            originalLoanAmount: 500_000,
            originalTermYears: termYears,
            loanStartDate: start,
            propertyValueToday: 600_000
        )
    }

    func testBreakEvenBaselineFallsBackToScenarioAWhenNoCurrentMortgage() {
        let inputs = TCAFormInputs.sampleDefault
        XCTAssertNil(inputs.currentMortgage)
        let monthlyPayments: [Decimal] = [3200, 2900, 3000, 2700]
        XCTAssertEqual(inputs.breakEvenBaselinePayment(monthlyPayments: monthlyPayments), 3200)
    }

    func testBreakEvenBaselineUsesCurrentMortgageWhenSet() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.currentMortgage = mortgageWithPayment(pi: 2_900)
        let monthlyPayments: [Decimal] = [3200, 2900, 3000, 2700]
        XCTAssertEqual(
            inputs.breakEvenBaselinePayment(monthlyPayments: monthlyPayments),
            2_900,
            "Break-even must anchor on the current mortgage's P&I, not scenario A"
        )
    }

    func testBreakEvenMonthComputedAgainstCurrentMortgage() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.currentMortgage = mortgageWithPayment(pi: 3_000)
        inputs.scenarios[0].closingCosts = 6_000
        // Scenario A payment 2700 → monthly savings 300 → break-even 20 months
        let monthlyPayments: [Decimal] = [2700, 3200, 2800, 2500]
        let month = inputs.breakEvenMonth(scenarioIndex: 0, monthlyPayments: monthlyPayments)
        XCTAssertEqual(month, 20, "6000 closing / 300 monthly = 20 months")
    }

    func testBreakEvenTermMonthsClampsToCurrentMortgageRemainingTerm() {
        var inputs = TCAFormInputs.sampleDefault
        // Current mortgage: 30-yr, 25 years in → 60 months remaining.
        inputs.currentMortgage = mortgageWithPayment(
            pi: 3_000, termYears: 30, monthsPaid: 25 * 12
        )
        inputs.scenarios[0].termYears = 30
        // 30-yr scenario would nominally allow 360 months; remaining-term clamp drops it.
        let clamped = inputs.breakEvenTermMonths(scenarioIndex: 0)
        XCTAssertLessThanOrEqual(clamped, 60,
                                 "New loan only has the remaining term of the old loan to recoup closing")
        XCTAssertGreaterThan(clamped, 0)
    }

    func testBreakEvenTermMonthsWithoutCurrentMortgageUsesScenarioTerm() {
        let inputs = TCAFormInputs.sampleDefault
        let scenarioTerm = inputs.scenarios[0].termYears * 12
        XCTAssertEqual(inputs.breakEvenTermMonths(scenarioIndex: 0), scenarioTerm)
    }

    // MARK: - 5P.8 currentMortgage Codable round-trip on TCAFormInputs

    func testTCAFormInputsCurrentMortgageRoundtrip() throws {
        var inputs = TCAFormInputs.sampleDefault
        inputs.currentMortgage = mortgageWithPayment(pi: 2_900)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(inputs)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TCAFormInputs.self, from: data)
        XCTAssertEqual(decoded.currentMortgage?.currentMonthlyPaymentPI, 2_900)
    }

    func testTCAFormInputsLoadsCurrentMortgageAsNilForLegacyJSON() throws {
        // JSON without currentMortgage — backward compat for 5M/5N/5O scenarios.
        let json = """
        {
            "mode": "refinance",
            "loanAmount": 400000,
            "homeValue": 600000,
            "monthlyTaxes": 500,
            "monthlyInsurance": 120,
            "monthlyHOA": 0,
            "scenarios": [],
            "horizonsYears": [5, 10, 30],
            "includeDebts": true,
            "scenarioCount": 2
        }
        """.data(using: .utf8) ?? Data()
        let inputs = try JSONDecoder().decode(TCAFormInputs.self, from: json)
        XCTAssertNil(inputs.currentMortgage)
    }

    // MARK: - Session 5Q.6 — reinvestment + break-even with currentMortgage

    /// Build a refi scenario with a currentMortgage costing $3000/mo in
    /// P&I against a proposed scenario A at $2400/mo. With
    /// currentMortgage set, A is a candidate — pathAInvestmentBalance
    /// should return > 0. Without currentMortgage, A is the baseline
    /// and path-A returns 0.
    func testPathAUsesCurrentMortgageBaselineWhenSet() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        let mortgage = CurrentMortgage(
            currentBalance: 400_000,
            currentRatePercent: 7.5,
            currentMonthlyPaymentPI: 3_000,
            originalLoanAmount: 450_000,
            originalTermYears: 30,
            loanStartDate: Date(timeIntervalSince1970: 1_650_000_000),
            propertyValueToday: 600_000
        )
        // Payments: [A=2400, B=2300] — both cheaper than $3000 current.
        let payments: [Decimal] = [2_400, 2_300]

        // Without currentMortgage: pre-5Q.6 legacy behavior — A is
        // the baseline and returns 0.
        inputs.currentMortgage = nil
        XCTAssertEqual(inputs.pathAInvestmentBalance(
            scenarioIndex: 0, months: 60, monthlyPayments: payments
        ), 0, "Without currentMortgage, scenario A is baseline → 0")

        // With currentMortgage: A is a candidate with $600/mo savings.
        inputs.currentMortgage = mortgage
        let path = inputs.pathAInvestmentBalance(
            scenarioIndex: 0, months: 60, monthlyPayments: payments
        )
        XCTAssertGreaterThan(path, 0,
            "With currentMortgage, scenario A's $600/mo savings should produce a non-zero future value")
    }

    /// Break-even chart series includes scenario A when currentMortgage
    /// is set and A saves vs status quo. 5P.9 established this for
    /// `breakEvenSeries`; 5Q.6 didn't change this helper but pins the
    /// contract while we're adjusting related code paths.
    func testBreakEvenSeriesIncludesScenarioAWhenCurrentMortgageSet() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.currentMortgage = CurrentMortgage(
            currentBalance: 400_000,
            currentRatePercent: 7.5,
            currentMonthlyPaymentPI: 3_000,
            originalLoanAmount: 450_000,
            originalTermYears: 30,
            loanStartDate: Date(timeIntervalSince1970: 1_650_000_000),
            propertyValueToday: 600_000
        )
        // Set A and B to known closing / payments.
        inputs.scenarios = [
            TCAScenario(label: "A", name: "Conv 30",
                        rate: 6.0, termYears: 30, closingCosts: 6_000,
                        loanAmount: 400_000),
            TCAScenario(label: "B", name: "Conv 15",
                        rate: 5.5, termYears: 15, closingCosts: 8_000,
                        loanAmount: 400_000),
        ]
        let payments: [Decimal] = [2_398, 3_267]  // A < current, B > current

        let series = TCAScreen.breakEvenSeries(
            inputs: inputs,
            monthlyPayments: payments,
            colorForIndex: { _ in .black }
        )
        let ids = series.map(\.id)
        XCTAssertTrue(ids.contains(0),
            "Scenario A must appear in break-even series when currentMortgage is set and A saves vs status quo")
    }

    /// Reinvestment savings: path-A and path-B baselines now resolve
    /// via `breakEvenBaselinePayment`, so they agree with the break-
    /// even math. Without currentMortgage + idx==0 stays skipped.
    // MARK: - Session 5R.2 — double-points bug fix

    /// Regression: `scenarioInputs()` must not add `principal × points`
    /// back into closing costs — points are already baked into the
    /// all-in `closingCosts` value per the 5B.5 convention. Pre-5R.2
    /// the helper double-charged, inflating engine closingCosts by
    /// the point dollar value and throwing off break-even /
    /// unrecoverable / total-cost math.
    /// Regression for the 5R.2 MI plumbing: scenario.monthlyMI is now
    /// forwarded to the engine via an AmortizationOptions.pmiSchedule.
    /// Pre-5R.2 the field was displayed but dropped silently, so
    /// `cumulativeMI(throughMonth:)` returned 0 and unrecoverable
    /// cost understated by the MI dollar amount.
    func testScenarioInputsPlumbsMIIntoEngine() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.loanAmount = 400_000
        inputs.homeValue = 500_000
        inputs.scenarios = [
            TCAScenario(
                label: "A",
                name: "Conv 30 w/ MI",
                rate: 6.5,
                termYears: 30,
                points: 0,
                closingCosts: 8_000,
                loanAmount: 400_000,
                monthlyMI: 180
            )
        ]
        let engineInputs = inputs.scenarioInputs()
        let schedule = amortize(
            loan: engineInputs[0].loan,
            options: engineInputs[0].options
        )
        // 12 months × $180/mo = $2,160 — barring HPA dropoff within
        // the first year. Starting LTV is 400/500 = 0.80 vs drop at
        // 0.78 threshold × 500 = $390. Balance at month 12 is still
        // well above $390K, so MI applies every month.
        let firstYearMI = schedule.cumulativeMI(throughMonth: 12)
        XCTAssertEqual(firstYearMI, 2_160,
            "Expected 12 × $180 = $2,160 of MI in year 1")
    }

    func testScenarioInputsDoesNotDoubleChargePoints() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.loanAmount = 400_000
        inputs.scenarios = [
            TCAScenario(
                label: "A",
                name: "Conv 30 w/ 1.5 pts",
                rate: 6.0,
                termYears: 30,
                points: 1.5,              // 1.5% of $400K = $6,000
                closingCosts: 12_000,     // ALL-IN amount (includes the $6K points)
                loanAmount: 400_000
            )
        ]
        let engineInputs = inputs.scenarioInputs()
        XCTAssertEqual(engineInputs.first?.closingCosts, 12_000,
            "scenarioInputs() must pass closingCosts through unchanged — points are already in the all-in value")
    }

    func testPathBSkipsScenarioAWhenNoCurrentMortgage() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.currentMortgage = nil
        let loan = Loan(
            principal: 400_000, annualRate: 0.06,
            termMonths: 360, startDate: Date()
        )
        let schedule = amortize(loan: loan)
        let result = inputs.pathBExtraPrincipal(
            scenarioIndex: 0,
            schedule: schedule,
            monthlyPayments: [2_398, 2_300]
        )
        XCTAssertNil(result,
            "Without currentMortgage, scenario A is the baseline — pathB must return nil")
    }
}
