// PDFBuilder.swift
// Session 5O / D8 — HTML-to-PDF entry points for each calculator.
// Each per-calculator builder composes a body HTML fragment via its
// dedicated *PDFHTML module, wraps it in base.html via
// PDFHTMLComposition, and renders via HTMLPDFRenderer
// (UIPrintPageRenderer + WKWebView.viewPrintFormatter). NestIQ header
// + per-page footer are drawn by NestIQPrintRenderer in Core Graphics.

import Foundation

@MainActor
enum PDFBuilder {

    static func buildAmortizationPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: AmortizationViewModel,
        scheduleGranularity: AmortScheduleGranularity = .yearly
    ) async throws -> URL {
        let html = try AmortizationPDFHTML.buildHTML(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            scheduleGranularity: scheduleGranularity
        )
        let url = PDFHTMLComposition.temporaryURL(for: "amortization")
        try await HTMLPDFRenderer.shared.renderPDF(
            html: html,
            to: url,
            baseURL: try PDFTemplateLoader.templatesFolderURL
        )
        return url
    }

    static func buildRefinancePDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: RefinanceViewModel,
        narrative: String
    ) async throws -> URL {
        let html = try RefinancePDFHTML.buildHTML(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            narrative: narrative
        )
        let url = PDFHTMLComposition.temporaryURL(for: "refinance")
        try await HTMLPDFRenderer.shared.renderPDF(
            html: html,
            to: url,
            baseURL: try PDFTemplateLoader.templatesFolderURL
        )
        return url
    }

    static func buildTCAPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: TCAViewModel
    ) async throws -> URL {
        let html = try TCAPDFHTML.buildHTML(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel
        )
        let url = PDFHTMLComposition.temporaryURL(for: "total-cost")
        try await HTMLPDFRenderer.shared.renderPDF(
            html: html,
            to: url,
            baseURL: try PDFTemplateLoader.templatesFolderURL
        )
        return url
    }

    static func buildHelocPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: HelocViewModel
    ) async throws -> URL {
        let html = try HelocPDFHTML.buildHTML(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel
        )
        let url = PDFHTMLComposition.temporaryURL(for: "heloc")
        try await HTMLPDFRenderer.shared.renderPDF(
            html: html,
            to: url,
            baseURL: try PDFTemplateLoader.templatesFolderURL
        )
        return url
    }

    // Session 7.4 (compliance / ECOA): PDF export from IncomeQual and
    // SelfEmployment was removed. Those calculators analyze borrower
    // qualification inputs that LOs can't hand to applicants via
    // printed report under Reg B.
}
