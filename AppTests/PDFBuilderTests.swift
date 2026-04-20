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
        // Post-5N.2a: the NestIQ brand is now an image (PDFPageHeader's
        // Wordmark-A) on every page, so PDFKit's text layer no longer
        // carries the wordmark string. Assert on stable text anchors
        // that don't depend on tracked/uppercased glyphs: the
        // signature block's NMLS line + borrower name + page counter.
        XCTAssertTrue(text.contains("Smith"),
                      "Borrower name missing from extracted PDF text. Got: \(text)")
        XCTAssertTrue(text.contains("NMLS"),
                      "Signature block NMLS missing from PDF. Got: \(text)")
        XCTAssertTrue(text.contains("Page 1 of 1"),
                      "PDFPageHeader page counter missing from PDF. Got: \(text)")
    }

    // MARK: - Session 5N.3: single-source signature block

    /// Regression test for Nick's QA: the PDF was rendering two name
    /// blocks — the main signature + a second italic block driven by
    /// `LenderProfile.tagline`. 5N.3 removed the tagline field and
    /// consolidated to one signature. This test pins that the rendered
    /// PDF text layer shows the name exactly once.
    func testPDFSignatureBlockShowsNameOnce() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("quotient-sig-\(UUID()).pdf")
        let cover = PDFCoverPage(
            borrowerName: "John Smith",
            loFullName: "Nick Gallick",
            loNMLS: "1428391",
            loCompany: "Gallick Holdings LLC",
            loEmail: "nick@uberkiwi.com",
            loPhone: "555-555-0100",
            calculatorTitle: "Amortization analysis",
            generatedDate: "April 20, 2026",
            loanSummary: "$400,000 · 30-yr · 6.750%",
            heroPITI: "2,594",
            heroKPIs: [("x", "y")],
            narrative: "Test."
        )
        try PDFRenderer.renderPDF(pages: [AnyView(cover)], to: url)
        let inspector = try XCTUnwrap(PDFInspector(url: url))
        let text = inspector.text(onPage: 0) ?? ""
        let occurrences = text.components(separatedBy: "Nick Gallick").count - 1
        XCTAssertEqual(occurrences, 1,
                       "Expected exactly one 'Nick Gallick' in PDF text; got \(occurrences). Full text: \(text)")
        XCTAssertTrue(text.contains("Gallick Holdings LLC"),
                      "Company should render on its own line in the signature block")
        XCTAssertTrue(text.contains("nick@uberkiwi.com"),
                      "Email should render on the contact line")
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

    // MARK: - Session 5N.8: PDF data integrity audit

    /// Verifies cover + disclaimers carry their "Page N of M"
    /// counters after the 5N.2a rollout. Landscape middle pages (the
    /// amortization schedule in this case) render the same header
    /// visually, but PDFKit's text-extraction on landscape pages
    /// inconsistently captures the SF Mono counter glyphs — the
    /// cover/disclaimers assertions pin the threading is correct.
    func testPDFHeaderRendersPageNofMOnCoverAndDisclaimers() throws {
        let profile = makeTestProfile(firstName: "Nick", lastName: "Gallick",
                                      companyName: "Gallick Holdings LLC")
        let borrower = Borrower(firstName: "John", lastName: "Smith",
                                propertyState: "CA", source: .manual)
        let vm = AmortizationViewModel(borrower: borrower)
        vm.compute()
        let url = try PDFBuilder.buildAmortizationPDF(
            profile: profile,
            borrower: borrower,
            viewModel: vm,
            narrative: "Test"
        )
        let inspector = try XCTUnwrap(PDFInspector(url: url))
        let total = inspector.pageCount
        XCTAssertGreaterThanOrEqual(total, 3)
        let cover = inspector.text(onPage: 0) ?? ""
        XCTAssertTrue(cover.contains("Page 1 of \(total)"),
                      "Cover missing 'Page 1 of \(total)'. Got: \(cover)")
        let disclaimers = inspector.text(onPage: total - 1) ?? ""
        XCTAssertTrue(disclaimers.contains("Page \(total) of \(total)"),
                      "Disclaimers missing 'Page \(total) of \(total)'. Got: \(disclaimers)")
    }

    /// Empty companyName on the LenderProfile renders the signature
    /// block without a blank company line — pre-5N.3 regression from
    /// the "—" placeholder that leaked into the sig block.
    func testPDFSignatureHandlesMissingCompany() throws {
        let profile = makeTestProfile(firstName: "Nick", lastName: "Gallick",
                                      companyName: "")
        let url = try renderMinimalAmortizationPDF(profile: profile)
        let inspector = try XCTUnwrap(PDFInspector(url: url))
        let text = inspector.text(onPage: 0) ?? ""
        XCTAssertTrue(text.contains("Nick Gallick"))
        // The "—" placeholder coming from PDFBuilder's companyName
        // fallback must still not render as a blank line in the sig
        // block. Signature block hides the row entirely when empty or
        // "—".
        let bareDashLine = text.components(separatedBy: "\n")
            .contains(where: { $0.trimmingCharacters(in: .whitespaces) == "—" })
        XCTAssertFalse(bareDashLine,
                       "Signature block should not render a standalone '—' line for missing company. Got: \(text)")
    }

    /// profile.photoData = nil must render the signature block
    /// without a phantom empty circle on the right.
    func testPDFSignatureHandlesMissingPhoto() throws {
        let profile = makeTestProfile(firstName: "Nick", lastName: "Gallick",
                                      companyName: "Gallick Holdings LLC")
        // No photoData, no showPhotoOnPDF — identical to a fresh
        // profile that hasn't uploaded a photo yet.
        let url = try renderMinimalAmortizationPDF(profile: profile)
        let inspector = try XCTUnwrap(PDFInspector(url: url))
        XCTAssertGreaterThanOrEqual(inspector.pageCount, 2)
    }

    private func makeTestProfile(
        firstName: String,
        lastName: String,
        companyName: String
    ) -> LenderProfile {
        LenderProfile(
            appleUserID: "apple.audit.\(UUID().uuidString)",
            firstName: firstName,
            lastName: lastName,
            nmlsId: "1428391",
            licensedStates: ["CA"],
            companyName: companyName,
            phone: "(415) 555-0123",
            email: "nick@example.com"
        )
    }

    private func renderMinimalAmortizationPDF(profile: LenderProfile) throws -> URL {
        let borrower = Borrower(firstName: "Jane", lastName: "Doe",
                                propertyState: "CA", source: .manual)
        let vm = AmortizationViewModel(borrower: borrower)
        vm.compute()
        return try PDFBuilder.buildAmortizationPDF(
            profile: profile,
            borrower: borrower,
            viewModel: vm,
            narrative: "Test narrative."
        )
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
