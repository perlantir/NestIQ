// PDFBuilderTests.swift

import XCTest
import Foundation
import SwiftUI
import UIKit
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

    // MARK: - Session 5I.3: profile photo on PDF cover

    /// Toggle-ON + photoData set → the rendered PDF carries the JPEG
    /// bytes. Asserts against size delta (toggle-ON PDF is larger than
    /// the matching toggle-OFF PDF by at least the JPEG payload size
    /// minus PDF re-encoding overhead).
    func testPhotoShowsOnPDFCoverWhenToggleOn() throws {
        let jpeg = makeTestJPEG()
        XCTAssertGreaterThan(jpeg.count, 2_000,
                             "Test JPEG payload is unexpectedly small — size-delta proxy won't be meaningful")

        let on = try renderAmortizationPDF(photoData: jpeg, showPhotoOnPDF: true)
        let off = try renderAmortizationPDF(photoData: jpeg, showPhotoOnPDF: false)
        let delta = on.size - off.size
        XCTAssertGreaterThan(delta, 1_000,
                             "PDF with photo toggle ON is not materially larger than toggle OFF (delta=\(delta) bytes) — photo likely not rendered")
    }

    /// Toggle-OFF + photoData still set → PDF cover omits the photo.
    /// Paired with the ON test this proves the toggle is the gate.
    func testPhotoHiddenOnPDFCoverWhenToggleOff() throws {
        let jpeg = makeTestJPEG()
        let off = try renderAmortizationPDF(photoData: jpeg, showPhotoOnPDF: false)
        let baseline = try renderAmortizationPDF(photoData: nil, showPhotoOnPDF: false)
        // No photo ≈ toggle off with photo, within PDF-overhead noise.
        let delta = abs(off.size - baseline.size)
        XCTAssertLessThan(delta, 1_000,
                          "Toggle OFF PDF differs from no-photo baseline by \(delta) bytes — photo may be rendering despite the toggle")
    }

    // MARK: Helpers for the PDF photo tests

    /// Noise-tile image so JPEG can't compress it to near-zero. Solid
    /// colors JPEG down to ~1KB which wouldn't exceed PDF-overhead
    /// noise; a random 16x16 tile grid pushes the payload to ~10KB+.
    private func makeTestJPEG() -> Data {
        let side: CGFloat = 256
        let tile: CGFloat = 16
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        let image = renderer.image { ctx in
            var generator = SystemRandomNumberGenerator()
            for y in stride(from: CGFloat(0), to: side, by: tile) {
                for x in stride(from: CGFloat(0), to: side, by: tile) {
                    let r = CGFloat(UInt8.random(in: 0...255, using: &generator)) / 255
                    let g = CGFloat(UInt8.random(in: 0...255, using: &generator)) / 255
                    let b = CGFloat(UInt8.random(in: 0...255, using: &generator)) / 255
                    UIColor(red: r, green: g, blue: b, alpha: 1).setFill()
                    ctx.fill(CGRect(x: x, y: y, width: tile, height: tile))
                }
            }
        }
        return image.jpegData(compressionQuality: 0.7) ?? Data(repeating: 0x42, count: 8_192)
    }

    private func renderAmortizationPDF(
        photoData: Data?,
        showPhotoOnPDF: Bool
    ) throws -> (url: URL, size: Int) {
        let profile = LenderProfile(
            appleUserID: "apple.photo.\(UUID().uuidString)",
            firstName: "Nick",
            lastName: "Moretti",
            nmlsId: "1428391",
            licensedStates: ["CA"],
            companyName: "Cascade Lending",
            phone: "(415) 555-0123",
            email: "nick@cascade.com",
            showPhotoOnPDF: showPhotoOnPDF
        )
        profile.photoData = photoData
        let borrower = Borrower(firstName: "John", lastName: "Smith",
                                propertyState: "CA", source: .manual)
        let vm = AmortizationViewModel(borrower: borrower)
        vm.compute()
        let url = try PDFBuilder.buildAmortizationPDF(
            profile: profile,
            borrower: borrower,
            viewModel: vm,
            narrative: "Test narrative."
        )
        let size = (try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        return (url, size)
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
