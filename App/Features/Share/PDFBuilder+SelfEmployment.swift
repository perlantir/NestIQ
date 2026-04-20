// PDFBuilder+SelfEmployment.swift
// Session 5G.5: Self-Employment PDF composition (cover → cash-flow
// analysis page → disclaimers). Extracted to keep the PDFBuilder enum
// under SwiftLint's type_body_length cap after six calculators' builders
// landed on the main file.

import SwiftUI
import QuotientPDF
import QuotientFinance

extension PDFBuilder {

    static func buildSelfEmploymentPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: SelfEmploymentViewModel
    ) throws -> URL {
        if viewModel.output == nil { viewModel.compute() }
        guard let output = viewModel.output else {
            throw PDFRenderer.PDFRendererError.couldNotCreateContext
        }
        let monthly = MoneyFormat.shared.currency(output.qualifyingMonthlyIncome)
        let annual = MoneyFormat.shared.currency(output.twoYearAverage.qualifyingAnnualIncome)
        let avgAnnual = MoneyFormat.shared.currency(output.twoYearAverage.average)
        let y1 = MoneyFormat.shared.currency(output.year1.cashFlow)
        let y2 = MoneyFormat.shared.currency(output.year2.cashFlow)
        let fallback = "Two-year 1084 analysis · qualifying monthly \(monthly) "
            + "(annual \(annual)). Year \(output.year1.year): \(y1). "
            + "Year \(output.year2.year): \(y2). Trend: \(output.twoYearAverage.trend.display)."
        let payload = Payload(
            calculatorSlug: "self-employment",
            calculatorTitle: "Self-employment income analysis",
            complianceScenarioType: .selfEmployment,
            loanSummary: "\(output.businessType.display) · 2-yr avg \(avgAnnual)",
            heroLabel: "Qualifying monthly income",
            heroValue: monthly,
            heroValuePrefix: "",
            heroKPIs: [
                ("Year \(output.year1.year)", y1),
                ("Year \(output.year2.year)", y2),
                ("Trend", output.twoYearAverage.trend.display),
            ],
            narrative: output.trendNotes ?? fallback
        )
        // Self-Employment ships cover + 1 cash-flow + disclaimers → 3 pages.
        let cashFlowPage = AnyView(makeCashFlowPage(
            profile: profile,
            borrower: borrower,
            output: output,
            pageIndex: 2,
            pageCount: 3
        ))
        return try buildPDF(
            profile: profile,
            borrower: borrower,
            payload: payload,
            extraPages: [(cashFlowPage, .portrait)]
        )
    }

    private static func makeCashFlowPage(
        profile: LenderProfile,
        borrower: Borrower?,
        output: SelfEmploymentOutput,
        pageIndex: Int,
        pageCount: Int
    ) -> some View {
        let generated = PDFPageHeader.formatDate(Date())
        let nmlsLine: String = {
            switch profile.nmlsDisplayFormat {
            case .idOnly: return "NMLS \(profile.nmlsId)"
            case .idAndURL: return "NMLS \(profile.nmlsId) · nmlsconsumeraccess.org"
            case .none: return ""
            }
        }()
        return SelfEmploymentCashFlowPage(
            borrowerName: borrower?.fullName ?? "Client",
            loFullName: profile.fullName.isEmpty ? "Loan Officer" : profile.fullName,
            loNMLSLine: nmlsLine,
            businessType: output.businessType,
            year1: output.year1,
            year2: output.year2,
            accentHex: profile.brandColorHex,
            generatedDate: generated,
            pageIndex: pageIndex,
            pageCount: pageCount
        )
    }
}
