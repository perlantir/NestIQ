// SavedScenariosDeleteTests.swift
// Session 5F.2: swipe-to-delete and multi-select Edit-mode delete on the
// Saved tab. Both paths go through a confirmation alert before the row
// leaves SwiftData.

import XCTest

@MainActor
final class SavedScenariosDeleteTests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    /// Seed one Amortization scenario, then swipe-left on its row,
    /// tap Delete, confirm the alert, and assert the row is gone.
    func testSwipeDeleteSingleRow() async throws {
        let app = UITest.launchApp()
        seedOneAmortization(app)

        // Navigate to Scenarios tab.
        let tab = app.tabBars.buttons["Scenarios"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let row = app.buttons["saved.row.amortization"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Seeded row missing")

        // Swipe left to reveal the destructive action.
        row.swipeLeft()

        // The swipe-revealed Delete button carries our accessibility id.
        let swipeDelete = app.buttons["saved.swipeDelete.amortization"]
        XCTAssertTrue(swipeDelete.waitForExistence(timeout: 3),
                      "Swipe-revealed Delete button not found")
        swipeDelete.tap()

        // Confirmation alert — tap the destructive "Delete" action.
        let confirmButton = app.alerts.buttons["Delete"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 3),
                      "Confirmation alert did not appear")
        confirmButton.tap()

        // Row is gone.
        XCTAssertFalse(row.waitForExistence(timeout: 2),
                       "Row still exists after confirmed swipe-delete")
    }

    /// Seed three scenarios of different calculator types, enter Edit
    /// mode, Select all, Delete, confirm, assert all three are gone.
    func testMultiSelectDeleteThreeRows() async throws {
        let app = UITest.launchApp()
        seedOneAmortization(app)
        seedOneRefinance(app)
        seedOneTCA(app)

        let tab = app.tabBars.buttons["Scenarios"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        // Wait for at least one row.
        XCTAssertTrue(app.buttons["saved.row.amortization"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["saved.row.refinance"].exists)
        XCTAssertTrue(app.buttons["saved.row.totalCostAnalysis"].exists)

        // Enter Edit mode.
        let edit = app.buttons["saved.edit"]
        XCTAssertTrue(edit.waitForExistence(timeout: 3), "Edit button missing")
        edit.tap()

        let selectAll = app.buttons["saved.selectAll"]
        XCTAssertTrue(selectAll.waitForExistence(timeout: 3), "Select all missing")
        selectAll.tap()

        let deleteSelected = app.buttons["saved.deleteSelected"]
        XCTAssertTrue(deleteSelected.waitForExistence(timeout: 3),
                      "Delete-selected button missing")
        deleteSelected.tap()

        let confirmButton = app.alerts.buttons["Delete"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 3),
                      "Multi-select confirmation alert did not appear")
        confirmButton.tap()

        // All three are gone; Edit mode has auto-exited.
        XCTAssertFalse(app.buttons["saved.row.amortization"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["saved.row.refinance"].exists)
        XCTAssertFalse(app.buttons["saved.row.totalCostAnalysis"].exists)
    }

    // MARK: - Seeding helpers

    private func seedOneAmortization(_ app: XCUIApplication) {
        UITest.tapCalculator(app, slug: "amortization")
        if app.keyboards.count > 0 { app.typeText("\n") }
        let compute = app.buttons["amort.compute"]
        XCTAssertTrue(compute.waitForExistence(timeout: 5))
        compute.tap()
        XCTAssertTrue(app.buttons["dock.save"].waitForExistence(timeout: 10))
        UITest.tapDock(app, "save")
        UITest.confirmSaveAlert(app)
        backToHome(app)
    }

    private func seedOneRefinance(_ app: XCUIApplication) {
        UITest.tapCalculator(app, slug: "refinance")
        if app.keyboards.count > 0 { app.typeText("\n") }
        let compute = app.buttons["refi.compute"]
        XCTAssertTrue(compute.waitForExistence(timeout: 5))
        compute.tap()
        XCTAssertTrue(app.buttons["dock.save"].waitForExistence(timeout: 10))
        UITest.tapDock(app, "save")
        UITest.confirmSaveAlert(app)
        backToHome(app)
    }

    private func seedOneTCA(_ app: XCUIApplication) {
        UITest.tapCalculator(app, slug: "totalCostAnalysis")
        if app.keyboards.count > 0 { app.typeText("\n") }
        let compute = app.buttons["tca.compute"]
        XCTAssertTrue(compute.waitForExistence(timeout: 5))
        compute.tap()
        XCTAssertTrue(app.buttons["dock.save"].waitForExistence(timeout: 10))
        UITest.tapDock(app, "save")
        UITest.confirmSaveAlert(app)
        backToHome(app)
    }

    /// Pop back to the home list of calculators. The root tab is labeled
    /// "Calculators" in RootTabBar. Tapping the already-selected tab a
    /// second time pops the stack to root — that's why we tap twice.
    private func backToHome(_ app: XCUIApplication) {
        let calcTab = app.tabBars.buttons["Calculators"]
        if calcTab.waitForExistence(timeout: 3) {
            calcTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            calcTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}
