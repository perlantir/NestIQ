// EdgeCaseTests.swift
// Branch-coverage targeted tests for zero-rate, zero-periods, and other
// lightly-traveled paths in the TVM and rate primitives.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("PV/FV zero-rate and zero-periods branches")
struct PVFVZeroBranches {

    @Test("PV of lump sum with zero rate equals FV")
    func pvLumpSumZeroRate() {
        #expect(presentValue(futureValue: 1000, periodRate: 0, periods: 60) == 1000)
    }

    @Test("PV of lump sum with zero periods equals FV")
    func pvLumpSumZeroPeriods() {
        #expect(presentValue(futureValue: 1000, periodRate: 0.05, periods: 0) == 1000)
    }

    @Test("PV of annuity with zero rate equals payment × periods")
    func pvAnnuityZeroRate() {
        let pv = presentValue(payment: 100, periodRate: 0, periods: 12)
        #expect(pv == 1200)
    }

    @Test("FV of lump sum with zero rate equals PV")
    func fvLumpSumZeroRate() {
        #expect(futureValue(presentValue: 1000, periodRate: 0, periods: 60) == 1000)
    }

    @Test("FV of lump sum with zero periods equals PV")
    func fvLumpSumZeroPeriods() {
        #expect(futureValue(presentValue: 1000, periodRate: 0.05, periods: 0) == 1000)
    }

    @Test("FV of annuity with zero rate equals payment × periods")
    func fvAnnuityZeroRate() {
        let fv = futureValue(payment: 250, periodRate: 0, periods: 24)
        #expect(fv == 6000)
    }
}

@Suite("Amortize edge paths")
struct AmortizeEdgePaths {

    @Test("Loan with extras larger than balance caps gracefully")
    func extrasLargerThanBalance() {
        let loan = Loan(
            principal: 100_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let lump = ExtraPayment(period: 1, amount: 500_000)
        let schedule = amortize(
            loan: loan,
            options: AmortizationOptions(oneTimeExtra: [lump])
        )
        // Loan should pay off in period 1
        #expect(schedule.numberOfPayments == 1)
        if let last = schedule.payments.last {
            #expect(last.balance == 0)
        }
    }

    @Test("PMI minimum periods honored")
    func pmiMinimumPeriods() {
        let policy = PMISchedule(
            monthlyAmount: 100,
            originalValue: 100_000, // tiny home so LTV drops below 78% quickly
            dropAtLTV: 0.78,
            minimumPeriods: 24
        )
        let loan = Loan(
            principal: 1_000, // already below the 78% threshold of orig value
            annualRate: 0.06,
            termMonths: 60,
            startDate: date(2026, 1, 1)
        )
        let schedule = amortize(loan: loan, options: AmortizationOptions(pmiSchedule: policy))
        // First 24 payments should still carry PMI even though LTV < 78%.
        for row in schedule.payments.prefix(24) {
            #expect(row.pmi == 100)
        }
    }
}

@Suite("PMI: USDA fallthrough, exempt VA")
struct PMIFallthrough {

    @Test("USDA returns 0 monthly via PMI primitive")
    func usdaZeroPMI() {
        let pmi = calculatePMI(
            ltv: 1.0,
            creditScore: 700,
            loanAmount: 250_000,
            loanType: .usda
        )
        #expect(pmi == 0)
    }
}

@Suite("Rates: precondition surrounding code paths")
struct RatesPreconditionAdjacent {

    @Test("blendedRate with three tranches")
    func blendedThreeTranches() {
        let r = blendedRate(tranches: [
            .init(balance: 100_000, annualRate: 0.05),
            .init(balance: 50_000, annualRate: 0.07),
            .init(balance: 25_000, annualRate: 0.10)
        ])
        // Weighted: (100*0.05 + 50*0.07 + 25*0.10) / 175 = (5 + 3.5 + 2.5)/175 = 0.0628...
        #expect(r.isApproximatelyEqual(to: 0.0628571, tolerance: 1e-5))
    }
}

@Suite("DTI / LTV / MaxQual edge branches")
struct UnderwritingMoreEdges {

