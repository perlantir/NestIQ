// AmortizationPDFHTML.swift
// Session 7.3f — Template-driven amortization PDF builder.
//
// Loads pdf-amortization-with-masthead.html, fills scalar tokens from
// AmortizationViewModel + +PDFDerivations, and emits the schedule-grid
// HTML at the two <!--{{schedule_page_N_rows}}--> sentinels. Template
// owns chrome, chart SVG, hero, and assumptions box.

import Foundation
import QuotientFinance

@MainActor
enum AmortizationPDFHTML {

    /// `scheduleGranularity` is preserved in the signature for call-site
    /// compatibility but is ignored — the v2.1.1 template is fixed to
    /// the annual-summary schedule shape (years 1-15 on page 2, 16-30
    /// on page 3). Monthly-granularity export moves to V0.1.2-BACKLOG.
    static func buildHTML(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: AmortizationViewModel,
        scheduleGranularity: AmortScheduleGranularity = .yearly
    ) throws -> String {
        let template = try PDFTemplateLoader.load("pdf-amortization-with-masthead")
        let values = tokens(profile: profile, borrower: borrower, viewModel: viewModel)
        var html = HTMLPDFRenderer.shared.interpolate(template: template, values: values)
        html = html.replacingOccurrences(
            of: "<!--{{schedule_page_1_rows}}-->",
            with: schedulePage1HTML(viewModel: viewModel)
        )
        html = html.replacingOccurrences(
            of: "<!--{{schedule_page_2_rows}}-->",
            with: schedulePage2HTML(viewModel: viewModel)
        )
        let trailer = PDFTemplateLoader.complianceTrailerPage(
            profile: profile,
            borrower: borrower,
            scenarioType: .amortization
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
        viewModel: AmortizationViewModel
    ) -> [String: String] {
        let inputs = viewModel.inputs
        let money = MoneyFormat.shared
        let first = borrower?.firstName ?? "Client"
        let last = borrower?.lastName ?? ""
        let addr = borrower?.propertyAddress ?? ""
        let prepared = PDFHTMLComposition.formatDate(Date(), style: .short)
        let firstPayDate = PDFHTMLComposition.formatDate(viewModel.firstPaymentDate, style: .short)
        let payoff = viewModel.payoffDate.map {
            PDFHTMLComposition.formatDate($0, style: .monthYear)
        } ?? "—"
        let ltvPct = String(format: "%.0f", viewModel.ltv * 100)

        let extraMonthly = inputs.extraPrincipalMonthly
        let extraShortened: String = {
            let m = viewModel.extraPaydownMonthsSaved
            guard m > 0 else { return "—" }
            let years = m / 12
            let months = m % 12
            if years > 0, months > 0 { return "\(years) yrs \(months) mos" }
            if years > 0 { return "\(years) yrs" }
            return "\(months) mos"
        }()

        let combinedIncome: String = inputs.combinedMonthlyIncome > 0
            ? money.currency(inputs.combinedMonthlyIncome)
            : "—"
        let rateLock: String = inputs.rateLock.isEmpty ? "—" : inputs.rateLock

        return [
            // common
            "borrower_first": PDFHTMLComposition.escape(first),
            "borrower_last": PDFHTMLComposition.escape(last.isEmpty ? first : last),
            "property_address": PDFHTMLComposition.escape(addr),
            "doc_num": generateDocNum(prefix: "AM"),
            "prepared_by_name": PDFHTMLComposition.escape(profile.fullName),
            "prepared_by_nmls": PDFHTMLComposition.escape(profile.nmlsId),
            "prepared_date": prepared,
            "loan_amount_formatted": money.currency(inputs.loanAmount),

            // Cover hero + KPI
            "rate_lock": rateLock,
            "product_badge": viewModel.productBadge,
            "piti_dollars": viewModel.pitiDollarsPart,
            "piti_cents": viewModel.pitiCentsPart,
            "first_payment_date": firstPayDate,
            "total_interest_formatted": money.dollarsShort(viewModel.totalInterest),
            "payoff_date": payoff,
            "total_paid_formatted": money.dollarsShort(viewModel.totalPaid),
            "ltv_pct": ltvPct,
            "pmi_note": viewModel.pmiNote,
            "yr10_balance_formatted": money.currency(viewModel.year10Balance),
            "rate_pct": String(format: "%.3f%%", inputs.annualRate),

            // Narrative column
            "extra_principal_formatted": money.decimalString(extraMonthly),
            "extra_paydown_shortened": extraShortened,
            "extra_paydown_interest_saved": money.dollarsShort(viewModel.extraPaydownInterestSaved),
            "quarterpt_savings_monthly": money.decimalString(viewModel.quarterPointSavingsMonthly),
            "quarterpt_savings_lifetime": money.dollarsShort(viewModel.quarterPointSavingsLifetime),
            "combined_monthly_income": combinedIncome
        ]
    }

    // MARK: - Schedule grid emitters

    /// Years 1–15 split 8/7 into two side-by-side tables.
    private static func schedulePage1HTML(viewModel: AmortizationViewModel) -> String {
        let annuals = yearlySummaries(viewModel: viewModel)
        let leftYears = Array(annuals.prefix(8))
        let rightYears = Array(annuals.dropFirst(8).prefix(7))
        return """
        <div class="schedule-split">
          \(scheduleTableHTML(rows: leftYears, footer: nil))
          \(scheduleTableHTML(rows: rightYears, footer: nil))
        </div>
        """
    }

    /// Years 16–30 split 8/7 plus a 30-year totals `<tfoot>` at the end
    /// of the right table.
    private static func schedulePage2HTML(viewModel: AmortizationViewModel) -> String {
        let annuals = yearlySummaries(viewModel: viewModel)
        let page2 = Array(annuals.dropFirst(15))
        let leftYears = Array(page2.prefix(8))
        let rightYears = Array(page2.dropFirst(8).prefix(7))
        let totals = totalsFooter(viewModel: viewModel)
        return """
        <div class="schedule-split">
          \(scheduleTableHTML(rows: leftYears, footer: nil))
          \(scheduleTableHTML(rows: rightYears, footer: totals))
        </div>
        """
    }

    private static func scheduleTableHTML(rows: [YearRow], footer: String?) -> String {
        let body = rows.map { row in
            """
            <tr class="year-end">
              <td>\(row.yearLabel)</td>
              <td>\(row.principal)</td>
              <td>\(row.interest)</td>
              <td>\(row.balance)</td>
            </tr>
            """
        }.joined()
        let footHTML = footer.map { "<tfoot>\($0)</tfoot>" } ?? ""
        return """
        <table class="schedule">
          <thead>
            <tr>
              <th>Year</th>
              <th>Principal</th>
              <th>Interest</th>
              <th>Balance</th>
            </tr>
          </thead>
          <tbody>\(body)</tbody>
          \(footHTML)
        </table>
        """
    }

    private static func totalsFooter(viewModel: AmortizationViewModel) -> String {
        let money = MoneyFormat.shared
        let annuals = yearlySummaries(viewModel: viewModel)
        let totalPrincipal = annuals.reduce(Decimal(0)) { $0 + $1.rawPrincipal }
        let totalInterest = viewModel.totalInterest
        return """
        <tr>
          <td>30-yr total</td>
          <td>\(money.currency(totalPrincipal))</td>
          <td>\(money.currency(totalInterest))</td>
          <td>$0</td>
        </tr>
        """
    }

    // MARK: - Per-year aggregation

    private struct YearRow {
        let yearLabel: String
        let principal: String
        let interest: String
        let balance: String
        let rawPrincipal: Decimal
    }

    private static func yearlySummaries(viewModel: AmortizationViewModel) -> [YearRow] {
        guard let schedule = viewModel.schedule else { return [] }
        let payments = schedule.payments
        let perYear = max(1, viewModel.inputs.biweekly ? 26 : 12)
        let termYears = viewModel.inputs.termYears
        let money = MoneyFormat.shared
        let cal = Calendar(identifier: .gregorian)
        var rows: [YearRow] = []
        for year in 1...termYears {
            let start = (year - 1) * perYear
            let end = min(year * perYear, payments.count)
            guard start < end else { break }
            let slice = payments[start..<end]
            let principal = slice.reduce(Decimal(0)) { $0 + $1.principal + $1.extraPrincipal }
            let interest = slice.reduce(Decimal(0)) { $0 + $1.interest }
            let endingBalance = slice.last?.balance ?? 0
            let calendarYear = cal.component(.year, from: slice.last?.date ?? Date())
            rows.append(YearRow(
                yearLabel: String(calendarYear),
                principal: money.currency(principal),
                interest: money.currency(interest),
                balance: money.currency(endingBalance),
                rawPrincipal: principal
            ))
        }
        // Pad to 30 years with paid-off rows so the template grid always
        // fills out; a loan retired early by extra principal still needs
        // a terminal row in each page's table.
        while rows.count < termYears {
            let lastLabel = rows.last.map { (Int($0.yearLabel) ?? 0) + 1 } ?? 0
            rows.append(YearRow(
                yearLabel: String(lastLabel),
                principal: "—",
                interest: "—",
                balance: money.currency(0),
                rawPrincipal: 0
            ))
        }
        return rows
    }

    private static func generateDocNum(prefix: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let stamp = df.string(from: Date())
        let seq = String(format: "%04d", Int.random(in: 0..<10_000))
        return "NIQ-\(prefix)-\(stamp)-\(seq)"
    }
}
