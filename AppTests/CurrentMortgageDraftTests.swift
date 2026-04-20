// CurrentMortgageDraftTests.swift
// Session 5P.7 coverage for the Current Mortgage form's draft model —
// validation rules + round-trip into the CurrentMortgage value type.

import XCTest
@testable import Quotient

final class CurrentMortgageDraftTests: XCTestCase {

    func testBlankDraftIsNeitherValidNorSubmittable() {
        let draft = CurrentMortgageDraft()
        XCTAssertTrue(draft.isBlank)
        XCTAssertFalse(draft.isValid)
        XCTAssertNil(draft.toMortgage(),
                     "A blank draft must not produce a CurrentMortgage")
    }

    func testPartiallyFilledDraftIsInvalid() {
        var draft = CurrentMortgageDraft()
        draft.currentBalance = 400_000
        // Other fields still 0 → invalid.
        XCTAssertFalse(draft.isBlank)
        XCTAssertFalse(draft.isValid)
        XCTAssertNil(draft.toMortgage())
    }

    func testCurrentBalanceExceedingOriginalIsInvalid() {
        var draft = fullyPopulatedDraft()
        draft.originalLoanAmount = 400_000
        draft.currentBalance = 450_000 // you don't owe more than you borrowed originally
        XCTAssertFalse(draft.isValid)
        XCTAssertNil(draft.toMortgage())
    }

    func testFutureStartDateIsInvalid() {
        var draft = fullyPopulatedDraft()
        draft.loanStartDate = Date().addingTimeInterval(60 * 60 * 24 * 30) // +30 days
        XCTAssertFalse(draft.isValid)
    }

    func testFullyPopulatedDraftProducesMortgage() throws {
        let draft = fullyPopulatedDraft()
        XCTAssertTrue(draft.isValid)
        let mortgage = try XCTUnwrap(draft.toMortgage())
        XCTAssertEqual(mortgage.currentBalance, draft.currentBalance)
        XCTAssertEqual(mortgage.originalTermYears, draft.originalTermYears)
        XCTAssertEqual(mortgage.loanStartDate, draft.loanStartDate)
    }

    func testDraftRoundtripsThroughMortgageValue() {
        let original = fullyPopulatedDraft()
        guard let mortgage = original.toMortgage() else {
            return XCTFail("Fully populated draft must produce a mortgage")
        }
        let reloaded = CurrentMortgageDraft(from: mortgage)
        XCTAssertEqual(reloaded.currentBalance, original.currentBalance)
        XCTAssertEqual(reloaded.currentRatePercent, original.currentRatePercent)
        XCTAssertEqual(reloaded.currentMonthlyPaymentPI, original.currentMonthlyPaymentPI)
        XCTAssertEqual(reloaded.originalLoanAmount, original.originalLoanAmount)
        XCTAssertEqual(reloaded.originalTermYears, original.originalTermYears)
        XCTAssertEqual(reloaded.loanStartDate, original.loanStartDate)
        XCTAssertEqual(reloaded.propertyValueToday, original.propertyValueToday)
    }

    // MARK: - Helpers

    private func fullyPopulatedDraft() -> CurrentMortgageDraft {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(byAdding: .year, value: -3, to: Date()) ?? Date()
        return CurrentMortgageDraft(
            currentBalance: 430_000,
            currentRatePercent: 5.875,
            currentMonthlyPaymentPI: 2_662,
            originalLoanAmount: 450_000,
            originalTermYears: 30,
            loanStartDate: start,
            propertyValueToday: 585_000
        )
    }
}
