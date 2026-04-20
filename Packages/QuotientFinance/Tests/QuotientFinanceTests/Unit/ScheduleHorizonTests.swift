// ScheduleHorizonTests.swift
// Session 5M.5 — cumulativeInterest / cumulativePrincipal through month
// helpers on AmortizationSchedule. Used by TCA's per-horizon interest
// vs principal breakdown.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("Schedule horizon totals")
struct ScheduleHorizonTests {

    private func thirtyYear() -> AmortizationSchedule {
        amortize(loan: Loan(
            principal: 300_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: Date(timeIntervalSince1970: 1_767_225_600)
        ))
    }

    @Test("Month 0 → zero cumulative")
    func monthZeroIsZero() {
        let s = thirtyYear()
        #expect(s.cumulativeInterest(throughMonth: 0) == 0)
        #expect(s.cumulativePrincipal(throughMonth: 0) == 0)
    }

    @Test("Negative month → zero cumulative")
    func negativeMonthIsZero() {
        let s = thirtyYear()
        #expect(s.cumulativeInterest(throughMonth: -3) == 0)
        #expect(s.cumulativePrincipal(throughMonth: -3) == 0)
    }

    @Test("Beyond termMonths → full totals")
    func beyondTermClampsToFull() {
        let s = thirtyYear()
        #expect(s.cumulativeInterest(throughMonth: 1000) == s.totalInterest)
        #expect(s.cumulativePrincipal(throughMonth: 1000) == s.totalPrincipal)
    }

    /// The invariant: principal repaid + interest + residual balance
    /// should equal the original principal + interest on the paid
    /// portion. Rearranged: principal_paid(M) + remaining_balance(M) ==
    /// original principal.
    @Test("Principal paid + remaining balance equals original principal")
    func principalBalanceInvariantAtMidpoint() {
        let s = thirtyYear()
        let month = 120
        let principalPaid = s.cumulativePrincipal(throughMonth: month)
        let remainingBalance = s.payments[month - 1].balance
        // Both in $ terms; should sum to original (300k) within rounding.
        let total = principalPaid + remainingBalance
        let diff = (total - Decimal(300_000)).asDouble
        #expect(abs(diff) < 1.0)  // within $1 rounding
    }

    @Test("Month-120 interest is material (> half of first-10yr payments)")
    func midpointInterestSanity() {
        let s = thirtyYear()
        let interest10yr = s.cumulativeInterest(throughMonth: 120)
        // 30-yr at 6% — well-known interest-heavy early; cumulative
        // interest at 10yr should be >= 150k for 300k principal.
        #expect(interest10yr > 150_000)
        #expect(interest10yr < 180_000)
    }

    @Test("Interest + principal sum equals total scheduled payments through month")
    func sumEqualsTotalScheduled() {
        let s = thirtyYear()
        let m = 60
        let principal = s.cumulativePrincipal(throughMonth: m)
        let interest = s.cumulativeInterest(throughMonth: m)
        let scheduledThroughM = s.payments.prefix(m)
            .reduce(Decimal(0)) { $0 + $1.principal + $1.extraPrincipal + $1.interest }
        #expect(principal + interest == scheduledThroughM)
    }

    @Test("Cumulative totals are monotonically non-decreasing")
    func monotonicallyNonDecreasing() {
        let s = thirtyYear()
        var lastInterest: Decimal = 0
        var lastPrincipal: Decimal = 0
        for m in [1, 12, 60, 120, 240, 360] {
            let i = s.cumulativeInterest(throughMonth: m)
            let p = s.cumulativePrincipal(throughMonth: m)
            #expect(i >= lastInterest)
            #expect(p >= lastPrincipal)
            lastInterest = i
            lastPrincipal = p
        }
    }

    // MARK: - cumulativeMI (5M.6)

    @Test("cumulativeMI is 0 when PMISchedule isn't set")
    func cumulativeMIWithoutSchedule() {
        let s = thirtyYear()  // no PMI in options
        #expect(s.cumulativeMI(throughMonth: 120) == 0)
    }

    @Test("cumulativeMI sums per-row pmi until dropoff")
    func cumulativeMIWithSchedule() {
        let loan = Loan(
            principal: 400_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: Date(timeIntervalSince1970: 1_767_225_600)
        )
        let pmi = PMISchedule(
            monthlyAmount: 120,
            originalValue: 425_000,
            dropAtLTV: 0.78
        )
        let options = AmortizationOptions(pmiSchedule: pmi)
        let schedule = amortize(loan: loan, options: options)
        // By month 60 MI should still be accruing — 5yr × 12 × $120 =
        // $7,200 ceiling. Actual may be lower if dropoff hits before
        // month 60, but >= $3,000 is a safe lower bound.
        let mi60 = schedule.cumulativeMI(throughMonth: 60)
        #expect(mi60 > 3_000)
        #expect(mi60 <= 7_200)
        // Cumulative MI at the end of the schedule equals the schedule's
        // own totalPMI (which is the full PMI run).
        #expect(schedule.cumulativeMI(throughMonth: 360) == schedule.totalPMI)
    }
}
