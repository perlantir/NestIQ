// HTMLPDFRenderer.swift
// HTML-to-PDF pipeline (Session 5O / D8; amended Session 7 / D12).
//
// WKWebView's `createPDF(configuration:)` does not support CSS Paged
// Media — no @page running headers, no counter(page). So we render
// via UIPrintPageRenderer + WKWebView.viewPrintFormatter(): WebKit
// paginates the body HTML.
//
// Per D12 (Session 7, 2026-04-21) the v2.1.1 with-masthead templates
// render the masthead, header, and pagefoot directly in HTML. The old
// NestIQPrintRenderer subclass that drew the chrome in Core Graphics
// is retired; we now use UIPrintPageRenderer directly and let the
// template fill the entire printable area.

import UIKit
import WebKit

@MainActor
final class HTMLPDFRenderer {

    static let shared = HTMLPDFRenderer()

    /// US Letter in PDF points (72 dpi). 8.5" × 11" = 612 × 792.
    static let usLetter = CGSize(width: 612, height: 792)

    /// Interpolate a mustache-style template. `{{KEY}}` → value.
    /// Missing keys are left in place so a failed interpolation is
    /// visible in the output rather than silently blank.
    func interpolate(template: String, values: [String: String]) -> String {
        var result = template
        for (key, value) in values {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return result
    }

    /// Render HTML to a multi-page PDF Data.
    ///
    /// `baseURL` is passed through to `WKWebView.loadHTMLString(_:baseURL:)`
    /// — when the HTML uses relative `<link href="…">` for external CSS or
    /// fonts, this must point at a folder URL WebKit can resolve against.
    /// Pass `nil` for HTML with fully self-contained resources.
    func renderPDF(
        html: String,
        baseURL: URL? = nil,
        pageSize: CGSize = usLetter
    ) async throws -> Data {
        let webView = try await loadedWebView(html: html, baseURL: baseURL, pageSize: pageSize)
        return pdfData(from: webView, pageSize: pageSize)
    }

    /// Render HTML straight to a file URL. Convenience for callers
    /// that need a URL for ShareSheet / QuickLook.
    func renderPDF(
        html: String,
        to url: URL,
        baseURL: URL? = nil,
        pageSize: CGSize = usLetter
    ) async throws {
        let data = try await renderPDF(html: html, baseURL: baseURL, pageSize: pageSize)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Private

    private func loadedWebView(
        html: String,
        baseURL: URL?,
        pageSize: CGSize
    ) async throws -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(
            frame: CGRect(origin: .zero, size: pageSize),
            configuration: config
        )
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, any Error>) in
            let delegate = LoadDelegate(continuation: cont)
            objc_setAssociatedObject(webView, LoadDelegate.key, delegate, .OBJC_ASSOCIATION_RETAIN)
            webView.navigationDelegate = delegate
            webView.loadHTMLString(html, baseURL: baseURL)
        }
        return webView
    }

    /// Paper background for the PDF page. Per user ask 2026-04-20 this
    /// is pure white; the prior cream (#FAF9F5) left a visible tan
    /// field on the PDF. Templates render on top of this fill.
    private static let paperFillColor = UIColor.white

    private func pdfData(from webView: WKWebView, pageSize: CGSize) -> Data {
        let printRenderer = UIPrintPageRenderer()
        printRenderer.addPrintFormatter(
            webView.viewPrintFormatter(),
            startingAtPageAt: 0
        )
        // Template owns all margins post-D12 — the HTML <article class="page">
        // holds its own padding. We give WebKit the full US Letter canvas.
        let paperRect = CGRect(origin: .zero, size: pageSize)
        let printableRect = paperRect
        printRenderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        printRenderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
        let pageCount = printRenderer.numberOfPages
        for pageIndex in 0..<pageCount {
            UIGraphicsBeginPDFPage()
            if let ctx = UIGraphicsGetCurrentContext() {
                ctx.setFillColor(Self.paperFillColor.cgColor)
                ctx.fill(paperRect)
            }
            printRenderer.drawPage(at: pageIndex, in: paperRect)
        }
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
}

private final class LoadDelegate: NSObject, WKNavigationDelegate {
    static let key = "nestiq.pdfrenderer.loaddelegate"
    private var continuation: CheckedContinuation<Void, any Error>?
    init(continuation: CheckedContinuation<Void, any Error>) {
        self.continuation = continuation
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Short delay lets WebKit complete layout + font load before
        // UIPrintPageRenderer asks for pages.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.continuation?.resume()
            self?.continuation = nil
        }
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: any Error
    ) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: any Error
    ) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
