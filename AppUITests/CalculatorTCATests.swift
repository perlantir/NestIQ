// CalculatorTCATests.swift
// Full calculator flow for Total Cost Analysis.

import XCTest

@MainActor
final class CalculatorTCATests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testTCAFullFlow() async throws {
        let app = UITest.launchApp()
        UITest.exerciseCalculatorFlow(app, slug: "totalCostAnalysis")
    }
}
