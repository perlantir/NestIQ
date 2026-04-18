// CalculatorIncomeTests.swift
// Full onboarding-bypassed calculator flow: open → save → reopen →
// share → preview.

import XCTest

@MainActor
final class CalculatorIncomeTests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testIncomeQualFullFlow() async throws {
        let app = UITest.launchApp()
        UITest.exerciseTwoStepCalculatorFlow(
            app,
            slug: "incomeQualification",
            computeId: "incomeQual.compute"
        )
    }
}
