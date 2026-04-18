// QuotientCompliance
//
// Public surface:
//   - `requiredDisclosures(for:propertyState:ruleVersion:)` — per-state disclosure
//     library for scenario output (PDF + narration).
//   - `nmlsConsumerAccessURL(for:)` — deep link to an individual LO's NMLS
//     Consumer Access page.
//   - `equalHousingOpportunityStatement(locale:)` — fixed federal housing-
//     equality statement, EN + ES.
//   - `requiredDisclaimer(context:locale:)` — short context-keyed legal
//     disclaimer for UI + PDF surfaces.
//
// State disclosure library policy:
//   - 11 states populated with state-specific text + regulator citation +
//     retrieval date + `CounselReviewStatus.pendingReview`: CA, TX, FL, NY,
//     IL, PA, OH, GA, NC, MI, IA.
//   - Remaining 39 states + DC: generic fallback text with `provenance =
//     .fallback` and `counselReviewStatus = .pendingReview`.
//   - Session 5's compliance attorney review moves each state from
//     `pendingReview` to `reviewedApproved` or `reviewedNeedsRevision` in
//     place. Scenarios generated before review preserve the earlier status
//     in their `DisclosureBundle` so regenerated PDFs can be flagged.
//
// Rule versioning: `ComplianceRuleVersion` lives in QuotientFinance (to
// avoid a cyclic dependency — see DECISIONS.md 2026-04-17). Every
// `DisclosureBundle` records the version used at generation time; Session 3
// persists it alongside `Scenario.complianceRuleVersion`.

import Foundation
import QuotientFinance

/// Module identity marker — kept Sendable/simple so downstream packages can
/// assert against it without pulling in internal types.
public enum QuotientCompliance {
    public static let version = "2026.Q2"
}
