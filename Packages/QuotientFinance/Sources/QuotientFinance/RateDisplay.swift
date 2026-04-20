// RateDisplay.swift
// Session 5M.1: Rate / APR display formatting. Pure presentation —
// never drives math. See DECISIONS.md § Session 5M (D1-D3) for the
// regulatory rationale: TILA § 1026.22 APR math is regulated; LOs
// source APR from their LOS and this app surfaces what they entered
// for borrower-facing compliance context.

import Foundation

/// Formats a rate and an optional APR into a borrower-facing display
/// string.
///
/// - When `apr` is `nil` (LO didn't enter one), or when `apr` matches
///   `rate` within half of the displayed precision (0.0005%), the
///   result is the rate alone: `"6.750%"`.
/// - When `apr` is meaningfully different from `rate`, both render
///   with an "APR" suffix on the second: `"6.750% / 6.812% APR"`.
///
/// Tolerance rationale: rates and APRs both render at 3 decimal
/// places. Two values that render identically (e.g. `6.7500001` and
/// `6.7500000`) shouldn't paint a redundant "6.750% / 6.750% APR"
/// just because their underlying `Double` representations differ by
/// binary epsilon.
///
/// - Parameters:
///   - rate: Note rate (note rate, in percent — e.g. `6.750` means
///     6.750%).
///   - apr: APR the LO entered (in percent), or `nil` if blank.
/// - Returns: Formatted display string.
public func displayRateAndAPR(rate: Double, apr: Double?) -> String {
    let rateStr = formatRatePercent(rate)
    guard let apr, abs(apr - rate) >= 0.0005 else { return rateStr }
    return "\(rateStr) / \(formatRatePercent(apr)) APR"
}

/// `Decimal?` bridge — the persisted `aprRate` field on every
/// FormInputs is `Optional<Decimal>` per D3, so the view layer almost
/// always has Decimal in hand. Converts via `.asDouble` and dispatches.
/// Not a name collision with the primary signature because the label
/// and outer type disambiguate: `decimalAPR` vs `apr`.
public func displayRateAndAPR(rate: Double, decimalAPR: Decimal?) -> String {
    displayRateAndAPR(rate: rate, apr: decimalAPR?.asDouble)
}

private func formatRatePercent(_ value: Double) -> String {
    String(format: "%.3f%%", value)
}
