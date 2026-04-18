// CFPBRegZAppendixJFixture.swift
//
// Reg Z Appendix J describes the "actuarial method" for APR computation.
// The CFPB publishes worked examples in the commentary; we use a
// representative one here and additionally validate the *property* that
// Appendix J enforces: APR is the rate at which PV of scheduled payments
// equals the amount financed, discounted per-period.
//
// Source: 12 CFR Part 1026, Appendix J to Part 1026 —
//         https://www.consumerfinance.gov/rules-policy/regulations/1026/j/
// Retrieved: 2026-04-17
//
// Tolerance: Reg Z §1026.22(a)(2) specifies an accuracy tolerance of
// ±⅛ of 1 percentage point (0.125%) for APR disclosures. Our fixture
// uses ±5 bps — comfortably inside the regulatory allowance and tight
// enough to catch algorithmic regressions.

import Foundation
import Testing
@testable import QuotientFinance

enum CFPBRegZAppendixJFixture {

    /// Worked example in the shape of Appendix J Part III:
    /// closed-end 30-year fixed mortgage, principal $250,000, note rate
    /// 6.5%, prepaid finance charges $5,000 (1% origination + $2,500 MI
    /// premium + small fee set). Amount financed: $245,000.
    static let loan = Loan(
        principal: 250_000,
        annualRate: 0.065,
        termMonths: 360,
        startDate: date(2026, 1, 1)
    )
    static let prepaidFinanceCharges: Decimal = 5_000

    /// Scheduled monthly P&I at the note rate (same formula Appendix J
    /// uses as its starting point): ~$1,580.17.
    static let expectedMonthlyPI: Decimal = 1_580.17

    /// Per Appendix J: the effective rate `i` that satisfies
    ///   AF = PMT × (1 − (1 + i/12)^−n) / (i/12)
    /// For these inputs, i ≈ 6.695% — ~20 bps above the note rate.
    /// Tolerance is 5 bps — far tighter than Reg Z §1026.22's ±12.5 bp
    /// disclosure tolerance, so algorithmic regressions trip this test
    /// long before they'd trigger a real compliance issue.
    static let expectedAPR: Double = 0.06695
    static let aprTolerance: Double = 0.0005
}

@Suite("Golden fixture — CFPB Reg Z Appendix J APR")
struct CFPBRegZAppendixJTests {

    @Test("Scheduled monthly P&I at note rate")
    func scheduledPI() {
        let schedule = amortize(loan: CFPBRegZAppendixJFixture.loan)
        #expect(schedule.scheduledPeriodicPayment.isApproximatelyEqual(
            to: CFPBRegZAppendixJFixture.expectedMonthlyPI, tolerance: 0.05)
        )
    }

    @Test("APR matches Appendix J actuarial computation")
    func apr() {
        let apr = calculateAPR(
            loan: CFPBRegZAppendixJFixture.loan,
            prepaidFinanceCharges: CFPBRegZAppendixJFixture.prepaidFinanceCharges
        )
        #expect(apr.isApproximatelyEqual(
            to: CFPBRegZAppendixJFixture.expectedAPR,
            tolerance: CFPBRegZAppendixJFixture.aprTolerance)
        )
    }

    /// The defining property of Appendix J: at the computed APR, the
    /// present value of all scheduled payments equals the amount financed.
    @Test("APR is self-consistent per Appendix J PV equation")
    func aprPVConsistency() {
        let apr = calculateAPR(
            loan: CFPBRegZAppendixJFixture.loan,
            prepaidFinanceCharges: CFPBRegZAppendixJFixture.prepaidFinanceCharges
        )
        let pmt = paymentFor(loan: CFPBRegZAppendixJFixture.loan).asDouble
        let amountFinanced = (CFPBRegZAppendixJFixture.loan.principal
                              - CFPBRegZAppendixJFixture.prepaidFinanceCharges).asDouble
        let i = apr / 12
        let pv = pmt * (1.0 - pow(1.0 + i, -360)) / i
        // PV should equal amount financed within a few cents
        #expect(abs(pv - amountFinanced) < 1.0)
    }
}
