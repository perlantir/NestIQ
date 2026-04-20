// RefinancePDFHTML.swift
// Session 5O.4 — Refinance Comparison PDF body composition.
//
// Mirrors the on-screen RefinanceTableView matrix (Current + N option
// columns, row per metric — loan amt, rate, APR, term, points,
// closing, payment, break-even, NPV, lifetime Δ, LTV, MI) plus a
// per-option break-even SVG (BreakEvenChartSVG).

import Foundation
import QuotientFinance

@MainActor
enum RefinancePDFHTML {

    static func buildHTML(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: RefinanceViewModel,
        narrative: String
    ) -> String {
        let body = coverSection(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            narrative: narrative
        )
            + comparisonSection(viewModel: viewModel)
            + breakEvenSection(viewModel: viewModel)
            + PDFHTMLComposition.disclaimersHTML(
                profile: profile,
                borrower: borrower,
                scenarioType: .refinance
            )
        return PDFHTMLComposition.wrap(body: body)
    }

    // MARK: - Cover

    private static func coverSection(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: RefinanceViewModel,
        narrative: String
    ) -> String {
        let borrowerName = borrower?.fullName ?? "Client"
        let savings = MoneyFormat.shared.currency(viewModel.monthlySavings)
        let be = viewModel.breakEvenMonth.map { "\($0) mo" } ?? "—"
        let lifetime = MoneyFormat.shared.dollarsShort(abs(viewModel.lifetimeDelta))
        let npv = MoneyFormat.shared.dollarsShort(abs(viewModel.npvDelta))
        let currentRate = String(format: "%.3f", viewModel.inputs.currentRate)
        let currentRateDisplay = displayRateAndAPR(
            rate: viewModel.inputs.currentRate,
            decimalAPR: viewModel.inputs.currentAPR
        )
        let fallback = "Selected refi saves \(savings)/mo versus the current \(currentRate)% loan. "
            + "Break-even: \(be)."
        let loanSummary = "Current "
            + MoneyFormat.shared.currency(viewModel.inputs.currentBalance)
            + " @ \(currentRateDisplay)"

        let eyebrow = "REFINANCE COMPARISON · \(PDFHTMLComposition.formatDate(Date()))"
        let hero = PDFHTMLComposition.heroCardHTML(
            label: "Monthly savings · selected option",
            value: savings,
            prefix: "",
            suffix: ""
        )
        let kpis = PDFHTMLComposition.kpiGridHTML([
            ("Break-even", be),
            ("Lifetime Δ", lifetime),
            ("NPV @ 5%", npv)
        ])
        let signature = PDFHTMLComposition.signatureHTML(profile: profile)
        let title = PDFHTMLComposition.titleBlockHTML(
            eyebrow: eyebrow,
            borrowerName: borrowerName,
            loanSummary: loanSummary
        )
        let narrativeCopy = narrative.isEmpty ? fallback : narrative
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

    // MARK: - Side-by-side comparison

    private static func comparisonSection(viewModel: RefinanceViewModel) -> String {
        let inputs = viewModel.inputs
        let options = inputs.options
        let headers = ["Cur"] + options.map { $0.label.uppercased() }
        let headerCells = headers.map { h in
            "<th class=\"num\">\(PDFHTMLComposition.escape(h))</th>"
        }.joined()

        let rows = buildRows(viewModel: viewModel)
        let bodyRows = rows.map { row in
            let cells = row.values.enumerated().map { idx, value -> String in
                let winner = row.winnerIndex == idx
                let displayed = winner ? "✓ \(value)" : value
                return "<td class=\"num\">\(PDFHTMLComposition.escape(displayed))</td>"
            }.joined()
            return "<tr><td>\(PDFHTMLComposition.escape(row.label))</td>\(cells)</tr>"
        }.joined()

        return """
        <section class="break-before">
          <p class="eyebrow">Side-by-side</p>
          <h2>Current vs refinance options</h2>
          <table class="data">
            <thead><tr><th>Metric</th>\(headerCells)</tr></thead>
            <tbody>\(bodyRows)</tbody>
          </table>
          <p class="meta">Winner per row carries a checkmark. Payment row minimizes $/mo; break-even
             row minimizes months to recoup closing; NPV / lifetime rows maximize delta vs Current.</p>
        </section>
        """
    }

    private struct Row {
        let label: String
        let values: [String]
        let winnerIndex: Int?
    }

    private static func buildRows(viewModel: RefinanceViewModel) -> [Row] {
        let inputs = viewModel.inputs
        let opts = inputs.options
        let anyAPR = inputs.currentAPR != nil || opts.contains { $0.aprRate != nil }
        let anyMI = inputs.currentMonthlyMI > 0 || opts.contains { $0.monthlyMI > 0 }
        let hasHomeValue = inputs.homeValue > 0

        var rows: [Row] = []

        rows.append(Row(
            label: "Loan amt",
            values: [MoneyFormat.shared.currency(inputs.currentBalance)]
                + opts.map {
                    MoneyFormat.shared.currency(inputs.effectiveLoanAmount(for: $0))
                },
            winnerIndex: nil
        ))
        rows.append(Row(
            label: "Rate",
            values: [String(format: "%.3f%%", inputs.currentRate)]
                + opts.map { String(format: "%.3f%%", $0.rate) },
            winnerIndex: nil
        ))
        if anyAPR {
            rows.append(Row(
                label: "APR",
                values: [formatAPR(inputs.currentAPR)]
                    + opts.map { formatAPR($0.aprRate) },
                winnerIndex: nil
            ))
        }
        rows.append(Row(
            label: "Term",
            values: ["\(inputs.currentRemainingYears) yr"]
                + opts.map { "\($0.termYears) yr" },
            winnerIndex: nil
        ))
        rows.append(Row(
            label: "Points",
            values: ["—"] + opts.map { String(format: "%.2f", $0.points) },
            winnerIndex: nil
        ))
        rows.append(Row(
            label: "Closing",
            values: ["—"] + opts.map { MoneyFormat.shared.currency($0.closingCosts) },
            winnerIndex: nil
        ))
        rows.append(paymentRow(viewModel: viewModel))
        rows.append(breakEvenRow(viewModel: viewModel))
        rows.append(npvRow(viewModel: viewModel))
        rows.append(lifetimeRow(viewModel: viewModel))
        if hasHomeValue {
            rows.append(Row(
                label: "LTV",
                values: [String(format: "%.1f%%", inputs.currentLTV * 100)]
                    + opts.map { String(format: "%.1f%%", inputs.ltv(for: $0) * 100) },
                winnerIndex: nil
            ))
        }
        if anyMI {
            rows.append(Row(
                label: "MI / mo",
                values: [miDisplay(inputs.currentMonthlyMI)]
                    + opts.map { miDisplay($0.monthlyMI) },
                winnerIndex: nil
            ))
        }
        return rows
    }

    private static func paymentRow(viewModel: RefinanceViewModel) -> Row {
        guard let result = viewModel.result else {
            return Row(label: "Payment",
                       values: Array(repeating: "—", count: 1 + viewModel.inputs.options.count),
                       winnerIndex: nil)
        }
        var values: [String] = []
        var bestIdx = 0
        var bestVal = Decimal.greatestFiniteMagnitude
        for (i, m) in result.scenarioMetrics.enumerated() {
            values.append(MoneyFormat.shared.currency(m.payment))
            if i > 0, m.payment < bestVal { bestVal = m.payment; bestIdx = i }
        }
        return Row(label: "Payment", values: values, winnerIndex: bestIdx)
    }

    private static func breakEvenRow(viewModel: RefinanceViewModel) -> Row {
        guard let result = viewModel.result else {
            return Row(label: "Break-even",
                       values: Array(repeating: "—", count: 1 + viewModel.inputs.options.count),
                       winnerIndex: nil)
        }
        var values: [String] = ["—"]
        var bestIdx: Int?
        var bestVal = Int.max
        for (i, m) in result.scenarioMetrics.enumerated() where i > 0 {
            if let be = m.breakEvenMonth {
                values.append("\(be) mo")
                if be < bestVal { bestVal = be; bestIdx = i }
            } else {
                values.append("—")
            }
        }
        return Row(label: "Break-even", values: values, winnerIndex: bestIdx)
    }

    private static func npvRow(viewModel: RefinanceViewModel) -> Row {
        guard let result = viewModel.result else {
            return Row(label: "NPV @ 5%",
                       values: Array(repeating: "—", count: 1 + viewModel.inputs.options.count),
                       winnerIndex: nil)
        }
        var values: [String] = []
        var bestIdx = 0
        var bestVal = Decimal(-.greatestFiniteMagnitude)
        for (i, m) in result.scenarioMetrics.enumerated() {
            values.append(MoneyFormat.shared.dollarsShort(m.npvAt5pct))
            if i > 0, m.npvAt5pct > bestVal { bestVal = m.npvAt5pct; bestIdx = i }
        }
        return Row(label: "NPV @ 5%", values: values, winnerIndex: bestIdx)
    }

    private static func lifetimeRow(viewModel: RefinanceViewModel) -> Row {
        guard let result = viewModel.result,
              let lastH = result.horizons.last,
              let hIdx = result.horizons.firstIndex(of: lastH) else {
            return Row(label: "Lifetime Δ",
                       values: Array(repeating: "—", count: 1 + viewModel.inputs.options.count),
                       winnerIndex: nil)
        }
        let current = result.scenarioTotalCosts[0][hIdx]
        var values: [String] = ["—"]
        var bestIdx: Int?
        var bestVal = Decimal(0)
        for i in 1..<result.scenarioTotalCosts.count {
            let diff = current - result.scenarioTotalCosts[i][hIdx]
            let short = MoneyFormat.shared.dollarsShort(abs(diff))
            values.append((diff >= 0 ? "+" : "-") + short)
            if diff > bestVal { bestVal = diff; bestIdx = i }
        }
        return Row(label: "Lifetime Δ", values: values, winnerIndex: bestIdx)
    }

    private static func formatAPR(_ apr: Decimal?) -> String {
        guard let apr else { return "—" }
        return String(format: "%.3f%%", apr.asDouble)
    }

    private static func miDisplay(_ mi: Decimal) -> String {
        mi > 0 ? MoneyFormat.shared.currency(mi) : "—"
    }

    // MARK: - Break-even SVG charts per option

    private static func breakEvenSection(viewModel: RefinanceViewModel) -> String {
        guard let result = viewModel.result else { return "" }
        let inputs = viewModel.inputs
        let currentPayment = result.scenarioMetrics.first?.payment ?? 0

        let chartParts = inputs.options.enumerated().compactMap { idx, opt -> String? in
            let scenarioIndex = idx + 1
            guard scenarioIndex < result.scenarioMetrics.count else { return nil }
            let optionPayment = result.scenarioMetrics[scenarioIndex].payment
            let monthlySavings = currentPayment - optionPayment
            let termMonths = opt.termYears * 12
            let closing = opt.closingCosts.asDouble

            if monthlySavings <= 0 || closing <= 0 {
                let title = "<h3>Break-even — \(PDFHTMLComposition.escape(opt.label.uppercased()))</h3>"
                let reason: String
                if monthlySavings <= 0 {
                    reason = "This option does not produce monthly savings vs the current loan; "
                        + "break-even analysis does not apply."
                } else {
                    reason = "No closing costs on this option — break-even analysis does not apply."
                }
                return title + "<p class=\"summary-text\">\(PDFHTMLComposition.escape(reason))</p>"
            }

            let savingsDouble = monthlySavings.asDouble
            let series: [(month: Int, cumulative: Double)] = (0...termMonths).map {
                (month: $0, cumulative: savingsDouble * Double($0))
            }
            let crossover = BreakEvenChartSVG.firstCrossover(
                series: series,
                closingCosts: closing,
                termMonths: termMonths
            )
            let title = "<h3>\(PDFHTMLComposition.escape("Break-even — \(opt.label.uppercased())"))</h3>"
            if crossover == nil {
                let reason = "This option does not break even within the \(opt.termYears)-year term. "
                    + "Consider a larger rate drop or lower closing costs."
                return title + "<p class=\"summary-text\">\(PDFHTMLComposition.escape(reason))</p>"
            }
            let caption: String = {
                guard let cx = crossover else { return "" }
                let years = Double(cx.month) / 12.0
                return "Crossover at month \(cx.month) (~\(String(format: "%.1f", years)) yr)."
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
        return """
        <section class="break-before">
          <p class="eyebrow">Break-even analysis</p>
          <h2>When savings pay back closing costs</h2>
          \(chartParts.joined())
        </section>
        """
    }
}
