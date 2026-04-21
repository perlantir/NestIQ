// RefinancePDFHTML.swift
// Session 7.3f — Template-driven refinance PDF builder.
//
// Loads pdf-refinance-with-masthead.html, fills ~49 tokens from
// RefinanceViewModel + +PDFDerivations, injects the AI narrative at
// <!--{{narrative_body}}-->, and appends the compliance trailer.

import Foundation
import QuotientFinance

@MainActor
enum RefinancePDFHTML {

    static func buildHTML(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: RefinanceViewModel,
        narrative: String
    ) throws -> String {
        let template = try PDFTemplateLoader.load("pdf-refinance-with-masthead")
        let values = tokens(profile: profile, borrower: borrower, viewModel: viewModel)
        var html = HTMLPDFRenderer.shared.interpolate(template: template, values: values)
        html = html.replacingOccurrences(
            of: "<!--{{narrative_body}}-->",
            with: narrativeBlockHTML(narrative: narrative)
        )
        let trailer = PDFTemplateLoader.complianceTrailerPage(
            profile: profile,
            borrower: borrower,
            scenarioType: .refinance
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
        viewModel: RefinanceViewModel
    ) -> [String: String] {
        let inputs = viewModel.inputs
        let money = MoneyFormat.shared
        let first = borrower?.firstName ?? "Client"
        let last = borrower?.lastName ?? ""
        let addr = borrower?.propertyAddress ?? ""
        let prepared = PDFHTMLComposition.formatDate(Date(), style: .short)

        let options = inputs.options
        // selectedOptionIndex is 1-based (0 = current). Map to options[] index.
        let recommendedIdx = max(viewModel.selectedOptionIndex - 1, 0)
        let recommendedOption = options.indices.contains(recommendedIdx)
            ? options[recommendedIdx]
            : nil
        let recommendedTag = recommendedOption.map { "Option \($0.label)" } ?? "Option A"

        let currentPI = viewModel.currentMonthlyPI
        let currentTerm = "\(inputs.currentOriginalTermYears) yr"
        let remainingYears = inputs.currentRemainingYears
        let currentRemainingTerm = "\(remainingYears) yr"

        let origFmt = DateFormatter()
        origFmt.dateFormat = "MMM yyyy"
        let originated = origFmt.string(from: inputs.currentLoanOriginatedDate)

        var out: [String: String] = [
            // common
            "borrower_first": PDFHTMLComposition.escape(first),
            "borrower_last": PDFHTMLComposition.escape(last.isEmpty ? first : last),
            "property_address": PDFHTMLComposition.escape(addr),
            "doc_num": generateDocNum(prefix: "RF"),
            "prepared_by_name": PDFHTMLComposition.escape(profile.fullName),
            "prepared_by_nmls": PDFHTMLComposition.escape(profile.nmlsId),
            "prepared_date": prepared,
            "loan_amount_formatted": money.currency(inputs.currentBalance),

            // Cover
            "refi_type": "Rate-&-term refinance",
            "current_balance_formatted": money.currency(inputs.currentBalance),
            "current_rate_pct": String(format: "%.3f%%", inputs.currentRate),
            "current_monthly_pi_formatted": money.currency(currentPI),

            // Recommendation
            "recommended_option_tag": recommendedTag,
            "recommended_option_name": recommendedOptionName(option: recommendedOption),
            "recommended_breakeven_months": breakEvenDisplayLong(months: viewModel.breakEvenMonth),
            "recommended_breakeven_months_short": breakEvenDisplayShort(months: viewModel.breakEvenMonth),
            "recommended_monthly_savings": money.decimalString(viewModel.monthlySavings),
            "recommended_closing_costs_formatted": money.currency(recommendedOption?.closingCosts ?? 0),
            "recommended_lifetime_savings_formatted": money.currency(max(viewModel.lifetimeDelta, 0)),
            "recommended_lifetime_short": money.dollarsShort(max(viewModel.lifetimeDelta, 0)),
            "recommended_npv_short": money.dollarsShort(max(viewModel.npvDelta, 0)),
            "recommended_remaining_years": String(viewModel.recommendedRemainingYears),

            // Current-loan assumptions (page 3)
            "original_loan_amount_formatted": money.currency(inputs.currentOriginalLoanAmount),
            "current_term": currentTerm,
            "current_remaining_term": currentRemainingTerm,
            "current_originated_date": originated
        ]

        // Three option columns — fill A/B/C from options[] or dash.
        let letters = ["a", "b", "c"]
        for (i, letter) in letters.enumerated() {
            let opt = options.indices.contains(i) ? options[i] : nil
            let metrics = viewModel.metrics(forOptionAt: i)
            let discountPts = viewModel.discountPointsAmount(forOptionAt: i)

            out["option_\(letter)_lender"] = opt.flatMap {
                $0.lender.isEmpty ? nil : PDFHTMLComposition.escape($0.lender)
            } ?? "—"
            out["option_\(letter)_term"] = opt.map { "\($0.termYears) yr" } ?? "—"
            out["option_\(letter)_rate_pct"] = opt.map { String(format: "%.3f%%", $0.rate) } ?? "—"
            out["option_\(letter)_apr_pct"] = opt.flatMap { $0.aprRate }
                .map { String(format: "%.3f%%", $0.asDouble) } ?? "—"
            out["option_\(letter)_points"] = opt.map { String(format: "%.2f", $0.points) } ?? "—"
            out["option_\(letter)_pi_formatted"] = metrics.map { money.currency($0.payment) } ?? "—"
            out["option_\(letter)_pi_delta_formatted"] = opt != nil
                ? signedDollars(viewModel.paymentDelta(forOptionAt: i))
                : "—"
            out["option_\(letter)_pi_delta_pct"] = opt != nil
                ? signedPercent(viewModel.paymentDeltaPct(forOptionAt: i))
                : "—"
            out["option_\(letter)_lender_fees_formatted"] = opt.map {
                $0.lenderFees > 0 ? money.currency($0.lenderFees) : "—"
            } ?? "—"
            out["option_\(letter)_third_party_formatted"] = opt.map {
                $0.thirdPartyFees > 0 ? money.currency($0.thirdPartyFees) : "—"
            } ?? "—"
            out["option_\(letter)_discount_points_formatted"] = discountPts > 0
                ? money.currency(discountPts)
                : "—"
            out["option_\(letter)_total_closing_formatted"] = opt.map { money.currency($0.closingCosts) } ?? "—"
            out["option_\(letter)_breakeven_label"] = viewModel
                .breakEvenMonth(forOptionAt: i)
                .map { "\($0) mo" } ?? "n/a"
            out["option_\(letter)_interest_remaining_formatted"] = opt != nil
                ? money.currency(viewModel.interestOverTerm(forOptionAt: i))
                : "—"
            out["option_\(letter)_lifetime_savings_formatted"] = opt != nil
                ? money.currency(max(viewModel.lifetimeSavings(forOptionAt: i), 0))
                : "—"
            out["option_\(letter)_npv_formatted"] = metrics
                .map { money.currency(max($0.npvAt5pct - (viewModel.current?.npvAt5pct ?? 0), 0)) } ?? "—"
        }

        return out
    }

    // MARK: - Narrative injection

    private static func narrativeBlockHTML(narrative: String) -> String {
        let trimmed = narrative.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return """
            <p class="lead" style="margin:0 0 8pt;">
              Narrative not available — add analyst narration from the refinance results screen.
            </p>
            """
        }
        let paragraphs = trimmed.components(separatedBy: "\n\n")
        return paragraphs.enumerated().map { idx, para in
            let escaped = PDFHTMLComposition.escape(para)
            if idx == 0 {
                return "<p class=\"lead\" style=\"margin:0 0 8pt;\">\(escaped)</p>"
            }
            return "<p style=\"margin:0 0 8pt;\">\(escaped)</p>"
        }.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func recommendedOptionName(option: RefiOption?) -> String {
        guard let option else { return "the highlighted option" }
        return "\(option.termYears)-yr fixed at "
            + String(format: "%.3f%%", option.rate)
    }

    private static func breakEvenDisplayLong(months: Int?) -> String {
        guard let m = months else { return "n/a" }
        return "\(m) months"
    }

    private static func breakEvenDisplayShort(months: Int?) -> String {
        guard let m = months else { return "—" }
        return String(m)
    }

    private static func signedDollars(_ value: Decimal) -> String {
        if value == 0 { return "$0" }
        let prefix = value < 0 ? "−" : "+"
        return prefix + MoneyFormat.shared.currency(abs(value))
    }

    private static func signedPercent(_ pct: Decimal) -> String {
        if pct == 0 { return "0.0%" }
        let prefix = pct < 0 ? "−" : "+"
        let d = abs(pct.asDouble)
        return prefix + String(format: "%.1f%%", d)
    }

    private static func generateDocNum(prefix: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let stamp = df.string(from: Date())
        let seq = String(format: "%04d", Int.random(in: 0..<10_000))
        return "NIQ-\(prefix)-\(stamp)-\(seq)"
    }
}
