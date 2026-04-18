// DisclaimerContext.swift
// Contexts where a short fixed disclaimer surfaces in UI / PDF / narration.
//
// Each context has an EN + ES template in Disclaimers/Templates.swift.
// Approved set (10 contexts) locked during Session 2 kickoff.

import Foundation

public enum DisclaimerContext: String, Sendable, Hashable, Codable, CaseIterable {
    /// Generic "this is illustrative, not an offer" line for home/rate ribbon.
    case marketingGeneral
    /// Rate ribbon / today's-rates cards — emphasizes rate is indicative.
    case rateQuoteNotOffer
    /// Income Qualification output — pre-qual is not a commitment.
    case preQualNotCommitment
    /// APR displays across all calculators — APR is Reg-Z approximation.
    case aprApproximation
    /// PDF cover footer — concise liability line under the LO contact block.
    case pdfCoverFooter
    /// PDF disclaimers appendix header — intro to per-state text.
    case pdfDisclaimersAppendix
    /// Narration drawer — this narrative was device-generated from the numbers.
    case narrationGenerated
    /// Narration drawer on regeneration — different wording from the
    /// first-generation note so borrowers can identify regenerated text.
    case narrativeRegenerated
    /// HELOC stress-path projections — based on assumed rate curves.
    case helocStressProjection
    /// Scenario-saved toast/reminder — saved calc is not a commitment.
    case scenarioSavedReminder
}
