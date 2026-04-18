// PMI.swift
// Monthly mortgage insurance premium across loan types.
//
// Returns the monthly MI dollar amount. Zero when MI isn't required
// (LTV ≤ 80% conv, VA with non-exempt funding fee captured elsewhere,
// HELOC). Callers that need cancellation / termination logic use the
// returned amount with a `PMISchedule` attached to `AmortizationOptions`.

import Foundation

/// Monthly mortgage-insurance premium for the requested product.
///
/// - Parameters:
///   - ltv: Origination LTV (as a decimal, 0.95 = 95%).
///   - creditScore: Tri-merged middle FICO.
///   - loanAmount: Base loan amount (before any financed UFMIP / funding fee).
///   - loanType: Product family.
///   - termMonths: Loan term in months (drives FHA MIP tier).
///   - paymentType: Structure of the MI payment.
/// - Returns: Monthly MI premium, rounded to cents. `0` when MI is not
///   required or not applicable.
public func calculatePMI(
    ltv: Double,
    creditScore: Int,
    loanAmount: Decimal,
    loanType: LoanType,
    termMonths: Int = 360,
    paymentType: PMIPaymentType = .monthly
) -> Decimal {
    guard ltv >= 0, loanAmount >= 0 else { return 0 }

    switch loanType {
    case .conventional, .jumbo:
        guard paymentType == .monthly || paymentType == .splitPremium else {
            // Upfront and LPMI don't carry a monthly line item.
            return 0
        }
        guard let annual = ConventionalMIGrid.annualRate(ltv: ltv, creditScore: creditScore) else {
            return 0
        }
        // Split-premium programs typically discount the monthly portion by
        // roughly a third in exchange for an upfront premium; we approximate
        // via a 0.65 multiplier.
        let adjusted = paymentType == .splitPremium ? annual * 0.65 : annual
        return ((loanAmount.asDouble * adjusted) / 12.0).asDecimal.money()

    case .fha:
        guard paymentType == .monthly else { return 0 }
        guard let annual = FHAMIPTable.annualRate(ltv: ltv, termMonths: termMonths) else {
            return 0
        }
        return ((loanAmount.asDouble * annual) / 12.0).asDecimal.money()

    case .va, .usda, .heloc:
        // VA: funding fee is upfront only — use `vaFundingFee(_:)`.
        // USDA: annual guarantee fee of 0.35% can be computed similarly but
        // isn't requested in the Session 1 primitives list.
        // HELOC: no MI.
        return 0
    }
}
