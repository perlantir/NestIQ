// YearlyAggregateTests.swift
// Property invariants for `yearlyAggregate(schedule:)`.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("Yearly aggregation — property invariants")
struct YearlyAggregateTests {

    @Test("Per-year principal totals equal the sum of the bucket's monthly principals")
    func yearlyPrincipalMatchesBucket() throws {
        try forAll(
            "yearly principal == Σ monthly principal",
            generator: LoanGen.standardFixed,
            count: 500,
            shrink: LoanGen.shrink
        ) { loan in
            let schedule = amortize(loan: loan)
            let yearly = yearlyAggregate(schedule: schedule)
            let perYear = schedule.loan.frequency.paymentsPerYear
            var idx = 0
            for row in yearly {
                let end = min(idx + perYear, schedule.payments.count)
                let bucket = schedule.payments[idx..<end]
                let sumP = bucket.reduce(Decimal(0)) { $0 + $1.principal + $1.extraPrincipal }
                let sumI = bucket.reduce(Decimal(0)) { $0 + $1.interest }
                let sumPay = bucket.reduce(Decimal(0)) { $0 + $1.payment + $1.extraPrincipal }
                try require(
                    sumP == row.totalPrincipal,
                    "year \(row.year) principal: \(sumP) != \(row.totalPrincipal)"
                )
                try require(
                    sumI == row.totalInterest,
                    "year \(row.year) interest: \(sumI) != \(row.totalInterest)"
                )
                try require(
                    sumPay == row.totalPayment,
                    "year \(row.year) payment: \(sumPay) != \(row.totalPayment)"
                )
                idx = end
            }
        }
    }

    @Test("Σ yearly principal equals the schedule's total principal")
    func yearlySumEqualsScheduleTotal() throws {
        try forAll(
            "Σ yearly principal == schedule.totalPrincipal",
            generator: LoanGen.standardFixed,
            count: 500,
            shrink: LoanGen.shrink
        ) { loan in
            let schedule = amortize(loan: loan)
            let yearly = yearlyAggregate(schedule: schedule)
            let sumP = yearly.reduce(Decimal(0)) { $0 + $1.totalPrincipal }
            let sumI = yearly.reduce(Decimal(0)) { $0 + $1.totalInterest }
            try require(
                sumP == schedule.totalPrincipal,
                "Σ yearly principal \(sumP) != schedule.totalPrincipal \(schedule.totalPrincipal)"
            )
            try require(
                sumI == schedule.totalInterest,
                "Σ yearly interest \(sumI) != schedule.totalInterest \(schedule.totalInterest)"
            )
        }
    }

    @Test("Bucket count matches ceil(payments / paymentsPerYear)")
    func yearlyBucketCount() throws {
        try forAll(
            "bucket count",
            generator: LoanGen.standardFixed,
            count: 300,
            shrink: LoanGen.shrink
        ) { loan in
            let schedule = amortize(loan: loan)
            let yearly = yearlyAggregate(schedule: schedule)
            let perYear = schedule.loan.frequency.paymentsPerYear
            let expected = (schedule.payments.count + perYear - 1) / perYear
            try require(
                yearly.count == expected,
                "expected \(expected) yearly rows, got \(yearly.count)"
            )
        }
    }

    @Test("Ending balance of the last bucket is zero for a fully-amortized loan")
    func finalBucketBalanceZero() {
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.065,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let schedule = amortize(loan: loan)
        let yearly = yearlyAggregate(schedule: schedule)
        #expect(yearly.count == 30)
        #expect(yearly.last?.endingBalance == 0)
    }
}
