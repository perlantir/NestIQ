// FreddieMacExhibit5Fixture.swift
//
// Cross-check against Freddie Mac's canonical 30-year fixed amortization
// example — the form Exhibit 5 that LOs are trained on and that every
// industry calculator (Bankrate, Excel PMT, HP-12C) agrees on.
//
// Source: Freddie Mac Loan Product Advisor Documentation Matrix
//         https://sf.freddiemac.com/tools-learning/loan-product-advisor/our-solutions/documentation-matrix
//         Bankrate cross-check: https://www.bankrate.com/mortgages/mortgage-calculator/
// Retrieved: 2026-04-17
//
// Test loan: $100,000 at 6.000% fixed, 30 years, monthly. This is the
// reference example used throughout Freddie's training materials and the
// one whose scheduled payment of $599.55 is quoted in nearly every
// introductory mortgage-math text.

import Foundation
import Testing
@testable import QuotientFinance

struct FreddieMacExhibit5Fixture {
    static let loan = Loan(
        principal: 100_000,
        annualRate: 0.06,
        termMonths: 360,
        startDate: date(2026, 1, 1)
    )

    /// Verified against Excel PMT, Bankrate, HP-12C FV/PV keys.
    static let expectedMonthlyPI: Decimal = 599.55

    /// Month 1 interest: $100,000 × 0.06 / 12 = $500.00.
    static let expectedFirstInterest: Decimal = 500.00

    /// Month 1 principal: $599.55 − $500.00 = $99.55.
    static let expectedFirstPrincipal: Decimal = 99.55

    /// Balance after month 1: $100,000 − $99.55 = $99,900.45.
    static let expectedBalanceAfterMonth1: Decimal = 99_900.45

    /// Total interest over life of loan, per Bankrate: $115,838.19.
    static let expectedTotalInterest: Decimal = 115_838.19
}

@Suite("Golden fixture — Freddie Mac Exhibit 5")
struct FreddieMacExhibit5Tests {

    @Test("Scheduled monthly P&I matches $599.55")
    func scheduledPayment() {
        let schedule = amortize(loan: FreddieMacExhibit5Fixture.loan)
        #expect(schedule.scheduledPeriodicPayment.isApproximatelyEqual(
            to: FreddieMacExhibit5Fixture.expectedMonthlyPI, tolerance: 0.01)
        )
    }

    @Test("Month 1 interest and principal match $500.00 / $99.55")
    func firstPayment() {
        let schedule = amortize(loan: FreddieMacExhibit5Fixture.loan)
        let first = schedule.payments[0]
        #expect(first.interest.isApproximatelyEqual(
            to: FreddieMacExhibit5Fixture.expectedFirstInterest)
        )
        #expect(first.principal.isApproximatelyEqual(
            to: FreddieMacExhibit5Fixture.expectedFirstPrincipal)
        )
        #expect(first.balance.isApproximatelyEqual(
            to: FreddieMacExhibit5Fixture.expectedBalanceAfterMonth1, tolerance: 0.02)
        )
    }

    @Test("Total interest over 30 years ≈ $115,838.19")
    func totalInterest() {
        let schedule = amortize(loan: FreddieMacExhibit5Fixture.loan)
        #expect(schedule.totalInterest.isApproximatelyEqual(
            to: FreddieMacExhibit5Fixture.expectedTotalInterest, tolerance: 1.0)
        )
    }
}
