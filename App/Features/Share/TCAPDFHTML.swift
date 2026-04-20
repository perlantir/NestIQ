// TCAPDFHTML.swift
// Session 5O.3 — Total Cost Analysis PDF body composition. Largest
// of the 6 calculator PDFs. Covers:
//
// - Signature + "For {Borrower}" cover header
// - Scenarios compared overview KPI row
// - Per-scenario spec cards (rate / APR / loan / LTV / MI / pts /
//   closing / approx cash-to-close / monthly payment)
// - Horizon × total-cost matrix with winner highlighting
// - Interest vs principal split table
// - Unrecoverable costs @ longest horizon + ongoing-housing explainer
// - Break-even SVG chart (refinance mode only) + per-scenario summary
// - Reinvestment messaging (5N.5 three-way classification)
// - Equity @ longest horizon per scenario
// - Compliance disclaimers appendix

import Foundation
import QuotientFinance

@MainActor
enum TCAPDFHTML {

    static func buildHTML(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: TCAViewModel,
        narrative: String
    ) -> String {
        let body = coverSection(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            narrative: narrative
        )
            + currentMortgageSection(viewModel: viewModel)
            + scenariosSection(viewModel: viewModel)
            + horizonMatrixSection(viewModel: viewModel)
            + interestPrincipalSection(viewModel: viewModel)
            + unrecoverableSection(viewModel: viewModel)
            + breakEvenSection(viewModel: viewModel)
            + reinvestmentSection(viewModel: viewModel)
            + equitySection(viewModel: viewModel)
            + PDFHTMLComposition.disclaimersHTML(
                profile: profile,
                borrower: borrower,
                scenarioType: .totalCostAnalysis
            )
        return PDFHTMLComposition.wrap(body: body)
    }

    // MARK: - Cover

