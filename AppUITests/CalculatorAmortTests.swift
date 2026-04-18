// CalculatorAmortTests.swift
// Full calculator flow for Amortization. Unlike the other four
// calculators, Amortization has a two-step flow (inputs → results via
// the Compute CTA) so the dock lives behind an additional navigation
// push.

import XCTest

@MainActor
final class CalculatorAmortTests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testAmortizationFullFlow() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "amortization")

        // Inputs screen → scroll to Compute CTA → tap → results screen
        // with dock. Dismiss any auto-focused keyboard first so the
        // Compute button isn't obscured.
        if app.keyboards.count > 0 {
            app.typeText("\n")
        }
        let compute = app.buttons["amort.compute"]
        XCTAssertTrue(compute.waitForExistence(timeout: 5),
                      "Compute CTA not found on Amortization inputs")
        compute.tap()

        // Results screen: the dock lives at the bottom of the results
        // view, behind a NavigationStack push. Allow up to 10s for the
        // push animation + initial compute() to complete.
        let dock = app.buttons["dock.narrate"]
        if !dock.waitForExistence(timeout: 10) {
            print("[UITest] post-Compute tree:\n\(app.debugDescription)")
            XCTFail("Dock did not appear after Compute")
            return
        }
        XCTAssertTrue(app.buttons["dock.save"].exists)
        XCTAssertTrue(app.buttons["dock.share"].exists)

        UITest.tapDock(app, "save")
        UITest.tapDock(app, "share")
        let previewTitle = app.staticTexts["Preview"]
        XCTAssertTrue(previewTitle.waitForExistence(timeout: 8),
                      "Share preview did not present for Amortization")
    }
}
