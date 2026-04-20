import Testing
import Foundation
import PDFKit
@testable import QuotientPDF

@Suite("QuotientPDF")
struct PDFInspectorTests {

    @Test("PDFInspector reads a valid PDF")
    func testReadsPDF() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("quotient-test-\(UUID()).pdf")
        // Write a minimal PDF using UIGraphicsBeginPDFContext equivalent
        // via PDFKit: create an empty PDFDocument + PDFPage, save to disk.
        let doc = PDFDocument()
        let page = PDFPage()
        doc.insert(page, at: 0)
        doc.insert(PDFPage(), at: 1)
        try #require(doc.write(to: url))

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