    private static func coverSection(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: TCAViewModel,
        narrative: String
    ) -> String {
        let borrowerName = borrower?.fullName ?? "Client"
        let loan = MoneyFormat.shared.currency(viewModel.inputs.loanAmount)
        let count = viewModel.inputs.scenarios.count
        let horizons = viewModel.inputs.horizonsYears.map { "\($0)yr" }.joined(separator: "/")
        let loanSummary = "\(loan) · \(count) scenarios · \(horizons)"
        let winnerIndex = viewModel.result?.winnerByHorizon.last ?? 0
        let winnerName = viewModel.inputs.scenarios.indices.contains(winnerIndex)
            ? viewModel.inputs.scenarios[winnerIndex].name : "—"
        let fallback = "Across \(count) scenarios over \(horizons) horizons, "
            + "\(winnerName) wins on total cost at the longest horizon."
        let narrativeCopy = narrative.isEmpty ? fallback : narrative

        let eyebrow = "TOTAL COST ANALYSIS · \(PDFHTMLComposition.formatDate(Date()))"
        let hero = PDFHTMLComposition.heroCardHTML(
            label: "Scenarios compared",
            value: "\(count)",
            prefix: "",
            suffix: ""
        )
        let kpis = PDFHTMLComposition.kpiGridHTML([
            ("Horizons", "\(viewModel.inputs.horizonsYears.count)"),
            ("Life winner", winnerName),
            ("Loan", MoneyFormat.shared.dollarsShort(viewModel.inputs.loanAmount))
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

    // MARK: - Scenario spec cards

    private static func scenariosSection(viewModel: TCAViewModel) -> String {
        let scenarios = viewModel.inputs.scenarios
        let metrics = viewModel.result?.scenarioMetrics
        let rows = scenarios.enumerated().map { idx, s -> String in
            let rate = String(format: "%.3f%%", s.rate)
            let apr: String = {
                guard let a = s.aprRate, abs(a.asDouble - s.rate) > 0.0005 else { return "" }
                return String(format: " · %.3f%% APR", a.asDouble)
            }()
            let loan = MoneyFormat.shared.dollarsShort(viewModel.inputs.effectiveLoanAmount(for: s))
            let ltv = viewModel.inputs.ltv(for: s)
            let ltvStr = ltv > 0 ? String(format: " · LTV %.1f%%", ltv * 100) : ""
            let mi = s.monthlyMI > 0
                ? " · MI \(MoneyFormat.shared.currency(s.monthlyMI))/mo"
                : ""
            let pmt: String = {
                guard let m = metrics, idx < m.count else { return "—" }
                return MoneyFormat.shared.currency(m[idx].payment)
            }()
            let cashToClose = MoneyFormat.shared.dollarsShort(
                viewModel.inputs.approximateCashToClose(for: s)
            )
            let pointsClose = String(
                format: "pts %.2f · closing %@",
                s.points,
                MoneyFormat.shared.currency(s.closingCosts)
            )
            let name = "\(s.label.uppercased()) · \(s.name)"
            return """
            <div class="content-card">
              <div class="label">\(PDFHTMLComposition.escape(name))</div>
              <div class="row">
                <div><div class="label">Rate</div><div class="value">\(rate)\(apr)</div></div>
                <div><div class="label">Term</div><div class="value">\(s.termYears) yr</div></div>
                <div><div class="label">Loan</div><div class="value">\(loan)\(ltvStr)</div></div>
              </div>
              <div class="row">
                <div><div class="label">Monthly P&amp;I</div><div class="value">\(pmt)\(mi)</div></div>
                <div><div class="label">Fees</div><div class="value">\(pointsClose)</div></div>
                <div><div class="label">Approx cash to close</div><div class="value">\(cashToClose)</div></div>
              </div>
            </div>
            """
        }.joined()
        return """
        <section class="break-before">
          <p class="eyebrow">Scenario detail</p>
          <h2>Scenarios compared</h2>
          \(rows)
        </section>
        """
    }

    // MARK: - Horizon × total-cost matrix

    private static func horizonMatrixSection(viewModel: TCAViewModel) -> String {
        guard let result = viewModel.result else { return "" }
        let scenarios = viewModel.inputs.scenarios
        let horizons = viewModel.inputs.horizonsYears
        let scenarioLabels = scenarios.map(\.label).map { $0.uppercased() }
        let showsCurrent = viewModel.showsCurrentColumn

        let currentHeader = showsCurrent ? "<th class=\"num\">Current</th>" : ""
        let headerCells = scenarioLabels.map { "<th class=\"num\">\($0)</th>" }.joined()
        let bodyRows = horizons.enumerated().map { hIdx, years -> String in
            // Mirror TCAComparisonPage.matrixRow: refi-mode debts overlay
            let horizonMonths = Decimal(years * 12)
            let costs: [Decimal] = result.scenarioTotalCosts.indices.map { i in
                let piti = result.scenarioTotalCosts[i][hIdx]
                guard viewModel.inputs.mode == .refinance,
                      viewModel.inputs.includeDebts,
                      i < scenarios.count,
                      let d = scenarios[i].otherDebts
                        ?? viewModel.inputs.currentOtherDebts,
                      !d.isZero else {
                    return piti
                }
                return piti + d.monthlyPayment * horizonMonths
            }
            guard !costs.isEmpty else { return "" }
            let winner = costs.indices.reduce(0) { costs[$1] < costs[$0] ? $1 : $0 }
            // Current column (5Q.4) — status-quo cost for the horizon.
            // Does not participate in winner highlighting.
            let currentCell: String = {
                guard showsCurrent else { return "" }
                let cost = viewModel.inputs.currentHorizonCost(years: years)
                return "<td class=\"num\">\(MoneyFormat.shared.dollarsShort(cost))</td>"
            }()
            let cells = costs.enumerated().map { i, cost -> String in
                let isW = i == winner
                let value = MoneyFormat.shared.dollarsShort(cost)
                let marker = isW ? "✓ " : ""
                return "<td class=\"num\">\(marker)\(value)</td>"
            }.joined()
            return "<tr><td>\(years)-yr</td>\(currentCell)\(cells)</tr>"
        }.joined()
        let caption: String = {
            let winner = "Winner per row carries a checkmark."
            let currentNote = showsCurrent
                ? " 'Current' = staying on the existing mortgage; reference, not a candidate."
                : ""
            let costs = " Costs aggregate P&amp;I plus MI; taxes, insurance, and HOA are excluded."
            return winner + currentNote + costs
        }()
        return """
        <section>
          <h2>Total cost by horizon</h2>
          <table class="data">
            <thead><tr><th>Horizon</th>\(currentHeader)\(headerCells)</tr></thead>
            <tbody>\(bodyRows)</tbody>
          </table>
          <p class="meta">\(caption)</p>
        </section>
        """
    }

    // MARK: - Interest vs principal / Unrecoverable / Equity
    // Extracted to TCAPDFHTML+HorizonDetails.swift in 5Q.4 so this
    // enum stays under SwiftLint's type_body_length cap after the
    // Current-column additions.

    // MARK: - Break-even SVG

    private static func breakEvenSection(viewModel: TCAViewModel) -> String {
        guard viewModel.inputs.mode == .refinance,
              viewModel.inputs.scenarios.count > 1,
              let metrics = viewModel.result?.scenarioMetrics else {
            return ""
        }
        let payments = metrics.map(\.payment)
        let longestTermMonths = viewModel.inputs.scenarios
            .dropFirst()
            .map { $0.termYears * 12 }
            .max() ?? 360

        let chartParts = viewModel.inputs.scenarios.enumerated().compactMap { idx, s -> String? in
            guard idx > 0 else { return nil }
            let termMonths = s.termYears * 12
            let series = viewModel.inputs.breakEvenGraphData(
                scenarioIndex: idx,
                monthlyPayments: payments,
                maxMonths: termMonths
            ).map { (month: $0.month, cumulative: $0.cumulative.asDouble) }
            let closing = s.closingCosts.asDouble
            let crossover = BreakEvenChartSVG.firstCrossover(
                series: series,
                closingCosts: closing,
                termMonths: termMonths
            )
            let title = "<h3>\(PDFHTMLComposition.escape("Break-even — \(s.label.uppercased()) · \(s.name)"))</h3>"
            if crossover == nil || closing <= 0 {
                let reason = closing <= 0
                    ? "No closing costs on this scenario — break-even analysis does not apply."
                    : "This scenario does not break even within the \(s.termYears)-year term. "
                        + "Consider a shorter horizon or a larger rate delta."
                return title
                    + "<p class=\"summary-text\">\(PDFHTMLComposition.escape(reason))</p>"
            }
            let caption: String = {
                guard let cx = crossover else { return "" }
                return "Crossover at month \(cx.month) (~\(String(format: "%.1f", Double(cx.month) / 12.0)) yr)."
            }()
            let svg = BreakEvenChartSVG.build(
                series: series,
                closingCosts: closing,
                termMonths: termMonths,
                caption: caption
            )
            return title + svg
        }

        guard !chartParts.isEmpty else { return "" }
        _ = longestTermMonths // may want in future summary; silence unused warning
        return """
        <section class="break-before">
          <p class="eyebrow">Break-even analysis</p>
          <h2>When savings pay back closing costs</h2>
          \(chartParts.joined())
        </section>
        """
    }

    // MARK: - Reinvestment

    private static func reinvestmentSection(viewModel: TCAViewModel) -> String {
        guard viewModel.inputs.mode == .refinance,
              viewModel.inputs.scenarios.count > 1,
              !viewModel.scenarioSchedules.isEmpty,
              let metrics = viewModel.result?.scenarioMetrics else {
            return ""
        }
        let payments = metrics.map(\.payment)
        let longest = viewModel.inputs.horizonsYears.max() ?? 30
        let ratePct = viewModel.inputs.reinvestmentRate.asDouble * 100
        let baseline = payments.first ?? 0
        let parts = viewModel.inputs.scenarios.enumerated().compactMap { idx, s -> String? in
            guard idx > 0, payments.indices.contains(idx) else { return nil }
            let diff = baseline - payments[idx]
            let row: String
            if abs(diff.asDouble) < 0.01 {
                row = "Equivalent monthly payment — no savings to reinvest."
            } else if diff < 0 {
                let more = MoneyFormat.shared.currency(-diff)
                row = "Costs \(more)/mo more than baseline — no monthly savings available to invest."
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
                    row = "Invest savings → \(investStr) @ \(longest)yr. "
                        + "Or apply as extra principal → payoff -\(monthsSaved) months, wealth built \(wealth)."
                } else {
                    row = "Invest savings → \(investStr) @ \(longest)yr."
                }
            }
            let name = "\(s.label.uppercased()) · \(s.name)"
            return """
            <div class="content-card">
              <div class="label">\(PDFHTMLComposition.escape(name))</div>
              <p>\(PDFHTMLComposition.escape(row))</p>
            </div>
            """
        }
        guard !parts.isEmpty else { return "" }
        return """
        <section>
          <h3>Reinvestment @ \(String(format: "%.2f%%", ratePct))</h3>
          \(parts.joined())
          <p class="meta">Reinvestment figures are illustrative. Past performance is not indicative of future results.</p>
        </section>
        """
    }

    // Equity section extracted to TCAPDFHTML+HorizonDetails.swift.
}
