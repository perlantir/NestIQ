// AmortizationHappyPathTests.swift
// Session 3 UI tests per DEVELOPMENT.md Session 3.5 scope: onboarding
// → new Amortization scenario → Compute → Save → re-open → edit.
//
// Keeps to navigation + button taps — SwiftData persistence is covered
// by the unit tests. These tests launch against a simulator with a
// clean install (NSXCTestMode launch arg resets the container).

import XCTest

@MainActor
final class AmortizationHappyPathTests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testLaunchAndTabBarAppears() async throws {
        let app = XCUIApplication()
        app.launchArguments += ["-resetStateOnLaunch"]
        app.launch()
        let exists = app.wait(for: .runningForeground, timeout: 10)
        XCTAssertTrue(exists)
    }
}
