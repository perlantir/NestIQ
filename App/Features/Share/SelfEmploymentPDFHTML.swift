// SelfEmploymentPDFHTML.swift
// Session 5O.7 — Self-Employment PDF body composition. Renders the
// Fannie 1084 two-year analysis with labeled addbacks + deductions
// per year + the averaged qualifying monthly income.

import Foundation
import QuotientFinance

@MainActor
enum SelfEmploymentPDFHTML {

    static func buildHTML(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: SelfEmploymentViewModel
    ) -> String {
        if viewModel.output == nil { viewModel.compute() }
        guard let output = viewModel.output else {
            // No output — render a minimal cover + disclaimers so
            // the share flow still succeeds rather than throwing.
            return PDFHTMLComposition.wrap(body: minimalBody(
                profile: profile, borrower: borrower
            ))
        }
        let body = coverSection(profile: profile, borrower: borrower, output: output)
            + yearBreakdownSection(output: output)
            + twoYearAverageSection(output: output)
            + PDFHTMLComposition.disclaimersHTML(
                profile: profile,
                borrower: borrower,
                scenarioType: .selfEmployment
            )
        return PDFHTMLComposition.wrap(body: body)
    }

    private static func minimalBody(profile: LenderProfile, borrower: Borrower?) -> String {
        let signature = PDFHTMLComposition.signatureHTML(profile: profile)
        let title = PDFHTMLComposition.titleBlockHTML(
            eyebrow: "SELF-EMPLOYMENT · \(PDFHTMLComposition.formatDate(Date()))",
            borrowerName: borrower?.fullName ?? "Client",
            loanSummary: "No two-year analysis available"
        )
        let disclaimers = PDFHTMLComposition.disclaimersHTML(
            profile: profile,
            borrower: borrower,
            scenarioType: .selfEmployment
        )
        return "<section>\(signature)\(title)</section>\(disclaimers)"
    }

    private static func coverSection(
        profile: LenderProfile,
        borrower: Borrower?,
        output: SelfEmploymentOutput
    ) -> String {
        let borrowerName = borrower?.fullName ?? "Client"
        let monthly = MoneyFormat.shared.currency(output.qualifyingMonthlyIncome)
        let annual = MoneyFormat.shared.currency(output.twoYearAverage.qualifyingAnnualIncome)
        let avgAnnual = MoneyFormat.shared.currency(output.twoYearAverage.average)
        let y1 = MoneyFormat.shared.currency(output.year1.cashFlow)
        let y2 = MoneyFormat.shared.currency(output.year2.cashFlow)
        let fallback = "Two-year 1084 analysis · qualifying monthly \(monthly) "
            + "(annual \(annual)). Year \(output.year1.year): \(y1). "
            + "Year \(output.year2.year): \(y2). Trend: \(output.twoYearAverage.trend.display)."
        let narrativeCopy = output.trendNotes ?? fallback

        let loanSummary = "\(output.businessType.display) · 2-yr avg \(avgAnnual)"
        let eyebrow = "SELF-EMPLOYMENT · \(PDFHTMLComposition.formatDate(Date()))"
        let hero = PDFHTMLComposition.heroCardHTML(
            label: "Qualifying monthly income",
            value: monthly,
            prefix: "",
            suffix: ""
        )
        let kpis = PDFHTMLComposition.kpiGridHTML([
            ("Year \(output.year1.year)", y1),
            ("Year \(output.year2.year)", y2),
            ("Trend", output.twoYearAverage.trend.display)
        ])
        let signature = PDFHTMLComposition.signatureHTML(profile: profile)
        let title = PDFHTMLComposition.titleBlockHTML(
            eyebrow: eyebrow,
            borrowerName: borrowerName,
            loanSummary: loanSummary
        )
        return """
        <section>
          \(signature)
          \(title)
          \(hero)
          \(kpis)
          <h2>Summary</h2>
          <p class="summary-text">\(PDFHTMLComposition.escape(narrativeCopy))</p>
        </section>
        """
    }

    // MARK: - Per-year cash flow breakdown (addbacks + deductions)

    private static func yearBreakdownSection(output: SelfEmploymentOutput) -> String {
        return """
        <section class="break-before">
          <p class="eyebrow">Fannie 1084 cash flow</p>
          <h2>Year-by-year breakdown</h2>
          \(yearCard(output.year1, businessType: output.businessType))
          \(yearCard(output.year2, businessType: output.businessType))
        </section>
        """
    }

    private static func yearCard(
        _ result: SelfEmploymentYearResult,
        businessType: BusinessType
    ) -> String {
        let cashFlow = MoneyFormat.shared.currency(result.cashFlow)
        // 5H.2: addback labels must explicitly indicate "— added back"
        // / "— deducted" so the LO's math is reproducible by any
        // reader. Sources come from Addback / Deduction `.label`.
        let addbackRows = result.addbacks.map { addback -> String in
            let amount = MoneyFormat.shared.currency(addback.amount)
            return """
            <tr>
              <td>\(PDFHTMLComposition.escape(addback.label))</td>
              <td class="num">+\(amount) — added back</td>
            </tr>
            """
        }.joined()
        let deductionRows = result.deductions.map { deduction -> String in
            let amount = MoneyFormat.shared.currency(deduction.amount)
            return """
            <tr>
              <td>\(PDFHTMLComposition.escape(deduction.label))</td>
              <td class="num">-\(amount) — deducted</td>
            </tr>
            """
        }.joined()
        let combinedRows: String
        if addbackRows.isEmpty && deductionRows.isEmpty {
            combinedRows = "<tr><td colspan=\"2\" class=\"meta\">No line-item adjustments.</td></tr>"
        } else {
            combinedRows = addbackRows + deductionRows
        }
        return """
        <div class="content-card">
          <div class="label">\(PDFHTMLComposition.escape(businessType.display)) · \(result.year)</div>
          <table class="data">
            <thead>
              <tr><th>Line item</th><th class="num">Adjustment</th></tr>
            </thead>
            <tbody>
              \(combinedRows)
              <tr>
                <td><strong>Net cash flow</strong></td>
                <td class="num"><strong>\(cashFlow)</strong></td>
              </tr>
            </tbody>
          </table>
        </div>
        """
    }

    // MARK: - Two-year average summary

    private static func twoYearAverageSection(output: SelfEmploymentOutput) -> String {
        let avg = output.twoYearAverage
        return """
        <section>
          <h3>Two-year average</h3>
          <table class="data">
            <tbody>
              <tr>
                <td>Average cash flow</td>
                <td class="num">\(MoneyFormat.shared.currency(avg.average))</td>
              </tr>
              <tr>
                <td>Trend</td>
                <td class="num">\(PDFHTMLComposition.escape(avg.trend.display))</td>
              </tr>
              <tr>
                <td>Qualifying annual income</td>
                <td class="num">\(MoneyFormat.shared.currency(avg.qualifyingAnnualIncome))</td>
              </tr>
              <tr>
                <td><strong>Qualifying monthly income</strong></td>
                <td class="num"><strong>\(MoneyFormat.shared.currency(output.qualifyingMonthlyIncome))</strong></td>
              </tr>
            </tbody>
          </table>
          <p class="meta">When the two-year trend is declining, Fannie 1084 uses the lower year's
             cash flow (not the mean) as the qualifying annual income.</p>
        </section>
        """
    }
}
