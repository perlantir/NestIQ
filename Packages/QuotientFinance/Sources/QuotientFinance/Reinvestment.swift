// Reinvestment.swift
// Session 5M.8: future-value-of-monthly-deposits primitive powering
// TCA's "Invest the savings" path. Standard annuity-future-value
// formula:
//
//    FV = PMT × ((1 + r)^n − 1) / r
//
// where r is the monthly rate (annualRate / 12) and n is months.
// Returns `PMT × n` when annualRate is 0 (degenerate no-compounding
// case; the formula divides by zero otherwise).

import Foundation

/// Future value of a series of `deposit` amounts made at the END of
/// each month (ordinary annuity), compounded monthly at
/// `annualRate` (as a decimal — `0.07` means 7%).
///
/// - Parameters:
///   - deposit: Monthly deposit amount. Negative or zero → 0 return.
///   - annualRate: Annualized return (decimal). 0 → no compounding,
///     result is `deposit × months`.
///   - months: Number of monthly deposits / compounding periods.
///     Negative or zero → 0 return.
public func futureValueOfMonthlyDeposits(
    deposit: Decimal,
    annualRate: Double,
    months: Int
) -> Decimal {
    guard deposit > 0, months > 0 else { return 0 }
    if annualRate == 0 {
        return deposit * Decimal(months)
    }
    let monthlyRate = annualRate / 12.0
    let growth = pow(1.0 + monthlyRate, Double(months))
    let factor = (growth - 1.0) / monthlyRate
    return deposit * Decimal(factor)
}
