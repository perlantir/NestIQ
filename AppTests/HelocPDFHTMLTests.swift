// HelocPDFHTMLTests.swift
// Session 5O.5 — PDF integrity for HELOC vs Refinance.

import XCTest
import PDFKit
import QuotientFinance
@testable import Quotient

@MainActor
final class HelocPDFHTMLTests: XCTestCase {

    func testHelocPDFRendersComparison() async throws {
        let profile = LenderProfile(
            appleUserID: "apple.heloc.\(UUID().uuidString)",
            firstName: "Nick",
            lastName: "Gallick",
            nmlsId: "1428391",
            licensedStates: ["CA"],
            companyName: "Gallick Holdings LLC",
            phone: "(415) 555-0123",
            email: "nick@example.com"
        )
        let borrower = Borrower(firstName: "John", lastName: "Smith",
                                propertyState: "CA", source: .manual)
        let vm = HelocViewModel(borrower: borrower)

        let url = try await PDFBuilder.buildHelocPDF(
            profile: profile,
            borrower: borrower,
            viewModel: vm,
            narrative: ""
        )
        let doc = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThanOrEqual(doc.pageCount, 2)

        let full = (0..<doc.pageCount)
            .compactMap { doc.page(at: $0)?.string }
            .joined(separator: "\n")
        XCTAssertTrue(full.contains("Smith"))
        XCTAssertTrue(full.contains("Cash-out refinance vs HELOC"))
        XCTAssertTrue(full.contains("Blended rate"))
        XCTAssertTrue(full.contains("Rate structure"))
        XCTAssertTrue(full.contains("The fine print"))
        // D12 (Session 7.3a): CG-drawn "Page 1 of N" counter retired —
        // replaced with an HTML-side assertion on the compliance footer.
        XCTAssertTrue(full.contains("Equal Housing Opportunity"))
    }
}
