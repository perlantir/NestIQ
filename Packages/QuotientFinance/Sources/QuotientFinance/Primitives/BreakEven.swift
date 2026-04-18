// BreakEven.swift
// Month at which a refinance recovers its closing costs through payment
// savings versus the current loan.
//
// Simple model: `ceil(closingCosts / (currentPayment − newPayment))`.
// Ignores discounting — the industry-standard "months to break even" quote
// LOs give borrowers. A full NPV-based comparison lives in `compareScenarios`
// (Session 2).

import Foundation

/// Refinance parameters: the replacement loan and its out-of-pocket closing
/// costs. Closing costs rolled into the loan should be reflected in the
/// loan's principal, not repeated here.
public struct RefiScenario: Sendable, Hashable, Codable {
    public var newLoan: Loan
    public var closingCosts: Decimal

    public init(newLoan: Loan, closingCosts: Decimal) {
        self.newLoan = newLoan
        self.closingCosts = closingCosts
    }
}

/// Number of months until cumulative monthly P&I savings equal or exceed
/// the refinance's closing costs. Returns `nil` when the new payment is
/// greater than or equal to the current payment — no break-even exists.
public func breakEvenMonth(refiScenario: RefiScenario, currentLoan: Loan) -> Int? {
    let currentPI = paymentFor(loan: currentLoan)
    let newPI = paymentFor(loan: refiScenario.newLoan)
    let monthlySavings = currentPI - newPI
    guard monthlySavings > 0 else { return nil }

    let costs = refiScenario.closingCosts.asDouble
    let savings = monthlySavings.asDouble
    return Int((costs / savings).rounded(.up))
}
