// UnderwritingTests.swift
// PITI, PMI, LTV, DTI, max qualifying loan.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("PITI")
struct PITITests {

    @Test("PITI sums P&I + taxes + insurance + HOA + PMI")
    func pitiComposition() {
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.065,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let pi = paymentFor(loan: loan) // ~1,896.20
        let piti = calculatePITI(
            loan: loan,
            monthlyTaxes: 400,
            monthlyInsurance: 150,
            monthlyHOA: 75,
            monthlyPMI: 50
        )
        #expect(piti == (pi + 400 + 150 + 75 + 50))
    }
}

@Suite("LTV / CLTV / HCLTV")
struct LTVTests {

    @Test("Simple LTV")
    func ltv() {
        let ltv = calculateLTV(loanAmount: 400_000, propertyValue: 500_000)
        #expect(ltv.isApproximatelyEqual(to: 0.80, tolerance: 1e-12))
    }

    @Test("CLTV sums subordinate liens")
    func cltv() {
        let cltv = calculateCLTV(
            firstLien: 300_000,
            subordinateLiens: [50_000, 25_000],
            propertyValue: 500_000
        )
        #expect(cltv.isApproximatelyEqual(to: 0.75, tolerance: 1e-12))
    }

    @Test("HCLTV uses full HELOC line, not balance")
    func hcltv() {
        let hc = calculateHCLTV(
            firstLien: 300_000,
            helocLineLimit: 100_000,
            propertyValue: 500_000
        )
        #expect(hc.isApproximatelyEqual(to: 0.80, tolerance: 1e-12))
    }
}

@Suite("DTI")
struct DTITests {

    @Test("DTI divides monthly debts by gross income")
    func dtiBasic() {
        let dti = calculateDTI(monthlyDebts: 3000, grossMonthlyIncome: 10_000)
        #expect(dti.isApproximatelyEqual(to: 0.30, tolerance: 1e-12))
    }

    @Test("DTI returns 0 when no debts")
    func dtiZero() {
        let dti = calculateDTI(monthlyDebts: 0, grossMonthlyIncome: 10_000)
        #expect(dti == 0)
    }
}

@Suite("Max qualifying loan")
struct MaxQualTests {

    @Test("Inverse of amortize: computed loan produces PITI at DTI cap")
    func invertsAmortize() {
        let income: Decimal = 10_000
        let debts: Decimal = 500
        let dtiCap = 0.43
        let taxes: Decimal = 300
        let insurance: Decimal = 100
        let hoa: Decimal = 50
        let rate = 0.065
        let term = 360

        let maxLoan = calculateMaxQualifyingLoan(
            grossMonthlyIncome: income,
            monthlyDebts: debts,
            annualRate: rate,
            termMonths: term,
            monthlyTaxes: taxes,
            monthlyInsurance: insurance,
            monthlyHOA: hoa,
            dtiCap: dtiCap
        )
        // Round-trip: compute PI from maxLoan, back-solve DTI
        let loan = Loan(
            principal: maxLoan,
            annualRate: rate,
            termMonths: term,
            startDate: date(2026, 1, 1)
        )
        let pi = paymentFor(loan: loan)
        let housing = pi + taxes + insurance + hoa
        let totalDebt = (housing + debts).asDouble
        let computedDTI = totalDebt / income.asDouble
        #expect(computedDTI.isApproximatelyEqual(to: dtiCap, tolerance: 1e-3))
    }

    @Test("Zero max qualifying when fixed housing costs exceed DTI headroom")
    func zeroWhenBlownOut() {
        let loan = calculateMaxQualifyingLoan(
            grossMonthlyIncome: 5000,
            monthlyDebts: 0,
            annualRate: 0.06,
            termMonths: 360,
            monthlyTaxes: 2500, // 50% of income on taxes alone
            monthlyInsurance: 500,
            dtiCap: 0.43
        )
        #expect(loan == 0)
    }
}

@Suite("PMI across products")
struct PMITests {

    @Test("Conventional PMI zero when LTV ≤ 80%")
    func conventionalNoPMIAtLowLTV() {
        let pmi = calculatePMI(
            ltv: 0.75,
            creditScore: 760,
            loanAmount: 300_000,
            loanType: .conventional
        )
        #expect(pmi == 0)
    }

    @Test("Conventional PMI grid: 95% LTV, 760+ credit")
    func conventionalGridHighLTVHighCredit() {
        // 0.30% annual × 300,000 / 12 = $75/mo
        let pmi = calculatePMI(
            ltv: 0.95,
            creditScore: 780,
            loanAmount: 300_000,
            loanType: .conventional
        )
        #expect(pmi.isApproximatelyEqual(to: 75.00, tolerance: 0.50))
    }

    @Test("FHA MIP: 96.5% LTV, 30-year at 0.55%")
    func fhaMIP() {
        // 0.55% × 300,000 / 12 = $137.50
        let mip = calculatePMI(
            ltv: 0.965,
            creditScore: 680,
            loanAmount: 300_000,
            loanType: .fha,
            termMonths: 360
        )
        #expect(mip.isApproximatelyEqual(to: 137.50))
    }

    @Test("VA has no monthly MI")
    func vaNoPMI() {
        let pmi = calculatePMI(
            ltv: 1.00,
            creditScore: 700,
            loanAmount: 400_000,
            loanType: .va
        )
        #expect(pmi == 0)
    }
}
