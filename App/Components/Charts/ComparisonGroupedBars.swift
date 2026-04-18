// ComparisonGroupedBars.swift
// Small grouped bar cluster per-horizon used inside the Total Cost
// Analysis row cells. Each group has one bar per scenario — bar heights
// are proportional to the scenario's total cost at that horizon.
//
// Tokens consumed: Palette scenarios[] + gain, Radius.chartBar,
// Typography.micro, Spacing.s8 / s12.

import SwiftUI
import Charts

public struct ComparisonBarGroup: Identifiable, Sendable {
    public let id: String
    public let horizon: String
    public let costs: [Double]       // parallel to scenarios
    public let winnerIndex: Int?     // scenario index to highlight, nil = no winner

    public init(id: String, horizon: String, costs: [Double], winnerIndex: Int?) {
        self.id = id
        self.horizon = horizon
        self.costs = costs
        self.winnerIndex = winnerIndex
    }
}

public struct ComparisonGroupedBars: View {
    let groups: [ComparisonBarGroup]
    let scenarioColors: [Color]

    public init(
        groups: [ComparisonBarGroup],
        scenarioColors: [Color] = Palette.scenarios
    ) {
        self.groups = groups
        self.scenarioColors = scenarioColors
    }

    public var body: some View {
        Chart {
            ForEach(groups) { group in
                ForEach(Array(group.costs.enumerated()), id: \.offset) { idx, value in
                    BarMark(
                        x: .value("Horizon", group.horizon),
                        y: .value("Cost", value)
                    )
                    .position(by: .value("Scenario", idx))
                    .foregroundStyle(color(for: idx, winner: group.winnerIndex))
                    .cornerRadius(Radius.chartBar)
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
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel().foregroundStyle(Palette.inkSecondary)
            }
        }
        .frame(height: 180)
    }

    private func color(for idx: Int, winner: Int?) -> Color {
        let base = scenarioColors[idx % scenarioColors.count]
        if let winner, idx == winner { return Palette.gain }
        return base
    }
}

#Preview {
    ComparisonGroupedBars(groups: [
        .init(id: "5", horizon: "5yr", costs: [180_000, 175_000, 178_000], winnerIndex: 1),
        .init(id: "7", horizon: "7yr", costs: [240_000, 235_000, 238_000], winnerIndex: 1),
        .init(id: "10", horizon: "10yr", costs: [320_000, 315_000, 319_000], winnerIndex: 1),
        .init(id: "15", horizon: "15yr", costs: [440_000, 438_000, 447_000], winnerIndex: 1),
        .init(id: "30", horizon: "30yr", costs: [830_000, 825_000, 850_000], winnerIndex: 1)
    ])
    .padding()
    .background(Palette.surfaceRaised)
}
