// MoneyTests.swift
// Payment, PV, FV, compound growth — the TVM primitives.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("Time value of money")
struct MoneyTests {

    @Test("paymentFor: $200k @ 6% 30-yr monthly = $1,199.10")
    func paymentFor30yrFixed() {
        let pmt = paymentFor(principal: 200_000, periodRate: 0.005, periods: 360)
        #expect(pmt.isApproximatelyEqual(to: 1199.10))
    }

    @Test("paymentFor: zero rate splits principal evenly")
    func paymentForZeroRate() {
        let pmt = paymentFor(principal: 120_000, periodRate: 0, periods: 120)
        #expect(pmt == 1000)
    }

    @Test("paymentFor: zero principal returns zero")
    func paymentForZeroPrincipal() {
        let pmt = paymentFor(principal: 0, periodRate: 0.005, periods: 360)
        #expect(pmt == 0)
    }

    @Test("paymentFor(loan:) uses loan frequency and day-count")
    func paymentForLoan() {
        let loan = Loan(
            principal: 200_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        #expect(paymentFor(loan: loan).isApproximatelyEqual(to: 1199.10))
    }

    @Test("presentValue of lump sum: $1,000 in 10 years at 5% monthly")
    func presentValueLumpSum() {
        // 1000 / (1 + 0.05/12)^120 = 1000 / 1.6470... = 607.16
        let pv = presentValue(futureValue: 1000, periodRate: 0.05 / 12, periods: 120)
        #expect(pv.isApproximatelyEqual(to: 607.16, tolerance: 0.05))
    }

    @Test("presentValue of annuity: $1,000/mo for 30 years at 6% = $166,791.61")
    func presentValueAnnuity() {
        let pv = presentValue(payment: 1000, periodRate: 0.005, periods: 360)
        #expect(pv.isApproximatelyEqual(to: 166_791.61, tolerance: 1.0))
    }

    @Test("futureValue of lump sum grows correctly")
    func futureValueLumpSum() {
        // 10,000 @ 6% compounded monthly for 30 years = 60,225.75
        let fv = futureValue(presentValue: 10_000, periodRate: 0.005, periods: 360)
        #expect(fv.isApproximatelyEqual(to: 60_225.75, tolerance: 1.0))
    }

    @Test("futureValue of annuity: $500/mo 30 years at 6%")
    func futureValueAnnuity() {
        // FV = 500 × ((1.005^360 − 1) / 0.005) = 502,257.52
        let fv = futureValue(payment: 500, periodRate: 0.005, periods: 360)
        #expect(fv.isApproximatelyEqual(to: 502_257.52, tolerance: 1.0))
    }

    @Test("compoundGrowth matches continuous formula at annual compounding")
    func compoundGrowthAnnual() {
        let fv = compoundGrowth(
            presentValue: 10_000,
            annualRate: 0.07,
            years: 10,
            compoundingsPerYear: 1
        )
        // 10000 × 1.07^10 = 19,671.51
        #expect(fv.isApproximatelyEqual(to: 19_671.51, tolerance: 1.0))
    }

    @Test("compoundGrowth: zero years returns principal")
    func compoundGrowthZeroYears() {
        let fv = compoundGrowth(
            presentValue: 50_000,
            annualRate: 0.05,
            years: 0,
            compoundingsPerYear: 12
        )
        #expect(fv == 50_000)
    }

    @Test("periodRate: 30/360 matches annual/paymentsPerYear")
    func periodRateThirty360() {
        let r = periodRate(annualRate: 0.06, frequency: .monthly, dayCount: .thirty360)
        #expect(r.isApproximatelyEqual(to: 0.005, tolerance: 1e-12))
    }

    @Test("periodRate: actual/365 accounts for frequency days")
    func periodRateActual365() {
        let r = periodRate(annualRate: 0.0365, frequency: .monthly, dayCount: .actual365)
        // 0.0365/365 × (365/12) = 0.003041666...
        #expect(r.isApproximatelyEqual(to: 0.0365 / 12, tolerance: 1e-9))
    }
}

@Suite("Rate conversions")
struct RateTests {

    @Test("nominalToEffective: 6% nominal monthly ≈ 6.167% EAR")
    func nominalToEffectiveMonthly() {
        let ear = nominalToEffective(nominalRate: 0.06, compoundingsPerYear: 12)
        #expect(ear.isApproximatelyEqual(to: 0.06167781, tolerance: 1e-6))
    }

    @Test("effectiveToNominal: inverse of nominalToEffective")
    func effectiveNominalRoundTrip() {
        let nominal = 0.075
        let ear = nominalToEffective(nominalRate: nominal, compoundingsPerYear: 12)
        let backToNominal = effectiveToNominal(effectiveRate: ear, compoundingsPerYear: 12)
        #expect(backToNominal.isApproximatelyEqual(to: nominal, tolerance: 1e-10))
    }

    @Test("effectiveRate: zero rate yields zero EAR")
    func effectiveRateZero() {
        #expect(effectiveRate(nominalRate: 0, compoundingsPerYear: 12) == 0)
    }

    @Test("blendedRate: principal-weighted average")
    func blendedRateWeighted() {
        // $300k @ 6% first, $100k HELOC @ 8% → blended = (300*0.06 + 100*0.08)/400 = 6.5%
        let r = blendedRate(tranches: [
            .init(balance: 300_000, annualRate: 0.06),
            .init(balance: 100_000, annualRate: 0.08)
        ])
        #expect(r.isApproximatelyEqual(to: 0.065, tolerance: 1e-10))
    }

    @Test("blendedRate: single tranche returns its own rate")
    func blendedRateSingle() {
        let r = blendedRate(tranches: [.init(balance: 100_000, annualRate: 0.055)])
        #expect(r.isApproximatelyEqual(to: 0.055, tolerance: 1e-10))
    }
}
