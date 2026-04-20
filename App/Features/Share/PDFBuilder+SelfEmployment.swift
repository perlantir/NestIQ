// PDFBuilder+SelfEmployment.swift
// Session 5G.5: Self-Employment PDF composition entry point.
// Session 5O.7 — migrated to HTML pipeline; body composition lives
// in SelfEmploymentPDFHTML. This wrapper preserves the
// PDFBuilder.buildSelfEmploymentPDF call site used by the
// Self-Employment results screen.

import Foundation

extension PDFBuilder {

    static func buildSelfEmploymentPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: SelfEmploymentViewModel
    ) async throws -> URL {
        let html = SelfEmploymentPDFHTML.buildHTML(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel
        )
        let url = PDFHTMLComposition.temporaryURL(for: "self-employment")
        try await HTMLPDFRenderer.shared.renderPDF(html: html, to: url)
        return url
    }
}
