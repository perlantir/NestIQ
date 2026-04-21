// TCAPDFHTML+V2Derivations.swift
// Session 7.3e — HTML emitters for the iOS-local v0.1.1 extension to
// pdf-tca-with-masthead.html (page 4: interest-vs-principal +
// unrecoverable + reinvestment). These produce the sentinel-ready HTML
// fragments consumed by the 4 new sentinels:
//
//   <!--{{interest_split_header}}-->
//   <!--{{interest_split_rows}}-->
//   <!--{{unrecoverable_rows}}-->
//   <!--{{reinvestment_section}}-->
//
// Business logic mirrors the legacy Swift-built PDF path
// (TCAPDFHTML+HorizonDetails.swift + TCAPDFHTML.swift's reinvestment
// section) so v0.1.1 editorial parity is preserved bit-for-bit.

import Foundation
import QuotientFinance

@MainActor
extension TCAPDFHTML {

    // MARK: - Scalar tokens (format strings)

    /// Longest horizon in years — feeds `{{longest_horizon_years}}`.
    static func longestHorizonYears(viewModel: TCAViewModel) -> Int {
        viewModel.inputs.horizonsYears.max() ?? 30
    }

    /// Pre-formatted ongoing-housing total over the longest horizon.
    /// Feeds `{{ongoing_housing_formatted}}`.
    static func ongoingHousingFormatted(viewModel: TCAViewModel) -> String {
        let years = longestHorizonYears(viewModel: viewModel)
        let monthly = viewModel.inputs.monthlyTaxes
            + viewModel.inputs.monthlyInsurance
            + viewModel.inputs.monthlyHOA
        return MoneyFormat.shared.dollarsShort(monthly * Decimal(years * 12))
    }

    /// Reinvestment rate formatted as a percent ("5.25%").
    /// Feeds `{{reinvestment_rate_pct}}`.
    static func reinvestmentRateFormatted(viewModel: TCAViewModel) -> String {
        String(format: "%.2f%%", viewModel.inputs.reinvestmentRate.asDouble * 100)
    }

    // MARK: - Interest-split helper

    /// Formatted "%int / %prin" for one schedule at one horizon. Used by
    /// both the page-4 interest-split table cells and related emitters.
    static func splitFor(schedule: AmortizationSchedule, years: Int) -> String {
        let month = years * 12
        let interest = schedule.cumulativeInterest(throughMonth: month)
        let principal = schedule.cumulativePrincipal(throughMonth: month)
        let total = interest + principal
        guard total > 0 else { return "—" }
        let intPct = (interest.asDouble / total.asDouble) * 100
        let prinPct = 100 - intPct
        return String(format: "%.0f%% int / %.0f%% prin", intPct, prinPct)
    }

    // MARK: - Interest-split table

    /// Inner content of the `<thead>` element — a single `<tr>` row.
    static func interestSplitHeader(viewModel: TCAViewModel) -> String {
        let showsCurrent = viewModel.showsCurrentColumn
        let currentHeader = showsCurrent ? "<th class=\"num\">Current</th>" : ""
        let scenarioHeaders = viewModel.inputs.scenarios.map { s in
            "<th class=\"num\">\(PDFHTMLComposition.escape(s.label.uppercased()))</th>"
        }.joined()
        return "<tr><th>Horizon</th>\(currentHeader)\(scenarioHeaders)</tr>"
    }

    /// Inner content of the `<tbody>` — N rows keyed by horizon.
    static func interestSplitRows(viewModel: TCAViewModel) -> String {
        let schedules = viewModel.scenarioSchedules
        guard !schedules.isEmpty else { return "" }
        let horizons = viewModel.inputs.horizonsYears
        let showsCurrent = viewModel.showsCurrentColumn
        return horizons.map { years -> String in
            let currentCell: String = {
                guard showsCurrent else { return "" }
                guard let cms = viewModel.currentMortgageSchedule else {
                    return "<td class=\"num\">—</td>"
                }
                return "<td class=\"num\">\(splitFor(schedule: cms, years: years))</td>"
            }()
            let scenarioCells = schedules.map { schedule -> String in
                "<td class=\"num\">\(splitFor(schedule: schedule, years: years))</td>"
            }.joined()
            return "<tr><td>\(years)-yr</td>\(currentCell)\(scenarioCells)</tr>"
        }.joined()
    }

    // MARK: - Unrecoverable table

