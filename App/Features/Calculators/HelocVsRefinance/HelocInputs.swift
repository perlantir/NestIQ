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
    /// Monthly MI on the cash-out refi option. HELOCs are second-lien
    /// and don't carry PMI, so there is no HELOC-side MI field.
    var refiMonthlyMI: Decimal
    /// Appraised value. LTV (1st lien only) and CLTV (1st + HELOC)
    /// render against this.
    var homeValue: Decimal
    var stressShockBps: Int             // e.g. 200 for +2pt
    /// Session 5M.1: optional APR on the existing first lien.
    /// Display-only (D1); `nil` collapses display to rate alone (D2).
    var firstLienAPR: Decimal?
    /// Session 5M.1: optional APR on the HELOC. One APR reflects the
    /// fully-indexed cost over time; not paired to intro vs indexed.
    var helocAPR: Decimal?
    /// Session 5M.1: optional APR on the cash-out refi alternative.
    var refiAPR: Decimal?

    enum CodingKeys: String, CodingKey {
        case firstLienBalance, firstLienRate, firstLienRemainingYears
        case helocAmount, helocIntroRate, helocIntroMonths, helocFullyIndexedRate
        case refiRate, refiTermYears, refiMonthlyMI, homeValue, stressShockBps
        case firstLienAPR, helocAPR, refiAPR
    }

    init(
        firstLienBalance: Decimal,
        firstLienRate: Double,
        firstLienRemainingYears: Int,
        helocAmount: Decimal,
        helocIntroRate: Double,
        helocIntroMonths: Int,
        helocFullyIndexedRate: Double,
        refiRate: Double,
        refiTermYears: Int,
        refiMonthlyMI: Decimal = 0,
        homeValue: Decimal = 0,
        stressShockBps: Int,
        firstLienAPR: Decimal? = nil,
        helocAPR: Decimal? = nil,
        refiAPR: Decimal? = nil
    ) {
        self.firstLienBalance = firstLienBalance
        self.firstLienRate = firstLienRate
        self.firstLienRemainingYears = firstLienRemainingYears
        self.helocAmount = helocAmount
        self.helocIntroRate = helocIntroRate
        self.helocIntroMonths = helocIntroMonths
        self.helocFullyIndexedRate = helocFullyIndexedRate
        self.refiRate = refiRate
        self.refiTermYears = refiTermYears
        self.refiMonthlyMI = refiMonthlyMI
        self.homeValue = homeValue
        self.stressShockBps = stressShockBps
        self.firstLienAPR = firstLienAPR
        self.helocAPR = helocAPR
        self.refiAPR = refiAPR
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.firstLienBalance = try c.decode(Decimal.self, forKey: .firstLienBalance)
        self.firstLienRate = try c.decode(Double.self, forKey: .firstLienRate)
        self.firstLienRemainingYears = try c.decode(Int.self, forKey: .firstLienRemainingYears)
        self.helocAmount = try c.decode(Decimal.self, forKey: .helocAmount)
        self.helocIntroRate = try c.decode(Double.self, forKey: .helocIntroRate)
        self.helocIntroMonths = try c.decode(Int.self, forKey: .helocIntroMonths)
        self.helocFullyIndexedRate = try c.decode(Double.self, forKey: .helocFullyIndexedRate)
        self.refiRate = try c.decode(Double.self, forKey: .refiRate)
        self.refiTermYears = try c.decode(Int.self, forKey: .refiTermYears)
        self.refiMonthlyMI = try c.decodeIfPresent(Decimal.self, forKey: .refiMonthlyMI) ?? 0
        self.homeValue = try c.decodeIfPresent(Decimal.self, forKey: .homeValue) ?? 0
        self.stressShockBps = try c.decode(Int.self, forKey: .stressShockBps)
        self.firstLienAPR = try c.decodeIfPresent(Decimal.self, forKey: .firstLienAPR)
        self.helocAPR = try c.decodeIfPresent(Decimal.self, forKey: .helocAPR)
        self.refiAPR = try c.decodeIfPresent(Decimal.self, forKey: .refiAPR)
    }

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
        refiMonthlyMI: 0,
        homeValue: 560_000,
        stressShockBps: 200
    )

    /// LTV of the first lien alone against homeValue. 0 when homeValue
    /// isn't set.
    var firstLienLTV: Double {
        guard homeValue > 0 else { return 0 }
        return Double(truncating: (firstLienBalance / homeValue) as NSNumber)
    }

    /// Combined LTV — (first lien + HELOC draw) / homeValue.
    var cltv: Double {
        guard homeValue > 0 else { return 0 }
        return Double(truncating: (totalCapital / homeValue) as NSNumber)
    }

    /// Cash-out refi LTV = (first lien + HELOC draw) / homeValue.
    /// Same numerator as CLTV since the refi rolls both into one loan.
    var refiLTV: Double { cltv }

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
