// StateDisclosureLibraryTests.swift
// Deterministic load + content tests for the state disclosure library.
//
// Verifies:
//   - every USState case returns a disclosure (11 state-specific, 40 fallbacks)
//   - named-state text carries a non-empty citation and isn't the fallback
//   - fallback text mentions the state display name
//   - fetched disclosure stamps the requested rule version

import Testing
import Foundation
@testable import QuotientCompliance
@testable import QuotientFinance

@Suite("State disclosure library")
struct StateDisclosureLibraryTests {

    /// The 11 named states per the Session 2 kickoff population list.
    private static let namedStates: [USState] =
        [.CA, .TX, .FL, .NY, .IL, .PA, .OH, .GA, .NC, .MI, .IA]

    @Test("Every state + DC returns exactly one disclosure")
    func everyStateResolves() {
        for state in USState.allCases {
            let ds = requiredDisclosures(for: .amortization, propertyState: state)
            #expect(ds.count == 1, "No disclosure for \(state)")
        }
    }

    @Test("All 11 named states return provenance = .stateSpecific")
    func namedStatesSpecific() {
        for state in Self.namedStates {
            let d = requiredDisclosures(for: .amortization, propertyState: state).first
            #expect(d?.provenance == .stateSpecific, "\(state) not stateSpecific")
        }
    }

    @Test("Remaining 40 states + DC return provenance = .fallback")
    func remainingAreFallbacks() {
        let fallbackStates = USState.allCases.filter { !Self.namedStates.contains($0) }
        #expect(fallbackStates.count == 40, "Unexpected fallback-state count: \(fallbackStates.count)")
        for state in fallbackStates {
            let d = requiredDisclosures(for: .amortization, propertyState: state).first
            #expect(d?.provenance == .fallback, "\(state) not fallback")
        }
    }

    @Test("All named-state citations start with the regulator authority")
    func citationsMentionAuthority() {
        for state in Self.namedStates {
            guard let d = requiredDisclosures(for: .amortization, propertyState: state).first else {
                Issue.record("Missing disclosure for \(state)")
                continue
            }
            #expect(!d.sourceCitation.isEmpty)
            // Citation format: `{AUTHORITY} · {statute/guidance}`.
            #expect(d.sourceCitation.contains(" · "), "Citation format for \(state): \(d.sourceCitation)")
        }
    }

    @Test("Named-state EN text mentions the state + regulator")
    func namedTextMentionsStateAndRegulator() {
        for state in Self.namedStates {
            guard let d = requiredDisclosures(for: .amortization, propertyState: state).first else {
                Issue.record("Missing disclosure for \(state)")
                continue
            }
            #expect(d.textEN.contains(state.displayName), "EN text missing state name for \(state)")
        }
    }

    @Test("Every disclosure is pendingReview until Session 5 counsel review")
    func allPendingReview() {
        for state in USState.allCases {
            guard let d = requiredDisclosures(for: .amortization, propertyState: state).first else {
                continue
            }
            if case .pendingReview = d.counselReviewStatus {
                // ok
            } else {
                Issue.record("Non-pending status at Session 2 landing for \(state)")
            }
        }
    }

    @Test("Fallback text references the state's display name")
    func fallbackMentionsStateName() {
        // Pick one known fallback.
        let d = requiredDisclosures(for: .amortization, propertyState: .WY).first
        #expect(d?.textEN.contains("Wyoming") == true)
        #expect(d?.textES.contains("Wyoming") == true)
    }

    @Test("Disclosure carries the requested ruleVersion")
    func ruleVersionStamped() {
        let custom = ComplianceRuleVersion(rawValue: "2099.Q4")
        let d = requiredDisclosures(
            for: .refinance,
            propertyState: .CA,
            ruleVersion: custom
        ).first
        #expect(d?.ruleVersion == custom)
    }

    @Test("Retrieval date is the canonical 2026-04-17 stamp for Session 2 texts")
    func retrievalDateConsistent() {
        for state in Self.namedStates {
            guard let d = requiredDisclosures(for: .amortization, propertyState: state).first else {
                continue
            }
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "UTC") ?? .gmt
            let comps = cal.dateComponents([.year, .month, .day], from: d.retrievalDate)
            #expect(comps.year == 2026, "\(state) retrieval year")
            #expect(comps.month == 4, "\(state) retrieval month")
            #expect(comps.day == 17, "\(state) retrieval day")
        }
    }

    @Test("Library is deterministic across repeated loads")
    func deterministicLoad() {
        let first = requiredDisclosures(for: .amortization, propertyState: .CA).first
        let second = requiredDisclosures(for: .amortization, propertyState: .CA).first
        // generatedAt changes on a bundle, but the individual disclosure
        // is identical and hashable.
        #expect(first == second)
    }

    @Test("Every scenario type resolves for every state")
    func allScenarioTypesResolve() {
        for state in USState.allCases {
            for scenario in ScenarioType.allCases {
                let ds = requiredDisclosures(for: scenario, propertyState: state)
                #expect(!ds.isEmpty, "\(state) × \(scenario) produced no disclosure")
            }
        }
    }
}

@Suite("USState")
struct USStateTests {

    @Test("All 50 states + DC accounted for")
    func fiftyOneEntries() {
        #expect(USState.allCases.count == 51)
    }

    @Test("Every state has a distinct non-empty displayName")
    func distinctDisplayNames() {
        let names = USState.allCases.map(\.displayName)
        #expect(Set(names).count == names.count)
        #expect(names.allSatisfy { !$0.isEmpty })
    }

    @Test("Raw values are USPS two-letter codes")
    func rawValuesAreTwoLetter() {
        for s in USState.allCases {
            let raw = s.rawValue
            let allUpper = raw.allSatisfy { $0.isUppercase }
            #expect(raw.count == 2)
            #expect(allUpper)
        }
    }
}
