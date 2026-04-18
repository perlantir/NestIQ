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
