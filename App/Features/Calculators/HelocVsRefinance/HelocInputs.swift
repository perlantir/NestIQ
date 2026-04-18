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
    var propertyDP: PropertyDownPaymentConfig

    enum CodingKeys: String, CodingKey {
        case firstLienBalance, firstLienRate, firstLienRemainingYears
        case helocAmount, helocIntroRate, helocIntroMonths, helocFullyIndexedRate
        case refiRate, refiTermYears, stressShockBps, propertyDP
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
        stressShockBps: Int,
        propertyDP: PropertyDownPaymentConfig = .empty
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
        self.stressShockBps = stressShockBps
        self.propertyDP = propertyDP
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
        self.stressShockBps = try c.decode(Int.self, forKey: .stressShockBps)
        self.propertyDP = try c.decodeIfPresent(
            PropertyDownPaymentConfig.self, forKey: .propertyDP
        ) ?? .empty
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
