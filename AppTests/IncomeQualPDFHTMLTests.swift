// IncomeQualPDFHTMLTests.swift
// Session 5O.6 — PDF integrity for Income Qualification.

import XCTest
import PDFKit
import QuotientFinance
@testable import Quotient

@MainActor
final class IncomeQualPDFHTMLTests: XCTestCase {

    func testIncomeQualPDFRendersBreakdown() async throws {
        let profile = LenderProfile(
            appleUserID: "apple.iq.\(UUID().uuidString)",
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
        let vm = IncomeQualViewModel(borrower: borrower)

        let url = try await PDFBuilder.buildIncomeQualPDF(
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
        XCTAssertTrue(full.contains("Qualification breakdown"))
        XCTAssertTrue(full.contains("Qualifying income"))
        XCTAssertTrue(full.contains("Max qualifying loan"))
        XCTAssertTrue(full.contains("The fine print"))
    }
}
