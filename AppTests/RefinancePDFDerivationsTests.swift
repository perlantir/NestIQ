// RefinancePDFDerivationsTests.swift
// Session 7.3c — coverage for v2.1.1 refi PDF backing derivations.

import XCTest
@testable import Quotient

final class RefinancePDFDerivationsTests: XCTestCase {

    // MARK: - D7 JSON migration

    /// Pre-7.3c RefinanceFormInputs JSON (missing the 3 new form-level
    /// fields + 3 new RefiOption fields) must decode cleanly into the
    /// post-7.3c struct with sensible defaults. Guards Saved Scenarios.
    func testPre7_3cJSONDecodesWithDefaults() throws {
        let pre7_3cJSON = """
        {
            "currentBalance": 412300,
            "currentRate": 7.375,
            "currentRemainingYears": 28,
            "currentMonthlyMI": 0,
            "homeValue": 575000,
            "monthlyTaxes": 542,
            "monthlyInsurance": 135,
            "monthlyHOA": 0,
            "options": [
                {
                    "id": "11111111-1111-1111-1111-111111111111",
                    "label": "A",
                    "rate": 6.125,
                    "termYears": 30,
                    "points": 0.5,
                    "closingCosts": 9800
                }
            ],
            "horizonsYears": [5, 7, 10, 15, 30],
            "stressTestHorizonYears": 5,
            "scenarioCount": 1
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(RefinanceFormInputs.self, from: pre7_3cJSON)

        // Existing fields intact
        XCTAssertEqual(decoded.currentBalance, 412_300)
        XCTAssertEqual(decoded.options.count, 1)
        XCTAssertEqual(decoded.options[0].label, "A")

        // 3 new form-level fields carry their defaults
        XCTAssertEqual(decoded.currentOriginalLoanAmount, 0)
        XCTAssertEqual(decoded.currentOriginalTermYears, 30)
        XCTAssertLessThan(decoded.currentLoanOriginatedDate, Date())

        // 3 new RefiOption fields carry their defaults
        XCTAssertEqual(decoded.options[0].lender, "")
        XCTAssertEqual(decoded.options[0].lenderFees, 0)
        XCTAssertEqual(decoded.options[0].thirdPartyFees, 0)
    }

    /// Round-trip post-7.3c: encode sampleDefault then decode — all
    /// new fields round-trip cleanly.
    func testPost7_3cRoundTrip() throws {
        let original = RefinanceFormInputs.sampleDefault
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RefinanceFormInputs.self, from: encoded)

        XCTAssertEqual(decoded.currentOriginalLoanAmount, 445_000)
        XCTAssertEqual(decoded.currentOriginalTermYears, 30)
        XCTAssertEqual(
            Calendar.current.component(.year, from: decoded.currentLoanOriginatedDate),
            2024
        )

        XCTAssertEqual(decoded.options[0].lender, "Lakeshore")
        XCTAssertEqual(decoded.options[0].lenderFees, 2_190)
        XCTAssertEqual(decoded.options[0].thirdPartyFees, 5_548)
        XCTAssertEqual(decoded.options[1].lender, "Coastal")
        XCTAssertEqual(decoded.options[2].thirdPartyFees, 6_090)
    }

    // MARK: - Derivations

    @MainActor
    func testCurrentMonthlyPIComputesAgainstCurrentLoan() {
        let vm = RefinanceViewModel(inputs: .sampleDefault)
        let pi = vm.currentMonthlyPI
        // Sample default: $412,300 @ 7.375% / 28 yr → roughly $2,900.
        // Checking it lands in a plausible range vs plugging numbers in.
        XCTAssertGreaterThan(pi, 2_500)
        XCTAssertLessThan(pi, 3_300)
    }

    @MainActor
    func testPaymentDeltaIsNegativeWhenOptionSaves() {
        // Sample options B + C have lower rates than current 7.375%.
        // Their P&I should be lower → paymentDelta negative.
        let vm = RefinanceViewModel(inputs: .sampleDefault)
        vm.compute()
        // Option index 2 = "C" at 5.875% with 30 yr — clearly cheaper.
        let delta = vm.paymentDelta(forOptionAt: 2)
        XCTAssertLessThan(delta, 0, "Option C should save monthly vs 7.375% current")
    }

    @MainActor
    func testPaymentDeltaPctIsProportional() {
        let vm = RefinanceViewModel(inputs: .sampleDefault)
        vm.compute()
        let delta = vm.paymentDelta(forOptionAt: 0)
        let pct = vm.paymentDeltaPct(forOptionAt: 0)
        // pct ≈ delta / current × 100 — check sign + magnitude rough match.
        XCTAssertEqual(pct.sign, delta.sign)
        XCTAssertGreaterThan(abs(pct), 0)
    }

    @MainActor
    func testInterestOverTermIsPositiveForRealOption() {
        let vm = RefinanceViewModel(inputs: .sampleDefault)
        let interest = vm.interestOverTerm(forOptionAt: 0)
        // 30-yr at 6.125% on ~$412K → ~$485K total interest.
        XCTAssertGreaterThan(interest, 300_000)
        XCTAssertLessThan(interest, 700_000)
    }

    @MainActor
    func testDiscountPointsMatchOneTimesPctOfLoan() {
        let vm = RefinanceViewModel(inputs: .sampleDefault)
        // Option A: 0.5 points on $412,300 → ~$2,062.
        let points = vm.discountPointsAmount(forOptionAt: 0)
        XCTAssertEqual(points, 2_061.5, "0.5% of $412,300")

        // Option B: 0 points → 0 (template renders em-dash "—").
        XCTAssertEqual(vm.discountPointsAmount(forOptionAt: 1), 0)
    }

    @MainActor
    func testRecommendedRemainingYearsTracksSelection() {
        let vm = RefinanceViewModel(inputs: .sampleDefault)
        // selectedOptionIndex is 1-based (0 = current, 1 = option A).
        // Default = 1 → option A (30-yr).
        XCTAssertEqual(vm.selectedOptionIndex, 1)
        XCTAssertEqual(vm.recommendedRemainingYears, 30)

        // Flip to option B (25-yr term).
        vm.selectedOptionIndex = 2
        XCTAssertEqual(vm.recommendedRemainingYears, 25)

        // Flip to option C (30-yr term).
        vm.selectedOptionIndex = 3
        XCTAssertEqual(vm.recommendedRemainingYears, 30)
    }

    @MainActor
    func testMetricsForInvalidIndexReturnsNil() {
        let vm = RefinanceViewModel(inputs: .sampleDefault)
        vm.compute()
        XCTAssertNil(vm.metrics(forOptionAt: -1))
        XCTAssertNil(vm.metrics(forOptionAt: 999))
    }
}
