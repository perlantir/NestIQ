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

    /// True when every field carries a plausible value. Partial drafts
    /// are now persisted on Borrower so LOs don't lose mid-entry work,
    /// so refi calculators must gate on this — invalid stored mortgages
    /// mustn't pre-fill calculator inputs or flip refi mode on.
    public var isValid: Bool {
        guard currentBalance > 0,
              currentRatePercent > 0,
              currentMonthlyPaymentPI > 0,
              originalLoanAmount > 0,
              originalTermYears > 0,
              propertyValueToday > 0 else {
            return false
        }
        guard loanStartDate < Date() else { return false }
        guard currentBalance <= originalLoanAmount else { return false }
        return true
    }
}
