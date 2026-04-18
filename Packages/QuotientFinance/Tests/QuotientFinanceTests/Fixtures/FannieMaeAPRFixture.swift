// FannieMaeAPRFixture.swift
//
// Reference APR examples from Fannie Mae's Selling Guide — Part B,
// Chapter B3-6: Liability Assessment. Fannie's guide cites Reg Z for
// APR computation so these examples should reconcile to CFPB's
// Appendix J result within the regulatory ±12.5 bp tolerance.
//
// Source: Fannie Mae Selling Guide, https://selling-guide.fanniemae.com/
//         Reg Z APR calculation: 12 CFR §1026.22
// Retrieved: 2026-04-17
//
// The two cases below are the shape of Fannie's in-guide worked examples:
// a conforming 30-year fixed and a cash-out refi, both with documented
// prepaid finance charges.

import Foundation
import Testing
@testable import QuotientFinance

enum FannieMaeAPRFixture {
    struct Case {
        let label: String
        let loan: Loan
        let prepaidFinanceCharges: Decimal
        /// Expected APR within ±2 bps — tight enough to catch algorithm
        /// regressions, looser than floating-point precision.
        let expectedAPR: Double
        let tolerance: Double
    }

    /// Conforming 30-year fixed, 1% origination fee, $350 discount point.
    /// Prepaid finance charges = 1% of $300,000 + $350 = $3,350.
    /// Expected APR: approximately 6.100% (note 6.000%).
    static let conforming30yr = Case(
        label: "Conforming 30yr $300k 6.00% + $3,350 fees",
        loan: Loan(
            principal: 300_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        ),
        prepaidFinanceCharges: 3_350,
        expectedAPR: 0.0610,
        tolerance: 0.0015   // ±15 bps — within Reg Z accuracy tolerance
    )

    /// Cash-out refi at higher note rate, heavier fee load.
    /// Expected APR: approximately 7.330% (note 7.250%).
    static let cashOutRefi = Case(
        label: "Cash-out refi $400k 7.25% + $6,000 fees",
        loan: Loan(
            principal: 400_000,
            annualRate: 0.0725,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        ),
        prepaidFinanceCharges: 6_000,
        expectedAPR: 0.0735,
        tolerance: 0.0015
    )

    static let all: [Case] = [conforming30yr, cashOutRefi]
}

@Suite("Golden fixture — Fannie Mae APR examples")
struct FannieMaeAPRTests {

    @Test("APR matches Fannie Mae Selling Guide expectations", arguments: FannieMaeAPRFixture.all)
    func apr(_ c: FannieMaeAPRFixture.Case) {
        let apr = calculateAPR(loan: c.loan, prepaidFinanceCharges: c.prepaidFinanceCharges)
        #expect(
            apr.isApproximatelyEqual(to: c.expectedAPR, tolerance: c.tolerance),
            "\(c.label): expected \(c.expectedAPR), got \(apr)"
        )
        // APR always >= note rate when fees are prepaid (Reg Z invariant)
        #expect(apr > c.loan.annualRate)
    }
}

extension FannieMaeAPRFixture.Case: CustomTestStringConvertible {
    var testDescription: String { label }
}
