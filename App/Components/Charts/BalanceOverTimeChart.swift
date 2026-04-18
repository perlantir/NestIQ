// BalanceOverTimeChart.swift
// Area + line chart showing amortized balance over time, with an
// optional accent marker at a caller-chosen "year X" milestone
// (typically 10yr, matching the Refi Comparison and Amortization Results
// spec of a "year-10 marker").
//
// Tokens consumed: Palette.accent / accentTint / ink / grid / inkTertiary,
// Typography.micro, Motion.chartDrawEaseInOut.

import SwiftUI
import Charts

public struct BalancePoint: Identifiable, Sendable {
    public let id: Int
    public let month: Int
    public let balance: Double

    public init(month: Int, balance: Double) {
        self.id = month
        self.month = month
        self.balance = balance
    }
}

public struct BalanceOverTimeChart: View {
    let points: [BalancePoint]
    let markerMonth: Int?

    public init(points: [BalancePoint], markerMonth: Int? = nil) {
        self.points = points
        self.markerMonth = markerMonth
    }

    public var body: some View {
        Chart {
            ForEach(points) { p in
                AreaMark(
                    x: .value("Month", p.month),
                    y: .value("Balance", p.balance)
                )
                .foregroundStyle(Palette.accentTint.opacity(0.7))
            }
            ForEach(points) { p in
                LineMark(
                    x: .value("Month", p.month),
                    y: .value("Balance", p.balance)
                )
                .foregroundStyle(Palette.accent)
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
            if let markerMonth,
               let marker = points.first(where: { $0.month == markerMonth }) {
                PointMark(
                    x: .value("Month", marker.month),
                    y: .value("Balance", marker.balance)
                )
                .foregroundStyle(Palette.accent)
                .symbol(.circle)
                .symbolSize(48)
                .annotation(position: .top) {
                    Text("Year \(markerMonth / 12)")
                        .textStyle(Typography.micro)
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(Palette.grid)
                AxisValueLabel().foregroundStyle(Palette.inkTertiary)
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Palette.grid)
                AxisValueLabel().foregroundStyle(Palette.inkTertiary)
            }
        }
        .frame(height: 170)
    }
}

#Preview {
    let sample: [BalancePoint] = (0...360).compactMap { m -> BalancePoint? in
        guard m % 6 == 0 else { return nil }
        let decay = pow(0.996, Double(m))
        return BalancePoint(month: m, balance: 400_000 * decay)
    }
    VStack(alignment: .leading, spacing: Spacing.s12) {
        Eyebrow("Balance over time")
        BalanceOverTimeChart(points: sample, markerMonth: 120)
    }
    .padding()
    .background(Palette.surfaceRaised)
}
