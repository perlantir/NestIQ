// Disclosures.swift
// Entry point for pulling the disclosure set a scenario needs.
//
// Returns `[Disclosure]` per the public API signature locked in
// DEVELOPMENT.md. Callers that want a persist-ready scenario-level
// summary (timestamp + rule version + audit string) wrap the array:
//
//     let disclosures = requiredDisclosures(for: .refinance, propertyState: .CA)
//     let bundle = DisclosureBundle(disclosures: disclosures)
//
// Session 3's PDF path writes the wrapped bundle as part of the scenario
// payload; Session 5's counsel-review audit reads it back to identify
// PDFs built on pre-review text.

import Foundation
import QuotientFinance

/// Disclosures required for a given scenario output, scoped to the
/// borrower's property state.
///
/// - Named states (CA, TX, FL, NY, IL, PA, OH, GA, NC, MI, IA) return
///   state-specific text with a regulator/statute citation.
/// - All other states + DC return the generic fallback with
///   `DisclosureProvenance.fallback`; callers MUST present these to
///   counsel before distributing the PDF (`needsCounselReview == true`).
///
/// - Parameters:
///   - scenarioType: Which calculator produced the output.
///   - propertyState: Borrower's property state — drives disclosure
///     selection.
///   - ruleVersion: Rule-table stamp; recorded on every returned
///     disclosure for reproducibility. Defaults to `.current`.
public func requiredDisclosures(
    for scenarioType: ScenarioType,
    propertyState: USState,
    ruleVersion: ComplianceRuleVersion = .current
) -> [Disclosure] {
    stateDisclosures(for: propertyState, scenarioType: scenarioType).map { d in
        Disclosure(
            state: d.state,
            scenarioType: d.scenarioType,
            textEN: d.textEN,
            textES: d.textES,
            sourceCitation: d.sourceCitation,
            retrievalDate: d.retrievalDate,
            counselReviewStatus: d.counselReviewStatus,
            provenance: d.provenance,
            ruleVersion: ruleVersion
        )
    }
}
