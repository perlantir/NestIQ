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

    static func buildIncomeQualPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: IncomeQualViewModel,
        narrative: String
    ) async throws -> URL {
        let html = IncomeQualPDFHTML.buildHTML(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            narrative: narrative
        )
        let url = PDFHTMLComposition.temporaryURL(for: "income-qualification")
        try await HTMLPDFRenderer.shared.renderPDF(html: html, to: url)
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

    // `buildSelfEmploymentPDF` lives in PDFBuilder+SelfEmployment.swift
    // (kept split to match existing call-site expectations).
}
