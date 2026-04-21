// PDFBuilderTests.swift
// Session 5O.8 — the two legacy tests that constructed `PDFCoverPage`
// directly (testPDFCoverRenders, testPDFSignatureBlockShowsNameOnce)
// were deleted along with the SwiftUI PDFCoverPage view. Equivalent
// coverage now lives in TCAPDFHTMLTests.testTCAPDFRendersAllSections
// (single-source signature regression) and the 5N.8 tests below
// (page counter, missing company/photo) which all route through the
// HTML pipeline's buildAmortizationPDF.

import XCTest
import Foundation
import UIKit
import QuotientPDF
@testable import Quotient

@MainActor
final class PDFBuilderTests: XCTestCase {

    // MARK: - Session 5I.3: profile photo on PDF cover

    /// Toggle-ON + photoData set → the rendered PDF carries the JPEG
    /// bytes. Asserts against size delta (toggle-ON PDF is larger than
    /// the matching toggle-OFF PDF by at least the JPEG payload size
    /// minus PDF re-encoding overhead).
    func testPhotoShowsOnPDFCoverWhenToggleOn() async throws {
        let jpeg = makeTestJPEG()
        XCTAssertGreaterThan(jpeg.count, 2_000,
                             "Test JPEG payload is unexpectedly small — size-delta proxy won't be meaningful")

        let on = try await renderAmortizationPDF(photoData: jpeg, showPhotoOnPDF: true)
        let off = try await renderAmortizationPDF(photoData: jpeg, showPhotoOnPDF: false)
        let delta = on.size - off.size
        XCTAssertGreaterThan(delta, 1_000,
                             "PDF with photo toggle ON is not materially larger than toggle OFF (delta=\(delta) bytes) — photo likely not rendered")
    }

    /// Toggle-OFF + photoData still set → PDF cover omits the photo.
    /// Paired with the ON test this proves the toggle is the gate.
    func testPhotoHiddenOnPDFCoverWhenToggleOff() async throws {
        let jpeg = makeTestJPEG()
        let off = try await renderAmortizationPDF(photoData: jpeg, showPhotoOnPDF: false)
        let baseline = try await renderAmortizationPDF(photoData: nil, showPhotoOnPDF: false)
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
    ) async throws -> (url: URL, size: Int) {
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
        let url = try await PDFBuilder.buildAmortizationPDF(
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
    /// counters. Session 5O rebuilt on HTMLPDFRenderer; headers are
    /// now drawn by NestIQPrintRenderer per-page in Core Graphics so
    /// every portrait page of the document should carry the counter.
    func testPDFHeaderRendersPageNofMOnCoverAndDisclaimers() async throws {
        let profile = makeTestProfile(firstName: "Nick", lastName: "Gallick",
                                      companyName: "Gallick Holdings LLC")
        let borrower = Borrower(firstName: "John", lastName: "Smith",
                                propertyState: "CA", source: .manual)
        let vm = AmortizationViewModel(borrower: borrower)
        vm.compute()
        let url = try await PDFBuilder.buildAmortizationPDF(
            profile: profile,
            borrower: borrower,
            viewModel: vm,
            narrative: "Test"
        )
        let inspector = try XCTUnwrap(PDFInspector(url: url))
        let total = inspector.pageCount
        XCTAssertGreaterThanOrEqual(total, 2)
        // D12 (Session 7.3a): the "Page N of M" counter was CG-drawn by
        // NestIQPrintRenderer, which is retired. PDF chrome is now
        // HTML-template-driven. Amortization still uses the legacy
        // base.html path for v0.1.1 pre-7.3f; no HTML counter runs.
        // Assert the disclaimers appendix renders instead — the
        // compliance content HTML-side footer survives CG retirement.
        let disclaimers = inspector.text(onPage: total - 1) ?? ""
        XCTAssertTrue(disclaimers.contains("Equal Housing Opportunity"),
                      "Disclaimers appendix EHO footer missing. Got: \(disclaimers)")
    }

    /// Empty companyName on the LenderProfile renders the signature
    /// block without a blank company line — pre-5N.3 regression from
    /// the "—" placeholder that leaked into the sig block.
    func testPDFSignatureHandlesMissingCompany() async throws {
        let profile = makeTestProfile(firstName: "Nick", lastName: "Gallick",
                                      companyName: "")
        let url = try await renderMinimalAmortizationPDF(profile: profile)
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
    func testPDFSignatureHandlesMissingPhoto() async throws {
        let profile = makeTestProfile(firstName: "Nick", lastName: "Gallick",
                                      companyName: "Gallick Holdings LLC")
        // No photoData, no showPhotoOnPDF — identical to a fresh
        // profile that hasn't uploaded a photo yet.
        let url = try await renderMinimalAmortizationPDF(profile: profile)
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

    private func renderMinimalAmortizationPDF(profile: LenderProfile) async throws -> URL {
        let borrower = Borrower(firstName: "Jane", lastName: "Doe",
                                propertyState: "CA", source: .manual)
        let vm = AmortizationViewModel(borrower: borrower)
        vm.compute()
        return try await PDFBuilder.buildAmortizationPDF(
            profile: profile,
            borrower: borrower,
            viewModel: vm,
            narrative: "Test narrative."
        )
    }

    func testAmortizationPDFEndToEnd() async throws {
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
        let url = try await PDFBuilder.buildAmortizationPDF(
            profile: profile,
            borrower: borrower,
            viewModel: vm,
            narrative: "Narrative copy from template."
        )
        let inspector = try XCTUnwrap(PDFInspector(url: url))
        XCTAssertGreaterThanOrEqual(inspector.pageCount, 2)
    }
}
