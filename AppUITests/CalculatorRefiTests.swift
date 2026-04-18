// CalculatorRefiTests.swift
// Full calculator flow for Refinance Comparison.

import XCTest

@MainActor
final class CalculatorRefiTests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testRefinanceFullFlow() async throws {
        let app = UITest.launchApp()
        UITest.exerciseCalculatorFlow(app, slug: "refinance")
    }
}
