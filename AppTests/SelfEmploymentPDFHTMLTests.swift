// SelfEmploymentPDFHTMLTests.swift
// Session 5O.7 — PDF integrity for Self-Employment.

import XCTest
import PDFKit
import QuotientFinance
@testable import Quotient

@MainActor
final class SelfEmploymentPDFHTMLTests: XCTestCase {

    func testSelfEmploymentPDFRendersBreakdown() async throws {
        let profile = LenderProfile(
            appleUserID: "apple.se.\(UUID().uuidString)",
            firstName: "Nick",
            lastName: "Gallick",
            nmlsId: "1428391",
            licensedStates: ["CA"],
            companyName: "Gallick Holdings LLC",
            phone: "(415) 555-0123",
            email: "nick@example.com"
        )
        let borrower = Borrower(firstName: "Jane", lastName: "Doe",
                                propertyState: "CA", source: .manual)
        let vm = SelfEmploymentViewModel()
        vm.borrower = borrower
        vm.compute()

        let url = try await PDFBuilder.buildSelfEmploymentPDF(
            profile: profile,
            borrower: borrower,
            viewModel: vm
        )
        let doc = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThanOrEqual(doc.pageCount, 2)
        let full = (0..<doc.pageCount)
            .compactMap { doc.page(at: $0)?.string }
            .joined(separator: "\n")
        XCTAssertTrue(full.contains("Doe"),
                      "Borrower surname missing from SE PDF")
        XCTAssertTrue(full.contains("Fannie 1084"),
                      "Fannie 1084 eyebrow missing")
        XCTAssertTrue(full.contains("Year-by-year breakdown"),
                      "Year breakdown section missing")
        XCTAssertTrue(full.contains("Two-year average"),
                      "Two-year average section missing")
        XCTAssertTrue(full.contains("Qualifying monthly income"),
                      "Qualifying monthly income row missing")
        XCTAssertTrue(full.contains("The fine print"),
                      "Disclaimers appendix missing")
    }

    // 5H.2 regression pin: addbacks must be labeled with "— added back"
    // in the PDF so the LO's math is self-documenting to any reader.
    func testAddbackRowsCarryAddedBackLabel() async throws {
        let profile = LenderProfile(
            appleUserID: "apple.se.addback.\(UUID().uuidString)",
            firstName: "Nick",
            lastName: "Gallick",
            nmlsId: "1428391",
            licensedStates: ["CA"],
            companyName: "Gallick Holdings LLC",
            phone: "(415) 555-0123",
            email: "nick@example.com"
        )
        let borrower = Borrower(firstName: "Jane", lastName: "Doe",
                                propertyState: "CA", source: .manual)
        let vm = SelfEmploymentViewModel()
        vm.borrower = borrower
        vm.compute()
        guard let output = vm.output, !output.year1.addbacks.isEmpty else {
            throw XCTSkip("Default inputs produced no addbacks — 5H.2 label check skipped")
        }

        let url = try await PDFBuilder.buildSelfEmploymentPDF(
            profile: profile,
            borrower: borrower,
            viewModel: vm
        )
        let doc = try XCTUnwrap(PDFDocument(url: url))
        let full = (0..<doc.pageCount)
            .compactMap { doc.page(at: $0)?.string }
            .joined(separator: "\n")
        XCTAssertTrue(full.contains("added back"),
                      "Addback rows should be labeled '— added back' (5H.2)")
    }
}
