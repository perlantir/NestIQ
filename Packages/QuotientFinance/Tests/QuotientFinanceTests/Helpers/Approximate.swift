// Approximate.swift
// Tolerance-based equality for Decimal and Double in tests.
//
// Uses absolute tolerances by default — mortgage math's absolute magnitudes
// are well-defined (cents for money, basis points for rates) so relative
// tolerance rarely adds value.

import Foundation
@testable import QuotientFinance

extension Decimal {
    /// True when `self` and `other` differ by at most `tolerance`.
    func isApproximatelyEqual(to other: Decimal, tolerance: Decimal = 0.01) -> Bool {
        let diff = self > other ? self - other : other - self
        return diff <= tolerance
    }
}

extension Double {
    /// True when `self` and `other` differ by at most `tolerance`.
    func isApproximatelyEqual(to other: Double, tolerance: Double = 1e-6) -> Bool {
        abs(self - other) <= tolerance
    }
}

/// Convenience constructor for a UTC `Date` from YYYY-MM-DD components.
/// Keeps test dates deterministic and readable.
func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    var dc = DateComponents()
    dc.timeZone = cal.timeZone
    dc.year = y
    dc.month = m
    dc.day = d
    return cal.date(from: dc) ?? Date()
}
