// QuotientPDF
//
// Session 5O.8 — legacy SwiftUI-based PDFRenderer removed. The HTML-to-PDF
// pipeline in the App target (HTMLPDFRenderer + NestIQPrintRenderer) now
// handles all PDF rendering. This package now exposes only the
// PDFInspector wrapper used by callers to read pageCount / text from
// the generated PDFs for the share sheet and tests.

import Foundation
import PDFKit

/// Minimal PDFKit-backed inspector for reading back generated PDFs.
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
