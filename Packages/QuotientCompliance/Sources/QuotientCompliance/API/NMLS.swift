// NMLS.swift
// Deep link to an individual LO's NMLS Consumer Access record.
//
// Production URL format per nmlsconsumeraccess.org (verified 2026-04-17):
//   https://www.nmlsconsumeraccess.org/EntityDetails.aspx/INDIVIDUAL/{id}
//
// Company-level lookups use a different path segment (`COMPANY` rather than
// `INDIVIDUAL`) and a different entity ID space; those are intentionally
// out of scope for this helper — Session 5 will add a parallel
// `nmlsConsumerAccessURL(forCompany:)` when Nick decides whether the app
// surfaces company records at all.

import Foundation

private let nmlsIndividualBase = "https://www.nmlsconsumeraccess.org/EntityDetails.aspx/INDIVIDUAL/"

/// Build the NMLS Consumer Access URL for an individual loan officer.
///
/// - Parameter nmlsId: String of digits (NMLS IDs are integer-valued but
///   padded/formatted by some sources; callers should strip separators
///   before passing). Validated: non-empty and all ASCII digits.
/// - Throws: `ComplianceError.invalidNMLS` with a descriptive message when
///   `nmlsId` is empty or contains any non-digit character.
/// - Returns: `URL` pointing at the individual's Consumer Access page.
public func nmlsConsumerAccessURL(for nmlsId: String) throws -> URL {
    let trimmed = nmlsId.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else {
        throw ComplianceError.invalidNMLS("NMLS ID is empty")
    }
    guard trimmed.allSatisfy(\.isASCII), trimmed.allSatisfy(\.isNumber) else {
        throw ComplianceError.invalidNMLS("NMLS ID must be numeric; got \"\(nmlsId)\"")
    }
    guard let url = URL(string: nmlsIndividualBase + trimmed) else {
        // Unreachable — base + digit string is always a valid URL. Throw
        // rather than force-unwrap so no production crash path exists.
        throw ComplianceError.invalidNMLS("Could not construct URL from \"\(nmlsId)\"")
    }
    return url
}
