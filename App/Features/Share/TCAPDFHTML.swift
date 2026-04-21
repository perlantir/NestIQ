// TCAPDFHTML.swift
// Session 7.3f — Template-driven Total Cost Analysis PDF builder.
//
// Loads pdf-tca-with-masthead.html, fills the 12 scalar tokens, emits
// the page-2 {{matrix_rows}} sentinel (scenarios × horizons) plus the
// page-4 sentinels via +V2Derivations, then appends the compliance
// trailer.

import Foundation
import QuotientFinance

@MainActor
enum TCAPDFHTML {

    static func buildHTML(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: TCAViewModel
    ) throws -> String {
        let template = try PDFTemplateLoader.load("pdf-tca-with-masthead")
        let values = tokens(profile: profile, borrower: borrower, viewModel: viewModel)
        var html = HTMLPDFRenderer.shared.interpolate(template: template, values: values)
        html = html.replacingOccurrences(
            of: "<!--{{matrix_rows}}-->",
            with: matrixRowsHTML(viewModel: viewModel)
        )
        html = html.replacingOccurrences(
            of: "<!--{{interest_split_header}}-->",
            with: interestSplitHeader(viewModel: viewModel)
        )
        html = html.replacingOccurrences(
            of: "<!--{{interest_split_rows}}-->",
            with: interestSplitRows(viewModel: viewModel)
        )
        html = html.replacingOccurrences(
            of: "<!--{{unrecoverable_rows}}-->",
            with: unrecoverableRows(viewModel: viewModel)
        )
        html = html.replacingOccurrences(
            of: "<!--{{reinvestment_section}}-->",
            with: reinvestmentSectionHTML(viewModel: viewModel)
        )
        let trailer = PDFTemplateLoader.complianceTrailerPage(
            profile: profile,
            borrower: borrower,
            scenarioType: .totalCostAnalysis
        )
        return html.replacingOccurrences(
            of: "</body>",
            with: "\(trailer)\n</body>"
        )
    }

    // MARK: - Tokens

    private static func tokens(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: TCAViewModel
    ) -> [String: String] {
        let inputs = viewModel.inputs
        let money = MoneyFormat.shared
        let first = borrower?.firstName ?? "Client"
        let last = borrower?.lastName ?? ""
        let addr = borrower?.propertyAddress ?? ""
        let prepared = PDFHTMLComposition.formatDate(Date(), style: .short)

        return [
            // common
            "borrower_first": PDFHTMLComposition.escape(first),
            "borrower_last": PDFHTMLComposition.escape(last.isEmpty ? first : last),
            "property_address": PDFHTMLComposition.escape(addr),
            "doc_num": generateDocNum(prefix: "TC"),
            "prepared_by_name": PDFHTMLComposition.escape(profile.fullName),
            "prepared_by_nmls": PDFHTMLComposition.escape(profile.nmlsId),
            "prepared_date": prepared,
            "loan_amount_formatted": money.currency(inputs.loanAmount),

            // TCA-specific
            "purchase_summary": purchaseSummary(inputs: inputs, borrower: borrower),
            "down_payment_summary": downPaymentSummary(inputs: inputs),
            "longest_horizon_years": String(longestHorizonYears(viewModel: viewModel)),
            "ongoing_housing_formatted": ongoingHousingFormatted(viewModel: viewModel),
            "reinvestment_rate_pct": reinvestmentRateFormatted(viewModel: viewModel)
        ]
    }

    // MARK: - Page 2 matrix emitter

    private static func matrixRowsHTML(viewModel: TCAViewModel) -> String {
        guard let result = viewModel.result else { return "" }
        let scenarios = viewModel.inputs.scenarios
        let horizons = viewModel.inputs.horizonsYears
        // Grid of costs: rows = scenarios, cols = horizons.
        let costs: [[Decimal]] = scenarios.indices.map { sIdx in
            horizons.indices.map { hIdx in
                guard sIdx + 1 < result.scenarioTotalCosts.count else { return Decimal(0) }
                return result.scenarioTotalCosts[sIdx + 1][hIdx]
            }
        }
        // Best scenario per horizon.
        let bestScenarioPerHorizon: [Int] = horizons.indices.map { hIdx in
            scenarios.indices.min(by: { costs[$0][hIdx] < costs[$1][hIdx] }) ?? 0
        }
        return scenarios.enumerated().map { sIdx, scenario in
            let cells = horizons.indices.map { hIdx -> String in
                let cost = costs[sIdx][hIdx]
                let klass = bestScenarioPerHorizon[hIdx] == sIdx ? "best" : ""
                let value = MoneyFormat.shared.dollarsShort(cost)
                return "<td class=\"\(klass)\">\(value)</td>"
            }.joined()
            let rateStr = String(format: "%.3f%%", scenario.rate)
            let sub = PDFHTMLComposition.escape(
                "\(scenario.termYears)-yr · \(rateStr)"
            )
            let nameEscaped = PDFHTMLComposition.escape(scenario.name)
            return """
            <tr>
              <th>\(nameEscaped)<span class="sub">\(sub)</span></th>
              \(cells)
            </tr>
            """
        }.joined()
    }

    // MARK: - Helpers

    private static func purchaseSummary(inputs: TCAFormInputs, borrower: Borrower?) -> String {
        let money = MoneyFormat.shared
        let price: Decimal = inputs.scenarios.first.map {
            $0.propertyDP.purchasePrice > 0 ? $0.propertyDP.purchasePrice : inputs.homeValue
        } ?? inputs.homeValue
        let city = borrower?.propertyState ?? ""
        let scenarios = "\(inputs.scenarios.count) product scenarios"
        let horizons = "\(inputs.horizonsYears.count) time horizons"
        let parts: [String] = [
            price > 0 ? "\(money.currency(price)) \(inputs.mode == .purchase ? "purchase" : "refinance")" : nil,
            city.isEmpty ? nil : city,
            scenarios,
            horizons
        ].compactMap { $0 }
        return PDFHTMLComposition.escape(parts.joined(separator: " · "))
    }

    private static func downPaymentSummary(inputs: TCAFormInputs) -> String {
        let money = MoneyFormat.shared
        guard inputs.mode == .purchase,
              let first = inputs.scenarios.first,
              first.propertyDP.purchasePrice > 0 else {
            return "—"
        }
        let pct = Int(round(first.propertyDP.downPaymentPct * 100))
        let dollars = money.currency(first.propertyDP.downPaymentAmount)
        return "\(pct)% · \(dollars)"
    }

    private static func generateDocNum(prefix: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let stamp = df.string(from: Date())
        let seq = String(format: "%04d", Int.random(in: 0..<10_000))
        return "NIQ-\(prefix)-\(stamp)-\(seq)"
    }
}
