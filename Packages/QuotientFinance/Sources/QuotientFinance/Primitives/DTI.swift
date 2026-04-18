// DTI.swift
// Debt-to-income ratios.
//
// - Front-end DTI: housing costs (PITI + MI) ÷ gross monthly income
// - Back-end DTI: all monthly debt obligations (housing + revolving +
//   installment + other) ÷ gross monthly income
//
// The caller decides which debts to include — `monthlyDebts` carries that
// decision. The `frontEnd` flag is carried for API symmetry with callers
// that want to document intent alongside the number.

import Foundation

/// DTI ratio as a decimal fraction (0.43 = 43%).
///
/// The `frontEnd` flag is not used in arithmetic — it's a caller-side marker
/// for intent. Pass `true` when `monthlyDebts` contains only housing costs,
/// `false` when it contains all monthly obligations.
public func calculateDTI(
    monthlyDebts: Decimal,
    grossMonthlyIncome: Decimal,
    frontEnd: Bool = false
) -> Double {
    guard grossMonthlyIncome > 0 else { return 0 }
    _ = frontEnd
    if monthlyDebts <= 0 { return 0 }
    return monthlyDebts.asDouble / grossMonthlyIncome.asDouble
}
