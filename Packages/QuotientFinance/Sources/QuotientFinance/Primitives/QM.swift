// QM.swift
// Qualified Mortgage determination per Reg Z §1026.43 (ATR/QM rule).
//
// This is the **math** side of QM only — points-and-fees test, APR-APOR
// spread, loan-term cap, disallowed-feature checks. State-specific rule
// variations (small creditor territory, manufactured home riders, etc.)
// and the full rule-version engine live in QuotientCompliance (Session 2).

import Foundation

/// Loan features that disqualify a mortgage from Gen-QM regardless of
/// pricing. Captured separately from `Loan` because the Session 1 `Loan`
/// struct models only standard fully-amortizing products.
public struct QMFeatures: Sendable, Hashable, Codable {
    public var interestOnly: Bool
    public var negativeAmortizing: Bool
    public var balloon: Bool

    public init(interestOnly: Bool = false, negativeAmortizing: Bool = false, balloon: Bool = false) {
        self.interestOnly = interestOnly
        self.negativeAmortizing = negativeAmortizing
        self.balloon = balloon
    }

    public static let standardFixed = QMFeatures()

    /// True if any disallowed Gen-QM feature is present.
    public var hasDisallowedFeature: Bool {
        interestOnly || negativeAmortizing || balloon
    }
}

/// Outcome of a QM assessment. Carries the full determination trail in
/// `reasons` so it can be shown to an LO and preserved with the scenario
/// for later audit.
public struct QMDetermination: Sendable, Hashable, Codable {
    public enum Status: String, Sendable, Hashable, Codable, CaseIterable {
        /// General QM (Rule 2021 final): DTI replaced by price-based test.
        case generalQM
        /// Seasoned QM: 36-month payment history safe harbor.
        case seasonedQM
        /// Small creditor portfolio QM (§1026.43(e)(5)).
        case smallCreditorQM
        case notQM
    }

    public enum Presumption: String, Sendable, Hashable, Codable, CaseIterable {
        case safeHarbor
        case rebuttablePresumption
        case notApplicable
    }

    public let status: Status
    public let presumption: Presumption
    public let isHigherPriced: Bool
    /// APR − APOR, in decimal fraction (0.02 = 2.00 percentage points).
    public let aprAporSpread: Double
    public let pointsAndFeesAmount: Decimal
    /// Points and fees as a fraction of loan amount.
    public let pointsAndFeesPercent: Double
    public let termCompliant: Bool
    public let featuresCompliant: Bool
    public let complianceRuleVersion: ComplianceRuleVersion
    public let reasons: [String]

    public init(
        status: Status,
        presumption: Presumption,
        isHigherPriced: Bool,
        aprAporSpread: Double,
        pointsAndFeesAmount: Decimal,
        pointsAndFeesPercent: Double,
        termCompliant: Bool,
        featuresCompliant: Bool,
        complianceRuleVersion: ComplianceRuleVersion,
        reasons: [String]
    ) {
        self.status = status
        self.presumption = presumption
        self.isHigherPriced = isHigherPriced
        self.aprAporSpread = aprAporSpread
        self.pointsAndFeesAmount = pointsAndFeesAmount
        self.pointsAndFeesPercent = pointsAndFeesPercent
        self.termCompliant = termCompliant
        self.featuresCompliant = featuresCompliant
        self.complianceRuleVersion = complianceRuleVersion
        self.reasons = reasons
    }
}

