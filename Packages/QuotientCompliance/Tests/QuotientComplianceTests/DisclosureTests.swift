// DisclosureTests.swift
// Unit tests for Disclosure + DisclosureBundle value types.

import Testing
import Foundation
@testable import QuotientCompliance
@testable import QuotientFinance

@Suite("Disclosure")
struct DisclosureTests {

    private static func makeDisclosure(
        status: CounselReviewStatus = .pendingReview,
        provenance: DisclosureProvenance = .stateSpecific
    ) -> Disclosure {
        Disclosure(
            state: .CA,
            textEN: "en text",
            textES: "es text",
            sourceCitation: "Test cite",
            retrievalDate: Date(timeIntervalSince1970: 0),
            counselReviewStatus: status,
            provenance: provenance
        )
    }

    @Test("needsCounselReview true for pendingReview")
    func pendingNeedsReview() {
        let d = Self.makeDisclosure(status: .pendingReview)
        #expect(d.needsCounselReview)
    }

    @Test("needsCounselReview true for reviewedNeedsRevision")
    func revisionNeedsReview() {
        let d = Self.makeDisclosure(
            status: .reviewedNeedsRevision(notes: "update statute reference")
        )
        #expect(d.needsCounselReview)
    }

    @Test("needsCounselReview false only when state-specific + approved")
    func approvedStateSpecificPasses() {
        let d = Self.makeDisclosure(
            status: .reviewedApproved(attorney: "Chen & Co.", date: Date()),
            provenance: .stateSpecific
        )
        #expect(!d.needsCounselReview)
    }

    @Test("needsCounselReview true when approved BUT fallback — still needs state-specific drafting")
    func approvedFallbackStillNeedsReview() {
        let d = Self.makeDisclosure(
            status: .reviewedApproved(attorney: "Chen & Co.", date: Date()),
            provenance: .fallback
        )
        #expect(d.needsCounselReview)
    }

    @Test("text(for:) returns ES for Spanish locale, EN otherwise")
    func textPicksLocale() {
        let d = Self.makeDisclosure()
        #expect(d.text(for: Locale(identifier: "en_US")) == "en text")
        #expect(d.text(for: Locale(identifier: "es_MX")) == "es text")
        #expect(d.text(for: Locale(identifier: "es")) == "es text")
        // Non-EN non-ES falls back to EN.
        #expect(d.text(for: Locale(identifier: "fr_FR")) == "en text")
    }

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let original = Self.makeDisclosure(
            status: .reviewedApproved(attorney: "Smith LLP", date: Date(timeIntervalSince1970: 1_735_689_600))
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Disclosure.self, from: data)
        #expect(decoded == original)
    }
}

@Suite("DisclosureBundle")
struct DisclosureBundleTests {

    private static func bundle(mix: [(Bool, DisclosureProvenance)]) -> DisclosureBundle {
        let disclosures = mix.enumerated().map { idx, flag in
            Disclosure(
                state: USState.allCases[idx],
                textEN: "x",
                textES: "y",
                sourceCitation: "c",
                retrievalDate: Date(timeIntervalSince1970: 0),
                counselReviewStatus: flag.0 ? .pendingReview : .reviewedApproved(attorney: "A", date: Date()),
                provenance: flag.1
            )
        }
        return DisclosureBundle(disclosures: disclosures)
    }

    @Test("hasAnyPendingReview true when any disclosure needs counsel review")
    func hasAnyPending() {
        let b = Self.bundle(mix: [(true, .stateSpecific), (false, .stateSpecific)])
        #expect(b.hasAnyPendingReview)
    }

    @Test("hasAnyPendingReview false when all approved and state-specific")
    func allApproved() {
        let b = Self.bundle(mix: [(false, .stateSpecific), (false, .stateSpecific)])
        #expect(!b.hasAnyPendingReview)
    }

    @Test("pendingReviewStates lists every state needing review")
    func pendingStatesListed() {
        let b = Self.bundle(mix: [
            (true, .stateSpecific),
            (false, .fallback),
            (false, .stateSpecific)
        ])
        // Indices 0 (pending) and 1 (approved but fallback) both need review.
        let states = b.pendingReviewStates
        #expect(states.count == 2)
        #expect(states.contains(USState.allCases[0]))
        #expect(states.contains(USState.allCases[1]))
    }

    @Test("auditSummary includes count + pending + rule version")
    func auditSummaryFormat() {
        let b = Self.bundle(mix: [(true, .stateSpecific), (false, .stateSpecific)])
        let s = b.auditSummary
        #expect(s.contains("2 disclosures"))
        #expect(s.contains("pending review"))
        #expect(s.contains("rule 2026.Q2"))
    }

    @Test("auditSummary marks 'all reviewed' when nothing pending")
    func auditSummaryAllReviewed() {
        let b = Self.bundle(mix: [(false, .stateSpecific)])
        #expect(b.auditSummary.contains("all reviewed"))
    }
}
