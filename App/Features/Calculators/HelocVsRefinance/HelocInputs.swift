// HelocInputs.swift
// Compare keeping the 1st + adding a HELOC vs a cash-out refi.

import Foundation
import QuotientFinance

struct HelocFormInputs: Codable, Hashable, Sendable {
    var firstLienBalance: Decimal
    var firstLienRate: Double           // % — untouched
    var firstLienRemainingYears: Int
    var helocAmount: Decimal
    var helocIntroRate: Double          // %
    var helocIntroMonths: Int
    var helocFullyIndexedRate: Double   // %
    var refiRate: Double                // % — alternative cash-out refi
    var refiTermYears: Int
    var stressShockBps: Int             // e.g. 200 for +2pt

    static let sampleDefault = HelocFormInputs(
        firstLienBalance: 318_000,
        firstLienRate: 3.125,
        firstLienRemainingYears: 22,
        helocAmount: 80_000,
        helocIntroRate: 6.990,
        helocIntroMonths: 12,
        helocFullyIndexedRate: 8.750,
        refiRate: 6.125,
        refiTermYears: 30,
        stressShockBps: 200
    )

    var blendedRate: Double {
        let tranches = [
            RateTranche(balance: firstLienBalance, annualRate: firstLienRate / 100),
            RateTranche(balance: helocAmount, annualRate: helocFullyIndexedRate / 100),
        ]
        return QuotientFinance.blendedRate(tranches: tranches) * 100
    }

    var totalCapital: Decimal { firstLienBalance + helocAmount }

    var firstLienWeight: Double {
        let total = totalCapital
        guard total > 0 else { return 0 }
        return Double(truncating: (firstLienBalance / total) as NSNumber)
    }

    var helocWeight: Double { 1 - firstLienWeight }
}
