// HPML.swift
// Higher-Priced Mortgage Loan + Higher-Priced Covered Transaction tests
// per Reg Z §§1026.35 and 1026.43(b)(4).

import Foundation

/// Where the lien sits in the security priority. Governs the APR-APOR spread
/// threshold for HPML / HPCT.
public enum LienPosition: String, Sendable, Codable, Hashable, CaseIterable {
    case first
    case subordinate
}

/// Is this a Higher-Priced Mortgage Loan under Reg Z §1026.35(a)(1)?
///
/// Thresholds (APR exceeds APOR by at least):
/// - First-lien, non-jumbo:  1.50 percentage points
/// - First-lien, jumbo:      2.50 percentage points
/// - Subordinate-lien:       3.50 percentage points
///
/// - Parameters:
///   - apr: Annual percentage rate (decimal fraction, e.g. 0.0825 = 8.25%).
///   - apor: Average Prime Offer Rate (decimal fraction).
///   - lienPosition: First or subordinate.
///   - isJumbo: True if the loan exceeds the FHFA conforming loan limit.
public func isHPML(
    apr: Double,
    apor: Double,
    lienPosition: LienPosition,
    isJumbo: Bool
) -> Bool {
    let spread = apr - apor
    let threshold: Double
    switch lienPosition {
    case .first:        threshold = isJumbo ? 0.025 : 0.015
    case .subordinate:  threshold = 0.035
    }
    return spread >= threshold
}

/// Is this a Higher-Priced Covered Transaction under Reg Z §1026.43(b)(4)?
///
/// HPCT shares HPML's spread thresholds for the general QM test. Small
/// creditor portfolio QM uses a 3.50 percentage-point threshold for
/// first-lien loans regardless of jumbo status.
public func isHPCT(
    apr: Double,
    apor: Double,
    lienPosition: LienPosition,
    isJumbo: Bool,
    isSmallCreditorPortfolio: Bool = false
) -> Bool {
    let spread = apr - apor
    let threshold: Double
    switch lienPosition {
    case .first:
        threshold = isSmallCreditorPortfolio ? 0.035 : (isJumbo ? 0.025 : 0.015)
    case .subordinate:
        threshold = 0.035
    }
    return spread >= threshold
}
