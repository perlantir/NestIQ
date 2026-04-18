// SupplementalCoverageTests.swift
// Targeted tests to bring line + region coverage over the 95% gate.
// Each suite exercises a specific previously-uncovered branch — when these
// fail in code-review, that's a real regression.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("Schedule aggregates")
struct ScheduleAggregateTests {

    @Test("totalPrincipal sums principal + extras across rows")
    func totalPrincipal() {
        let loan = Loan(
            principal: 200_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let schedule = amortize(
            loan: loan,
            options: AmortizationOptions(extraPeriodicPrincipal: 100)
        )
        // Sum should equal principal exactly when fully amortized
        #expect(schedule.totalPrincipal.isApproximatelyEqual(to: 200_000, tolerance: 0.05))
    }

    @Test("totalPayments includes extras and PMI")
    func totalPayments() {
        let loan = Loan(
            principal: 200_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let policy = PMISchedule(monthlyAmount: 50, originalValue: 250_000, isPermanent: true)
        let schedule = amortize(loan: loan, options: AmortizationOptions(pmiSchedule: policy))
        #expect(schedule.totalPMI > 0)
        #expect(schedule.totalPayments > schedule.totalPrincipal + schedule.totalInterest)
    }

    @Test("payoffDate matches last payment's date")
    func payoffDate() {
        let loan = Loan(
            principal: 100_000,
            annualRate: 0.05,
            termMonths: 120,
            startDate: date(2026, 1, 1)
        )
        let schedule = amortize(loan: loan)
        #expect(schedule.payoffDate == schedule.payments.last?.date)
    }

    @Test("Empty principal yields empty schedule")
    func emptySchedule() {
        let loan = Loan(
            principal: 0,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let schedule = amortize(loan: loan)
        #expect(schedule.payments.isEmpty)
        #expect(schedule.payoffDate == nil)
    }
}

@Suite("Decimal extensions and helpers")
struct DecimalExtensionsTests {

    @Test("Decimal.money rounds banker-style")
    func moneyRounding() {
        let half: Decimal = 0.005
        // 0.005 → 0.00 (banker's rounds to nearest even)
        #expect(half.money() == 0)

        let upper: Decimal = 0.015
        #expect(upper.money() == 0.02)
    }

    @Test("Decimal.clampedNonNegative pins negatives to zero")
    func clampedNonNeg() {
        let neg: Decimal = -1.50
        #expect(neg.clampedNonNegative == 0)

        let pos: Decimal = 1.50
        #expect(pos.clampedNonNegative == 1.50)
    }

    @Test("Double.asDecimal preserves precision via String")
    func doubleToDecimal() {
        let d: Double = 0.1
        let dec = d.asDecimal
        #expect(dec == Decimal(string: "0.1"))
    }
}

@Suite("PaymentFrequency / DayCountConvention enums")
struct EnumTests {

    @Test("paymentsPerYear values per frequency")
    func paymentsPerYear() {
        #expect(PaymentFrequency.monthly.paymentsPerYear == 12)
        #expect(PaymentFrequency.biweekly.paymentsPerYear == 26)
        #expect(PaymentFrequency.semiMonthly.paymentsPerYear == 24)
        #expect(PaymentFrequency.weekly.paymentsPerYear == 52)
    }

    @Test("averageDaysPerPeriod for each frequency")
    func averageDays() {
        #expect(PaymentFrequency.monthly.averageDaysPerPeriod
            .isApproximatelyEqual(to: 365.0 / 12.0, tolerance: 1e-9))
        #expect(PaymentFrequency.weekly.averageDaysPerPeriod
            .isApproximatelyEqual(to: 365.0 / 52.0, tolerance: 1e-9))
    }

    @Test("daysPerYear by day-count convention")
    func daysPerYear() {
        #expect(DayCountConvention.thirty360.daysPerYear == 360)
        #expect(DayCountConvention.actual365.daysPerYear == 365)
        #expect(DayCountConvention.actual360.daysPerYear == 360)
        #expect(DayCountConvention.actualActual.daysPerYear == 365.25)
    }

    @Test("Loan.dayCount matches loan/rate type")
    func loanDayCount() {
        let start = date(2026, 1, 1)
        let conv = Loan(principal: 1, annualRate: 0.05, termMonths: 360, startDate: start)
        #expect(conv.dayCount == .thirty360)

        let heloc = Loan(
            principal: 1,
            annualRate: 0.05,
            termMonths: 360,
            loanType: .heloc,
            startDate: start
        )
        #expect(heloc.dayCount == .actual365)

        let sofr = Loan(
            principal: 1,
            annualRate: 0.05,
            termMonths: 360,
            rateType: .armSOFR,
            startDate: start
        )
        #expect(sofr.dayCount == .actual360)

        let treas = Loan(
            principal: 1,
            annualRate: 0.05,
            termMonths: 360,
            rateType: .armTreasury,
            startDate: start
        )
        #expect(treas.dayCount == .actualActual)
    }
}

@Suite("Conventional MI grid coverage")
struct ConventionalMIGridCoverageTests {

