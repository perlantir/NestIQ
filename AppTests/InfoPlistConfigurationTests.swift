// InfoPlistConfigurationTests.swift
// Session 6.1 — guards that TestFlight-required Info.plist keys are
// present in the app bundle. Catches accidental deletion or rename.

import XCTest

final class InfoPlistConfigurationTests: XCTestCase {

    func testFREDAPIKeyPresent() {
        let value = Bundle.main.object(forInfoDictionaryKey: "FREDAPIKey") as? String
        XCTAssertNotNil(value, "FREDAPIKey missing from Info.plist")
        XCTAssertFalse(value?.isEmpty ?? true, "FREDAPIKey is empty")
    }

    func testPhotoLibraryUsageDescriptionMatchesTestFlightCopy() {
        let value = Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") as? String
        XCTAssertEqual(
            value,
            "NestIQ uses your photo library to set a profile photo that appears on borrower-facing PDFs."
        )
    }

    func testFaceIDUsageDescriptionMatchesTestFlightCopy() {
        let value = Bundle.main.object(forInfoDictionaryKey: "NSFaceIDUsageDescription") as? String
        XCTAssertEqual(
            value,
            "NestIQ uses Face ID to securely open the app with your borrower data."
        )
    }
}
