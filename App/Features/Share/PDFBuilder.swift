// PDFBuilder.swift
// Assembles a PDF for any calculator: cover page (hero KPIs + narrative)
// + state-specific disclaimers appendix from QuotientCompliance.
// Per-calculator body pages (schedule, comparison tables, stress paths)
// are deferred to Session 5's polish pass where the on-screen views are
// re-used at print dimensions.

import SwiftUI
import Foundation
import QuotientPDF
import QuotientCompliance
import QuotientFinance

@MainActor
enum PDFBuilder {

    /// Calculator-agnostic composition payload.
    struct Payload {
        let calculatorSlug: String            // used for temp filename
        let calculatorTitle: String           // printed on the cover eyebrow
        let complianceScenarioType: ScenarioType
        let loanSummary: String               // mono-line under the "For *Name*"
        let heroLabel: String                 // "Monthly payment · PITI" etc
        let heroValue: String                 // e.g. "4,207"
        let heroValuePrefix: String           // "$" for money, "" for rate
        let heroValueSuffix: String           // "%" for rate, "" for money
        let heroKPIs: [(label: String, value: String)]
        let narrative: String

        init(
            calculatorSlug: String,
            calculatorTitle: String,
            complianceScenarioType: ScenarioType,
            loanSummary: String,
            heroLabel: String,
            heroValue: String,
            heroValuePrefix: String = "$",
            heroValueSuffix: String = "",
            heroKPIs: [(label: String, value: String)],
            narrative: String
        ) {
            self.calculatorSlug = calculatorSlug
            self.calculatorTitle = calculatorTitle
            self.complianceScenarioType = complianceScenarioType
            self.loanSummary = loanSummary
            self.heroLabel = heroLabel
            self.heroValue = heroValue
            self.heroValuePrefix = heroValuePrefix
            self.heroValueSuffix = heroValueSuffix
            self.heroKPIs = heroKPIs
            self.narrative = narrative
        }
    }

