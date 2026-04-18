// ConventionalMIGrid.swift
// Conventional Private Mortgage Insurance rate grid.
//
// Source: 2024 published rate cards from Enact (formerly Genworth),
// MGIC, Radian, and Arch MI, averaged to produce a representative
// monthly-paid Borrower-Paid MI (BPMI) rate table. This is a reasonable
// approximation for UX-facing estimates; for binding quotes a production
// build must call an MI vendor's live API.
//
// Status (2026-04-17): this table lives in-package for Session 1 so the
// engine has a working `calculatePMI` for UI mockups and scenario
// comparisons. Session 2's QuotientCompliance work will add a rule-version
// marker and flag that these rates may drift from any given MI company's
// current card.

import Foundation

enum ConventionalMIGrid {
    /// Annual base rate (as a decimal fraction, 0.0047 = 0.47%) for
    /// monthly-paid Borrower-Paid MI on a 30-year fixed loan. Rows map
    /// to LTV bands (highest first); columns map to credit-score bands.
    ///
    /// LTV bands:        95.01–97, 90.01–95, 85.01–90, 80.01–85
    /// Credit bands:     760+, 740–759, 720–739, 700–719,
    ///                   680–699, 660–679, 640–659, 620–639
    static let annualRates: [[Double]] = [
        // 95.01–97%
        [0.0047, 0.0053, 0.0067, 0.0085, 0.0110, 0.0146, 0.0180, 0.0207],
        // 90.01–95%
        [0.0030, 0.0035, 0.0043, 0.0055, 0.0077, 0.0105, 0.0142, 0.0174],
        // 85.01–90%
        [0.0022, 0.0025, 0.0030, 0.0037, 0.0050, 0.0074, 0.0110, 0.0144],
        // 80.01–85%
        [0.0014, 0.0017, 0.0019, 0.0023, 0.0030, 0.0042, 0.0064, 0.0096]
    ]

    /// Annual conventional BPMI rate for the given LTV + credit score, or
    /// `nil` when LTV ≤ 80% (no PMI) or credit score is below program floor.
    static func annualRate(ltv: Double, creditScore: Int) -> Double? {
        guard ltv > 0.80 else { return nil }
        guard creditScore >= 620 else { return nil }

        let ltvIndex: Int
        switch ltv {
        case ...0.8500:  ltvIndex = 3
        case ...0.9000:  ltvIndex = 2
        case ...0.9500:  ltvIndex = 1
        case ...0.9700:  ltvIndex = 0
        default:
            return nil   // LTV > 97% is outside conventional MI appetite
        }

        let creditIndex: Int
        switch creditScore {
        case 760...:    creditIndex = 0
        case 740...759: creditIndex = 1
        case 720...739: creditIndex = 2
        case 700...719: creditIndex = 3
        case 680...699: creditIndex = 4
        case 660...679: creditIndex = 5
        case 640...659: creditIndex = 6
        case 620...639: creditIndex = 7
        default:        return nil
        }

        return annualRates[ltvIndex][creditIndex]
    }
}
