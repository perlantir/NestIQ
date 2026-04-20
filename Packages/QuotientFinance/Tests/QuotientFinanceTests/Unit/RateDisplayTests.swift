// RateDisplayTests.swift
// Session 5M.1 — unit tests for the displayRateAndAPR helper.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("displayRateAndAPR")
struct RateDisplayTests {

    @Test("APR nil → rate only")
    func aprNilShowsRateOnly() {
        #expect(displayRateAndAPR(rate: 6.750, apr: nil) == "6.750%")
    }

    @Test("APR equal to rate → rate only")
    func aprEqualShowsRateOnly() {
        #expect(displayRateAndAPR(rate: 6.750, apr: 6.750) == "6.750%")
    }

    @Test("APR within display tolerance → rate only")
    func aprWithinToleranceShowsRateOnly() {
        // 0.0001% delta is below the 3-decimal display precision; the
        // two values would render identically, so no APR suffix.
        #expect(displayRateAndAPR(rate: 6.750, apr: 6.7501) == "6.750%")
    }

    @Test("APR meaningfully different → both with APR suffix")
    func aprDifferentShowsBoth() {
        #expect(displayRateAndAPR(rate: 6.750, apr: 6.812) ==
                "6.750% / 6.812% APR")
    }

    @Test("APR higher than rate at edge of tolerance still shows both")
    func aprAtEdgeShowsBoth() {
        // 0.001% delta — visibly different at 3-decimal precision.
        #expect(displayRateAndAPR(rate: 5.125, apr: 5.126) ==
                "5.125% / 5.126% APR")
    }

    @Test("APR lower than rate shows both (credits case)")
    func aprLowerShowsBoth() {
        // Rare but valid: lender credits at closing can push APR
        // below the note rate.
        #expect(displayRateAndAPR(rate: 7.000, apr: 6.875) ==
                "7.000% / 6.875% APR")
    }

    @Test("Decimal-typed APR dispatches to Double helper")
    func decimalAPROverload() {
        let apr: Decimal = 6.812
        #expect(displayRateAndAPR(rate: 6.750, decimalAPR: apr) ==
                "6.750% / 6.812% APR")
    }

    @Test("Nil Decimal APR short-circuits")
    func nilDecimalAPR() {
        let apr: Decimal? = nil
        #expect(displayRateAndAPR(rate: 6.750, decimalAPR: apr) == "6.750%")
    }
}
