// LTV.swift
// Loan-to-value calculations used across underwriting and compliance.
//
// - LTV: first lien ÷ property value
// - CLTV: all liens (current balances) ÷ property value
// - HCLTV: first lien + (HELOC maximum line, not current balance) + other
//          subordinate liens ÷ property value. This is what GSEs use for QM,
//          not CLTV, because an undrawn HELOC could be drawn at any time.

import Foundation

/// Simple LTV — first lien over property value. Returns 0 if
/// `propertyValue ≤ 0` (defensive — prevents NaN in downstream chart code).
public func calculateLTV(loanAmount: Decimal, propertyValue: Decimal) -> Double {
    guard propertyValue > 0 else { return 0 }
    return loanAmount.asDouble / propertyValue.asDouble
}

/// Combined LTV — first lien plus all subordinate lien **current balances**.
public func calculateCLTV(
    firstLien: Decimal,
    subordinateLiens: [Decimal],
    propertyValue: Decimal
) -> Double {
    guard propertyValue > 0 else { return 0 }
    let total = subordinateLiens.reduce(firstLien) { $0 + $1 }
    return total.asDouble / propertyValue.asDouble
}

/// Home-equity combined LTV — first lien plus the **full HELOC line** (not
/// its current balance) plus any other subordinate lien balances, over
/// property value. HCLTV is the figure GSEs use for QM eligibility because
/// an undrawn HELOC line can be drawn at any time.
public func calculateHCLTV(
    firstLien: Decimal,
    helocLineLimit: Decimal,
    otherSubordinateLiens: [Decimal] = [],
    propertyValue: Decimal
) -> Double {
    guard propertyValue > 0 else { return 0 }
    let total = otherSubordinateLiens.reduce(firstLien + helocLineLimit) { $0 + $1 }
    return total.asDouble / propertyValue.asDouble
}
