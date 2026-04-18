// AmortizeTests.swift

import Testing
import Foundation
@testable import QuotientFinance

@Suite("Amortization")
struct AmortizeTests {

    @Test("Standard 30-year fixed produces 360 payments ending at zero balance")
    func thirtyYearFixed() {
        let loan = Loan(
            principal: 200_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let schedule = amortize(loan: loan)
        #expect(schedule.numberOfPayments == 360)
        #expect(schedule.scheduledPeriodicPayment.isApproximatelyEqual(to: 1199.10))
        if let last = schedule.payments.last {
            #expect(last.balance == 0)
        }
    }

    @Test("First payment interest matches balance × period rate")
    func firstPaymentInterest() {
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.0575,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let schedule = amortize(loan: loan)
        let first = schedule.payments[0]
        // Interest month 1 = 300,000 × 0.0575/12 = 1437.50
        #expect(first.interest.isApproximatelyEqual(to: 1437.50, tolerance: 0.01))
    }

    @Test("Payments advance monthly by calendar month")
    func monthlyDateAdvance() {
        let loan = Loan(
            principal: 100_000,
            annualRate: 0.05,
            termMonths: 360,
            startDate: date(2026, 1, 15)
        )
        let schedule = amortize(loan: loan)
        let second = schedule.payments[1].date
        let expected = date(2026, 2, 15)
        #expect(second == expected)
    }

    @Test("Biweekly loan has payment dates 14 days apart")
    func biweeklyDateAdvance() {
        let loan = Loan(
            principal: 100_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1),
            frequency: .biweekly
        )
        let schedule = amortize(loan: loan)
        let first = schedule.payments[0].date
        let second = schedule.payments[1].date
        let days = Calendar(identifier: .gregorian).dateComponents([.day], from: first, to: second).day ?? 0
        #expect(days == 14)
    }

    @Test("Extra periodic principal shortens the term")
    func extraPrincipalShortens() {
        let loan = Loan(
            principal: 250_000,
            annualRate: 0.065,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let baseline = amortize(loan: loan)
        let withExtra = amortize(
            loan: loan,
            options: AmortizationOptions(extraPeriodicPrincipal: 200)
        )
        #expect(withExtra.numberOfPayments < baseline.numberOfPayments)
        #expect(withExtra.totalInterest < baseline.totalInterest)
    }

    @Test("Zero-rate loan: principal divides evenly with no interest")
    func zeroRateLoan() {
        let loan = Loan(
            principal: 120_000,
            annualRate: 0,
            termMonths: 120,
            startDate: date(2026, 1, 1)
        )
        let schedule = amortize(loan: loan)
        #expect(schedule.numberOfPayments == 120)
        #expect(schedule.totalInterest == 0)
        #expect(schedule.scheduledPeriodicPayment == 1000)
    }

    @Test("PMI drops at scheduled 78% LTV — not accelerated by extras")
    func pmiDropsPerSchedule() {
        let policy = PMISchedule(
            monthlyAmount: 150,
            originalValue: 250_000,
            dropAtLTV: 0.78
        )
        let loan = Loan(
            principal: 237_500, // 95% LTV at origination
            annualRate: 0.07,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let options = AmortizationOptions(
            extraPeriodicPrincipal: 500, // accelerates actual payoff, but NOT PMI
            pmiSchedule: policy
        )
        let schedule = amortize(loan: loan, options: options)
        let withPMI = schedule.payments.filter { $0.pmi > 0 }.count
        let withoutPMI = schedule.payments.filter { $0.pmi == 0 }.count
        #expect(withPMI > 0)
        #expect(withoutPMI > 0)
        // PMI drops where scheduled balance ≤ 78% × 250,000 = 195,000
        // At 237,500 @ 7% / 360 mo, scheduled balance falls to ~195k around month 164
        if let firstZeroPMI = schedule.payments.first(where: { $0.pmi == 0 }) {
            #expect(firstZeroPMI.number > 100)   // plenty of PMI months came first
        }
    }

    @Test("Permanent PMI never drops")
    func permanentPMI() {
        let policy = PMISchedule(
            monthlyAmount: 120,
            originalValue: 300_000,
            isPermanent: true
        )
        let loan = Loan(
            principal: 290_000,
            annualRate: 0.065,
            termMonths: 360,
            loanType: .fha,
            startDate: date(2026, 1, 1)
        )
        let schedule = amortize(loan: loan, options: AmortizationOptions(pmiSchedule: policy))
        let allHavePMI = schedule.payments.allSatisfy { $0.pmi == 120 }
        #expect(allHavePMI)
    }

    @Test("Recast at month 60 reduces subsequent scheduled payment")
    func recastReducesPayment() {
        let loan = Loan(
            principal: 400_000,
            annualRate: 0.07,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let lumpsum = ExtraPayment(period: 60, amount: 50_000)
        let schedule = amortize(
            loan: loan,
            options: AmortizationOptions(oneTimeExtra: [lumpsum], recastPeriods: [60])
        )
        let originalPI = schedule.scheduledPeriodicPayment
        let postRecastPI = schedule.payments[70].payment   // well after recast
        #expect(postRecastPI < originalPI)
    }
}
