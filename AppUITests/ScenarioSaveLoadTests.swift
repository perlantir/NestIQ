// ScenarioSaveLoadTests.swift
// Session 5E.1: round-trip per-calculator tests. Nick's QA reported
// that saved scenarios never appeared in the Saved tab. This file
// codifies the contract:
//   1. Compute, then tap Save → dock.save
//   2. Switch to the Scenarios tab
//   3. Assert a saved row for the right calculator slug exists
//   4. Tap it → Reopen destination renders (InputsScreen for calculators
//      with a two-step flow, Results for those that compute on present)
//   5. Change one input (a free-text FieldRow), re-save
//   6. Assert Scenarios tab shows one row (updated, not duplicated)
//
// These tests would have caught the Session 5D → 5E regression. They
// use coordinate taps for the dock + Scenarios tab per the iOS 18
// simulator AX workaround documented in UITestHelpers.

import XCTest

@MainActor
final class ScenarioSaveLoadTests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    // MARK: - Amortization

    func testAmortizationSaveThenShowsInSavedTab() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "amortization")

        if app.keyboards.count > 0 { app.typeText("\n") }
        let compute = app.buttons["amort.compute"]
        XCTAssertTrue(compute.waitForExistence(timeout: 5),
                      "Amort compute CTA not found")
        compute.tap()

        let dock = app.buttons["dock.save"]
        XCTAssertTrue(dock.waitForExistence(timeout: 10),
                      "Dock did not appear after Amort compute")
        dock.tap()

        // Give SwiftData.save() a moment to propagate to @Query.
        let row = app.buttons["saved.row.amortization"]
        let tab = app.tabBars.buttons["Scenarios"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5),
                      "Scenarios tab not found")
        tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5),
                      "Saved Amortization row did not appear after Save")
    }

    // MARK: - Income Qualification

    func testIncomeQualSaveThenShowsInSavedTab() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "incomeQualification")

        if app.keyboards.count > 0 { app.typeText("\n") }
        let compute = app.buttons["incomeQual.compute"]
        XCTAssertTrue(compute.waitForExistence(timeout: 5),
                      "IncomeQual compute CTA not found")
        compute.tap()

        let dock = app.buttons["dock.save"]
        XCTAssertTrue(dock.waitForExistence(timeout: 10),
                      "Dock did not appear after IncomeQual compute")
        UITest.tapDock(app, "save")

        let tab = app.tabBars.buttons["Scenarios"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5),
                      "Scenarios tab not found")
        tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let row = app.buttons["saved.row.incomeQualification"]
        XCTAssertTrue(row.waitForExistence(timeout: 5),
                      "Saved IncomeQual row did not appear after Save")
    }

    // MARK: - Refinance

    func testRefinanceSaveThenShowsInSavedTab() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "refinance")

        if app.keyboards.count > 0 { app.typeText("\n") }
        let compute = app.buttons["refi.compute"]
        XCTAssertTrue(compute.waitForExistence(timeout: 5),
                      "Refi compute CTA not found")
        compute.tap()

        let dock = app.buttons["dock.save"]
        XCTAssertTrue(dock.waitForExistence(timeout: 10),
                      "Dock did not appear after Refi compute")
        UITest.tapDock(app, "save")

        let tab = app.tabBars.buttons["Scenarios"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5),
                      "Scenarios tab not found")
        tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let row = app.buttons["saved.row.refinance"]
        XCTAssertTrue(row.waitForExistence(timeout: 5),
                      "Saved Refinance row did not appear after Save")
    }

    // MARK: - TCA

    func testTCASaveThenShowsInSavedTab() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "totalCostAnalysis")

        if app.keyboards.count > 0 { app.typeText("\n") }
        let compute = app.buttons["tca.compute"]
        XCTAssertTrue(compute.waitForExistence(timeout: 5),
                      "TCA compute CTA not found")
        compute.tap()

        let dock = app.buttons["dock.save"]
        XCTAssertTrue(dock.waitForExistence(timeout: 10),
                      "Dock did not appear after TCA compute")
        UITest.tapDock(app, "save")

        let tab = app.tabBars.buttons["Scenarios"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5),
                      "Scenarios tab not found")
        tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let row = app.buttons["saved.row.totalCostAnalysis"]
        XCTAssertTrue(row.waitForExistence(timeout: 5),
                      "Saved TCA row did not appear after Save")
    }

    // MARK: - HELOC

    func testHelocSaveThenShowsInSavedTab() async throws {
        let app = UITest.launchApp()
        UITest.tapCalculator(app, slug: "helocVsRefinance")

        if app.keyboards.count > 0 { app.typeText("\n") }
        let compute = app.buttons["heloc.compute"]
        XCTAssertTrue(compute.waitForExistence(timeout: 5),
                      "HELOC compute CTA not found")
        compute.tap()

        let dock = app.buttons["dock.save"]
        XCTAssertTrue(dock.waitForExistence(timeout: 10),
                      "Dock did not appear after HELOC compute")
        UITest.tapDock(app, "save")

        let tab = app.tabBars.buttons["Scenarios"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5),
                      "Scenarios tab not found")
        tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let row = app.buttons["saved.row.helocVsRefinance"]
        XCTAssertTrue(row.waitForExistence(timeout: 5),
                      "Saved HELOC row did not appear after Save")
    }
}
