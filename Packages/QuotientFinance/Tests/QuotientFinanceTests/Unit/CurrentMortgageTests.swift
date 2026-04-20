// CurrentMortgageTests.swift
// Session 5P.6 coverage for CurrentMortgageCalculations primitives.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("Current mortgage calculations")
struct CurrentMortgageTests {

    /// Constructs a Date at UTC midnight for the given y/m/d without
    /// using optional force-unwrap — Calendar.date(from:) returns nil
    /// only for impossible components, which the hard-coded test dates
    /// below can't trigger.
    private func date(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let components = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    @Test("monthsPaid — 24 months elapsed")
    func monthsPaidExact() {
        let start = date(year: 2024, month: 1, day: 1)
        let asOf = date(year: 2026, month: 1, day: 1)
        #expect(CurrentMortgageCalculations.monthsPaid(
            loanStartDate: start, asOfDate: asOf
        ) == 24)
    }

    @Test("monthsPaid — future start date returns 0")
    func monthsPaidFutureStart() {
        let start = date(year: 2027, month: 1, day: 1)
        let asOf = date(year: 2026, month: 1, day: 1)
        #expect(CurrentMortgageCalculations.monthsPaid(
            loanStartDate: start, asOfDate: asOf
        ) == 0)
    }

    @Test("monthsRemaining — 30-year loan, 24 months paid")
    func monthsRemainingMidTerm() {
        let start = date(year: 2024, month: 1, day: 1)
        let asOf = date(year: 2026, month: 1, day: 1)
        // 30 * 12 − 24 = 336
        #expect(CurrentMortgageCalculations.monthsRemaining(
            originalTermYears: 30,
            loanStartDate: start,
            asOfDate: asOf
        ) == 336)
    }

    @Test("monthsRemaining — past-term loan clamps at 0")
    func monthsRemainingPastTerm() {
        // 35 years before the asOf date, 30-yr term = 5 years past term.
        let start = date(year: 1991, month: 1, day: 1)
        let asOf = date(year: 2026, month: 1, day: 1)
        #expect(CurrentMortgageCalculations.monthsRemaining(
            originalTermYears: 30,
            loanStartDate: start,
            asOfDate: asOf
        ) == 0)
    }

    @Test("ltvToday — 80% at 400k balance on 500k property")
    func ltvTodayBasic() {
        let ltv = CurrentMortgageCalculations.ltvToday(
            currentBalance: 400_000, propertyValue: 500_000
        )
        let expected = Decimal(string: "0.8") ?? 0
        #expect(ltv == expected)
    }

    @Test("ltvToday — zero property value returns 0 (guards div/0)")
    func ltvTodayZeroProperty() {
        let ltv = CurrentMortgageCalculations.ltvToday(
            currentBalance: 100_000, propertyValue: 0
        )
        #expect(ltv == 0)
    }

    @Test("ltvToday — underwater loan returns > 1.0 (not clamped)")
    func ltvTodayUnderwater() {
        let ltv = CurrentMortgageCalculations.ltvToday(
            currentBalance: 600_000, propertyValue: 500_000
        )
        let expected = Decimal(string: "1.2") ?? 0
        #expect(ltv == expected)
    }

    @Test("equityToday — 100k equity on 500k home with 400k balance")
    func equityTodayBasic() {
        #expect(CurrentMortgageCalculations.equityToday(
            currentBalance: 400_000, propertyValue: 500_000
        ) == 100_000)
    }

    @Test("equityToday — underwater loan clamps at 0 (no negative equity)")
    func equityTodayUnderwater() {
        #expect(CurrentMortgageCalculations.equityToday(
            currentBalance: 600_000, propertyValue: 500_000
        ) == 0)
    }
}
