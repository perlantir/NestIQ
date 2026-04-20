// RefinancePDFHTMLTests.swift
// Session 5O.4 — PDF integrity tests for the Refinance HTML builder.

import XCTest
import PDFKit
import QuotientFinance
@testable import Quotient

@MainActor
final class RefinancePDFHTMLTests: XCTestCase {

    func testRefinancePDFRendersCoverAndComparison() async throws {
        let profile = makeProfile()
        let borrower = makeBorrower()
        let vm = RefinanceViewModel(borrower: borrower)
        vm.compute()

        let url = try await PDFBuilder.buildRefinancePDF(
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
        XCTAssertTrue(full.contains("Smith"),
                      "Borrower surname missing from Refi PDF")
        XCTAssertTrue(full.contains("Current vs refinance options"),
                      "Refi comparison section heading missing")
        // Exhibit the comparison rows exist
        XCTAssertTrue(full.contains("Loan amt"),
                      "Loan amt row missing")
        XCTAssertTrue(full.contains("Break-even"),
                      "Break-even row missing")
        XCTAssertTrue(full.contains("NPV"),
                      "NPV row missing")
        XCTAssertTrue(full.contains("The fine print"),
                      "Disclaimers appendix missing")
        XCTAssertTrue(full.contains("Page 1 of "),
                      "Cover page counter missing")
    }

    private func makeProfile() -> LenderProfile {
        LenderProfile(
            appleUserID: "apple.refi.\(UUID().uuidString)",
            firstName: "Nick",
            lastName: "Gallick",
            nmlsId: "1428391",
            licensedStates: ["CA"],
            companyName: "Gallick Holdings LLC",
            phone: "(415) 555-0123",
            email: "nick@example.com"
        )
    }

    private func makeBorrower() -> Borrower {
        Borrower(firstName: "John", lastName: "Smith",
                 propertyState: "CA", source: .manual)
    }
}
