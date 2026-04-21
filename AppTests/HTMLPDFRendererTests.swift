// HTMLPDFRendererTests.swift
// Session 5O.1 — foundation smoke tests for the HTML-to-PDF pipeline
// (WKWebView viewPrintFormatter + UIPrintPageRenderer).
//
// Scope pinned here: template loading, interpolation, rendering
// produces a valid multi-page PDF with Core Graphics header/footer
// reserved via headerHeight / footerHeight. Per-calculator HTML
// builders + SVG chart tests land in 5O.2–5O.7 / 5O.9.

import XCTest
import PDFKit
import UIKit
@testable import Quotient

@MainActor
final class HTMLPDFRendererTests: XCTestCase {

    func testBaseHTMLTemplateLoadsFromBundle() throws {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "base", withExtension: "html"),
            "base.html not found in main bundle — PDFTemplates resource folder may not be wired into the Xcode project"
        )
        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(contents.contains("{{CONTENT}}"),
                      "base.html missing CONTENT placeholder")
        XCTAssertTrue(contents.contains("--accent: #1F4D3F"),
                      "base.html missing NestIQ accent token")
    }

    func testSignatureBlockTemplateLoadsFromBundle() throws {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "SignatureBlock", withExtension: "html"),
            "SignatureBlock.html not found in main bundle"
        )
        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(contents.contains("{{NAME}}"))
        XCTAssertTrue(contents.contains("{{CONTACT_LINE}}"))
    }

    func testInterpolateReplacesNamedPlaceholders() {
        let renderer = HTMLPDFRenderer.shared
        let out = renderer.interpolate(
            template: "Hello {{NAME}}, welcome to {{BRAND}}.",
            values: ["NAME": "Nick", "BRAND": "NestIQ"]
        )
        XCTAssertEqual(out, "Hello Nick, welcome to NestIQ.")
    }

    func testInterpolateLeavesUnknownPlaceholdersVisible() {
        // Missing keys stay as `{{KEY}}` so a failed binding is
        // obvious in the rendered PDF rather than silently blank.
        let renderer = HTMLPDFRenderer.shared
        let out = renderer.interpolate(
            template: "A={{A}} B={{B}}",
            values: ["A": "1"]
        )
        XCTAssertEqual(out, "A=1 B={{B}}")
    }

    func testRendererProducesValidSinglePagePDF() async throws {
        let html = wrapInBaseTemplate(body: """
            <p class="eyebrow">HTML PDF · Smoke test</p>
            <h1>Hello <em>NestIQ</em></h1>
            <p class="summary-text">This is a single-page smoke test.</p>
        """)
        let data = try await HTMLPDFRenderer.shared.renderPDF(html: html)
        XCTAssertGreaterThan(data.count, 500,
                             "PDF data should have non-trivial size; got \(data.count) bytes")
        let doc = try XCTUnwrap(PDFDocument(data: data),
                                "Renderer output is not a valid PDF")
        XCTAssertEqual(doc.pageCount, 1,
                       "Short content should render to 1 page; got \(doc.pageCount)")
    }

    func testRendererPaginatesLongContentAcrossMultiplePages() async throws {
        // 40 rows × ~24pt each easily overflows one Letter printable
        // rect (~668pt tall after header/footer margins).
        var rowsHTML = ""
        for i in 1...60 {
            rowsHTML += """
                <div class="row">
                  <div><div class="label">Row</div><div class="value">#\(i)</div></div>
                  <div><div class="label">Payment</div><div class="value">$1,234.56</div></div>
                  <div><div class="label">Interest</div><div class="value">$987.65</div></div>
                </div>
            """
        }
        let html = wrapInBaseTemplate(body: """
            <p class="eyebrow">HTML PDF · Pagination smoke</p>
            <h1>Multi-page content</h1>
            \(rowsHTML)
        """)
        let data = try await HTMLPDFRenderer.shared.renderPDF(html: html)
        let doc = try XCTUnwrap(PDFDocument(data: data))
        XCTAssertGreaterThan(doc.pageCount, 1,
                             "60 rows should paginate across >1 page; got \(doc.pageCount)")

        // D12 (Session 7.3a): CG-drawn per-page "Page N of M" + footer
        // URL retired. Pagination itself is still verifiable via
        // doc.pageCount assertion above; nothing left to check here.
    }

    // MARK: - Helpers

    private func wrapInBaseTemplate(body: String) -> String {
        guard let url = Bundle.main.url(forResource: "base", withExtension: "html"),
              let template = try? String(contentsOf: url, encoding: .utf8) else {
            XCTFail("base.html missing from bundle")
            return ""
        }
        return template.replacingOccurrences(of: "{{CONTENT}}", with: body)
    }
}
