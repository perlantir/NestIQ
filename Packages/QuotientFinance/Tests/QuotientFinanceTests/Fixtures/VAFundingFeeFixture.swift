// VAFundingFeeFixture.swift
//
// VA Funding Fee table, current rates effective 2023-04-07.
//
// Source: Department of Veterans Affairs
//         https://www.va.gov/housing-assistance/home-loans/funding-fee-and-closing-costs/
// Retrieved: 2026-04-17

import Foundation
import Testing
@testable import QuotientFinance

@Suite("Golden fixture — VA Funding Fee table")
struct VAFundingFeeFixture {

    @Test("First-use purchase, 0% down: 2.15%")
    func firstUseNoDown() {
        let fee = vaFundingFee(VAFundingFeeInputs(
            loanAmount: 400_000,
            transactionType: .purchase,
            usage: .firstUse,
            downPaymentFraction: 0
        ))
        #expect(fee == 8_600)  // 400,000 × 0.0215
    }

    @Test("First-use purchase, 5% down: 1.50%")
    func firstUseFivePercent() {
        let fee = vaFundingFee(VAFundingFeeInputs(
            loanAmount: 400_000,
            transactionType: .purchase,
            usage: .firstUse,
            downPaymentFraction: 0.05
        ))
        #expect(fee == 6_000)
    }

    @Test("First-use purchase, 10%+ down: 1.25%")
    func firstUseTenPercent() {
        let fee = vaFundingFee(VAFundingFeeInputs(
            loanAmount: 400_000,
            transactionType: .purchase,
            usage: .firstUse,
            downPaymentFraction: 0.10
        ))
        #expect(fee == 5_000)
    }

    @Test("Subsequent use purchase, 0% down: 3.30%")
    func subsequentUseNoDown() {
        let fee = vaFundingFee(VAFundingFeeInputs(
            loanAmount: 400_000,
            transactionType: .purchase,
            usage: .subsequentUse,
            downPaymentFraction: 0
        ))
        #expect(fee == 13_200)
    }

    @Test("IRRRL: 0.50% regardless of usage")
    func irrrl() {
        let fee = vaFundingFee(VAFundingFeeInputs(
            loanAmount: 400_000,
            transactionType: .irrrl,
            usage: .firstUse
        ))
        #expect(fee == 2_000)
    }

    @Test("Cash-out first use: 2.15%; subsequent: 3.30%")
    func cashOut() {
        let firstUse = vaFundingFee(VAFundingFeeInputs(
            loanAmount: 400_000,
            transactionType: .cashOutRefinance,
            usage: .firstUse
        ))
        #expect(firstUse == 8_600)

        let subsequent = vaFundingFee(VAFundingFeeInputs(
            loanAmount: 400_000,
            transactionType: .cashOutRefinance,
            usage: .subsequentUse
        ))
        #expect(subsequent == 13_200)
    }

    @Test("Exempt borrower pays zero fee")
    func exemptZero() {
        let fee = vaFundingFee(VAFundingFeeInputs(
            loanAmount: 400_000,
            transactionType: .purchase,
            usage: .firstUse,
            isExempt: true
        ))
        #expect(fee == 0)
    }
}
