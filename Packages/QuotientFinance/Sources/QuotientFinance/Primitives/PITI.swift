// PITI.swift
// Principal, Interest, Taxes, Insurance — the monthly housing payment.

import Foundation

/// Full monthly housing payment: P&I + escrowed taxes + hazard insurance
/// + HOA dues + mortgage insurance (if applicable).
///
/// Day-count convention: P&I is computed from the loan via `paymentFor(loan:)`,
/// which uses the loan's implied day-count (30/360 for conv/FHA/VA/USDA fixed).
public func calculatePITI(
    loan: Loan,
    monthlyTaxes: Decimal,
    monthlyInsurance: Decimal,
    monthlyHOA: Decimal = 0,
    monthlyPMI: Decimal = 0
) -> Decimal {
    let pi = paymentFor(loan: loan)
    return (pi + monthlyTaxes + monthlyInsurance + monthlyHOA + monthlyPMI).money()
}
