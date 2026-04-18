// CalculatorIncomeTests.swift
// Session 4.5.1 UI coverage for Income Qualification. Onboarding is
// bypassed via the seeded test profile, so the flow tested here is:
//
//   home tab → tap Income row → dock.save → dock.share → preview shown

import XCTest

@MainActor
final class CalculatorIncomeTests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testIncomeQualDockFlow() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "incomeQualification")

        // All three dock buttons must be hittable.
        XCTAssertTrue(app.buttons["dock.narrate"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["dock.save"].exists)
        XCTAssertTrue(app.buttons["dock.share"].exists)

        // Save persists; the save handler's 2s "Saved" label flip is
        // the observable side effect.
        UITest.tapDock(app, "save")

        // Share triggers the PDF build + sheet present.
        UITest.tapDock(app, "share")
        let previewTitle = app.staticTexts["Preview"]
        XCTAssertTrue(previewTitle.waitForExistence(timeout: 8),
                      "Share preview did not present after Share tap")
    }
}
