// Disclosure.swift
// A single state disclosure and a bundle type that summarizes the
// disclosures used to produce a specific scenario output.

import Foundation
import QuotientFinance

/// Whether the disclosure text is state-specific or a generic fallback.
/// Fallbacks are used for the 39 stubbed states pending state-specific
/// drafting in Session 5; named-state disclosures carry `.stateSpecific`.
public enum DisclosureProvenance: String, Sendable, Hashable, Codable, CaseIterable {
    case stateSpecific
    case fallback
}

/// A single disclosure: EN + ES text, regulator citation, retrieval date,
/// review status, provenance, and the rule-version stamp that produced it.
///
/// Scoping: when `scenarioType == nil` the disclosure applies to any
/// scenario output (general-purpose marketing/calculation disclaimer);
/// when non-nil, it only applies to that specific scenario type (e.g.,
/// a HELOC-specific state notice).
public struct Disclosure: Sendable, Hashable, Codable {
    public let state: USState
    public let scenarioType: ScenarioType?
    public let textEN: String
    public let textES: String
    /// Regulator URL, statute citation, or public-guidance document the
    /// text was drawn from. Format: free-form, but by convention begins
    /// with the issuing authority, followed by the citation.
    public let sourceCitation: String
    /// Date the `sourceCitation` was retrieved.
    public let retrievalDate: Date
    public let counselReviewStatus: CounselReviewStatus
    public let provenance: DisclosureProvenance
    public let ruleVersion: ComplianceRuleVersion

    public init(
        state: USState,
        scenarioType: ScenarioType? = nil,
        textEN: String,
        textES: String,
        sourceCitation: String,
        retrievalDate: Date,
        counselReviewStatus: CounselReviewStatus = .pendingReview,
        provenance: DisclosureProvenance,
        ruleVersion: ComplianceRuleVersion = .current
    ) {
        self.state = state
        self.scenarioType = scenarioType
        self.textEN = textEN
        self.textES = textES
        self.sourceCitation = sourceCitation
        self.retrievalDate = retrievalDate
        self.counselReviewStatus = counselReviewStatus
        self.provenance = provenance
        self.ruleVersion = ruleVersion
    }

    /// True when this disclosure requires counsel review before a PDF
    /// carrying it is distributed. `false` only for explicitly-approved
    /// text; `true` for pending review, needs-revision, and fallbacks.
    public var needsCounselReview: Bool {
        switch counselReviewStatus {
        case .reviewedApproved: return provenance == .fallback
        case .pendingReview, .reviewedNeedsRevision: return true
        }
    }

    /// Pick the appropriate localized text based on the locale's language
    /// code; defaults to EN for anything that isn't Spanish.
    public func text(for locale: Locale) -> String {
        let lang = locale.language.languageCode?.identifier ?? "en"
        return lang == "es" ? textES : textEN
    }
}

/// A scenario-level grouping of disclosures produced by
/// `requiredDisclosures(for:propertyState:ruleVersion:)`. Captures:
/// - the disclosures themselves,
/// - the rule version active at generation time,
/// - a timestamp so audits can correlate bundles with later rule updates.
///
/// Persisted alongside a saved scenario so later regeneration can detect
/// disclosure-text drift and flag PDFs for reissue.
public struct DisclosureBundle: Sendable, Hashable, Codable {
    public let disclosures: [Disclosure]
    public let ruleVersion: ComplianceRuleVersion
    public let generatedAt: Date

    public init(
        disclosures: [Disclosure],
        ruleVersion: ComplianceRuleVersion = .current,
        generatedAt: Date = Date()
    ) {
        self.disclosures = disclosures
        self.ruleVersion = ruleVersion
        self.generatedAt = generatedAt
    }

    /// `true` when any disclosure in the bundle still needs counsel review.
    /// PDF generation should watermark or annotate accordingly.
    public var hasAnyPendingReview: Bool {
        disclosures.contains { $0.needsCounselReview }
    }

    /// States whose disclosure still needs counsel review.
    public var pendingReviewStates: [USState] {
        disclosures.filter(\.needsCounselReview).map(\.state)
    }

    /// Short human-readable summary suitable for audit logs / session
    /// summaries / PDF footers.
    /// Example: `"3 disclosures · 2 pending review · rule 2026.Q2"`.
    public var auditSummary: String {
        let pending = disclosures.filter(\.needsCounselReview).count
        let pendingFragment = pending == 0 ? "all reviewed" : "\(pending) pending review"
        return "\(disclosures.count) disclosures · \(pendingFragment) · rule \(ruleVersion.rawValue)"
    }
}
