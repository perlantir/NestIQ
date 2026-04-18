// StressPathsChart.swift
// 3-curve overlay for the HELOC stress panel — rate-flat / +100bps /
// +200bps cumulative cost paths drawn over a shared horizon (typically
// 10 years, matching simulateHelocPath's horizon aggregate).
//
// Tokens consumed: Palette.accent / warn / loss / grid / inkTertiary,
// Typography.micro.

import SwiftUI
import Charts

public struct StressPath: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let monthlyCumulativeCost: [Double]
    public let color: Color

    public init(id: String, label: String, monthlyCumulativeCost: [Double], color: Color) {
        self.id = id
        self.label = label
        self.monthlyCumulativeCost = monthlyCumulativeCost
        self.color = color
    }
}

public struct StressPathsChart: View {
    let paths: [StressPath]

    public init(paths: [StressPath]) {
        self.paths = paths
    }

    public var body: some View {
        Chart {
            ForEach(paths) { path in
                ForEach(Array(path.monthlyCumulativeCost.enumerated()), id: \.offset) { month, value in
                    LineMark(
                        x: .value("Month", month),
                        y: .value("Cost", value),
                        series: .value("Path", path.id)
                    )
                    .foregroundStyle(path.color)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(Palette.grid)
                AxisValueLabel().foregroundStyle(Palette.inkTertiary)
            }
        }
        .chartForegroundStyleScale([
            "flat": Palette.accent,
            "+100bps": Palette.warn,
            "+200bps": Palette.loss
        ])
        .frame(height: 190)
    }
}

private func stressSampleSeries(rate: Double) -> [Double] {
    (0..<120).map { month in
        (50_000 * rate / 12.0) * Double(month)
    }
}

#Preview {
    StressPathsChart(paths: [
        .init(
            id: "flat",
            label: "Flat 7%",
            monthlyCumulativeCost: stressSampleSeries(rate: 0.07),
            color: Palette.accent
        ),
        .init(
            id: "+100bps",
            label: "+100bps",
            monthlyCumulativeCost: stressSampleSeries(rate: 0.08),
            color: Palette.warn
        ),
        .init(
            id: "+200bps",
            label: "+200bps",
            monthlyCumulativeCost: stressSampleSeries(rate: 0.09),
            color: Palette.loss
        )
    ])
    .padding()
    .background(Palette.surfaceRaised)
}
