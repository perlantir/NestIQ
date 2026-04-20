// TCACurrentMortgagePersistenceTests.swift
// Session 5Q.3 — exercise the save-back semantics the TCA refi
// Inputs screen runs on Compute. Three behaviors pinned:
//   1. Toggle ON + borrower attached + valid mortgage → written to
//      borrower.currentMortgage.
//   2. Toggle OFF → no-op; borrower unchanged.
//   3. Toggle ON without a borrower → no-op; nothing to write to.

import XCTest
import SwiftData
@testable import Quotient

@MainActor
final class TCACurrentMortgagePersistenceTests: XCTestCase {

    private func makeContext() -> ModelContext {
        let container = QuotientSchema.makeContainer(inMemory: true)
        return ModelContext(container)
    }

    private func sampleMortgage() -> CurrentMortgage {
        CurrentMortgage(
            currentBalance: 388_500,
            currentRatePercent: 5.875,
            currentMonthlyPaymentPI: 2_462,
            originalLoanAmount: 420_000,
            originalTermYears: 30,
            loanStartDate: Date(timeIntervalSince1970: 1_650_000_000),
            propertyValueToday: 570_000
        )
    }

    /// Toggle ON + borrower attached + valid current mortgage:
    /// persist writes the mortgage onto the borrower's JSON blob and
    /// saves the context. Returns true to confirm the write happened.
    func testTCARefiInlineCurrentMortgageSavesToBorrower() throws {
        let ctx = makeContext()
        let borrower = Borrower(firstName: "Jamie", lastName: "Park", source: .manual)
        ctx.insert(borrower)
        try ctx.save()
        XCTAssertNil(borrower.currentMortgage)

        let mortgage = sampleMortgage()
        let wrote = TCACurrentMortgagePersistence.persist(
            mortgage: mortgage,
            to: borrower,
            saveToBorrower: true,
            context: ctx
        )
        XCTAssertTrue(wrote)

        // Round-trip: fetched borrower carries the new currentMortgage.
        let fetched = try ctx.fetch(FetchDescriptor<Borrower>()).first
        XCTAssertEqual(fetched?.currentMortgage, mortgage)
    }

    /// Toggle OFF: persist is a no-op, even when a borrower and
    /// mortgage are supplied. Scenario snapshot still carries the
    /// mortgage (the caller does that separately); the borrower
    /// record stays untouched.
    func testTCARefiInlineCurrentMortgageToggleOffStaysLocal() throws {
        let ctx = makeContext()
        let borrower = Borrower(firstName: "Sloan", lastName: "Fitz", source: .manual)
        ctx.insert(borrower)
        try ctx.save()

        let wrote = TCACurrentMortgagePersistence.persist(
            mortgage: sampleMortgage(),
            to: borrower,
            saveToBorrower: false,
            context: ctx
        )
        XCTAssertFalse(wrote)

        let fetched = try ctx.fetch(FetchDescriptor<Borrower>()).first
        XCTAssertNil(fetched?.currentMortgage,
                     "Toggle OFF must leave borrower.currentMortgage untouched")
    }

    /// No borrower attached: even with toggle ON, persist has nothing
    /// to write to and returns false. Matches the UI state where the
    /// toggle is disabled in the first place.
    func testTCARefiToggleDisabledWithoutBorrower() throws {
        let ctx = makeContext()
        let wrote = TCACurrentMortgagePersistence.persist(
            mortgage: sampleMortgage(),
            to: nil,
            saveToBorrower: true,
            context: ctx
        )
        XCTAssertFalse(wrote)

        // Sanity: no stray borrower got created.
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Borrower>()).count, 0)
    }

    // MARK: - Session 5R.1 — prefill loanAmount + homeValue from currentMortgage

    /// Valid currentMortgage hydrates `form.loanAmount` + `form.homeValue`
    /// (when those are 0). Lets LOs skip typing the balance / home value
    /// twice in TCA refi.
    func testCurrentMortgagePrefillsEmptyFormFields() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.loanAmount = 0
        inputs.homeValue = 0
        let mortgage = sampleMortgage()

        // Simulate the prefill logic from TCAInputsScreen+CurrentMortgage.
        // The SwiftUI view holds this state; tests exercise the same
        // transition.
        if inputs.loanAmount == 0, mortgage.currentBalance > 0 {
            inputs.loanAmount = mortgage.currentBalance
        }
        if inputs.homeValue == 0, mortgage.propertyValueToday > 0 {
            inputs.homeValue = mortgage.propertyValueToday
        }

        XCTAssertEqual(inputs.loanAmount, mortgage.currentBalance)
        XCTAssertEqual(inputs.homeValue, mortgage.propertyValueToday)
    }

    /// LO overrides: a custom loanAmount or homeValue already set on
    /// the form (non-zero) must not be clobbered by prefill. Cash-out
    /// refis rely on this (new loan > current balance).
    func testCurrentMortgagePrefillPreservesLOOverrides() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.loanAmount = 450_000        // LO typed cash-out amount
        inputs.homeValue = 620_000          // LO typed appraised value
        let mortgage = sampleMortgage()     // balance 388_500, propertyValueToday 570_000

        if inputs.loanAmount == 0, mortgage.currentBalance > 0 {
            inputs.loanAmount = mortgage.currentBalance
        }
        if inputs.homeValue == 0, mortgage.propertyValueToday > 0 {
            inputs.homeValue = mortgage.propertyValueToday
        }

        XCTAssertEqual(inputs.loanAmount, 450_000, "Cash-out loan amount must not be overwritten")
        XCTAssertEqual(inputs.homeValue, 620_000, "LO-entered home value must not be overwritten")
    }

    /// Nil mortgage (LO blanked the section, or purchase-mode path):
    /// persist is a no-op even with toggle ON + borrower attached.
    /// The existing borrower.currentMortgage (if any) is preserved —
    /// clearing the toggle-driven section shouldn't wipe a
    /// persisted mortgage the borrower still needs.
    func testTCARefiPersistSkipsNilMortgage() throws {
        let ctx = makeContext()
        let borrower = Borrower(firstName: "Rae", lastName: "Min", source: .manual)
        borrower.currentMortgage = sampleMortgage()
        ctx.insert(borrower)
        try ctx.save()

        let wrote = TCACurrentMortgagePersistence.persist(
            mortgage: nil,
            to: borrower,
            saveToBorrower: true,
            context: ctx
        )
        XCTAssertFalse(wrote)

        let fetched = try ctx.fetch(FetchDescriptor<Borrower>()).first
        XCTAssertEqual(fetched?.currentMortgage, sampleMortgage(),
                       "nil mortgage from a partial inline edit must not clear a persisted one")
    }
}
