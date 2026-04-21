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
            viewModel: vm
        )
        let doc = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThanOrEqual(doc.pageCount, 2)

        let full = (0..<doc.pageCount)
            .compactMap { doc.page(at: $0)?.string }
            .joined(separator: "\n")
        // v2.1.1 template renders the borrower last name in the scenario
        // head + page footers; renders the cash-out-vs-HELOC comparison
        // grid on page 2; and the Blended rate badge in the scenario
        // meta on page 1. Compliance trailer appends the fine-print
        // page + EHO footer.
        XCTAssertTrue(full.contains("Smith"))
        XCTAssertTrue(full.contains("HELOC vs Cash-out refinance"))
        XCTAssertTrue(
            full.lowercased().contains("blended"),
            "Blended-rate framing missing — template may have failed token interpolation"
        )
        XCTAssertTrue(full.contains("Equal Housing Opportunity"))
    }
}
