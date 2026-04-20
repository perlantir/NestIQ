// TCAPDFHTML+HorizonDetails.swift
// Session 5Q.4 — the three horizon-keyed sections (interest vs
// principal, unrecoverable costs, equity buildup) that render on the
// TCA PDF. Extracted from TCAPDFHTML.swift so the main enum stays
// under SwiftLint's type_body_length cap after the Current-column
// additions landed.
//
// All three sections prepend a "Current" column / row in refi mode
// when the attached borrower has a `currentMortgage` — same
// status-quo baseline the on-screen Results surface shows.

import Foundation
import QuotientFinance

@MainActor
extension TCAPDFHTML {

    // MARK: - Interest vs principal split

    static func interestPrincipalSection(viewModel: TCAViewModel) -> String {
        let schedules = viewModel.scenarioSchedules
        guard !schedules.isEmpty else { return "" }
        let scenarios = viewModel.inputs.scenarios
        let horizons = viewModel.inputs.horizonsYears
        let showsCurrent = viewModel.showsCurrentColumn
        let currentHeader = showsCurrent ? "<th class=\"num\">Current</th>" : ""
        let headerCells = scenarios.map { s in
            "<th class=\"num\">\(PDFHTMLComposition.escape(s.label.uppercased()))</th>"
        }.joined()
        let rows = horizons.map { years -> String in
            let currentCell: String = {
                guard showsCurrent, let cms = viewModel.currentMortgageSchedule else {
                    return showsCurrent ? "<td class=\"num\">—</td>" : ""
                }
                return "<td class=\"num\">\(splitFor(schedule: cms, years: years))</td>"
            }()
            let cells = schedules.map { schedule -> String in
                let split = splitFor(schedule: schedule, years: years)
                return "<td class=\"num\">\(split)</td>"
            }.joined()
            return "<tr><td>\(years)-yr</td>\(currentCell)\(cells)</tr>"
        }.joined()
        return """
        <section>
          <h3>Interest vs principal</h3>
          <table class="data">
            <thead><tr><th>Horizon</th>\(currentHeader)\(headerCells)</tr></thead>
            <tbody>\(rows)</tbody>
          </table>
        </section>
        """
    }

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

    // MARK: - Unrecoverable costs

    static func unrecoverableSection(viewModel: TCAViewModel) -> String {
        let schedules = viewModel.scenarioSchedules
        guard !schedules.isEmpty else { return "" }
        let longest = viewModel.inputs.horizonsYears.max() ?? 30
        let monthlyOngoing = viewModel.inputs.monthlyTaxes
            + viewModel.inputs.monthlyInsurance
            + viewModel.inputs.monthlyHOA
        let ongoing = monthlyOngoing * Decimal(longest * 12)
        // Session 5Q.4: prepend a Current row showing cumulative
        // interest on the status quo over the longest horizon — the
        // apples-to-apples baseline for the per-scenario figures.
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
        let rows = viewModel.inputs.scenarios.enumerated().map { idx, s -> String in
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
        return """
        <section>
          <h3>Unrecoverable costs @ \(longest)yr</h3>
          <table class="data">
            <thead>
              <tr><th>Scenario</th><th>Program</th><th class="num">Unrecoverable</th></tr>
            </thead>
            <tbody>\(currentRow)\(rows)</tbody>
          </table>
          <p class="meta">Ongoing housing @ \(longest)yr: \(MoneyFormat.shared.dollarsShort(ongoing))
             (taxes, insurance, HOA — paid regardless of program choice).</p>
        </section>
        """
    }

    // MARK: - Equity buildup

    static func equitySection(viewModel: TCAViewModel) -> String {
        let schedules = viewModel.scenarioSchedules
        guard !schedules.isEmpty else { return "" }
        let longest = viewModel.inputs.horizonsYears.max() ?? 30
        let currentRow: String = {
            guard viewModel.showsCurrentColumn else { return "" }
            let equity = viewModel.inputs.currentHorizonEquity(
                schedule: viewModel.currentMortgageSchedule,
                years: longest
            )
            return """
            <tr>
              <td>Current</td>
              <td>Status quo</td>
              <td class="num">\(MoneyFormat.shared.dollarsShort(equity))</td>
            </tr>
            """
        }()
        let cells = viewModel.inputs.scenarios.enumerated().compactMap { idx, s -> String? in
            guard idx < schedules.count else { return nil }
            let equity = viewModel.inputs.equityAtHorizon(
                scenarioIndex: idx,
                schedule: schedules[idx],
                years: longest
            )
            return """
            <tr>
              <td>\(PDFHTMLComposition.escape(s.label.uppercased()))</td>
              <td>\(PDFHTMLComposition.escape(s.name))</td>
              <td class="num">\(MoneyFormat.shared.dollarsShort(equity))</td>
            </tr>
            """
        }
        guard !cells.isEmpty || !currentRow.isEmpty else { return "" }
        return """
        <section>
          <h3>Equity buildup @ \(longest)yr</h3>
          <table class="data">
            <thead>
              <tr><th>Scenario</th><th>Program</th><th class="num">Equity</th></tr>
            </thead>
            <tbody>\(currentRow)\(cells.joined())</tbody>
          </table>
        </section>
        """
    }
}
