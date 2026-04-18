// ComplianceRuleVersion.swift
// Rule-version tag stamped on every QM determination and persisted scenario.
//
// Lives in QuotientFinance (not QuotientCompliance) so the finance engine
// can reference it without creating a circular dependency — Session 2's
// QuotientCompliance depends on QuotientFinance, not the other way around.
//
// The raw value format is `YYYY.QN` (e.g. `"2026.Q2"`), which sorts
// lexicographically in chronological order: Q1..Q4 of any given year always
// precede Q1 of the next year.

import Foundation

/// Snapshot marker for the regulatory rule tables (APOR, points-and-fees
/// caps, state disclosure library version) that produced a given result.
/// Persisted with every saved scenario so old results can be reproduced
/// deterministically after quarterly regulatory updates.
public struct ComplianceRuleVersion: Hashable, Sendable, Codable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Rule version Quotient v1 ships against at GA (Session 5 target).
    public static let current = ComplianceRuleVersion(rawValue: "2026.Q2")
}
