// QuotientPDF
//
// Render SwiftUI views to PDF via ImageRenderer + CGContext.pdfContext,
// then assemble into a PDF file. A full PDF is cover + per-calculator
// body + disclaimers appendix.

import Foundation
import SwiftUI
import PDFKit

public enum PDFRenderer {

    /// US Letter in points at 72 DPI: 8.5×11 → 612×792.
    public static let letterSize = CGSize(width: 612, height: 792)
    /// US Letter rotated — landscape comparison pages.
    public static let landscapeSize = CGSize(width: 792, height: 612)

    /// Per-page orientation. Determines the mediaBox and the
    /// ImageRenderer frame size when the page is drawn.
    public enum Orientation: Sendable {
        case portrait, landscape
        public var size: CGSize {
            switch self {
            case .portrait:  return letterSize
            case .landscape: return landscapeSize
            }
        }
    }

    /// Render an ordered set of SwiftUI pages to a PDF file at
    /// `fileURL`. Each page is rendered at letter size.
    @MainActor
    public static func renderPDF<Page: View>(
        pages: [Page],
        to fileURL: URL
    ) throws {
        try renderMixed(
            pages: pages.map { ($0, Orientation.portrait) },
            to: fileURL
        )
    }

    /// Render a sequence of (view, orientation) pages. Each page
    /// resets its mediaBox, so portrait and landscape pages can
    /// coexist in one document — which is how side-by-side
    /// comparisons land next to portrait covers / schedules.
    @MainActor
    public static func renderMixed<Page: View>(
        pages: [(Page, Orientation)],
        to fileURL: URL
    ) throws {
        var initial = CGRect(origin: .zero, size: letterSize)
        guard let context = CGContext(fileURL as CFURL, mediaBox: &initial, nil) else {
            throw PDFRendererError.couldNotCreateContext
        }

        for (page, orientation) in pages {
            let size = orientation.size
            var mediaBox = CGRect(origin: .zero, size: size)
            let pageInfo = [
                kCGPDFContextMediaBox as String: Data(
                    bytes: &mediaBox,
                    count: MemoryLayout<CGRect>.size
                )
            ]
            context.beginPDFPage(pageInfo as CFDictionary)
            let renderer = ImageRenderer(
                content: page.frame(width: size.width, height: size.height)
            )
            renderer.proposedSize = .init(size)
            renderer.render { _, drawer in
                context.saveGState()
                drawer(context)
                context.restoreGState()
            }
            context.endPDFPage()
        }
        context.closePDF()
    }

    public enum PDFRendererError: Error, Sendable {
        case couldNotCreateContext
    }
}

/// Minimal PDFKit-backed inspector for unit + UI tests.
public struct PDFInspector {
    public let document: PDFDocument

    public init?(url: URL) {
        guard let doc = PDFDocument(url: url) else { return nil }
        self.document = doc
    }

    public var pageCount: Int { document.pageCount }

    public func text(onPage index: Int) -> String? {
        document.page(at: index)?.string
    }
}
