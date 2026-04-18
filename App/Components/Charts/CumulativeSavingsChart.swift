// CumulativeSavingsChart.swift
// Zero-crossing cumulative savings plot used on Refi Comparison. Faint
// non-winner curves, bold accent winner curve, break-even dot where
// cumulative savings cross zero.
//
// Tokens consumed: Palette.accent / gain / inkTertiary / grid,
// Typography.micro.

import SwiftUI
import Charts

public struct CumulativeSavingsSeries: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let monthlySavings: [Double]  // cumulative cash savings at each month
    public let isWinner: Bool
    public let color: Color

    public init(id: String, label: String, monthlySavings: [Double], isWinner: Bool, color: Color) {
        self.id = id
        self.label = label
        self.monthlySavings = monthlySavings
        self.isWinner = isWinner
        self.color = color
    }
}

public struct CumulativeSavingsChart: View {
    let series: [CumulativeSavingsSeries]
    let breakEvenMonth: Int?

    public init(series: [CumulativeSavingsSeries], breakEvenMonth: Int? = nil) {
        self.series = series
        self.breakEvenMonth = breakEvenMonth
    }

    public var body: some View {
        Chart {
            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(Palette.inkTertiary.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            ForEach(series) { s in
                ForEach(Array(s.monthlySavings.enumerated()), id: \.offset) { month, value in
                    LineMark(
                        x: .value("Month", month),
                        y: .value("Savings", value),
                        series: .value("Scenario", s.id)
                    )
                    .foregroundStyle(s.color)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: s.isWinner ? 2 : 0.9))
                    .opacity(s.isWinner ? 1 : 0.5)
                }
            }
            if let breakEvenMonth,
               let winner = series.first(where: \.isWinner),
               breakEvenMonth < winner.monthlySavings.count {
                PointMark(
                    x: .value("Month", breakEvenMonth),
                    y: .value("Zero", 0)
                )
                .foregroundStyle(Palette.gain)
                .symbol(.circle)
                .symbolSize(72)
                .annotation(position: .top) {
                    Text("Break-even")
                        .textStyle(Typography.micro)
                        .foregroundStyle(Palette.gain)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(Palette.grid)
                AxisValueLabel().foregroundStyle(Palette.inkTertiary)
            }
        }
        .frame(height: 190)
    }
}

private func cumulativeSample(offset: Double, slope: Double) -> [Double] {
    (0..<60).map { offset + Double($0) * slope }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.s12) {
        Eyebrow("Cumulative savings")
        CumulativeSavingsChart(
            series: [
                .init(
                    id: "A",
                    label: "Refi A",
                    monthlySavings: cumulativeSample(offset: -7_500, slope: 215),
                    isWinner: true,
                    color: Palette.accent
                ),
                .init(
                    id: "B",
                    label: "Refi B",
                    monthlySavings: cumulativeSample(offset: -10_000, slope: 185),
                    isWinner: false,
                    color: Palette.scenario2
                ),
                .init(
                    id: "C",
                    label: "Refi C",
                    monthlySavings: cumulativeSample(offset: -14_000, slope: 160),
                    isWinner: false,
                    color: Palette.scenario3
                )
            ],
            breakEvenMonth: 35
        )
    }
    .padding()
    .background(Palette.surfaceRaised)
}
