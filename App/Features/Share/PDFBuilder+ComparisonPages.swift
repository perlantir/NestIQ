// PDFBuilder+ComparisonPages.swift
// Landscape comparison-page builders split off from PDFBuilder.swift
// to keep the main enum body under SwiftLint's type_body_length cap.

import SwiftUI
import QuotientCompliance
import QuotientFinance
import QuotientPDF

extension PDFBuilder {

    /// Build the landscape amortization schedule page(s) appropriate to
    /// the active granularity. Yearly emits a single page; monthly
    /// paginates across ~30-row slices with a running header + page
    /// index. MI dropoff marker only renders in purchase mode.
    static func amortizationSchedulePages(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: AmortizationViewModel,
        loanSummary: String,
        granularity: AmortScheduleGranularity,
        globalPageStart: Int,
        globalPageCount: Int
    ) -> [(AnyView, PDFRenderer.Orientation)] {
        guard let schedule = viewModel.schedule else { return [] }
        let generated = PDFPageHeader.formatDate(Date())
        let borrowerName = borrower?.fullName ?? "Client"
        let loFullName = profile.fullName.isEmpty ? "Loan Officer" : profile.fullName
        let nmlsLine = nmlsLineFor(profile: profile)
        let dropoff = viewModel.inputs.mode == .purchase
            ? viewModel.miDropoffPeriod
            : nil
        switch granularity {
        case .yearly:
            let rows = yearlyAggregate(schedule: schedule)
            let page = AmortizationYearlyPage(
                borrowerName: borrowerName,
                loanSummary: loanSummary,
                generatedDate: generated,
                loFullName: loFullName,
                loNMLSLine: nmlsLine,
                rows: rows,
                startDate: viewModel.inputs.startDate,
                accentHex: profile.brandColorHex,
                pageIndex: globalPageStart,
                pageCount: globalPageCount
            )
            return [(AnyView(page), .landscape)]
        case .monthly:
            let chunks = AmortizationSchedulePages.monthlyChunks(schedule.payments)
            let total = chunks.count
            return chunks.enumerated().map { idx, chunk in
                let page = AmortizationMonthlyPage(
                    borrowerName: borrowerName,
                    loanSummary: loanSummary,
                    generatedDate: generated,
                    loFullName: loFullName,
                    loNMLSLine: nmlsLine,
                    payments: chunk,
                    pageIndex: globalPageStart + idx,
                    pageCount: globalPageCount,
                    sliceIndex: idx + 1,
                    sliceCount: total,
                    miDropoffPeriod: dropoff,
                    accentHex: profile.brandColorHex
                )
                return (AnyView(page), .landscape)
            }
        }
    }

    static func refinanceComparisonPage(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: RefinanceViewModel,
        pageIndex: Int,
        pageCount: Int
    ) -> some View {
        let generated = PDFPageHeader.formatDate(Date())
        let state = resolveState(borrower: borrower)
        let disclosures = requiredDisclosures(
            for: .refinance,
            propertyState: state ?? .CA
        )
        let disclaimer = disclosures.first?.textEN ?? defaultDisclaimer()
        let ehoStatement = equalHousingOpportunityStatement(locale: Locale(identifier: "en_US"))
        let nmlsLine = nmlsLineFor(profile: profile)
        let colors: [Color] = [
            Palette.inkTertiary, Palette.accent, Palette.scenario2, Palette.scenario3,
        ]
        return RefinanceComparisonPage(
            borrowerName: borrower?.fullName ?? "Client",
            generatedDate: generated,
            loFullName: profile.fullName.isEmpty ? "Loan Officer" : profile.fullName,
            loNMLSLine: nmlsLine,
            tableView: RefinanceTableView(viewModel: viewModel, scenarioColors: colors),
            disclaimer: disclaimer,
            ehoStatement: ehoStatement,
            accentHex: profile.brandColorHex,
            pageIndex: pageIndex,
            pageCount: pageCount
        )
    }

    static func tcaComparisonPage(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: TCAViewModel,
        pageIndex: Int,
        pageCount: Int
    ) -> some View {
        let generated = PDFPageHeader.formatDate(Date())
        let state = resolveState(borrower: borrower)
        let disclosures = requiredDisclosures(
            for: .totalCostAnalysis,
            propertyState: state ?? .CA
        )
        let disclaimer = disclosures.first?.textEN ?? defaultDisclaimer()
        let ehoStatement = equalHousingOpportunityStatement(locale: Locale(identifier: "en_US"))
        let nmlsLine = nmlsLineFor(profile: profile)
        let colors: [Color] = [
            Palette.accent, Palette.scenario2, Palette.scenario3, Palette.scenario4,
        ]
        return TCAComparisonPage(
            borrowerName: borrower?.fullName ?? "Client",
            generatedDate: generated,
            loFullName: profile.fullName.isEmpty ? "Loan Officer" : profile.fullName,
            loNMLSLine: nmlsLine,
            viewModel: viewModel,
            disclaimer: disclaimer,
            ehoStatement: ehoStatement,
            accentHex: profile.brandColorHex,
            scenarioColors: colors,
            pageIndex: pageIndex,
            pageCount: pageCount
        )
    }

    static func nmlsLineFor(profile: LenderProfile) -> String {
        switch profile.nmlsDisplayFormat {
        case .idOnly: return "NMLS \(profile.nmlsId)"
        case .idAndURL: return "NMLS \(profile.nmlsId) · nmlsconsumeraccess.org"
        case .none: return ""
        }
    }
}
