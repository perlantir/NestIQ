// PDFBuilderTests.swift

import XCTest
import Foundation
import SwiftUI
import QuotientPDF
@testable import Quotient

@MainActor
final class PDFBuilderTests: XCTestCase {

    func testPDFCoverRenders() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("quotient-cover-\(UUID()).pdf")
        let cover = PDFCoverPage(
            borrowerName: "John & Maya Smith",
            loFullName: "Nick Moretti",
            loNMLS: "1428391",
            loCompany: "Cascade Lending",
            loEmail: "nick@cascade.com",
            loPhone: "(415) 555-0123",
            calculatorTitle: "Amortization analysis",
            generatedDate: "April 17, 2026",
            loanSummary: "$548,000 · 30-yr fixed · 6.750%",
            heroPITI: "4,207",
            heroKPIs: [
                ("Total interest", "$560,961"),
                ("Payoff", "Mar 2056"),
                ("Total paid", "$1.28M"),
            ],
            narrative: "John and Maya — this is a 30-year fixed on $548,000 at 6.75%."
        )
        try PDFRenderer.renderPDF(pages: [AnyView(cover)], to: url)
        let inspector = try XCTUnwrap(PDFInspector(url: url))
        XCTAssertEqual(inspector.pageCount, 1)
        let text = inspector.text(onPage: 0) ?? ""
        XCTAssertTrue(text.contains("Quotient"))
        XCTAssertTrue(text.contains("Smith"))
    }

    func testAmortizationPDFEndToEnd() throws {
        let profile = LenderProfile(
            appleUserID: "apple.1",
            firstName: "Nick",
            lastName: "Moretti",
            nmlsId: "1428391",
            licensedStates: ["CA", "OR", "WA"],
            companyName: "Cascade Lending",
            phone: "(415) 555-0123",
            email: "nick@cascade.com"
        )
        let borrower = Borrower(
            firstName: "John",
            lastName: "Smith",
            email: "john@example.com",
            propertyState: "CA",
            source: .manual
        )
        let vm = AmortizationViewModel(borrower: borrower)
        vm.compute()
        let url = try PDFBuilder.buildAmortizationPDF(
            profile: profile,
            borrower: borrower,
            viewModel: vm,
            narrative: "Narrative copy from template."
        )
        let inspector = try XCTUnwrap(PDFInspector(url: url))
        XCTAssertGreaterThanOrEqual(inspector.pageCount, 2)
    }
}