    /// Inner content of the unrecoverable `<tbody>` — optional Current
    /// row + one row per scenario.
    static func unrecoverableRows(viewModel: TCAViewModel) -> String {
        let schedules = viewModel.scenarioSchedules
        guard !schedules.isEmpty else { return "" }
        let longest = longestHorizonYears(viewModel: viewModel)
        let currentRow: String = {
            guard viewModel.showsCurrentColumn else { return "" }
            let value = MoneyFormat.shared.dollarsShort(
                viewModel.inputs.currentHorizonUnrecoverable(
                    schedule: viewModel.currentMortgageSchedule,
                    years: longest
                )
            )
            return """
            <tr>
              <td>Current</td>
              <td>Status quo</td>
              <td class="num">\(value)</td>
            </tr>
            """
        }()
        let scenarioRows = viewModel.inputs.scenarios.enumerated().map { idx, s -> String in
            let value: String = {
                guard idx < schedules.count else { return "—" }
                return MoneyFormat.shared.dollarsShort(
                    viewModel.inputs.unrecoverableCost(
                        scenario: s,
                        schedule: schedules[idx],
                        years: longest
                    )
                )
            }()
            return """
            <tr>
              <td>\(PDFHTMLComposition.escape(s.label.uppercased()))</td>
              <td>\(PDFHTMLComposition.escape(s.name))</td>
              <td class="num">\(value)</td>
            </tr>
            """
        }.joined()
        return currentRow + scenarioRows
    }

    // MARK: - Reinvestment section

    /// Whole `<section>…</section>` HTML fragment, or "" in purchase
    /// mode / when reinvestment can't be computed. Replaces the
    /// `<!--{{reinvestment_section}}-->` sentinel entirely.
    static func reinvestmentSectionHTML(viewModel: TCAViewModel) -> String {
        guard viewModel.inputs.mode == .refinance,
              viewModel.inputs.scenarios.count > 1,
              !viewModel.scenarioSchedules.isEmpty,
              let metrics = viewModel.result?.scenarioMetrics else {
            return ""
        }
        let payments = metrics.map(\.payment)
        let longest = longestHorizonYears(viewModel: viewModel)
        let ratePct = reinvestmentRateFormatted(viewModel: viewModel)
        let hasCurrent = viewModel.inputs.currentMortgage != nil
        let baseline = viewModel.inputs.breakEvenBaselinePayment(
            monthlyPayments: payments
        )
        let cards = viewModel.inputs.scenarios.enumerated().compactMap { idx, s -> String? in
            guard hasCurrent || idx > 0, payments.indices.contains(idx) else { return nil }
            let diff = baseline - payments[idx]
            let narrative: String
            if abs(diff.asDouble) < 0.01 {
                narrative = "Equivalent monthly payment — no savings to reinvest."
            } else if diff < 0 {
                let more = MoneyFormat.shared.currency(-diff)
                narrative = "Costs \(more)/mo more than baseline — no monthly savings available to invest."
            } else {
                let invest = viewModel.inputs.pathAInvestmentBalance(
                    scenarioIndex: idx,
                    months: longest * 12,
                    monthlyPayments: payments
                )
                let investStr = MoneyFormat.shared.dollarsShort(invest)
                if idx < viewModel.scenarioSchedules.count,
                   let pathB = viewModel.inputs.pathBExtraPrincipal(
                    scenarioIndex: idx,
                    schedule: viewModel.scenarioSchedules[idx],
                    monthlyPayments: payments
                   ) {
                    let monthsSaved = pathB.originalPayoffMonth - pathB.newPayoffMonth
                    let wealth = MoneyFormat.shared.dollarsShort(pathB.wealthBuilt)
                    narrative = "Invest savings → \(investStr) @ \(longest)yr. "
                        + "Or apply as extra principal → payoff -\(monthsSaved) months, wealth built \(wealth)."
                } else {
                    narrative = "Invest savings → \(investStr) @ \(longest)yr."
                }
            }
            let name = "\(s.label.uppercased()) · \(s.name)"
            return """
            <div class="content-card">
              <div class="label">\(PDFHTMLComposition.escape(name))</div>
              <p>\(PDFHTMLComposition.escape(narrative))</p>
            </div>
            """
        }
        guard !cards.isEmpty else { return "" }
        return """
        <section style="margin-top: 28pt;">
          <div class="section-head">
            <h2>Reinvestment @ \(ratePct)</h2>
            <div class="note">Invest savings vs prepay principal</div>
          </div>
          <p class="section-sub">
            Per scenario: if you take the monthly savings and invest them at
            \(ratePct), how does that compare to applying the same savings
            as extra principal on the loan?
          </p>
          \(cards.joined())
          <p class="meta">
            Reinvestment figures are illustrative. Past performance is not
            indicative of future results.
          </p>
        </section>
        """
    }
}