    static func buildPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        payload: Payload,
        extraPages: [(AnyView, PDFRenderer.Orientation)] = []
    ) throws -> URL {
        let url = temporaryURL(for: payload.calculatorSlug)
        // Total pages known up front: cover + extras + disclaimers.
        let total = 1 + extraPages.count + 1
        let cover = AnyView(coverPage(
            profile: profile,
            borrower: borrower,
            payload: payload,
            pageIndex: 1,
            pageCount: total
        ))
        let disclaimers = AnyView(disclaimersPage(
            profile: profile,
            borrower: borrower,
            scenarioType: payload.complianceScenarioType,
            pageIndex: total,
            pageCount: total
        ))
        var pages: [(AnyView, PDFRenderer.Orientation)] = [(cover, .portrait)]
        pages.append(contentsOf: extraPages)
        pages.append((disclaimers, .portrait))
        try PDFRenderer.renderMixed(pages: pages, to: url)
        return url
    }

    // MARK: Per-calculator convenience builders

    /// Session 5O.2 — rebuilt to render via HTMLPDFRenderer
    /// (UIPrintPageRenderer + WKWebView.viewPrintFormatter). Async
    /// because WKWebView HTML loading is async.
    static func buildAmortizationPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: AmortizationViewModel,
        narrative: String,
        scheduleGranularity: AmortScheduleGranularity = .yearly
    ) async throws -> URL {
        let html = AmortizationPDFHTML.buildHTML(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            narrative: narrative,
            scheduleGranularity: scheduleGranularity
        )
        let url = PDFHTMLComposition.temporaryURL(for: "amortization")
        try await HTMLPDFRenderer.shared.renderPDF(html: html, to: url)
        return url
    }

    /// Session 5O.6 — IncomeQualification PDF via HTML pipeline.
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

    /// Session 5O.4 — Refinance PDF now renders via HTML pipeline.
    static func buildRefinancePDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: RefinanceViewModel,
        narrative: String
    ) async throws -> URL {
        let html = RefinancePDFHTML.buildHTML(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            narrative: narrative
        )
        let url = PDFHTMLComposition.temporaryURL(for: "refinance")
        try await HTMLPDFRenderer.shared.renderPDF(html: html, to: url)
        return url
    }

    /// Session 5O.3 — TCA PDF now renders via HTML pipeline.
    /// Break-even chart is embedded as inline SVG per scenario
    /// (BreakEvenChartSVG).
    static func buildTCAPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: TCAViewModel,
        narrative: String
    ) async throws -> URL {
        let html = TCAPDFHTML.buildHTML(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            narrative: narrative
        )
        let url = PDFHTMLComposition.temporaryURL(for: "total-cost")
        try await HTMLPDFRenderer.shared.renderPDF(html: html, to: url)
        return url
    }

    /// Session 5O.5 — HELOC PDF now renders via HTML pipeline.
    static func buildHelocPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: HelocViewModel,
        narrative: String
    ) async throws -> URL {
        let html = HelocPDFHTML.buildHTML(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            narrative: narrative
        )
        let url = PDFHTMLComposition.temporaryURL(for: "heloc")
        try await HTMLPDFRenderer.shared.renderPDF(html: html, to: url)
        return url
    }

    // `buildSelfEmploymentPDF` lives in PDFBuilder+SelfEmployment.swift
    // to keep this enum under SwiftLint's type_body_length cap.

    private static func helocComparisonPage(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: HelocViewModel,
        pageIndex: Int,
        pageCount: Int
    ) -> some View {
        let generated = PDFPageHeader.formatDate(Date())
        let rows = HelocComparisonPage.rows(for: viewModel)
        let state = resolveState(borrower: borrower)
        let disclosures = requiredDisclosures(
            for: .helocVsRefinance,
            propertyState: state ?? .CA
        )
        let disclaimer = disclosures.first?.textEN ?? defaultDisclaimer()
        let ehoStatement = equalHousingOpportunityStatement(locale: Locale(identifier: "en_US"))
        let nmlsLine: String = {
            switch profile.nmlsDisplayFormat {
            case .idOnly: return "NMLS \(profile.nmlsId)"
            case .idAndURL: return "NMLS \(profile.nmlsId) · nmlsconsumeraccess.org"
            case .none: return ""
            }
        }()
        let blended10yr = viewModel.blendedRateAtTenYears
        let verdict = blended10yr < viewModel.inputs.refiRate ? "keep 1st" : "refi wins"
        return HelocComparisonPage(
            borrowerName: borrower?.fullName ?? "Client",
            generatedDate: generated,
            loFullName: profile.fullName.isEmpty ? "Loan Officer" : profile.fullName,
            loNMLSLine: nmlsLine,
            rows: rows,
            disclaimer: disclaimer,
            ehoStatement: ehoStatement,
            accentHex: profile.brandColorHex,
            blendedRate10yr: blended10yr,
            refiRate: viewModel.inputs.refiRate,
            verdict: verdict,
            pageIndex: pageIndex,
            pageCount: pageCount
        )
    }

    // Page composition helpers live in PDFBuilder+Pages.swift.

    static func defaultDisclaimer() -> String {
        "This illustration is not a commitment to lend. Rates reflect pricing "
            + "available at the time of generation for qualifying borrowers and may "
            + "change without notice. Actual APR will vary by program, property, "
            + "borrower qualifications, and closing date. See your Loan Estimate "
            + "for final terms."
    }

    static func resolveState(borrower: Borrower?) -> USState? {
        guard let code = borrower?.propertyState?.uppercased() else { return nil }
        return USState(rawValue: code)
    }

    private static func temporaryURL(for calc: String) -> URL {
        let dir = FileManager.default.temporaryDirectory
        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        return dir.appendingPathComponent("quotient-\(calc)-\(stamp).pdf")
    }
}
