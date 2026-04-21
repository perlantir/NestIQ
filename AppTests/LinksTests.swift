// LinksTests.swift
// Session 6.2 — guards that production URL constants match the
// nestiq.mortgage domain. Catches accidental edits to Links.swift.

import XCTest
@testable import Quotient

final class LinksTests: XCTestCase {

    func testPrivacyURL() {
        XCTAssertEqual(Links.privacyURL, "https://nestiq.mortgage/privacy")
    }

    func testTermsURL() {
        XCTAssertEqual(Links.termsURL, "https://nestiq.mortgage/terms")
    }

    func testSupportURL() {
        XCTAssertEqual(Links.supportURL, "https://nestiq.mortgage/support")
    }

    func testFeedbackMailto() {
        XCTAssertEqual(
            Links.feedbackMailto,
            "mailto:support@nestiq.mortgage?subject=NestIQ%20feedback"
        )
    }

    func testSupportEmail() {
        XCTAssertEqual(Links.supportEmail, "support@nestiq.mortgage")
    }

    func testURLValuesAreNonFallback() {
        XCTAssertEqual(Links.privacyURLValue.absoluteString, Links.privacyURL)
        XCTAssertEqual(Links.termsURLValue.absoluteString, Links.termsURL)
        XCTAssertEqual(Links.supportURLValue.absoluteString, Links.supportURL)
        XCTAssertEqual(Links.feedbackMailtoValue.absoluteString, Links.feedbackMailto)
    }
}
