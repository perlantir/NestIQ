// FHAMIPFixture.swift
//
// FHA MIP schedule — Mortgagee Letter 2023-05, effective 2023-03-20,
// unchanged through 2024 and 2025.
//
// Source: HUD Mortgagee Letter 2023-05 —
//         https://www.hud.gov/sites/dfiles/OCHCO/documents/2023-05hsngml.pdf
// Retrieved: 2026-04-17

import Foundation
import Testing
@testable import QuotientFinance

@Suite("Golden fixture — FHA MIP schedule")
struct FHAMIPFixture {

    @Test("UFMIP: 1.75% of base loan amount")
    func upfront() {
        let base: Decimal = 400_000
        let ufmip = Decimal(FHAMIPTable.ufmipRate) * base
        #expect(ufmip.isApproximatelyEqual(to: 7_000))
    }

    @Test("Long-term, LTV > 95%: 55 bps annual")
    func longTermHighLTV() {
        let rate = FHAMIPTable.annualRate(ltv: 0.965, termMonths: 360)
        #expect(rate == 0.0055)
    }

    @Test("Long-term, LTV 90–95%: 50 bps annual")
    func longTermMidLTV() {
        let rate = FHAMIPTable.annualRate(ltv: 0.93, termMonths: 360)
        #expect(rate == 0.0050)
    }

    @Test("Long-term, LTV ≤ 90%: 50 bps annual")
    func longTermLowLTV() {
        let rate = FHAMIPTable.annualRate(ltv: 0.85, termMonths: 360)
        #expect(rate == 0.0050)
    }

    @Test("Short-term (≤ 15yr), LTV > 90%: 40 bps annual")
    func shortTermHighLTV() {
        let rate = FHAMIPTable.annualRate(ltv: 0.95, termMonths: 180)
        #expect(rate == 0.0040)
    }

    @Test("Short-term, LTV ≤ 90%: 15 bps annual")
    func shortTermLowLTV() {
        let rate = FHAMIPTable.annualRate(ltv: 0.85, termMonths: 180)
        #expect(rate == 0.0015)
    }

    @Test("MIP is permanent for original LTV > 90%")
    func permanentForHighLTV() {
        #expect(FHAMIPTable.isPermanent(ltv: 0.95))
        #expect(FHAMIPTable.isPermanent(ltv: 0.965))
    }

    @Test("MIP cancellable after 11 years for original LTV ≤ 90%")
    func cancellableForLowLTV() {
        #expect(!FHAMIPTable.isPermanent(ltv: 0.89))
        #expect(FHAMIPTable.minimumPeriodsForLowLTV == 132)
    }

    @Test("Monthly MIP via calculatePMI: 96.5% LTV, 30yr, $300k")
    func monthlyMIP() {
        // 0.55% × 300,000 / 12 = $137.50
        let mip = calculatePMI(
            ltv: 0.965,
            creditScore: 680,
            loanAmount: 300_000,
            loanType: .fha,
            termMonths: 360
        )
        #expect(mip == 137.50)
    }
}
