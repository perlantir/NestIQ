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
}
