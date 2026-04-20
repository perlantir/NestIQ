// CurrentMortgage.swift
// Session 5P.6: the borrower's current mortgage as a first-class
// persisted concept (D9). Stored on Borrower as a JSON blob —
// `Borrower.currentMortgageJSON: Data?` with a computed accessor
// on Borrower returning / setting this value.
//
// Refi-mode calculators (TCA refinance, Refinance Comparison, HELOC
// vs Refinance) pull the current mortgage off the selected borrower
// to anchor their comparisons against a real status-quo loan, not a
// duplicate scenario. Purchase-mode calculators ignore this field.
//
// Home value appreciation is intentionally not modeled — `propertyValueToday`
// is the LO's estimate of present value, applied uniformly across
// refi scenarios as a constant.

import Foundation

public struct CurrentMortgage: Codable, Hashable, Sendable {
    public var currentBalance: Decimal
    public var currentRatePercent: Decimal
    public var currentMonthlyPaymentPI: Decimal
    public var originalLoanAmount: Decimal
    public var originalTermYears: Int
    public var loanStartDate: Date
    public var propertyValueToday: Decimal

    public init(
        currentBalance: Decimal,
        currentRatePercent: Decimal,
        currentMonthlyPaymentPI: Decimal,
        originalLoanAmount: Decimal,
        originalTermYears: Int,
        loanStartDate: Date,
        propertyValueToday: Decimal
    ) {
        self.currentBalance = currentBalance
        self.currentRatePercent = currentRatePercent
        self.currentMonthlyPaymentPI = currentMonthlyPaymentPI
        self.originalLoanAmount = originalLoanAmount
        self.originalTermYears = originalTermYears
        self.loanStartDate = loanStartDate
        self.propertyValueToday = propertyValueToday
    }
}
