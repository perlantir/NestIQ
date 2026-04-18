// ComplianceError.swift
//
// Errors raised by the QuotientCompliance public API.
//
// Design choice: a separate error type from `QuotientFinance.FinanceError`.
// Rationale — NMLS validation, disclosure-table lookup failures, and other
// compliance concerns are logically distinct from finance-engine math
// domain errors (solver convergence, invalid recast). Keeping two error
// types makes call sites read clearly: a refi comparison throws
// `FinanceError`; an NMLS lookup throws `ComplianceError`. The Session 3
// UI layer maps each to its own user-facing surface. Logged in
// DECISIONS.md.

import Foundation

public enum ComplianceError: Error, Sendable, Hashable, CustomStringConvertible {
    /// NMLS ID was empty, contained non-digit characters, or otherwise
    /// failed validation. The associated string carries a
    /// presentation-friendly reason.
    case invalidNMLS(String)

    public var description: String {
        switch self {
        case let .invalidNMLS(msg):
            return "Invalid NMLS ID: \(msg)"
        }
    }
}
