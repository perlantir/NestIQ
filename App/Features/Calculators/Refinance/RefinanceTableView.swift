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
        let opts = viewModel.inputs.options
        let dp = viewModel.inputs.propertyDP
        let bal = viewModel.inputs.currentBalance
        let miRequired = dp.miRequired(loanAmount: bal)
        var base: [Row] = [
            Row(label: "Rate",
                values: [String(format: "%.3f%%", viewModel.inputs.currentRate)]
                    + opts.map { String(format: "%.3f%%", $0.rate) },
                winnerIndex: nil),
            Row(label: "Term",
                values: ["\(viewModel.inputs.currentRemainingYears) yr"]
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
        ]
        if miRequired {
            base.append(Row(
                label: "MI / mo",
                values: ["$\(MoneyFormat.shared.decimalString(dp.manualMonthlyMI))"]
                    + opts.map { _ in
                        "$\(MoneyFormat.shared.decimalString(dp.manualMonthlyMI))"
                    },
                winnerIndex: nil
            ))
            let dropoff = miDropoffMonth(
                loanAmount: bal,
                appraisedValue: dp.purchasePrice > 0
                    ? dp.purchasePrice : bal * Decimal(1.25),
                rate: viewModel.inputs.currentRate / 100,
                termMonths: viewModel.inputs.currentRemainingYears * 12,
                requestRemovalAt80: dp.requestMIRemovalAt80
            )
            let dropoffStr = dropoff.map { "mo \($0)" } ?? "—"
            base.append(Row(
                label: "MI drops",
                values: [dropoffStr] + opts.map { _ in dropoffStr },
                winnerIndex: nil
            ))
        }
        return base
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
