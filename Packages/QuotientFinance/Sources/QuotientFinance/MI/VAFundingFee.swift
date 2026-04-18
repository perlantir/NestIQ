// VAFundingFee.swift
// VA Funding Fee — the upfront charge that replaces PMI for VA loans.
//
// Source: Department of Veterans Affairs — https://www.va.gov/housing-assistance/home-loans/funding-fee-and-closing-costs/
// Table effective 2023-04-07 and unchanged for 2024–2025 (subject to
// statutory review; historically changed in multi-year intervals).

import Foundation

/// Type of VA loan transaction — determines the funding-fee schedule.
public enum VATransactionType: String, Sendable, Codable, Hashable, CaseIterable {
    case purchase
    case irrrl              // Interest Rate Reduction Refinance Loan
    case cashOutRefinance
}

/// Whether this is the borrower's first-time use of their VA benefit.
public enum VABenefitUsage: String, Sendable, Codable, Hashable, CaseIterable {
    case firstUse
    case subsequentUse
}

/// Parameters to compute the VA funding fee.
public struct VAFundingFeeInputs: Sendable, Hashable, Codable {
    public let loanAmount: Decimal
    public let transactionType: VATransactionType
    public let usage: VABenefitUsage
    /// Down payment as a fraction of purchase price (0.05 = 5%). Ignored for
    /// IRRRL and cash-out refinances.
    public let downPaymentFraction: Double
    /// Borrower is exempt (service-connected disability, surviving spouse,
    /// Purple Heart, etc.).
    public let isExempt: Bool

    public init(
        loanAmount: Decimal,
        transactionType: VATransactionType,
        usage: VABenefitUsage,
        downPaymentFraction: Double = 0,
        isExempt: Bool = false
    ) {
        self.loanAmount = loanAmount
        self.transactionType = transactionType
        self.usage = usage
        self.downPaymentFraction = downPaymentFraction
        self.isExempt = isExempt
    }
}

/// Upfront VA funding fee in dollars.
///
/// Formula: `fee = loanAmount × feeRate`, where `feeRate` is looked up from
/// the VA's published schedule on the transaction type, benefit usage, and
/// (for purchases) down-payment tier.
public func vaFundingFee(_ inputs: VAFundingFeeInputs) -> Decimal {
    if inputs.isExempt { return 0 }

    let rate: Double
    switch inputs.transactionType {
    case .irrrl:
        rate = 0.0050

    case .cashOutRefinance:
        rate = inputs.usage == .firstUse ? 0.0215 : 0.0330

    case .purchase:
        switch inputs.usage {
        case .firstUse:
            switch inputs.downPaymentFraction {
            case 0.10...:          rate = 0.0125
            case 0.05..<0.10:      rate = 0.0150
            default:               rate = 0.0215
            }
        case .subsequentUse:
            switch inputs.downPaymentFraction {
            case 0.10...:          rate = 0.0125
            case 0.05..<0.10:      rate = 0.0150
            default:               rate = 0.0330
            }
        }
    }

    return (inputs.loanAmount.asDouble * rate).asDecimal.money()
}
