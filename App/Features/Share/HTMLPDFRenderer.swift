// HTMLPDFRenderer.swift
// HTML-to-PDF pipeline (Session 5O / D8).
//
// WKWebView's `createPDF(configuration:)` does not support CSS Paged
// Media — no @page running headers, no counter(page). So we render
// via UIPrintPageRenderer + WKWebView.viewPrintFormatter(): WebKit
// paginates the body HTML, and we draw the NestIQ header + footer
// per-page in Core Graphics (see NestIQPrintRenderer).
//
// Named `HTMLPDFRenderer` during the 5O.2–5O.7 migration to avoid
// ambiguity with the legacy `QuotientPDF.PDFRenderer` enum. 5O.8
// deletes the legacy package.

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

    /// Render HTML to a multi-page PDF Data. Caller provides the full
    /// HTML document; header + footer are drawn by
    /// NestIQPrintRenderer per-page.
    func renderPDF(
        html: String,
        pageSize: CGSize = usLetter
    ) async throws -> Data {
        let webView = try await loadedWebView(html: html, pageSize: pageSize)
        return pdfData(from: webView, pageSize: pageSize)
    }

    /// Render HTML straight to a file URL. Convenience for callers
    /// that need a URL for ShareSheet / QuickLook.
    func renderPDF(
        html: String,
        to url: URL,
        pageSize: CGSize = usLetter
    ) async throws {
        let data = try await renderPDF(html: html, pageSize: pageSize)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Private

    private func loadedWebView(
        html: String,
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
            webView.loadHTMLString(html, baseURL: nil)
        }
        return webView
    }

    private func pdfData(from webView: WKWebView, pageSize: CGSize) -> Data {
        let printRenderer = NestIQPrintRenderer()
        printRenderer.addPrintFormatter(
            webView.viewPrintFormatter(),
            startingAtPageAt: 0
        )
        let paperRect = CGRect(origin: .zero, size: pageSize)
        // 0.75" side margins; top/bottom reserve space for header +
        // footer (headerHeight / footerHeight live on the renderer).
        let sideMargin: CGFloat = 54   // 0.75" × 72
        let topMargin: CGFloat = 72    // 1.0" — header band drawn in top ~50pt
        let bottomMargin: CGFloat = 54 // 0.75" — footer band drawn in bottom ~40pt
        let printableRect = CGRect(
            x: sideMargin,
            y: topMargin,
            width: pageSize.width - sideMargin * 2,
            height: pageSize.height - topMargin - bottomMargin
        )
        printRenderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        printRenderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
        let pageCount = printRenderer.numberOfPages
        for pageIndex in 0..<pageCount {
            UIGraphicsBeginPDFPage()
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
