// CalculatorRefiTests.swift
// Session 4.5.2 UI coverage for Refinance Comparison — same pattern as
// the Income test: tap the calculator row, verify all three dock
// buttons are hittable, exercise save + share.

import XCTest

@MainActor
final class CalculatorRefiTests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testRefinanceDockFlow() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "refinance")

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
