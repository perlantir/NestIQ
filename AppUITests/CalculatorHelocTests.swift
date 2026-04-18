// CalculatorHelocTests.swift
// Session 4.5.4 UI coverage for HELOC vs Refinance.

import XCTest

@MainActor
final class CalculatorHelocTests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testHelocDockFlow() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "helocVsRefinance")

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
