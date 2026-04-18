// MaxQualifyingLoan.swift
// Inverse of amortize: given income constraints, solve for the largest
// principal that satisfies a DTI cap.

import Foundation

/// Largest loan principal that keeps back-end DTI ≤ `dtiCap` given the
/// borrower's income, existing debts, and the product's rate + term.
///
/// Day-count convention: 30/360 monthly (conventional / FHA / VA / USDA
/// fixed). ARM / HELOC callers must recompute with the appropriate
/// convention — Session 2 may add overloads.
///
/// Simplifications (documented intentionally; refined in Session 2):
/// - PMI is **not** included. If the computed loan would require PMI, the
///   true max qualifying loan is lower; the caller is expected to subtract
///   an estimated MI premium from `monthlyTaxes + monthlyInsurance + …`
///   before calling, or to iterate using `calculatePMI`.
/// - Taxes + insurance + HOA are caller-supplied monthly amounts. A
///   production flow looks these up from property state + purchase price.
public func calculateMaxQualifyingLoan(
    grossMonthlyIncome: Decimal,
    monthlyDebts: Decimal,
    annualRate: Double,
    termMonths: Int,
    monthlyTaxes: Decimal,
    monthlyInsurance: Decimal,
    monthlyHOA: Decimal = 0,
    dtiCap: Double = 0.43,
    loanType: LoanType = .conventional
) -> Decimal {
    guard grossMonthlyIncome > 0,
          termMonths > 0,
          dtiCap > 0,
          dtiCap < 1 else { return 0 }
    _ = loanType

    let maxTotalDebtService = grossMonthlyIncome.asDouble * dtiCap
    let maxHousing = maxTotalDebtService - monthlyDebts.asDouble
    let fixedHousingCost = monthlyTaxes.asDouble + monthlyInsurance.asDouble + monthlyHOA.asDouble
    let maxPI = maxHousing - fixedHousingCost

    guard maxPI > 0 else { return 0 }

    // Inverse of the ordinary-annuity PMT formula:
    //   P = PMT × (1 − (1 + r)^−n) / r
    let r = annualRate / 12.0
    let n = Double(termMonths)

    let principal: Double
    if r == 0 {
        principal = maxPI * n
    } else {
        principal = maxPI * (1.0 - pow(1.0 + r, -n)) / r
    }
    return principal.asDecimal.money()
}
