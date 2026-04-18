import Testing
import SwiftUI
import Foundation
@testable import QuotientPDF

@Suite("QuotientPDF")
struct PDFRendererTests {

    @Test("renderPDF produces a readable PDFKit document")
    @MainActor
    func testRenderBasicPDF() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("quotient-test-\(UUID()).pdf")
        let pages: [AnyView] = [
            AnyView(Text("Page One").frame(width: 612, height: 792)),
            AnyView(Text("Page Two").frame(width: 612, height: 792)),
        ]
        try PDFRenderer.renderPDF(pages: pages, to: url)
        let inspector = try #require(PDFInspector(url: url))
        #expect(inspector.pageCount == 2)
    }

    @Test("PDFInspector returns nil for missing file")
    func testMissingFile() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("does-not-exist.pdf")
        #expect(PDFInspector(url: url) == nil)
    }
}
