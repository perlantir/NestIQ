// CalculatorSelfEmploymentTests.swift
// Session 5G.8: smoke tests for the Self-Employment calculator.
// Happy-path per business type (Schedule C / 1120S / 1065) round-trip
// through save/reopen, plus the Income Qualification import wiring.

import XCTest

@MainActor
final class CalculatorSelfEmploymentTests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    // MARK: - Happy paths per business type

    func testScheduleCHappyPath() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "selfEmployment")
        // Default type is Schedule C — no segmented tap needed.
        dismissKeyboardIfPresent(app)
        tapCompute(app)
        saveAndVerify(app, slug: "selfEmployment")
    }

    func testForm1120SHappyPath() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "selfEmployment")
        // Flip to 1120S via the segmented control.
        let typeToggle = app.segmentedControls["selfEmployment.typeToggle"]
        XCTAssertTrue(typeToggle.waitForExistence(timeout: 5),
                      "Business-type segmented control not found")
        typeToggle.buttons["1120S"].tap()
        dismissKeyboardIfPresent(app)
        tapCompute(app)
        saveAndVerify(app, slug: "selfEmployment")
    }

    func testForm1065HappyPath() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "selfEmployment")
        let typeToggle = app.segmentedControls["selfEmployment.typeToggle"]
        XCTAssertTrue(typeToggle.waitForExistence(timeout: 5),
                      "Business-type segmented control not found")
        typeToggle.buttons["1065"].tap()
        dismissKeyboardIfPresent(app)
        tapCompute(app)
        saveAndVerify(app, slug: "selfEmployment")
    }

    // MARK: - Income Qualification import

    func testSelfEmploymentImportToIncomeQual() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "incomeQualification")

        // Pill below the Gross monthly income field.
        let pill = app.buttons["incomeQual.openSelfEmployment"]
        XCTAssertTrue(pill.waitForExistence(timeout: 5),
                      "SE import pill not found on Income Qualification Inputs")
        pill.tap()

        // Dismiss the SE Inputs keyboard (sheet landed focused) and compute.
        dismissKeyboardIfPresent(app)
        let compute = app.buttons["selfEmployment.compute"]
        XCTAssertTrue(compute.waitForExistence(timeout: 5),
                      "SE compute CTA not found in the sheet")
        compute.tap()

        // On the Results screen, tap "Use this income" (accessibility
        // identifier selfEmployment.useIncome) to import and dismiss.
        let useIncome = app.buttons["selfEmployment.useIncome"]
        XCTAssertTrue(useIncome.waitForExistence(timeout: 8),
                      "'Use this income' button did not appear in SE Results")
        useIncome.tap()

        // After the sheet dismisses we should still see the IncomeQual
        // Compute CTA — confirming we returned to the right parent view.
        let iqCompute = app.buttons["incomeQual.compute"]
        XCTAssertTrue(iqCompute.waitForExistence(timeout: 5),
                      "Did not return to Income Qualification Inputs")
    }

    // MARK: - Helpers

    private func dismissKeyboardIfPresent(_ app: XCUIApplication) {
        if app.keyboards.count > 0 { app.typeText("\n") }
    }

    private func tapCompute(_ app: XCUIApplication) {
        let compute = app.buttons["selfEmployment.compute"]
        XCTAssertTrue(compute.waitForExistence(timeout: 5),
                      "SE compute CTA not found")
        compute.tap()
    }

    private func saveAndVerify(_ app: XCUIApplication, slug: String) {
        let dock = app.buttons["dock.save"]
        XCTAssertTrue(dock.waitForExistence(timeout: 10),
                      "Dock did not appear after SE compute")
        UITest.tapDock(app, "save")

        let tab = app.tabBars.buttons["Scenarios"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5),
                      "Scenarios tab not found")
        tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let row = app.buttons["saved.row.\(slug)"]
        XCTAssertTrue(row.waitForExistence(timeout: 5),
                      "Saved SE row did not appear after Save")
    }
}
