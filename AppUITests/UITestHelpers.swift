// UITestHelpers.swift
// Shared launch helpers for the calculator UI tests. Each test uses
// `-uitestReset` + `-uitestSeedProfile` to land directly in the tab
// bar with a pre-onboarded LenderProfile, skipping Sign in with Apple
// (which requires a real Apple ID in the simulator).

import XCTest

@MainActor
enum UITest {
    static func launchApp(file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestReset", "-uitestSeedProfile"]
        app.launch()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 10),
            "App failed to reach foreground",
            file: file, line: line
        )
        return app
    }

    static func tapCalculator(_ app: XCUIApplication, slug: String) {
        let row = app.buttons["home.calculator.\(slug)"]
        XCTAssertTrue(row.waitForExistence(timeout: 8),
                      "Home row for \(slug) not found")
        row.tap()
    }

    /// Tap a dock button by its accessibility identifier. The three
    /// docks all expose: dock.narrate, dock.save, dock.share. We use a
    /// coordinate tap because the dock sits under an `.ultraThinMaterial`
    /// overlay whose synthesized scroll-to-visible call fails on the
    /// simulator — a coordinate tap skips that step.
    static func tapDock(_ app: XCUIApplication, _ action: String) {
        let button = app.buttons["dock.\(action)"]
        XCTAssertTrue(button.waitForExistence(timeout: 5),
                      "Dock button '\(action)' not found")
        let coordinate = button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
    }

    /// Switch to the Scenarios tab and tap the saved row for the
    /// given calculator slug. Uses coordinate taps because the tab bar
    /// and saved rows both trigger the simulator's AX scroll-to-
    /// visible bug under ultra-thin material overlays.
    static func openSavedScenario(_ app: XCUIApplication, slug: String) {
        let tab = app.tabBars.buttons["Scenarios"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5),
                      "Scenarios tab not found")
        tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let row = app.buttons["saved.row.\(slug)"]
        XCTAssertTrue(row.waitForExistence(timeout: 5),
                      "Saved row for \(slug) not found")
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// Calculator smoke flow: open → dock.save → dock.share → verify
    /// the share-preview sheet. The reopen-from-Saved leg is covered
    /// by the SwiftData unit tests (cascade-delete + fetch) since
    /// tab-switch accessibility on iOS 18 simulators is unreliable
    /// (see DECISIONS.md 2026-04-18).
    static func exerciseCalculatorFlow(_ app: XCUIApplication, slug: String) {
        tapCalculator(app, slug: slug)

        XCTAssertTrue(app.buttons["dock.narrate"].waitForExistence(timeout: 5),
                      "dock.narrate absent for \(slug)")
        XCTAssertTrue(app.buttons["dock.save"].exists,
                      "dock.save absent for \(slug)")
        XCTAssertTrue(app.buttons["dock.share"].exists,
                      "dock.share absent for \(slug)")

        tapDock(app, "save")
        tapDock(app, "share")

        let previewTitle = app.staticTexts["Preview"]
        XCTAssertTrue(previewTitle.waitForExistence(timeout: 8),
                      "Share preview did not present (slug=\(slug))")
    }

    /// Two-step flow: calculator row → Inputs screen → Compute CTA →
    /// Results screen with dock. Used by every calculator that has its
    /// own Inputs screen (all five as of the v1 Inputs rollout).
    static func exerciseTwoStepCalculatorFlow(
        _ app: XCUIApplication,
        slug: String,
        computeId: String
    ) {
        tapCalculator(app, slug: slug)

        // Dismiss any auto-focused keyboard so the Compute button isn't
        // obscured — same dance as CalculatorAmortTests.
        if app.keyboards.count > 0 {
            app.typeText("\n")
        }
        let compute = app.buttons[computeId]
        XCTAssertTrue(compute.waitForExistence(timeout: 5),
                      "Compute CTA \(computeId) not found for \(slug)")
        compute.tap()

        let dock = app.buttons["dock.narrate"]
        if !dock.waitForExistence(timeout: 10) {
            print("[UITest] post-Compute tree for \(slug):\n\(app.debugDescription)")
            XCTFail("Dock did not appear after Compute for \(slug)")
            return
        }
        XCTAssertTrue(app.buttons["dock.save"].exists,
                      "dock.save absent after compute for \(slug)")
        XCTAssertTrue(app.buttons["dock.share"].exists,
                      "dock.share absent after compute for \(slug)")

        tapDock(app, "save")
        tapDock(app, "share")

        let previewTitle = app.staticTexts["Preview"]
        XCTAssertTrue(previewTitle.waitForExistence(timeout: 8),
                      "Share preview did not present (slug=\(slug))")
    }
}
