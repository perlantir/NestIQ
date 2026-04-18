// DecimalExtensions.swift
// Narrow helpers for moving between Decimal (money) and Double (rate math).
//
// Rationale: Swift's `Decimal` has no native `pow()` or `exp()`, so any
// formula involving (1 + r)^n must detour through Double. We keep the detour
// explicit and re-round to cents at money boundaries to avoid binary
// floating-point drift leaking into dollar figures.

import Foundation

public extension Decimal {
    /// Round to `scale` fractional digits using banker's rounding.
    func rounded(_ scale: Int, _ mode: NSDecimalNumber.RoundingMode = .bankers) -> Decimal {
        var result = Decimal()
        var source = self
        NSDecimalRound(&result, &source, scale, mode)
        return result
    }

    /// Currency precision — 2 decimal places, banker's rounding. Used at
    /// every payment-boundary to prevent sub-cent drift.
    func money() -> Decimal {
        rounded(2, .bankers)
    }

    /// Convert to `Double` for rate math. Lossy by design — use only as an
    /// intermediate, never as a final money output.
    var asDouble: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    /// `true` when this value is strictly positive.
    var isPositive: Bool { self > 0 }

    /// `self` clamped to `>= 0`. Used to defend against sub-cent residuals
    /// pushing a balance very slightly negative on the final payment.
    var clampedNonNegative: Decimal { Swift.max(self, 0) }
}

public extension Double {
    /// Convert to `Decimal` via the String form. Avoids introducing binary
    /// floating-point artifacts (e.g. 0.1 → 0.1000000000000000055).
    var asDecimal: Decimal {
        Decimal(string: String(self)) ?? .zero
    }
}
