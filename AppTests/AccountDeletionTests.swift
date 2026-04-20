// AccountDeletionTests.swift
// Session 5N.1 — local-only delete account wipe. Apple Guideline
// 5.1.1(v) requires in-app deletion; SIWA token revocation is server-
// side TODO. These tests pin the local-wipe primitive.

import XCTest
import SwiftData
@testable import Quotient

@MainActor
final class AccountDeletionTests: XCTestCase {

    private func makeContext() -> ModelContext {
        ModelContext(QuotientSchema.makeContainer(inMemory: true))
    }

    private func seed(_ ctx: ModelContext) -> LenderProfile {
        let profile = LenderProfile(
            appleUserID: "apple.del.1",
            firstName: "Test",
            lastName: "User"
        )
        profile.photoData = Data(repeating: 0x42, count: 64)
        ctx.insert(profile)

        let borrower = Borrower(firstName: "A", lastName: "Buyer")
        ctx.insert(borrower)

        let scenario = Scenario(
            borrower: borrower,
            calculatorType: .amortization,
            name: "Test scenario",
            inputsJSON: Data()
        )
        ctx.insert(scenario)
        try? ctx.save()
        return profile
    }

    // MARK: - Local wipe

    /// `preservingProfile: nil` deletes everything so a test can
    /// verify the full clear state. The UI uses a non-nil parameter
    /// to keep the profile alive until the success screen dismisses.
    func testLocalWipeClearsAllSwiftData() throws {
        let ctx = makeContext()
        _ = seed(ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<LenderProfile>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Borrower>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Scenario>()).count, 1)

        AccountDeletion.performLocalWipe(context: ctx, preservingProfile: nil)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<LenderProfile>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Borrower>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Scenario>()).count, 0)
    }

    func testLocalWipePreservesProfileWhenRequested() throws {
        let ctx = makeContext()
        let profile = seed(ctx)

        AccountDeletion.performLocalWipe(context: ctx, preservingProfile: profile)

        let profiles = try ctx.fetch(FetchDescriptor<LenderProfile>())
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.appleUserID, "apple.del.1")
        // Child models still gone regardless of profile preservation.
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Borrower>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Scenario>()).count, 0)
    }

    func testLocalWipeIsIdempotent() throws {
        let ctx = makeContext()
        _ = seed(ctx)

        AccountDeletion.performLocalWipe(context: ctx, preservingProfile: nil)
        // Running it again on an already-empty context must not throw
        // or re-introduce rows.
        AccountDeletion.performLocalWipe(context: ctx, preservingProfile: nil)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<LenderProfile>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Borrower>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Scenario>()).count, 0)
    }

    /// Photo data lives inside `LenderProfile.photoData` — a SwiftData
    /// attribute, not a file-system file. Full-wipe deletion removes
    /// it transitively when the profile record is deleted.
    func testLocalWipeClearsProfilePhotoData() throws {
        let ctx = makeContext()
        _ = seed(ctx)

        AccountDeletion.performLocalWipe(context: ctx, preservingProfile: nil)

        let remaining = try ctx.fetch(FetchDescriptor<LenderProfile>())
        XCTAssertTrue(remaining.isEmpty)
    }
}
