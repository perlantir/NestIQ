// TCAScreen+BreakEven.swift
// Session 5N.4 — extracted from TCAScreen+BreakdownSections.swift so
// the main breakdown file stays under SwiftLint's 600-line cap after
// the break-even chart redesign (non-negative y-axis, neutral dashed
// reference, crossover PointMark, per-scenario description).

import SwiftUI
import Charts
import QuotientFinance

extension TCAScreen {

    // MARK: - Data model

    struct BreakEvenPoint: Identifiable {
        let month: Int
        let yValue: Double
        var id: Int { month }
    }

    struct BreakEvenCrossover {
        let month: Int
    }

    struct BreakEvenSeries: Identifiable {
        let id: Int
        let seriesKey: String
        let color: Color
        let closingCosts: Double
        let closingLabel: String
        let points: [BreakEvenPoint]
        let crossover: BreakEvenCrossover?
    }

    // MARK: - Section

    /// Refinance-mode break-even section: per-scenario "Month N"
    /// summary rows + a Swift Charts line chart with crossover markers
    /// + per-scenario description paragraph. Baseline scenario (index
    /// 0) is excluded — it IS the reference.
    @ViewBuilder var breakEvenSection: some View {
        if viewModel.inputs.mode == .refinance,
           viewModel.inputs.scenarios.count > 1,
           let metrics = viewModel.result?.scenarioMetrics {
            let monthlyPayments = metrics.map(\.payment)
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text("Estimated break-even · refinance")
                    .textStyle(Typography.section)
                    .foregroundStyle(Palette.ink)
                Text(
                    "When cumulative monthly savings equal the scenario's closing costs. "
                    + "Actual break-even may vary with tax, insurance, or escrow changes."
                )
                    .textStyle(Typography.body.withSize(12))
                    .foregroundStyle(Palette.inkSecondary)
                    .padding(.bottom, Spacing.s12)

                breakEvenSummaryRows(monthlyPayments: monthlyPayments)
                breakEvenChart(monthlyPayments: monthlyPayments)
                    .frame(height: 200)
                    .padding(.top, Spacing.s12)
                breakEvenDescription(monthlyPayments: monthlyPayments)
            }
        }
    }

    // MARK: - Summary rows (per-scenario "Month N" labels)

    private func breakEvenSummaryRows(monthlyPayments: [Decimal]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.element.id) { idx, s in
                if idx > 0 {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s8) {
                        Circle()
                            .fill(breakdownColor(idx))
                            .frame(width: 8, height: 8)
                        Text(s.label.uppercased() + " · " + s.name)
                            .textStyle(Typography.num.withSize(12, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Text(breakEvenLabel(
                            scenarioIndex: idx,
                            monthlyPayments: monthlyPayments,
                            termYears: s.termYears
                        ))
                        .textStyle(Typography.num.withSize(12, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                    }
                }
            }
        }
    }

    func breakEvenLabel(
        scenarioIndex: Int,
        monthlyPayments: [Decimal],
        termYears: Int
    ) -> String {
        let month = viewModel.inputs.breakEvenMonth(
            scenarioIndex: scenarioIndex,
            monthlyPayments: monthlyPayments
        )
        guard let month else { return "Never (within \(termYears)-yr term)" }
        let years = Double(month) / 12.0
        return String(format: "Month %d (~%.1f years)", month, years)
    }

    // MARK: - Chart

    /// Session 5N.4 redesign — y-axis clamped to non-negative,
    /// neutral dashed reference at closing costs, crossover PointMark
    /// with "Break-even · Month N" annotation. Per-scenario color
    /// preserved so multiple refi options stay distinguishable.
    @ViewBuilder
    func breakEvenChart(monthlyPayments: [Decimal]) -> some View {
        let series = breakEvenSeries(monthlyPayments: monthlyPayments)
        let yMax = breakEvenYMax(series: series)
        Chart {
            ForEach(series) { item in
                breakEvenMarks(for: item)
            }
        }
        .chartYScale(domain: 0...yMax)
        .chartYAxis { AxisMarks(position: .leading) }
        .chartXAxisLabel("Months")
        .chartYAxisLabel("$ saved")
    }

    private func breakEvenYMax(series: [BreakEvenSeries]) -> Double {
        let savingsMax = series.flatMap(\.points).map(\.yValue).max() ?? 0
        let closingMax = series.map(\.closingCosts).max() ?? 0
        let top = max(savingsMax, closingMax)
        guard top > 0 else { return 1 }
        return top * 1.15
    }

    @ChartContentBuilder
    private func breakEvenMarks(for item: BreakEvenSeries) -> some ChartContent {
        ForEach(item.points) { pt in
            LineMark(
                x: .value("Month", pt.month),
                y: .value("$ saved", pt.yValue),
                series: .value("Scenario", item.seriesKey)
            )
            .foregroundStyle(item.color)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        RuleMark(y: .value("Closing", item.closingCosts))
            .foregroundStyle(Palette.inkTertiary.opacity(0.6))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .annotation(position: .trailing, alignment: .leading) {
                Text("Closing \(item.closingLabel)")
                    .font(.system(size: 8.5))
                    .foregroundStyle(Palette.inkTertiary)
            }
        if let crossover = item.crossover {
            PointMark(
                x: .value("Month", crossover.month),
                y: .value("Closing", item.closingCosts)
            )
            .foregroundStyle(item.color)
            .symbolSize(60)
            .annotation(position: .top, alignment: .center) {
                Text("Break-even · Month \(crossover.month)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(item.color)
            }
        }
    }

    /// Pre-compute the chart's data so the Chart body stays within
    /// Swift's type-checker budget. Each returned item corresponds to
    /// one non-baseline scenario that produces monthly savings.
    func breakEvenSeries(monthlyPayments: [Decimal]) -> [BreakEvenSeries] {
        let nonBaseline = Array(viewModel.inputs.scenarios.enumerated()).dropFirst()
        let baselinePayment = monthlyPayments.first ?? 0
        let maxMonths = nonBaseline.map { $1.termYears * 12 }.max() ?? 360
        let windowMonths = min(maxMonths, 360)
        var items: [BreakEvenSeries] = []
        for (idx, scenario) in nonBaseline {
            guard monthlyPayments.indices.contains(idx),
                  monthlyPayments[idx] < baselinePayment else { continue }
            let rawPoints = viewModel.inputs.breakEvenGraphData(
                scenarioIndex: idx,
                monthlyPayments: monthlyPayments,
                maxMonths: windowMonths
            )
            let points = rawPoints.map { raw in
                BreakEvenPoint(month: raw.month, yValue: max(0, raw.cumulative.asDouble))
            }
            let crossoverMonth = viewModel.inputs.breakEvenMonth(
                scenarioIndex: idx,
                monthlyPayments: monthlyPayments
            )
            items.append(BreakEvenSeries(
                id: idx,
                seriesKey: scenario.label,
                color: breakdownColor(idx),
                closingCosts: scenario.closingCosts.asDouble,
                closingLabel: MoneyFormat.shared.dollarsShort(scenario.closingCosts),
                points: points,
                crossover: crossoverMonth.map { BreakEvenCrossover(month: $0) }
            ))
        }
        return items
    }

    // MARK: - Description paragraph

    @ViewBuilder
    func breakEvenDescription(monthlyPayments: [Decimal]) -> some View {
        let lines = breakEvenDescriptionLines(monthlyPayments: monthlyPayments)
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .textStyle(Typography.body.withSize(11))
                        .foregroundStyle(Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, Spacing.s8)
        }
    }

    func breakEvenDescriptionLines(monthlyPayments: [Decimal]) -> [String] {
        let baselinePayment = monthlyPayments.first ?? 0
        return viewModel.inputs.scenarios.enumerated().compactMap { idx, s in
            guard idx > 0,
                  monthlyPayments.indices.contains(idx),
                  monthlyPayments[idx] < baselinePayment else { return nil }
            let month = viewModel.inputs.breakEvenMonth(
                scenarioIndex: idx,
                monthlyPayments: monthlyPayments
            )
            let label = s.label.uppercased()
            if let month {
                let years = Double(month) / 12.0
                return String(
                    format: "%@ · savings exceed closing costs at month %d (~%.1f yr). Net positive thereafter.",
                    label,
                    month,
                    years
                )
            }
            return "\(label) · savings do not exceed closing costs within the "
                + "\(s.termYears)-yr term. Consider a shorter horizon or larger rate delta."
        }
    }
}
