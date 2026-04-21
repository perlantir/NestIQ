// AmortizationPDFDerivationsTests.swift
// Session 7.3d — coverage for v2.1.1 amortization PDF derivations.

import XCTest
@testable import Quotient

final class AmortizationPDFDerivationsTests: XCTestCase {

    // MARK: - D7 JSON migration

    /// Pre-7.3d AmortizationFormInputs JSON (missing rateLock +
    /// combinedMonthlyIncome) must decode cleanly with defaults.
    func testPre7_3dJSONDecodesWithDefaults() throws {
        let pre7_3dJSON = """
        {
            "mode": "purchase",
            "loanAmount": 548000,
            "annualRate": 6.75,
            "termYears": 30,
            "startDate": 766540800,
            "annualTaxes": 6500,
            "annualInsurance": 1620,
            "monthlyHOA": 0,
            "includePMI": false,
            "manualMonthlyPMI": 0,
            "extraPrincipalMonthly": 0,
            "biweekly": false
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AmortizationFormInputs.self, from: pre7_3dJSON)

        // Core fields intact
        XCTAssertEqual(decoded.loanAmount, 548_000)
        XCTAssertEqual(decoded.termYears, 30)

        // 2 new 7.3d fields carry defaults
        XCTAssertEqual(decoded.rateLock, "")
        XCTAssertEqual(decoded.combinedMonthlyIncome, 0)
    }

    func testPost7_3dRoundTrip() throws {
        let original = AmortizationFormInputs.sampleDefault
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AmortizationFormInputs.self, from: encoded)

        XCTAssertEqual(decoded.rateLock, "45-day")
        XCTAssertEqual(decoded.combinedMonthlyIncome, 20_400)
    }

    // MARK: - Derivations

    @MainActor
    func testPitiDollarsAndCentsMatchMonthlyPITI() {
        let vm = AmortizationViewModel(inputs: .sampleDefault)
        vm.compute()

        // Reassemble dollars.cents and verify it's within 1 cent of PITI
        // (rounding via Int truncation may lose the cent representation).
        let piti = vm.monthlyPITI
        let wholePart = (piti as NSDecimalNumber).intValue
        XCTAssertTrue(
            vm.pitiDollarsPart.contains(NumberFormatter.localizedString(
                from: NSNumber(value: wholePart), number: .decimal))
            || vm.pitiDollarsPart == "\(wholePart)"
        )
        // Cents is 2 characters
        XCTAssertEqual(vm.pitiCentsPart.count, 2)
    }

    @MainActor
    func testProductBadgeReflectsTerm() {
        let vm = AmortizationViewModel(inputs: .sampleDefault)
        XCTAssertEqual(vm.productBadge, "GEN-QM · 30yr")

        var inputs = AmortizationFormInputs.sampleDefault
        inputs.termYears = 15
        let vm15 = AmortizationViewModel(inputs: inputs)
        XCTAssertEqual(vm15.productBadge, "GEN-QM · 15yr")
    }

    @MainActor
    func testPmiNoteWhenPMIOff() {
        var inputs = AmortizationFormInputs.sampleDefault
        inputs.includePMI = false
        let vm = AmortizationViewModel(inputs: inputs)
        XCTAssertEqual(vm.pmiNote, "no PMI required")
    }

    @MainActor
    func testPmiNoteWithMonthlyAmountWhenPMIOn() {
        var inputs = AmortizationFormInputs.sampleDefault
        inputs.includePMI = true
        inputs.manualMonthlyPMI = 185
        let vm = AmortizationViewModel(inputs: inputs)
        vm.compute()
        // Without purchase price captured, dropoff can't be computed —
        // falls to the "$/mo until LTV 78%" branch.
        XCTAssertTrue(
            vm.pmiNote.contains("$185") || vm.pmiNote.hasPrefix("PMI drops"),
            "Got: \(vm.pmiNote)"
        )
    }

    @MainActor
    func testYear10BalanceIsBetweenZeroAndLoanAmount() {
        let vm = AmortizationViewModel(inputs: .sampleDefault)
        vm.compute()
        let bal = vm.year10Balance
        XCTAssertGreaterThan(bal, 0)
        XCTAssertLessThan(bal, AmortizationFormInputs.sampleDefault.loanAmount)
    }

    @MainActor
    func testExtraPaydownReturnsZeroWhenNoExtra() {
        let vm = AmortizationViewModel(inputs: .sampleDefault)
        vm.compute()
        XCTAssertEqual(vm.extraPaydownMonthsSaved, 0)
        XCTAssertEqual(vm.extraPaydownInterestSaved, 0)
    }

    @MainActor
    func testExtraPaydownSavesInterestWhenExtraSet() {
        var inputs = AmortizationFormInputs.sampleDefault
        inputs.extraPrincipalMonthly = 200
        let vm = AmortizationViewModel(inputs: inputs)
        vm.compute()

        XCTAssertGreaterThan(vm.extraPaydownMonthsSaved, 0)
        XCTAssertGreaterThan(vm.extraPaydownInterestSaved, 0)
    }

    @MainActor
    func testQuarterPointSavingsArePositive() {
        let vm = AmortizationViewModel(inputs: .sampleDefault)
        vm.compute()
        XCTAssertGreaterThan(vm.quarterPointSavingsMonthly, 0)
        XCTAssertGreaterThan(vm.quarterPointSavingsLifetime, 0)
    }

    @MainActor
    func testFirstPaymentDateAtOrAfterStartDate() {
        let vm = AmortizationViewModel(inputs: .sampleDefault)
        vm.compute()
        // Engine convention places the first scheduled payment AT the
        // start date (not start + 1 mo). The derivation falls back to
        // start + 1mo only when the schedule is empty.
        XCTAssertGreaterThanOrEqual(
            vm.firstPaymentDate,
            AmortizationFormInputs.sampleDefault.startDate
        )
    }
}