/// Compute a Qualified Mortgage determination.
///
/// - Parameters:
///   - loan: The loan being evaluated.
///   - apr: Annual percentage rate (from `calculateAPR`).
///   - apor: Average Prime Offer Rate for the product / lock date (from
///     `calculateAPOR`).
///   - pointsAndFees: Total points and fees per §1026.32(b)(1).
///   - lienPosition: First or subordinate.
///   - isJumbo: True when loan exceeds FHFA conforming loan limit.
///   - features: Disallowed-feature flags (IO, neg-am, balloon).
///   - isSmallCreditorPortfolio: True for §1026.43(e)(5) small creditor QM.
///   - ruleVersion: Compliance rule version to stamp on the determination.
/// - Returns: A `QMDetermination` with status, presumption level, and a
///   human-readable `reasons` trail.
public func calculateQMStatus(
    loan: Loan,
    apr: Double,
    apor: Double,
    pointsAndFees: Decimal,
    lienPosition: LienPosition = .first,
    isJumbo: Bool = false,
    features: QMFeatures = .standardFixed,
    isSmallCreditorPortfolio: Bool = false,
    ruleVersion: ComplianceRuleVersion = .current
) -> QMDetermination {
    var reasons: [String] = []

    // --- 1. APR-APOR spread (pricing-based presumption) ---
    let spread = apr - apor
    let higherPriced = isHPCT(
        apr: apr,
        apor: apor,
        lienPosition: lienPosition,
        isJumbo: isJumbo,
        isSmallCreditorPortfolio: isSmallCreditorPortfolio
    )

    // --- 2. Term cap: 30 years for Gen-QM ---
    let termOK = loan.termMonths <= 360
    if !termOK {
        reasons.append("Loan term of \(loan.termMonths) months exceeds Gen-QM maximum of 360.")
    }

    // --- 3. Disallowed features ---
    let featuresOK = !features.hasDisallowedFeature
    if features.interestOnly {
        reasons.append("Interest-only period disallowed under Gen-QM.")
    }
    if features.negativeAmortizing {
        reasons.append("Negative amortization disallowed under Gen-QM.")
    }
    if features.balloon {
        reasons.append("Balloon payment disallowed under Gen-QM (small creditor exception may apply).")
    }

    // --- 4. Points and fees test ---
    //
    // Simplified to the "standard" 3% cap for loans ≥ approx. $130k. Tiered
    // caps for smaller loans (5%, 8%, plus two flat-dollar tiers) are a
    // Session 2 compliance concern and require an annually-adjusted table.
    let loanAmount = loan.principal.asDouble
    let pfPercent = loanAmount > 0 ? pointsAndFees.asDouble / loanAmount : 0
    let pfCap = 0.03
    let pfOK = pfPercent <= pfCap
    if !pfOK {
        let pfPct = String(format: "%.2f%%", pfPercent * 100)
        reasons.append("Points and fees \(pfPct) exceeds \(Int(pfCap * 100))% cap.")
    }

    // --- 5. Combine ---
    let passesGenQM = termOK && featuresOK && pfOK
    let status: QMDetermination.Status
    let presumption: QMDetermination.Presumption

    if !passesGenQM {
        status = .notQM
        presumption = .notApplicable
        reasons.insert("Not a Qualified Mortgage.", at: 0)
    } else if isSmallCreditorPortfolio {
        status = .smallCreditorQM
        presumption = higherPriced ? .rebuttablePresumption : .safeHarbor
        reasons.insert("Small creditor portfolio QM.", at: 0)
    } else {
        status = .generalQM
        presumption = higherPriced ? .rebuttablePresumption : .safeHarbor
        if higherPriced {
            let spreadPct = String(format: "%.2f", spread * 100)
            reasons.append("APR exceeds APOR by \(spreadPct) pp — rebuttable presumption QM.")
        } else {
            let spreadPct = String(format: "%.2f", spread * 100)
            reasons.append("APR-APOR spread \(spreadPct) pp — safe-harbor QM.")
        }
    }

    return QMDetermination(
        status: status,
        presumption: presumption,
        isHigherPriced: higherPriced,
        aprAporSpread: spread,
        pointsAndFeesAmount: pointsAndFees,
        pointsAndFeesPercent: pfPercent,
        termCompliant: termOK,
        featuresCompliant: featuresOK,
        complianceRuleVersion: ruleVersion,
        reasons: reasons
    )
}
