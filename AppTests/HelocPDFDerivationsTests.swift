// HelocPDFDerivationsTests.swift
// Session 7.3b — coverage for the v2.1.1 HELOC PDF backing derivations.
// Focus: JSON migration (old scenarios decode into new struct with
// defaults), stressPathMatrix shape, and the 10-year cumulative metrics.

import XCTest
@testable import Quotient

final class HelocPDFDerivationsTests: XCTestCase {

    // MARK: - D7 JSON migration

    /// Pre-7.3b HelocFormInputs JSON (missing all 11 new fields) must
    /// decode cleanly into the post-7.3b struct with sensible defaults.
    /// Guards against Saved Scenarios corruption after the v0.1.1 bump.
    func testPre7_3bJSONDecodesWithDefaults() throws {
        let pre7_3bJSON = """
        {
            "firstLienBalance": 318000,
            "firstLienRate": 3.125,
            "firstLienRemainingYears": 22,
            "helocAmount": 80000,
            "helocIntroRate": 6.99,
            "helocIntroMonths": 12,
            "helocFullyIndexedRate": 8.75,
            "refiRate": 6.125,
            "refiTermYears": 30,
            "refiMonthlyMI": 0,
            "homeValue": 560000,
            "stressShockBps": 200
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(HelocFormInputs.self, from: pre7_3bJSON)

        // Existing fields preserved verbatim
        XCTAssertEqual(decoded.firstLienBalance, 318_000)
        XCTAssertEqual(decoded.stressShockBps, 200)

        // 11 new fields carry their Codable-synthesized defaults
        XCTAssertEqual(decoded.helocClosingCosts, 500)
        XCTAssertEqual(decoded.helocLifetimeCapPct, 18.00)
        XCTAssertEqual(decoded.helocIndexType, .prime)
        XCTAssertEqual(decoded.helocMarginPct, 0.50)
        XCTAssertEqual(decoded.helocDrawPeriodYears, 10)
        XCTAssertEqual(decoded.helocRepaymentPeriodYears, 20)
        XCTAssertEqual(decoded.cashoutRefiClosingCosts, 11_000)
        XCTAssertEqual(decoded.cashoutRefiRate, 6.875)
        XCTAssertEqual(decoded.cashoutRefiTerm, 30)
        XCTAssertEqual(decoded.firstMortgageOriginalAmount, 0)
        // firstMortgageOriginationDate default is "two years ago"
        XCTAssertLessThan(decoded.firstMortgageOriginationDate, Date())
    }

    /// Round-trip: encode sampleDefault (all new fields populated) then
    /// decode — all values must match exactly.
    func testPost7_3bRoundTrip() throws {
        let original = HelocFormInputs.sampleDefault
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HelocFormInputs.self, from: encoded)

        XCTAssertEqual(decoded.helocClosingCosts, 450)
        XCTAssertEqual(decoded.helocLifetimeCapPct, 18.00)
        XCTAssertEqual(decoded.helocIndexType, .prime)
        XCTAssertEqual(decoded.helocMarginPct, 0.50)
        XCTAssertEqual(decoded.cashoutRefiClosingCosts, 11_200)
        XCTAssertEqual(decoded.cashoutRefiRate, 6.875)
        XCTAssertEqual(decoded.firstMortgageOriginalAmount, 340_000)
        XCTAssertEqual(
            Calendar.current.component(.year, from: decoded.firstMortgageOriginationDate),
            2024
        )
    }

    // MARK: - stressPathMatrix shape

    @MainActor
    func testStressMatrixHasFiveRowsWithCorrectLabels() {
        let vm = HelocViewModel(inputs: .sampleDefault)
        let matrix = vm.stressPathMatrix

        XCTAssertEqual(matrix.count, 5)
        XCTAssertEqual(matrix[0].scenarioLabel, "Today")
        XCTAssertEqual(matrix[1].scenarioLabel, "Flat")
        XCTAssertEqual(matrix[2].scenarioLabel, "+100 bps")
        XCTAssertEqual(matrix[3].scenarioLabel, "+200 bps")
        XCTAssertEqual(matrix[4].scenarioLabel, "+300 bps / at cap")
    }

    @MainActor
    func testStressMatrixTodayAndFlatHaveZeroDelta() {
        let vm = HelocViewModel(inputs: .sampleDefault)
        let matrix = vm.stressPathMatrix

        XCTAssertEqual(matrix[0].delta, 0)
        XCTAssertEqual(matrix[1].delta, 0)
    }

    @MainActor
    func testStressMatrixPlus200HasBlendedRatePopulated() {
        let vm = HelocViewModel(inputs: .sampleDefault)
        let matrix = vm.stressPathMatrix

        // Only the +200 bps row populates blendedRate for the template's
        // `stress_plus2_blended` token.
        XCTAssertNil(matrix[0].blendedRate)
        XCTAssertNil(matrix[1].blendedRate)
        XCTAssertNil(matrix[2].blendedRate)
        XCTAssertNotNil(matrix[3].blendedRate)
        XCTAssertNil(matrix[4].blendedRate)
    }

    @MainActor
    func testStressMatrixRatesEscalateMonotonically() {
        let vm = HelocViewModel(inputs: .sampleDefault)
        let matrix = vm.stressPathMatrix

        // Today == Flat (no rate change)
        XCTAssertEqual(matrix[0].rate, matrix[1].rate)
        // Then +100, +200, +300 all strictly greater than Today, until
        // the lifetime cap clamps.
        XCTAssertGreaterThan(matrix[2].rate, matrix[0].rate)
        XCTAssertGreaterThan(matrix[3].rate, matrix[2].rate)
        XCTAssertGreaterThanOrEqual(matrix[4].rate, matrix[3].rate)
    }

    @MainActor
    func testStressMatrixClampsAtLifetimeCap() {
        // 15% fully-indexed + 300 bps would be 18% — exactly at default cap.
        // Bumping the input rate above the cap verifies clamp behavior.
        var inputs = HelocFormInputs.sampleDefault
        inputs.helocFullyIndexedRate = 15.5  // +300 bps = 18.5 → cap at 18.0
        inputs.helocLifetimeCapPct = 18.00

        let vm = HelocViewModel(inputs: inputs)
        let matrix = vm.stressPathMatrix

        XCTAssertEqual(matrix[4].rate, 18.00, "+300 bps must clamp at lifetime cap")
    }

    // MARK: - 10-year cumulative metrics (smoke)

    @MainActor
    func testTenYearCumulativeInterestIsPositive() {
        let vm = HelocViewModel(inputs: .sampleDefault)
        XCTAssertGreaterThan(vm.tenYearCumulativeInterestHELOC, 0)
        XCTAssertGreaterThan(vm.tenYearCumulativeInterestRefi, 0)
    }

    @MainActor
    func testHELOCPathOftenOutpacesRefiOnPrincipalPaydown() {
        // With the sample default (first lien at 3.125% vs cash-out at
        // 6.875% / 30 yr), the low-rate first-lien amortization over
        // 10 years outpaces the higher-rate / longer-term cash-out refi
        // on principal paydown — even though HELOC itself is IO.
        // Matches the template's demo numbers (HELOC $112K vs refi $76K).
        let vm = HelocViewModel(inputs: .sampleDefault)
        XCTAssertGreaterThan(
            vm.tenYearPrincipalPaydownHELOC,
            vm.tenYearPrincipalPaydownRefi
        )
    }

    @MainActor
    func testBreakEvenMonthsIsFiniteOrNilWithNoNegatives() {
        let vm = HelocViewModel(inputs: .sampleDefault)
        if let months = vm.breakEvenMonthsHELOCvsRefi {
            XCTAssertGreaterThan(months, 0)
            XCTAssertLessThanOrEqual(months, 360)
        }
        // nil is acceptable — HELOC wins throughout the horizon.
    }
}
