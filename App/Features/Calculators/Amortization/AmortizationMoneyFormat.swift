// AmortizationMoneyFormat.swift
// Small formatting helpers shared between the inputs / results screens.

import Foundation

final class MoneyFormat: Sendable {
    static let shared = MoneyFormat()

    func currencyCompact(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: value as NSNumber) ?? "\(value)"
    }

    /// Locale-aware currency string with no fraction digits: "$4,231".
    /// Single source of truth for currency rendering — do not prefix a
    /// literal "$" to the output.
    func currency(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f.string(from: value as NSNumber) ?? "$\(value)"
    }

    func dollarsLong(_ value: Decimal) -> String {
        currency(value)
    }

    /// Compact currency for tight layouts: "$732K", "$1.24M". Already
    /// prefixed — do not prepend another "$".
    func dollarsShort(_ value: Decimal) -> String {
        let d = Double(truncating: value as NSNumber)
        if d >= 1_000_000 {
            return String(format: "$%.2fM", d / 1_000_000)
        }
        if d >= 1_000 {
            return String(format: "$%.0fK", d / 1_000)
        }
        return String(format: "$%.0f", d)
    }

    func decimalString(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: value as NSNumber) ?? "\(value)"
    }
}