    @Test("LTV ≤ 80% returns nil")
    func belowPMIThreshold() {
        #expect(ConventionalMIGrid.annualRate(ltv: 0.79, creditScore: 760) == nil)
        #expect(ConventionalMIGrid.annualRate(ltv: 0.80, creditScore: 760) == nil)
    }

    @Test("Credit score below 620 returns nil")
    func belowCreditFloor() {
        #expect(ConventionalMIGrid.annualRate(ltv: 0.95, creditScore: 619) == nil)
    }

    @Test("LTV above 97% returns nil")
    func aboveLTVCeiling() {
        #expect(ConventionalMIGrid.annualRate(ltv: 0.98, creditScore: 760) == nil)
    }

    @Test("Each LTV band returns expected base rate at 760+ credit")
    func ltvBandsAtTopCredit() {
        // 95.01–97
        #expect(ConventionalMIGrid.annualRate(ltv: 0.97, creditScore: 760) == 0.0047)
        // 90.01–95
        #expect(ConventionalMIGrid.annualRate(ltv: 0.95, creditScore: 760) == 0.0030)
        // 85.01–90
        #expect(ConventionalMIGrid.annualRate(ltv: 0.90, creditScore: 760) == 0.0022)
        // 80.01–85
        #expect(ConventionalMIGrid.annualRate(ltv: 0.85, creditScore: 760) == 0.0014)
    }

    @Test("Each credit band at 95% LTV")
    func creditBandsAt95LTV() {
        #expect(ConventionalMIGrid.annualRate(ltv: 0.95, creditScore: 760) == 0.0030)
        #expect(ConventionalMIGrid.annualRate(ltv: 0.95, creditScore: 740) == 0.0035)
        #expect(ConventionalMIGrid.annualRate(ltv: 0.95, creditScore: 720) == 0.0043)
        #expect(ConventionalMIGrid.annualRate(ltv: 0.95, creditScore: 700) == 0.0055)
        #expect(ConventionalMIGrid.annualRate(ltv: 0.95, creditScore: 680) == 0.0077)
        #expect(ConventionalMIGrid.annualRate(ltv: 0.95, creditScore: 660) == 0.0105)
        #expect(ConventionalMIGrid.annualRate(ltv: 0.95, creditScore: 640) == 0.0142)
        #expect(ConventionalMIGrid.annualRate(ltv: 0.95, creditScore: 620) == 0.0174)
    }
}

@Suite("PMI: jumbo, single premium, LPMI, split, HELOC, USDA")
struct PMIVariantTests {

    @Test("Jumbo uses conventional grid")
    func jumboUsesConvGrid() {
        let pmi = calculatePMI(
            ltv: 0.90,
            creditScore: 740,
            loanAmount: 1_000_000,
            loanType: .jumbo
        )
        // 0.25% × 1M / 12 = 208.33
        #expect(pmi.isApproximatelyEqual(to: 208.33, tolerance: 0.50))
    }

    @Test("Single premium returns 0 monthly")
    func singlePremiumZeroMonthly() {
        let pmi = calculatePMI(
            ltv: 0.95,
            creditScore: 740,
            loanAmount: 300_000,
            loanType: .conventional,
            paymentType: .singlePremium
        )
        #expect(pmi == 0)
    }

    @Test("Lender-paid returns 0 monthly")
    func lenderPaidZeroMonthly() {
        let pmi = calculatePMI(
            ltv: 0.95,
            creditScore: 740,
            loanAmount: 300_000,
            loanType: .conventional,
            paymentType: .lenderPaid
        )
        #expect(pmi == 0)
    }

