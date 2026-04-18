// DownPayment.swift
// Borrower's down payment, expressed either as a percentage of the
// purchase price or a fixed dollar amount. Converts freely between
// forms at a given purchase price so the UI can let the LO toggle
// between "%" and "$" while keeping the underlying value stable.
//
// Returned dollar amounts round to cents via `Decimal.money()` so
// derived numbers don't drift below the penny.

import Foundation

public struct DownPayment: Sendable, Hashable, Codable {
    public enum Form: Sendable, Hashable, Codable {
        /// 0.20 = 20%.
        case percentage(Double)
        case dollarAmount(Decimal)
    }

    public let form: Form

    public init(form: Form) {
        self.form = form
    }

    public static func percentage(_ p: Double) -> DownPayment {
        DownPayment(form: .percentage(p))
    }

    public static func dollars(_ amount: Decimal) -> DownPayment {
        DownPayment(form: .dollarAmount(amount))
    }

    /// Dollar amount at the given price. Rounds to cents.
    public func amount(purchasePrice: Decimal) -> Decimal {
        switch form {
        case .percentage(let p):
            let d = (purchasePrice.asDouble * p).asDecimal
            return d.money()
        case .dollarAmount(let amt):
            return amt
        }
    }

    /// Fractional percentage at the given price. `0.20` for 20%.
    /// Returns 0 if `purchasePrice <= 0`.
    public func percentage(purchasePrice: Decimal) -> Double {
        switch form {
        case .percentage(let p):
            return p
        case .dollarAmount(let amt):
            guard purchasePrice > 0 else { return 0 }
            return amt.asDouble / purchasePrice.asDouble
        }
    }

    /// Loan amount implied by this down payment at the given price.
    /// Never negative: if the down payment exceeds the price, returns 0.
    public func loanAmount(purchasePrice: Decimal) -> Decimal {
        let down = amount(purchasePrice: purchasePrice)
        return max(0, purchasePrice - down)
    }
}

/// GSE / HPA rule: mortgage insurance is required when LTV exceeds 80%.
/// Returns `true` iff `ltv > 0.80`.
public func isMIRequired(ltv: Double) -> Bool {
    ltv > 0.80
}
