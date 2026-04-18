// ClosingCostBreakdown.swift
// Convention (Session 5B.5): the borrower-facing "Closing costs"
// field on every scenario is the **all-in** amount, INCLUDING any
// points. `pointsPercentage` is carried alongside as an informational
// split — UI and PDF render both ("Closing costs $9,800 — of which
// $2,740 is 0.5 points on $548,000").
//
// This replaces the pre-5B.5 pattern where points were implicitly
// added to closing costs inside `scenarioInputs()` helpers; we now
// normalize at the form / Codable layer so the number stored on a
// Scenario matches what the LO typed on the Inputs screen.

import Foundation

public struct ClosingCostBreakdown: Sendable, Hashable, Codable {
    /// All-in user-entered amount. Includes the dollar value of any
    /// points the borrower is buying.
    public let totalClosingCosts: Decimal
    /// Points as a percentage of the loan amount. `0.5` = 0.5 points
    /// = half-point discount. Informational only — already baked
    /// into `totalClosingCosts`.
    public let pointsPercentage: Double
    /// Loan amount the points apply to. Stored alongside so
    /// `pointsAmount` can be recomputed without reaching into the
    /// owning scenario.
    public let loanAmount: Decimal

    public init(
        totalClosingCosts: Decimal,
        pointsPercentage: Double,
        loanAmount: Decimal
    ) {
        self.totalClosingCosts = totalClosingCosts
        self.pointsPercentage = pointsPercentage
        self.loanAmount = loanAmount
    }

    /// Dollar value of the points portion. Clamped to
    /// `totalClosingCosts` so the invariant `pointsAmount ≤ total`
    /// always holds, even if callers hand us nonsense inputs.
    public var pointsAmount: Decimal {
        let raw = (loanAmount.asDouble * pointsPercentage / 100).asDecimal.money()
        return min(raw, totalClosingCosts)
    }

    /// Non-points portion of the closing costs.
    public var feesAmount: Decimal {
        max(0, totalClosingCosts - pointsAmount)
    }
}
