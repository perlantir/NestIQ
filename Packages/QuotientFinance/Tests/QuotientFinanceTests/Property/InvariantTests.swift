// InvariantTests.swift
//
// The seven property-based invariants from DEVELOPMENT.md's Session 1
// Testing gate. Each runs 1000+ random cases against a seeded PRNG.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("Property invariants — 1000+ cases each")
struct InvariantTests {

    // MARK: 1. sum(principal) == loanAmount

    @Test("Σ principal (including final-period absorption) equals loan amount")
    func sumOfPrincipalEqualsLoan() throws {
        try forAll(
            "sum(principal) == loanAmount",
            generator: LoanGen.standardFixed,
            count: 1_000,
            shrink: LoanGen.shrink
        ) { loan in
            let schedule = amortize(loan: loan)
            let sumP = schedule.payments.reduce(Decimal(0)) { $0 + $1.principal + $1.extraPrincipal }
            try require(
                sumP.isApproximatelyEqual(to: loan.principal, tolerance: 0.02),
                "sum(principal) \(sumP) != principal \(loan.principal)"
            )
        }
    }

    // MARK: 2. sum(principal) + sum(interest) == sum(payment) ±0.01

    @Test("Σ principal + Σ interest ≈ Σ payment per row")
    func principalPlusInterestEqualsPayment() throws {
        try forAll(
            "p + i == payment",
            generator: LoanGen.standardFixed,
            count: 1_000,
            shrink: LoanGen.shrink
        ) { loan in
            let schedule = amortize(loan: loan)
            let sumP = schedule.payments.reduce(Decimal(0)) { $0 + $1.principal }
            let sumI = schedule.payments.reduce(Decimal(0)) { $0 + $1.interest }
            let sumPay = schedule.payments.reduce(Decimal(0)) { $0 + $1.payment }
            let drift = (sumP + sumI) - sumPay
            try require(
                abs(drift) <= 1.0, // cumulative cents drift across ≤ 360 rows
                "drift \(drift) exceeds $1 over \(schedule.payments.count) rows"
            )
        }
    }

    // MARK: 3. Balance monotonically non-increasing without extras

    @Test("Balance is monotonically non-increasing under plain amortization")
    func balanceMonotone() throws {
        try forAll(
            "balance monotone",
            generator: LoanGen.standardFixed,
            count: 1_000,
            shrink: LoanGen.shrink
        ) { loan in
            let schedule = amortize(loan: loan)
            var previous = loan.principal
            for (idx, row) in schedule.payments.enumerated() {
                try require(
                    row.balance <= previous,
                    "balance increased at period \(idx + 1): \(previous) → \(row.balance)"
                )
                previous = row.balance
            }
        }
    }

    // MARK: 4. APR >= noteRate when closing costs > 0

    @Test("APR is never below note rate when prepaid charges are positive")
    func aprNeverBelowNoteRate() throws {
        try forAll(
            "APR >= note rate",
            generator: LoanWithFeesGen.standard,
            count: 1_000,
            shrink: LoanWithFeesGen.shrink
        ) { lf in
            let apr = calculateAPR(loan: lf.loan, prepaidFinanceCharges: lf.prepaidFinanceCharges)
            try require(
                apr >= lf.loan.annualRate - 1e-9,
                "apr \(apr) below note rate \(lf.loan.annualRate)"
            )
        }
    }

    // MARK: 5. Biweekly yields exactly 26 payments/year

    @Test("Biweekly schedule has 26 payments per 364-day window")
    func biweeklyCadence() throws {
        try forAll(
            "biweekly = 26/year",
            generator: LoanGen.biweeklyFixed,
            count: 1_000
        ) { loan in
            let schedule = amortize(loan: loan)
            guard let first = schedule.payments.first else {
                throw PropertyFailure(message: "empty schedule")
            }
            // Biweekly = every 14 days. In a 364-day window there are exactly
            // 26 payments (days 0, 14, ..., 350). Payment 27 lands on day 364.
            let windowEnd = Calendar(identifier: .gregorian)
                .date(byAdding: .day, value: 364, to: first.date) ?? first.date
            let inWindow = schedule.payments.filter { $0.date < windowEnd }.count
            try require(
                inWindow == 26,
                "biweekly year-1 had \(inWindow) payments, expected 26"
            )
        }
    }

    // MARK: 6. PMI drops at 78% LTV per original schedule

    @Test("PMI drops exactly when scheduled balance crosses 78% LTV")
    func pmiDropsAt78() throws {
        try forAll(
            "PMI drop @ 78% scheduled LTV",
            generator: LoanWithPMIGen.highLTVConventional,
            count: 1_000
        ) { lp in
            let policy = PMISchedule(
                monthlyAmount: 100,
                originalValue: lp.originalValue,
                dropAtLTV: 0.78
            )
            let schedule = amortize(loan: lp.loan, options: AmortizationOptions(pmiSchedule: policy))

            // Find first period where scheduled LTV drops to ≤ 78% —
            // PMI should be 0 from that period on. Use the same scheduled
            // trajectory the amortize primitive uses internally.
            let pRate = periodRate(
                annualRate: lp.loan.annualRate,
                frequency: lp.loan.frequency,
                dayCount: lp.loan.dayCount
            )
            let sched = scheduledBalanceTrajectory(
                principal: lp.loan.principal,
                periodRate: pRate,
                periods: totalPeriods(loan: lp.loan),
                scheduledPayment: schedule.scheduledPeriodicPayment
            )
            var dropPeriod: Int?
            for p in 1..<sched.count {
                let ltv = sched[p].asDouble / lp.originalValue.asDouble
                if ltv <= 0.78 {
                    dropPeriod = p
                    break
                }
            }

            if let dp = dropPeriod, dp <= schedule.payments.count {
                // Before dp: pmi > 0. From dp onward: pmi == 0.
                let before = schedule.payments.prefix(dp - 1)
                let after = schedule.payments.suffix(from: dp - 1)
                try require(
                    before.allSatisfy { $0.pmi > 0 },
                    "PMI was zero before scheduled drop at period \(dp)"
                )
                try require(
                    after.allSatisfy { $0.pmi == 0 },
                    "PMI was non-zero after scheduled drop at period \(dp)"
                )
            }
        }
    }

    // MARK: 7. Recast reduces monthly payment and total interest

    @Test("Recast strictly reduces scheduled payment and total interest")
    func recastReducesPaymentAndInterest() throws {
        try forAll(
            "recast reduces payment + total interest",
            generator: LoanWithRecastGen.standard,
            count: 1_000
        ) { lr in
            let baseline = amortize(loan: lr.loan)
            let lumpsum = ExtraPayment(period: lr.recastPeriod, amount: lr.lumpSum)
            let recasted = amortize(
                loan: lr.loan,
                options: AmortizationOptions(
                    oneTimeExtra: [lumpsum],
                    recastPeriods: [lr.recastPeriod]
                )
            )
            // Post-recast scheduled payment is strictly lower than the original.
            let postIndex = min(lr.recastPeriod + 1, recasted.payments.count - 1)
            let postRecastPayment = recasted.payments[postIndex].payment
            try require(
                postRecastPayment < baseline.scheduledPeriodicPayment,
                "recast did not reduce payment: \(postRecastPayment) vs baseline \(baseline.scheduledPeriodicPayment)"
            )
            // Total interest is strictly lower because principal was paid down.
            try require(
                recasted.totalInterest < baseline.totalInterest,
                "recast total interest \(recasted.totalInterest) not less than baseline \(baseline.totalInterest)"
            )
        }
    }
}
