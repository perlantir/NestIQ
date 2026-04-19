// OtherDebts.swift
// Aggregate non-mortgage debts carried by the borrower — credit cards,
// auto loans, student loans, etc. Used by TCA refinance-mode scenarios
// to show the monthly-payment impact of consolidating some/all of
// those balances into a refi.
//
// Intentionally aggregate-only. Itemization (card A + card B + auto)
// is out of scope for v1; the LO enters total balance + total monthly
// payment. If a scenario's cash-out covers the full balance, the LO
// sets per-scenario `remaining` to zero; partial consolidations are
// LO-entered per option.

import Foundation

public struct OtherDebts: Codable, Hashable, Sendable {
    public let totalBalance: Decimal
    public let monthlyPayment: Decimal

    public init(totalBalance: Decimal, monthlyPayment: Decimal) {
        self.totalBalance = totalBalance
        self.monthlyPayment = monthlyPayment
    }

    /// Convenience for "no other debts." Using a function rather than
    /// a constant so the call site reads as "OtherDebts.zero()" and we
    /// don't accidentally share identity across callers.
    public static func zero() -> OtherDebts {
        OtherDebts(totalBalance: 0, monthlyPayment: 0)
    }

    public var isZero: Bool {
        totalBalance == 0 && monthlyPayment == 0
    }
}