    @Test("Split premium discounts monthly portion")
    func splitPremiumDiscounted() {
        let monthly = calculatePMI(
            ltv: 0.95,
            creditScore: 740,
            loanAmount: 300_000,
            loanType: .conventional,
            paymentType: .monthly
        )
        let split = calculatePMI(
            ltv: 0.95,
            creditScore: 740,
            loanAmount: 300_000,
            loanType: .conventional,
            paymentType: .splitPremium
        )
        #expect(split < monthly)
        #expect(split > 0)
    }

    @Test("HELOC and USDA return 0 PMI")
    func helocAndUsdaZero() {
        #expect(calculatePMI(ltv: 1.0, creditScore: 700, loanAmount: 200_000, loanType: .heloc) == 0)
        #expect(calculatePMI(ltv: 1.0, creditScore: 700, loanAmount: 200_000, loanType: .usda) == 0)
    }

    @Test("FHA non-monthly payment type returns 0")
    func fhaNonMonthlyZero() {
        let pmi = calculatePMI(
            ltv: 0.965,
            creditScore: 680,
            loanAmount: 300_000,
            loanType: .fha,
            paymentType: .singlePremium
        )
        #expect(pmi == 0)
    }
}

@Suite("Rate conversion edge cases")
struct RateEdgeTests {

    @Test("nominalToEffective alias matches effectiveRate")
    func nominalToEffectiveAlias() {
        let r = nominalToEffective(nominalRate: 0.06, compoundingsPerYear: 12)
        #expect(r == effectiveRate(nominalRate: 0.06, compoundingsPerYear: 12))
    }

    @Test("effectiveToNominal handles zero")
    func zeroEffective() {
        #expect(effectiveToNominal(effectiveRate: 0, compoundingsPerYear: 12) == 0)
    }
}

@Suite("APOR and APR additional cases")
struct APRAPORAdditionalTests {

    @Test("APOR for ARM uses variable table")
    func aporARM() {
        let apor = calculateAPOR(
            loanType: .conventional,
            rateType: .armSOFR,
            termYears: 5,
            lockDate: date(2026, 4, 2)
        )
        #expect(apor != nil)
    }

    @Test("APOR with non-tabulated term falls back to closest")
    func aporNonExactTerm() {
        let apor = calculateAPOR(
            loanType: .conventional,
            rateType: .fixed,
            termYears: 25,
            lockDate: date(2026, 4, 2)
        )
        #expect(apor != nil)
    }

    @Test("APR converges for tiny prepaid charges")
    func aprTinyFees() {
        let loan = Loan(
            principal: 200_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let apr = calculateAPR(loan: loan, prepaidFinanceCharges: 1)
        #expect(apr > loan.annualRate)
        #expect(apr < loan.annualRate + 0.0001)
    }
}

@Suite("NPV / IRR additional paths")
struct NPVAdditionalTests {

    @Test("NPV with zero rate equals direct sum")
    func npvZeroRate() {
        let cf: [Decimal] = [-500, 100, 100, 100, 100, 100]
        #expect(npv(rate: 0, cashFlows: cf) == 0)
    }

    @Test("xnpv with zero rate")
    func xnpvBasic() {
        let d0 = date(2026, 1, 1)
        let d1 = date(2026, 7, 1)
        let result = xnpv(rate: 0.05, cashFlows: [(date: d0, amount: -1000), (date: d1, amount: 1100)])
        #expect(result.isPositive)
    }

    @Test("IRR with zero between flows")
    func irrWithZero() throws {
        let cf: [Decimal] = [-1000, 0, 0, 1331]   // ≈ 10% annual
        let r = try irr(cashFlows: cf)
        #expect(r.isApproximatelyEqual(to: 0.10, tolerance: 1e-3))
    }

    @Test("XIRR throws when sign doesn't change")
    func xirrNoSignChange() {
        let d0 = date(2026, 1, 1)
        let d1 = date(2027, 1, 1)
        #expect(throws: FinanceError.self) {
            _ = try xirr(cashFlows: [(d0, 100), (d1, 100)])
        }
    }
}

@Suite("LTV / DTI / MaxQual edge cases")
struct UnderwritingEdgeTests {

    @Test("CLTV with empty subordinate liens")
    func cltvNoSubordinate() {
        let cltv = calculateCLTV(
            firstLien: 200_000,
            subordinateLiens: [],
            propertyValue: 300_000
        )
        #expect(cltv.isApproximatelyEqual(to: 200.0 / 300.0, tolerance: 1e-9))
    }

