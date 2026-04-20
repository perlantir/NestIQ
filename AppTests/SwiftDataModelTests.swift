// SwiftDataModelTests.swift
// Session 3 unit coverage for the SwiftData CRUD path that drives
// Saved Scenarios + Home recent + LenderProfile.

import XCTest
import SwiftData
@testable import Quotient

@MainActor
final class SwiftDataModelTests: XCTestCase {

    func makeContext() -> ModelContext {
        let container = QuotientSchema.makeContainer(inMemory: true)
        return ModelContext(container)
    }

    // MARK: - LenderProfile

    func testProfileInsertAndFetch() throws {
        let ctx = makeContext()
        let profile = LenderProfile(appleUserID: "apple.user.1", firstName: "Nick", lastName: "Moretti")
        ctx.insert(profile)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<LenderProfile>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.fullName, "Nick Moretti")
        XCTAssertEqual(fetched.first?.initials, "NM")
    }

    /// Session 5I.3: the Settings upper-right hero was rendering
    /// initials even after a photo was uploaded. Root-cause analysis
    /// confirmed the save path itself was correct (ProfileEditor writes
    /// `photoData` on MainActor then calls `modelContext.save()`); the
    /// bug was purely in the hero's render path. This test pins the
    /// round-trip so a future regression in persistence can't go
    /// unnoticed either.
    func testProfilePhotoUploadAndPersist() throws {
        let ctx = makeContext()
        let profile = LenderProfile(appleUserID: "apple.photo.1", firstName: "Nick")
        let bytes = Data([0xFF, 0xD8, 0xFF, 0xE0] + Array(repeating: UInt8(0x42), count: 256))
        profile.photoData = bytes
        profile.showPhotoOnPDF = true
        ctx.insert(profile)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<LenderProfile>()).first
        XCTAssertEqual(fetched?.photoData, bytes)
        XCTAssertEqual(fetched?.showPhotoOnPDF, true)

        fetched?.photoData = nil
        try ctx.save()
        let cleared = try ctx.fetch(FetchDescriptor<LenderProfile>()).first
        XCTAssertNil(cleared?.photoData)
    }

    func testProfileAppearanceRoundTrip() throws {
        let ctx = makeContext()
        let profile = LenderProfile(appleUserID: "apple.2")
        profile.appearance = .dark
        profile.density = .compact
        ctx.insert(profile)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<LenderProfile>()).first
        XCTAssertEqual(fetched?.appearance, .dark)
        XCTAssertEqual(fetched?.density, .compact)
    }

    // MARK: - Borrower + Scenario

    func testBorrowerScenarioRelationship() throws {
        let ctx = makeContext()
        let borrower = Borrower(firstName: "John", lastName: "Smith",
                                email: "john@example.com",
                                source: .manual)
        ctx.insert(borrower)
        let scenario = Scenario(
            borrower: borrower,
            calculatorType: .amortization,
            name: "Smith 30yr",
            inputsJSON: Data(),
            keyStatLine: "$548,000 · 30-yr · 6.750%"
        )
        ctx.insert(scenario)
        try ctx.save()

        let fetchedBorrowers = try ctx.fetch(FetchDescriptor<Borrower>())
        XCTAssertEqual(fetchedBorrowers.count, 1)
        XCTAssertEqual(fetchedBorrowers.first?.scenarios.count, 1)
        XCTAssertEqual(fetchedBorrowers.first?.scenarios.first?.calculatorType, .amortization)
    }

    func testScenarioArchiveFlag() throws {
        let ctx = makeContext()
        let scenario = Scenario(
            calculatorType: .amortization,
            name: "Sample",
            inputsJSON: Data(),
            keyStatLine: ""
        )
        ctx.insert(scenario)
        try ctx.save()
        XCTAssertFalse(scenario.archived)

        scenario.archived = true
        try ctx.save()
        XCTAssertTrue(scenario.archived)
    }

    func testCascadeDeleteOnBorrower() throws {
        let ctx = makeContext()
        let borrower = Borrower(firstName: "Priya", lastName: "V", source: .manual)
        ctx.insert(borrower)
        let s1 = Scenario(borrower: borrower, calculatorType: .refinance,
                          name: "Refi A", inputsJSON: Data(), keyStatLine: "")
        let s2 = Scenario(borrower: borrower, calculatorType: .refinance,
                          name: "Refi B", inputsJSON: Data(), keyStatLine: "")
        ctx.insert(s1); ctx.insert(s2)
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Scenario>()).count, 2)

        ctx.delete(borrower)
        try ctx.save()
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<Scenario>()).isEmpty,
                      "Scenarios should cascade-delete with their borrower")
    }

    /// Session 5K.1: when a Scenario is loaded from the Saved tab and
    /// re-saved after edits, the calculator screens' Save button must
    /// mutate the existing record in place rather than insert a new one.
    /// This pins the two branches of the `if let existing =
    /// existingScenario` pattern used across all six calculator screens.
    func testSaveOverwriteDoesNotDuplicate() throws {
        let ctx = makeContext()
        let borrower = Borrower(firstName: "Jane", lastName: "Doe", source: .manual)
        ctx.insert(borrower)
        let original = Scenario(
            borrower: borrower,
            calculatorType: .amortization,
            name: "Doe · Amortization",
            inputsJSON: Data("v1".utf8),
            keyStatLine: "$400K · 30-yr · 6.500%"
        )
        ctx.insert(original)
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Scenario>()).count, 1)

        // Simulate the overwrite branch used by every results screen:
        // mutate inputsJSON / keyStatLine / updatedAt on the same
        // record, save, assert the count is unchanged.
        original.inputsJSON = Data("v2".utf8)
        original.keyStatLine = "$450K · 30-yr · 6.375%"
        original.updatedAt = Date()
        try ctx.save()

        let scenarios = try ctx.fetch(FetchDescriptor<Scenario>())
        XCTAssertEqual(scenarios.count, 1, "overwrite must not duplicate")
        XCTAssertEqual(scenarios.first?.inputsJSON, Data("v2".utf8))
        XCTAssertEqual(scenarios.first?.keyStatLine, "$450K · 30-yr · 6.375%")
    }

    /// Session 5K.1: saving from a fresh calculator (no existingScenario
    /// handle) inserts a new record. This pins the else-branch.
    func testSaveNewScenarioInserts() throws {
        let ctx = makeContext()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Scenario>()).count, 0)

        let fresh = Scenario(
            calculatorType: .refinance,
            name: "New scenario · Refi",
            inputsJSON: Data(),
            keyStatLine: ""
        )
        ctx.insert(fresh)
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Scenario>()).count, 1)

        let another = Scenario(
            calculatorType: .refinance,
            name: "Another · Refi",
            inputsJSON: Data(),
            keyStatLine: ""
        )
        ctx.insert(another)
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Scenario>()).count, 2,
                       "fresh saves must accumulate as distinct records")
    }

    // MARK: - Amortization form inputs round trip

    func testAmortizationInputsRoundTrip() throws {
        let inputs = AmortizationFormInputs(
            loanAmount: 300_000,
            annualRate: 6.125,
            termYears: 15,
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            annualTaxes: 4_200,
            annualInsurance: 960,
            monthlyHOA: 0,
            includePMI: false,
            extraPrincipalMonthly: 0,
            biweekly: false
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(inputs)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AmortizationFormInputs.self, from: data)
        XCTAssertEqual(decoded, inputs)
    }
}
