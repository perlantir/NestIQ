// CounselReviewStatus.swift
// Review state for a single state disclosure. Mutable during Session 5 as
// compliance counsel works through the library.
//
// Propagation: every `Disclosure` carries its status; every
// `DisclosureBundle` preserves the status of every disclosure it includes
// so that previously-generated PDFs can be audited against later reviews.
// When counsel updates a disclosure from `.pendingReview` to
// `.reviewedApproved`, prior scenarios retain the `.pendingReview` tag in
// their persisted bundle — a flag that the PDF was built on pre-review
// text and should be regenerated before distribution.

import Foundation

public enum CounselReviewStatus: Sendable, Hashable, Codable {
    /// Drafted text awaiting compliance attorney review. Default for all
    /// disclosures at Session 2 landing time.
    case pendingReview
    /// Text reviewed and approved as-is. Safe to distribute.
    case reviewedApproved(attorney: String, date: Date)
    /// Text reviewed and flagged for revision. The `notes` field carries
    /// counsel's specific feedback; the text itself is still in the
    /// disclosure until a follow-up edit lands.
    case reviewedNeedsRevision(notes: String)
}
