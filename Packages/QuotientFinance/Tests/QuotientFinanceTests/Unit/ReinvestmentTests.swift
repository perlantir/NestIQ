// ReinvestmentTests.swift
// Session 5M.8 — annuity future-value primitive.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("Reinvestment — FV of monthly deposits")
struct ReinvestmentTests {

    @Test("Zero deposit → 0")
    func zeroDeposit() {
        #expect(futureValueOfMonthlyDeposits(deposit: 0, annualRate: 0.07, months: 120) == 0)
    }

    @Test("Zero months → 0")
    func zeroMonths() {
        #expect(futureValueOfMonthlyDeposits(deposit: 100, annualRate: 0.07, months: 0) == 0)
    }

    @Test("Zero rate → deposit × months (no compounding)")
    func zeroRate() {
        let fv = futureValueOfMonthlyDeposits(deposit: 100, annualRate: 0.0, months: 120)
        #expect(fv == Decimal(12_000))
    }

    /// Textbook check: $100/mo at 7% annualized for 10 years → ~$17,308.
    /// Formula: 100 × ((1.005833)^120 − 1) / 0.005833 ≈ 17308.48.
    @Test("Known annuity FV — 100/mo at 7% for 10yr ≈ 17,308")
    func knownAnnuity() {
        let fv = futureValueOfMonthlyDeposits(deposit: 100, annualRate: 0.07, months: 120)
        let fvDouble = fv.asDouble
        #expect(fvDouble > 17_300)
        #expect(fvDouble < 17_320)
    }

    /// Higher rate > lower rate at same deposit/term.
    @Test("FV is monotonic in rate")
    func monotonicInRate() {
        let atFive = futureValueOfMonthlyDeposits(deposit: 100, annualRate: 0.05, months: 120)
        let atSeven = futureValueOfMonthlyDeposits(deposit: 100, annualRate: 0.07, months: 120)
        #expect(atSeven > atFive)
    }

    /// Longer horizon > shorter at same deposit/rate.
    @Test("FV is monotonic in months")
    func monotonicInMonths() {
        let fiveYr = futureValueOfMonthlyDeposits(deposit: 100, annualRate: 0.07, months: 60)
        let tenYr = futureValueOfMonthlyDeposits(deposit: 100, annualRate: 0.07, months: 120)
        #expect(tenYr > fiveYr)
    }
}