    @Test("DTI with negative debts returns 0")
    func dtiNegative() {
        let d = calculateDTI(monthlyDebts: -100, grossMonthlyIncome: 5_000)
        #expect(d == 0)
    }

    @Test("MaxQualifyingLoan with very high HOA → small loan")
    func maxQualHighHOA() {
        let max = calculateMaxQualifyingLoan(
            grossMonthlyIncome: 8_000,
            monthlyDebts: 500,
            annualRate: 0.07,
            termMonths: 360,
            monthlyTaxes: 200,
            monthlyInsurance: 100,
            monthlyHOA: 600
        )
        #expect(max > 0)
    }
}

@Suite("Amortize: alternative frequencies")
struct AmortizeFrequencyTests {

    @Test("Weekly schedule advances by 7 days")
    func weeklyDateAdvance() {
        let loan = Loan(
            principal: 50_000,
            annualRate: 0.05,
            termMonths: 60,
            startDate: date(2026, 1, 1),
            frequency: .weekly
        )
        let schedule = amortize(loan: loan)
        let cal = Calendar(identifier: .gregorian)
        let days = cal.dateComponents(
            [.day],
            from: schedule.payments[0].date,
            to: schedule.payments[1].date
        ).day ?? 0
        #expect(days == 7)
    }

    @Test("SemiMonthly schedule advances by 15 days")
    func semiMonthlyDateAdvance() {
        let loan = Loan(
            principal: 50_000,
            annualRate: 0.05,
            termMonths: 60,
            startDate: date(2026, 1, 1),
            frequency: .semiMonthly
        )
        let schedule = amortize(loan: loan)
        let cal = Calendar(identifier: .gregorian)
        let days = cal.dateComponents(
            [.day],
            from: schedule.payments[0].date,
            to: schedule.payments[1].date
        ).day ?? 0
        #expect(days == 15)
    }
}

@Suite("IRR / XIRR no-bracket throw")
struct IRRNoBracketTests {

    @Test("IRR with IRR above bisection ceiling throws")
    func irrAboveCeiling() {
        // -1 then +1,000,000 → IRR is 999,999%, far above our 10000% high bound.
        // Both endpoints evaluate positive, no sign change → throws.
        #expect(throws: FinanceError.self) {
            _ = try irr(cashFlows: [-1, 1_000_000])
        }
    }

    @Test("XIRR with IRR above bisection ceiling throws")
    func xirrAboveCeiling() {
        let d0 = date(2026, 1, 1)
        let d1 = date(2026, 1, 2)  // 1 day later
        #expect(throws: FinanceError.self) {
            _ = try xirr(cashFlows: [(d0, -1), (d1, 1_000_000)])
        }
    }
}

@Suite("blendedRate guards")
struct BlendedRateGuardTests {

    @Test("Empty tranches returns 0")
    func empty() {
        #expect(blendedRate(tranches: []) == 0)
    }

    @Test("Zero total balance returns 0")
    func zeroBalance() {
        let r = blendedRate(tranches: [.init(balance: 0, annualRate: 0.05)])
        #expect(r == 0)
    }
}

