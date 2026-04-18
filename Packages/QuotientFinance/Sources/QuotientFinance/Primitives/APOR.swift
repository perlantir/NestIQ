// APOR.swift
// Average Prime Offer Rate lookup.
//
// Returns the APOR for a given loan type and lock date by finding the
// most recent FFIEC weekly entry on or before that date.

import Foundation

/// Look up the APOR for a given product and lock date.
///
/// - Parameters:
///   - loanType: Distinguishes product family. HELOCs have no APOR under
///     Reg Z; return `nil`. Jumbo uses the same APOR as conforming — the
///     HPML/HPCT threshold for jumbos is handled in `isHPML`, not here.
///   - rateType: `.fixed` uses the FFIEC fixed table (keyed on term);
///     ARM types use the variable table (keyed on initial fixed period).
///   - termYears: Loan term for fixed, or initial fixed period for ARMs,
///     in whole years (15, 20, 30 for fixed; 5, 7, 10 for ARMs).
///   - lockDate: The rate-lock date to look up. Rounded down to the most
///     recent weekly FFIEC publication.
/// - Returns: APOR as a decimal (0.0685 = 6.85%). `nil` when the product
///   is not covered or the lock date precedes the embedded table's start.
public func calculateAPOR(
    loanType: LoanType,
    rateType: RateType,
    termYears: Int,
    lockDate: Date
) -> Double? {
    switch loanType {
    case .heloc:
        return nil
    case .conventional, .fha, .va, .usda, .jumbo:
        break
    }

    guard let entry = lookupAPOREntry(on: lockDate) else { return nil }

    switch rateType {
    case .fixed:
        return nearestTerm(in: entry.fixed, requested: termYears)
    case .armSOFR, .armTreasury:
        return nearestTerm(in: entry.variable, requested: termYears)
    }
}

/// Binary-search the APOR table for the entry with the greatest
/// `weekStartDate` ≤ `date`.
func lookupAPOREntry(on date: Date) -> APOREntry? {
    let entries = APORTable.entries
    guard let first = entries.first, date >= first.weekStartDate else { return nil }

    var low = 0
    var high = entries.count - 1
    var best = 0
    while low <= high {
        let mid = (low + high) / 2
        if entries[mid].weekStartDate <= date {
            best = mid
            low = mid + 1
        } else {
            high = mid - 1
        }
    }
    return entries[best]
}

/// Find the APOR for the requested term — falling back to the closest
/// tabulated term if the exact one isn't present.
func nearestTerm(in table: [Int: Double], requested: Int) -> Double? {
    if let exact = table[requested] { return exact }
    guard !table.isEmpty else { return nil }
    let sorted = table.keys.sorted { abs($0 - requested) < abs($1 - requested) }
    guard let closest = sorted.first else { return nil }
    return table[closest]
}
