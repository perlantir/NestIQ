// RefinanceTableView.swift
// Side-by-side comparison table used on RefinanceScreen (portrait app
// view) and reused by the Refi PDF landscape page.

import SwiftUI
import QuotientFinance

struct RefinanceTableView: View {
    let viewModel: RefinanceViewModel
    let scenarioColors: [Color]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear.frame(width: 92)
                ForEach(Array(headers.enumerated()), id: \.offset) { idx, h in
                    Text(h)
                        .textStyle(Typography.micro.withSize(9.5, weight: .semibold))
                        .foregroundStyle(scenarioColors[min(idx, scenarioColors.count - 1)])
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.bottom, Spacing.s4)
            Rectangle().fill(Palette.borderSubtle).frame(height: 1)
            ForEach(rows, id: \.label) { row in
                HStack(spacing: 0) {
                    Text(row.label)
                        .textStyle(Typography.body.withSize(11, weight: .medium))
                        .foregroundStyle(Palette.inkSecondary)
                        .frame(width: 92, alignment: .leading)
                    ForEach(Array(row.values.enumerated()), id: \.offset) { idx, val in
                        let winnerIdx = row.winnerIndex ?? -1
                        let isWin = idx == winnerIdx
                        HStack(spacing: 2) {
                            if isWin {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Palette.gain)
                            }
                            Text(val)
                                .textStyle(Typography.num.withSize(12, weight: isWin ? .semibold : .regular))
                                .foregroundStyle(colorFor(idx: idx, isWinner: isWin))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.vertical, Spacing.s8)
                Rectangle().fill(Palette.borderSubtle).frame(height: 1)
            }
        }
    }

    private var headers: [String] {
        ["Cur"] + viewModel.inputs.options.map { $0.label }
    }

    private struct Row {
        let label: String
        let values: [String]
        let winnerIndex: Int?
    }

    private var rows: [Row] {
        let inputs = viewModel.inputs
        let opts = inputs.options
        let anyMI = inputs.currentMonthlyMI > 0 || opts.contains { $0.monthlyMI > 0 }
        let hasHomeValue = inputs.homeValue > 0
        let anyAPR = inputs.currentAPR != nil || opts.contains { $0.aprRate != nil }
        var base: [Row] = [
            Row(label: "Loan amt",
                values: ["$\(MoneyFormat.shared.decimalString(inputs.currentBalance))"]
                    + opts.map {
                        "$\(MoneyFormat.shared.decimalString(inputs.effectiveLoanAmount(for: $0)))"
                    },
                winnerIndex: nil),
            Row(label: "Rate",
                values: [String(format: "%.3f%%", inputs.currentRate)]
                    + opts.map { String(format: "%.3f%%", $0.rate) },
                winnerIndex: nil),
        ]
        if anyAPR {
            base.append(
                Row(label: "APR",
                    values: [formatAPR(inputs.currentAPR)]
                        + opts.map { formatAPR($0.aprRate) },
                    winnerIndex: nil)
            )
        }
        base.append(contentsOf: [
            Row(label: "Term",
                values: ["\(inputs.currentRemainingYears) yr"]
                    + opts.map { "\($0.termYears) yr" },
                winnerIndex: nil),
            Row(label: "Points",
                values: ["—"] + opts.map { String(format: "%.2f", $0.points) },
                winnerIndex: nil),
            Row(label: "Closing",
                values: ["—"]
                    + opts.map { "$\(MoneyFormat.shared.decimalString($0.closingCosts))" },
                winnerIndex: nil),
            paymentRow(),
            breakEvenRow(),
            npvRow(),
            lifetimeRow(),
        ])
        if hasHomeValue {
            base.append(Row(
                label: "LTV",
                values: [String(format: "%.1f%%", inputs.currentLTV * 100)]
                    + opts.map { String(format: "%.1f%%", inputs.ltv(for: $0) * 100) },
                winnerIndex: nil
            ))
        }
        if anyMI {
            base.append(Row(
                label: "MI / mo",
                values: [miDisplay(inputs.currentMonthlyMI)]
                    + opts.map { miDisplay($0.monthlyMI) },
                winnerIndex: nil
            ))
        }
        return base
    }

    private func miDisplay(_ mi: Decimal) -> String {
        mi > 0 ? "$\(MoneyFormat.shared.decimalString(mi))" : "—"
    }

    /// Compact APR cell — "6.812%" when set, "—" otherwise. The full
    /// rate/APR side-by-side display is the per-scenario card (not
    /// this comparison table). Used only when at least one scenario
    /// carries an explicit APR so the row doesn't show em-dashes
    /// everywhere.
    private func formatAPR(_ apr: Decimal?) -> String {
        guard let apr else { return "—" }
        return String(format: "%.3f%%", apr.asDouble)
    }

    private func npvRow() -> Row {
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

    private func paymentRow() -> Row {
        guard let result = viewModel.result else {
            return Row(label: "Payment", values: ["—", "—", "—", "—"], winnerIndex: nil)
        }
        var values: [String] = []
        var bestIdx = 0
        var bestVal = Decimal.greatestFiniteMagnitude
        for (i, m) in result.scenarioMetrics.enumerated() {
            values.append("$\(MoneyFormat.shared.decimalString(m.payment))")
            if i > 0, m.payment < bestVal { bestVal = m.payment; bestIdx = i }
        }
        return Row(label: "Payment", values: values, winnerIndex: bestIdx)
    }

    private func breakEvenRow() -> Row {
        guard let result = viewModel.result else {
            return Row(label: "Break-even", values: ["—", "—", "—", "—"], winnerIndex: nil)
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

    private func lifetimeRow() -> Row {
        guard let result = viewModel.result, let lastH = result.horizons.last,
              let hIdx = result.horizons.firstIndex(of: lastH) else {
            return Row(label: "Lifetime Δ", values: ["—", "—", "—", "—"], winnerIndex: nil)
        }
        let current = result.scenarioTotalCosts[0][hIdx]
        var values: [String] = ["—"]
        var bestIdx: Int?
        var bestVal = Decimal(0)
        for i in 1..<result.scenarioTotalCosts.count {
            let diff = current - result.scenarioTotalCosts[i][hIdx]
            let short = MoneyFormat.shared.dollarsShort(abs(diff))
            values.append((diff >= 0 ? "+" : "-") + short.replacingOccurrences(of: "$", with: "$"))
            if diff > bestVal { bestVal = diff; bestIdx = i }
        }
        return Row(label: "Lifetime Δ", values: values, winnerIndex: bestIdx)
    }

    private func colorFor(idx: Int, isWinner: Bool) -> Color {
        if idx == 0 { return Palette.inkTertiary }
        return isWinner ? Palette.gain : Palette.ink
    }
}
