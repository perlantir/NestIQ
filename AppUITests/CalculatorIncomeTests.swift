// CalculatorIncomeTests.swift
// Income qualification full flow — Session 7.4 removed PDF export from
// this calculator (Reg B / ECOA compliance), so the test no longer
// asserts a share dock or share-preview presentation. Save still works.

import XCTest

@MainActor
final class CalculatorIncomeTests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testIncomeQualFullFlow() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "incomeQualification")

        if app.keyboards.count > 0 {
            app.typeText("\n")
        }
        let compute = app.buttons["incomeQual.compute"]
        XCTAssertTrue(compute.waitForExistence(timeout: 5),
                      "Compute CTA incomeQual.compute not found")
        compute.tap()

        let dockSave = app.buttons["dock.save"]
        XCTAssertTrue(dockSave.waitForExistence(timeout: 10),
                      "dock.save absent after IncomeQual compute")
        XCTAssertFalse(app.buttons["dock.share"].exists,
                       "dock.share must not exist — IncomeQual has no PDF export "
                       + "(Session 7.4 / Reg B compliance)")

        UITest.tapDock(app, "save")
        UITest.confirmSaveAlert(app)
    }
}
