// BankrateFixture.swift
//
// Second cross-check source for amortization — Bankrate's public calculator.
// Two representative loans, each with values pulled from the calculator's
// detailed schedule output.
//
// Source: https://www.bankrate.com/mortgages/mortgage-calculator/
// Retrieved: 2026-04-17

import Foundation
import Testing
@testable import QuotientFinance

enum BankrateFixture {
    struct Case {
        let label: String
        let loan: Loan
        let expectedMonthlyPI: Decimal
        let expectedTotalInterest: Decimal
    }

    /// $300,000 @ 7.500% for 30 years.
    ///   Monthly P&I: $2,097.64  (verified via Bankrate)
    ///   Total interest: $455,152.49
    static let case300k750 = Case(
        label: "$300k @ 7.5% 30yr",
        loan: Loan(
            principal: 300_000,
            annualRate: 0.075,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        ),
        expectedMonthlyPI: 2097.64,
        expectedTotalInterest: 455_152.49
    )

    /// $250,000 @ 4.500% for 15 years.
    ///   Monthly P&I: $1,912.48
    ///   Total interest: $94,247.04
    static let case250k450yr15 = Case(
        label: "$250k @ 4.5% 15yr",
        loan: Loan(
            principal: 250_000,
            annualRate: 0.045,
            termMonths: 180,
            startDate: date(2026, 1, 1)
        ),
        expectedMonthlyPI: 1912.48,
        expectedTotalInterest: 94_247.04
    )

    static let all: [Case] = [case300k750, case250k450yr15]
}

@Suite("Golden fixture — Bankrate amortization")
struct BankrateTests {

    @Test("Bankrate scheduled payments match", arguments: BankrateFixture.all)
    func scheduledPayment(_ c: BankrateFixture.Case) {
        let schedule = amortize(loan: c.loan)
        #expect(
            schedule.scheduledPeriodicPayment.isApproximatelyEqual(to: c.expectedMonthlyPI),
            "\(c.label): expected \(c.expectedMonthlyPI), got \(schedule.scheduledPeriodicPayment)"
        )
    }

    @Test("Bankrate total interest matches", arguments: BankrateFixture.all)
    func totalInterest(_ c: BankrateFixture.Case) {
        let schedule = amortize(loan: c.loan)
        // Tolerance of $5 reflects cents-rounding differences between our
        // per-period rounding and Bankrate's display — still 0.001% of the
        // total, more than tight enough to catch algorithmic regressions.
        #expect(
            schedule.totalInterest.isApproximatelyEqual(to: c.expectedTotalInterest, tolerance: 5.0),
            "\(c.label): expected \(c.expectedTotalInterest), got \(schedule.totalInterest)"
        )
    }
}

extension BankrateFixture.Case: CustomTestStringConvertible {
    var testDescription: String { label }
}
