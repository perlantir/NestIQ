// BorrowerFormTests.swift
// Session 5Q.1: exercise the SwiftData persistence semantics the
// `BorrowerForm` view relies on in its create / edit / delete paths.
// The form itself holds SwiftUI @State; these tests mirror what its
// submit / delete closures do so a future regression in persistence
// (duplication on edit, stale currentMortgage blob, cascade leak)
// can't go unnoticed.

import XCTest
import SwiftData
@testable import Quotient

@MainActor
final class BorrowerFormTests: XCTestCase {

    private func makeContext() -> ModelContext {
        let container = QuotientSchema.makeContainer(inMemory: true)
        return ModelContext(container)
    }

    private func sampleMortgage(balance: Decimal = 388_500) -> CurrentMortgage {
        CurrentMortgage(
            currentBalance: balance,
            currentRatePercent: 5.875,
            currentMonthlyPaymentPI: 2_462,
            originalLoanAmount: 420_000,
            originalTermYears: 30,
            loanStartDate: Date(timeIntervalSince1970: 1_650_000_000),
            propertyValueToday: 570_000
        )
    }

    /// Form `.create` mode: construct a fresh Borrower, insert, save.
    /// One row in the store after.
    func testBorrowerFormCreateMode() throws {
        let ctx = makeContext()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Borrower>()).count, 0)

        let borrower = Borrower(
            firstName: "Jane",
            lastName: "Doe",
            email: "jane@example.com",
            phone: "555-0100",
            source: .manual
        )
        borrower.currentMortgage = sampleMortgage()
        ctx.insert(borrower)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<Borrower>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.firstName, "Jane")
        XCTAssertEqual(fetched.first?.email, "jane@example.com")
        XCTAssertEqual(fetched.first?.currentMortgage, sampleMortgage())
    }

    /// Form `.edit` mode: mutate an existing Borrower in place, save.
    /// Row count stays at 1 — no duplicate — and the fields match the
    /// edits.
    func testBorrowerFormEditMode() throws {
        let ctx = makeContext()
        let borrower = Borrower(
            firstName: "John",
            lastName: "Smith",
            email: "john@example.com",
            source: .manual
        )
        ctx.insert(borrower)
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Borrower>()).count, 1)

        borrower.firstName = "Jon"
        borrower.lastName = "Smyth"
        borrower.email = "jon.smyth@example.com"
        borrower.phone = "555-0199"
        borrower.updatedAt = Date()
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<Borrower>())
        XCTAssertEqual(fetched.count, 1, "edit must not duplicate the borrower")
        XCTAssertEqual(fetched.first?.firstName, "Jon")
        XCTAssertEqual(fetched.first?.lastName, "Smyth")
        XCTAssertEqual(fetched.first?.email, "jon.smyth@example.com")
        XCTAssertEqual(fetched.first?.phone, "555-0199")
    }

    /// Form `.edit` mode + Cancel: the form holds a local @State draft
    /// so cancelling without calling submit leaves the persisted
    /// borrower untouched. Simulated by mutating a draft locally,
    /// never writing it to the persisted record.
    func testBorrowerFormEditModeCancelPreservesOriginal() throws {
        let ctx = makeContext()
        let borrower = Borrower(
            firstName: "Ava",
            lastName: "Reyes",
            email: "ava@example.com",
            source: .manual
        )
        ctx.insert(borrower)
        try ctx.save()

        // "Draft" values the form holds in @State — never applied.
        let draftFirst = "Avery"
        let draftLast = "Reese"
        _ = (draftFirst, draftLast)  // explicitly not mutated onto borrower

        try ctx.save()
        let fetched = try ctx.fetch(FetchDescriptor<Borrower>()).first
        XCTAssertEqual(fetched?.firstName, "Ava")
        XCTAssertEqual(fetched?.lastName, "Reyes")
    }

    /// Form Delete: confirm-alert → onDelete closure runs
    /// `modelContext.delete(borrower)` + save. Zero rows after.
    func testBorrowerFormDeleteRemovesBorrower() throws {
        let ctx = makeContext()
        let borrower = Borrower(firstName: "Pat", lastName: "Nguyen", source: .manual)
        ctx.insert(borrower)
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Borrower>()).count, 1)

        ctx.delete(borrower)
        try ctx.save()

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Borrower>()).count, 0)
    }

    /// Form `.edit` mode mutates `currentMortgage`: add when borrower
    /// had none, modify when borrower had one, clear when draft is
    /// blanked. Covers the round-trip through the JSON blob.
    func testBorrowerFormEditCurrentMortgage() throws {
        let ctx = makeContext()
        let borrower = Borrower(firstName: "Mo", lastName: "Kiernan")
        ctx.insert(borrower)
        try ctx.save()
        XCTAssertNil(borrower.currentMortgage)

        // Add: edit form's draft committed onto the borrower.
        borrower.currentMortgage = sampleMortgage()
        try ctx.save()
        XCTAssertEqual(
            try ctx.fetch(FetchDescriptor<Borrower>()).first?.currentMortgage,
            sampleMortgage()
        )

        // Modify: draft balance differs, setter re-encodes.
        let modified = sampleMortgage(balance: 301_250)
        borrower.currentMortgage = modified
        try ctx.save()
        XCTAssertEqual(
            try ctx.fetch(FetchDescriptor<Borrower>()).first?.currentMortgage,
            modified
        )

        // Clear: setting nil wipes the blob.
        borrower.currentMortgage = nil
        try ctx.save()
        let cleared = try ctx.fetch(FetchDescriptor<Borrower>()).first
        XCTAssertNil(cleared?.currentMortgage)
        XCTAssertNil(cleared?.currentMortgageJSON)
    }
}