    @Test("HCLTV with other subordinate liens")
    func hcltvWithOthers() {
        let hc = calculateHCLTV(
            firstLien: 200_000,
            helocLineLimit: 50_000,
            otherSubordinateLiens: [25_000],
            propertyValue: 400_000
        )
        // (200 + 50 + 25) / 400 = 0.6875
        #expect(hc.isApproximatelyEqual(to: 0.6875, tolerance: 1e-9))
    }

    @Test("DTI with frontEnd flag set (no math difference)")
    func dtiFrontEnd() {
        let d = calculateDTI(monthlyDebts: 1500, grossMonthlyIncome: 5000, frontEnd: true)
        #expect(d == 0.30)
    }

    @Test("MaxQualifyingLoan with zero rate (interest-free)")
    func maxQualZeroRate() {
        let max = calculateMaxQualifyingLoan(
            grossMonthlyIncome: 10_000,
            monthlyDebts: 0,
            annualRate: 0,
            termMonths: 360,
            monthlyTaxes: 0,
            monthlyInsurance: 0
        )
        #expect(max > 0)
    }
}

@Suite("HPCT small-creditor + edge cases")
struct HPCTAdditionalTests {

    @Test("Small creditor portfolio threshold is 3.5% even non-jumbo")
    func smallCreditorThreshold() {
        // Under standard non-jumbo: spread 0.030 → HPCT = true
        // Under small creditor: 0.030 < 0.035 → HPCT = false
        let standard = isHPCT(
            apr: 0.085,
            apor: 0.055,
            lienPosition: .first,
            isJumbo: false,
            isSmallCreditorPortfolio: false
        )
        let small = isHPCT(
            apr: 0.085,
            apor: 0.055,
            lienPosition: .first,
            isJumbo: false,
            isSmallCreditorPortfolio: true
        )
        #expect(standard)
        #expect(!small)
    }

    @Test("HPCT subordinate threshold")
    func hpctSubordinate() {
        #expect(isHPCT(apr: 0.10, apor: 0.05, lienPosition: .subordinate, isJumbo: false))
        #expect(!isHPCT(apr: 0.08, apor: 0.05, lienPosition: .subordinate, isJumbo: false))
    }
}

@Suite("QM negative-am and balloon paths")
struct QMFeatureTests {

    @Test("Negative-am loan is not QM")
    func negAmNotQM() {
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let qm = calculateQMStatus(
            loan: loan,
            apr: 0.061,
            apor: 0.055,
            pointsAndFees: 1000,
            features: QMFeatures(negativeAmortizing: true)
        )
        #expect(qm.status == .notQM)
    }

    @Test("Balloon loan is not QM")
    func balloonNotQM() {
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let qm = calculateQMStatus(
            loan: loan,
            apr: 0.061,
            apor: 0.055,
            pointsAndFees: 1000,
            features: QMFeatures(balloon: true)
        )
        #expect(qm.status == .notQM)
    }

    @Test("Small creditor portfolio QM gets safe harbor when not higher-priced")
    func smallCreditorPortfolioSafeHarbor() {
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let qm = calculateQMStatus(
            loan: loan,
            apr: 0.061,
            apor: 0.055,
            pointsAndFees: 1000,
            isSmallCreditorPortfolio: true
        )
        #expect(qm.status == .smallCreditorQM)
        #expect(qm.presumption == .safeHarbor)
    }
}

@Suite("FinanceError descriptions")
struct FinanceErrorTests {

    @Test("solverDidNotConverge description")
    func solverDescription() {
        let err = FinanceError.solverDidNotConverge(function: "irr", iterations: 200)
        #expect(err.description.contains("irr"))
        #expect(err.description.contains("200"))
    }

    @Test("invalidInput description")
    func invalidInputDescription() {
        let err = FinanceError.invalidInput("bad signs")
        #expect(err.description.contains("bad signs"))
    }
}

@Suite("ComplianceRuleVersion")
struct RuleVersionTests {
    @Test("Round-trip Codable")
    func codable() throws {
        let v = ComplianceRuleVersion.current
        let encoded = try JSONEncoder().encode(v)
        let decoded = try JSONDecoder().decode(ComplianceRuleVersion.self, from: encoded)
        #expect(decoded == v)
    }
}
