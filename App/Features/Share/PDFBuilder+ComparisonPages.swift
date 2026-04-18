// PDFBuilder+ComparisonPages.swift
// Landscape comparison-page builders split off from PDFBuilder.swift
// to keep the main enum body under SwiftLint's type_body_length cap.

import SwiftUI
import QuotientCompliance

extension PDFBuilder {

    static func refinanceComparisonPage(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: RefinanceViewModel
    ) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let generated = formatter.string(from: Date())
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
            accentHex: profile.brandColorHex
        )
    }

    static func tcaComparisonPage(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: TCAViewModel
    ) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let generated = formatter.string(from: Date())
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
            scenarioColors: colors
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
