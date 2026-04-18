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

    /// Render an ordered set of SwiftUI pages to a PDF file at
    /// `fileURL`. Each page is rendered at letter size.
    @MainActor
    public static func renderPDF<Page: View>(
        pages: [Page],
        to fileURL: URL
    ) throws {
        var mediaBox = CGRect(origin: .zero, size: letterSize)
        guard let context = CGContext(fileURL as CFURL, mediaBox: &mediaBox, nil) else {
            throw PDFRendererError.couldNotCreateContext
        }

        for page in pages {
            context.beginPDFPage(nil)
            let renderer = ImageRenderer(
                content: page.frame(width: letterSize.width,
                                    height: letterSize.height)
            )
            renderer.proposedSize = .init(letterSize)
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
