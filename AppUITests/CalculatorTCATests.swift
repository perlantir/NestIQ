// CalculatorTCATests.swift
// Session 4.5.3 UI coverage for Total Cost Analysis.

import XCTest

@MainActor
final class CalculatorTCATests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testTCADockFlow() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "totalCostAnalysis")

        XCTAssertTrue(app.buttons["dock.narrate"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["dock.save"].exists)
        XCTAssertTrue(app.buttons["dock.share"].exists)

        UITest.tapDock(app, "save")
        UITest.tapDock(app, "share")
        let previewTitle = app.staticTexts["Preview"]
        XCTAssertTrue(previewTitle.waitForExistence(timeout: 8),
                      "Share preview did not present after Share tap")
    }
}
