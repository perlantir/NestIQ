// CalculatorHelocTests.swift
// Full calculator flow for HELOC vs Refinance.

import XCTest

@MainActor
final class CalculatorHelocTests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testHelocFullFlow() async throws {
        let app = UITest.launchApp()
        UITest.exerciseTwoStepCalculatorFlow(
            app,
            slug: "helocVsRefinance",
            computeId: "heloc.compute"
        )
    }
}