@Suite("Decimal.isPositive extension")
struct DecimalIsPositiveTests {
    @Test("Positive returns true")
    func pos() { #expect((Decimal(5) as Decimal).isPositive) }
    @Test("Zero returns false")
    func zero() { #expect(!(Decimal(0) as Decimal).isPositive) }
    @Test("Negative returns false")
    func neg() { #expect(!(Decimal(-1) as Decimal).isPositive) }
}

@Suite("Type initializers and constructors")
struct TypeInitTests {

    @Test("ComparisonResult init is callable")
    func comparisonResultInit() {
        let cr = ComparisonResult(
            scenarioTotalCosts: [[100, 200], [110, 190]],
            winnerByHorizon: [0, 1],
            horizons: [5, 10]
        )
        #expect(cr.scenarioTotalCosts.count == 2)
        #expect(cr.winnerByHorizon == [0, 1])
        #expect(cr.horizons == [5, 10])
    }

    @Test("AmortizationPayment init is callable")
    func paymentInit() {
        let row = AmortizationPayment(
            number: 1,
            date: date(2026, 1, 1),
            payment: 1000,
            principal: 500,
            interest: 500,
            extraPrincipal: 0,
            pmi: 0,
            balance: 99_500
        )
        #expect(row.number == 1)
    }

    @Test("ExtraPayment init")
    func extraPaymentInit() {
        let xp = ExtraPayment(period: 12, amount: 5_000)
        #expect(xp.period == 12)
        #expect(xp.amount == 5_000)
    }
}

@Suite("APR high-fee bracket expansion")
struct APRHighFeeTests {

    @Test("APR converges when initial high bound needs expanding")
    func aprNeedsBracketExpansion() {
        // Very high prepaid charges relative to principal force APR way above
        // the initial high = noteI + 0.005 starting bound, exercising the
        // bracket-expansion loop.
        let loan = Loan(
            principal: 10_000,
            annualRate: 0.05,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let apr = calculateAPR(loan: loan, prepaidFinanceCharges: 5_000)
        #expect(apr > 0.05)
    }
}

@Suite("APR + Amortize: zero-rate corner cases")
struct ZeroRateCorners {

    @Test("APR for zero-rate loan with prepaid charges")
    func aprZeroRateLoan() {
        let loan = Loan(
            principal: 100_000,
            annualRate: 0,
            termMonths: 120,
            startDate: date(2026, 1, 1)
        )
        let apr = calculateAPR(loan: loan, prepaidFinanceCharges: 1_000)
        // With zero note rate but 1k prepaid, APR > 0
        #expect(apr > 0)
    }
}

@Suite("Guard branches — invalid input returns sentinel values")
struct GuardBranchTests {

    @Test("LTV with zero property value returns 0")
    func ltvZeroProperty() {
        #expect(calculateLTV(loanAmount: 200_000, propertyValue: 0) == 0)
    }

    @Test("CLTV with zero property value returns 0")
    func cltvZeroProperty() {
        let cltv = calculateCLTV(firstLien: 100_000, subordinateLiens: [25_000], propertyValue: 0)
        #expect(cltv == 0)
    }

    @Test("HCLTV with zero property value returns 0")
    func hcltvZeroProperty() {
        let hc = calculateHCLTV(firstLien: 100_000, helocLineLimit: 50_000, propertyValue: 0)
        #expect(hc == 0)
    }

    @Test("DTI with zero income returns 0")
    func dtiZeroIncome() {
        #expect(calculateDTI(monthlyDebts: 1_000, grossMonthlyIncome: 0) == 0)
    }

    @Test("effectiveRate with zero compoundings returns 0")
    func effectiveRateZeroComp() {
        #expect(effectiveRate(nominalRate: 0.06, compoundingsPerYear: 0) == 0)
    }

    @Test("effectiveToNominal with zero compoundings returns 0")
    func effectiveToNominalZeroComp() {
        #expect(effectiveToNominal(effectiveRate: 0.05, compoundingsPerYear: 0) == 0)
    }

    @Test("effectiveToNominal with effectiveRate ≤ -1 returns 0")
    func effectiveToNominalSubMinusOne() {
        #expect(effectiveToNominal(effectiveRate: -1.5, compoundingsPerYear: 12) == 0)
    }

    @Test("compoundGrowth with zero compoundings returns PV")
    func compoundGrowthZeroComp() {
        let result = compoundGrowth(presentValue: 5_000, annualRate: 0.07, years: 10, compoundingsPerYear: 0)
        #expect(result == 5_000)
    }

    @Test("compoundGrowth with negative years returns PV")
    func compoundGrowthNegativeYears() {
        let result = compoundGrowth(presentValue: 5_000, annualRate: 0.07, years: -1, compoundingsPerYear: 12)
        #expect(result == 5_000)
    }

    @Test("paymentFor with zero periods returns 0")
    func paymentForZeroPeriods() {
        #expect(paymentFor(principal: 100_000, periodRate: 0.005, periods: 0) == 0)
    }

    @Test("paymentFor with negative principal returns 0")
    func paymentForNegativePrincipal() {
        #expect(paymentFor(principal: -1, periodRate: 0.005, periods: 360) == 0)
    }

    @Test("presentValue (annuity) with zero periods returns 0")
    func pvAnnuityZeroPeriods() {
        #expect(presentValue(payment: 100, periodRate: 0.05, periods: 0) == 0)
    }

    @Test("futureValue (annuity) with zero periods returns 0")
    func fvAnnuityZeroPeriods() {
        #expect(futureValue(payment: 100, periodRate: 0.05, periods: 0) == 0)
    }

    @Test("MaxQualifyingLoan with zero income returns 0")
    func maxQualZeroIncome() {
        let max = calculateMaxQualifyingLoan(
            grossMonthlyIncome: 0,
            monthlyDebts: 0,
            annualRate: 0.06,
            termMonths: 360,
            monthlyTaxes: 0,
            monthlyInsurance: 0
        )
        #expect(max == 0)
    }

    @Test("MaxQualifyingLoan with dtiCap ≥ 1 returns 0")
    func maxQualHighDTICap() {
        let max = calculateMaxQualifyingLoan(
            grossMonthlyIncome: 10_000,
            monthlyDebts: 0,
            annualRate: 0.06,
            termMonths: 360,
            monthlyTaxes: 0,
            monthlyInsurance: 0,
            dtiCap: 1.5
        )
        #expect(max == 0)
    }

    @Test("MaxQualifyingLoan with zero term returns 0")
    func maxQualZeroTerm() {
        let max = calculateMaxQualifyingLoan(
            grossMonthlyIncome: 10_000,
            monthlyDebts: 0,
            annualRate: 0.06,
            termMonths: 0,
            monthlyTaxes: 0,
            monthlyInsurance: 0
        )
        #expect(max == 0)
    }

    @Test("amortize with zero term yields empty schedule")
    func amortizeZeroTerm() {
        let loan = Loan(
            principal: 100_000,
            annualRate: 0.06,
            termMonths: 0,
            startDate: date(2026, 1, 1)
        )
        let schedule = amortize(loan: loan)
        #expect(schedule.payments.isEmpty)
    }

    @Test("npv with empty cash flows returns 0")
    func npvEmpty() {
        #expect(npv(rate: 0.05, cashFlows: []) == 0)
    }

    @Test("xnpv with empty cash flows returns 0")
    func xnpvEmpty() {
        #expect(xnpv(rate: 0.05, cashFlows: []) == 0)
    }

    @Test("irr with single cash flow throws")
    func irrSingleFlow() {
        #expect(throws: FinanceError.self) {
            _ = try irr(cashFlows: [-100])
        }
    }

    @Test("xirr with single cash flow throws")
    func xirrSingleFlow() {
        #expect(throws: FinanceError.self) {
            _ = try xirr(cashFlows: [(date(2026, 1, 1), -100)])
        }
    }

    @Test("calculateAPR with zero principal returns note rate")
    func aprZeroPrincipal() {
        let loan = Loan(
            principal: 0,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let apr = calculateAPR(loan: loan, prepaidFinanceCharges: 100)
        #expect(apr == 0.06)
    }

    @Test("calculatePMI with negative LTV returns 0")
    func pmiNegativeLTV() {
        let pmi = calculatePMI(ltv: -0.1, creditScore: 700, loanAmount: 100_000, loanType: .conventional)
        #expect(pmi == 0)
    }
}
