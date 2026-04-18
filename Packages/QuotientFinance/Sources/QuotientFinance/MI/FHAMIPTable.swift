// FHAMIPTable.swift
// FHA Mortgage Insurance Premium schedule.
//
// Source: HUD Mortgagee Letter 2023-05 (effective 2023-03-20) and the
// subsequent unchanged 2024/2025 tables. Rates apply to case numbers
// assigned on or after the effective date.
//
// Two components:
// - UFMIP (Upfront MIP): 1.75% of base loan amount, paid at closing or
//   financed into the loan. Same for all base-loan terms ≥ 15 years.
// - Annual MIP: paid monthly as 1/12 of the annual rate × loan balance.
//   Rate depends on term, base LTV at origination, and loan amount tier.
//
// Base loan threshold (2024+): $726,200 was the GSE conforming limit
// through 2023; FHA uses a different high-balance threshold that tracks
// FHA forward-mortgage limits. For simplicity we use the most-common
// low-balance tier rates; the high-balance adder is +10 bps.

import Foundation

enum FHAMIPTable {
    /// Upfront Mortgage Insurance Premium rate — 1.75% of base loan amount.
    static let ufmipRate: Double = 0.0175

    /// Annual MIP rate for the standard low-balance tier.
    /// - Parameters:
    ///   - ltv: Base LTV at origination.
    ///   - termMonths: Loan term in months. Long-term = > 180 months.
    /// - Returns: Annual rate as a decimal fraction, or `nil` if outside
    ///   FHA's standard matrix.
    static func annualRate(ltv: Double, termMonths: Int) -> Double? {
        let longTerm = termMonths > 180

        if longTerm {
            switch ltv {
            case ...0.9000:  return 0.0050   // LTV ≤ 90%:     50 bps
            case ...0.9500:  return 0.0050   // 90 < LTV ≤ 95: 50 bps
            default:         return 0.0055   // LTV > 95%:     55 bps
            }
        } else {
            switch ltv {
            case ...0.9000:  return 0.0015   // LTV ≤ 90%, term ≤ 15 yr
            default:         return 0.0040   // LTV > 90%, term ≤ 15 yr
            }
        }
    }

    /// Automatic cancellation criterion. Loans with original base LTV > 90%
    /// pay MIP for the life of the loan; loans with LTV ≤ 90% pay for
    /// 11 years.
    static func isPermanent(ltv: Double) -> Bool {
        ltv > 0.90
    }

    /// Minimum months MIP must be paid for LTV ≤ 90% loans.
    static let minimumPeriodsForLowLTV: Int = 132  // 11 years × 12 months
}
