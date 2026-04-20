// CurrentMortgage.swift
// Session 5P.6 helpers — derive months-paid / months-remaining /
// LTV / equity for a borrower's current mortgage. The app-level
// `CurrentMortgage` Codable struct (App/Storage/CurrentMortgage.swift)
// is the storage format; these helpers operate on its primitive
// fields so the finance package stays decoupled from app types.

import Foundation

public enum CurrentMortgageCalculations {

    /// Full calendar months elapsed from `loanStartDate` to `asOfDate`
    /// (default today), rounded down. Returns 0 when `asOfDate` is
    /// at or before `loanStartDate`.
    public static func monthsPaid(
        loanStartDate: Date,
        asOfDate: Date = Date()
    ) -> Int {
        guard asOfDate > loanStartDate else { return 0 }
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(
            [.month],
            from: loanStartDate,
            to: asOfDate
        )
        return max(0, components.month ?? 0)
    }

    /// Months remaining on the original amortization term. Clamps at 0
    /// when the loan has run past its original term — LOs may still be
    /// working with a borrower who's past term (recast / modification /
    /// interest-only residue), so returning a negative would propagate
    /// garbage into downstream math.
    public static func monthsRemaining(
        originalTermYears: Int,
        loanStartDate: Date,
        asOfDate: Date = Date()
    ) -> Int {
        let elapsed = monthsPaid(loanStartDate: loanStartDate, asOfDate: asOfDate)
        let total = max(0, originalTermYears) * 12
        return max(0, total - elapsed)
    }

    /// Current loan-to-value as a ratio (0.0–1.x). Returns 0 when
    /// `propertyValue` is non-positive so callers don't divide by zero.
    /// Values above 1.0 are possible (underwater loans) and intentionally
    /// not clamped — surfacing the true ratio is the point.
    public static func ltvToday(
        currentBalance: Decimal,
        propertyValue: Decimal
    ) -> Decimal {
        guard propertyValue > 0 else { return 0 }
        return currentBalance / propertyValue
    }

    /// Current equity = property value − current balance. Clamped at 0
    /// to avoid surfacing a negative equity figure downstream — underwater
    /// loans should be flagged separately via LTV > 1.0 checks.
    public static func equityToday(
        currentBalance: Decimal,
        propertyValue: Decimal
    ) -> Decimal {
        let raw = propertyValue - currentBalance
        return raw > 0 ? raw : 0
    }
}
