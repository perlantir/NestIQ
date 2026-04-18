// StackedHorizontalBar.swift
// Segmented horizontal bar used for the PITI breakdown on the
// Amortization Results hero. Each segment renders proportional to its
// value; colors come in via `segments`.
//
// Tokens consumed: Radius.chartBar, Palette.grid, Spacing.s4,
// Motion.chartDrawEaseInOut.

import SwiftUI

public struct StackedHorizontalBarSegment: Identifiable, Sendable {
    public let id: String
    public let value: Double
    public let color: Color

    public init(id: String, value: Double, color: Color) {
        self.id = id
        self.value = value
        self.color = color
    }
}

public struct StackedHorizontalBar: View {
    let segments: [StackedHorizontalBarSegment]
    let height: CGFloat
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    public init(segments: [StackedHorizontalBarSegment], height: CGFloat = 12) {
        self.segments = segments
        self.height = height
    }

    public var body: some View {
        GeometryReader { proxy in
            let total = max(segments.reduce(0) { $0 + $1.value }, .ulpOfOne)
            HStack(spacing: 2) {
                ForEach(segments) { seg in
                    RoundedRectangle(cornerRadius: Radius.chartBar)
                        .fill(seg.color)
                        .frame(width: max(0, (seg.value / total) * proxy.size.width - 2))
                }
            }
            .frame(height: height)
        }
        .frame(height: height)
        .animation(
            reduceMotion ? nil : Motion.chartDrawEaseInOut,
            value: segments.map(\.value)
        )
        .accessibilityLabel(summaryLabel)
    }

    private var summaryLabel: String {
        let parts = segments.map { "\($0.id) \(Int($0.value))" }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.s12) {
        Eyebrow("PITI breakdown")
        StackedHorizontalBar(segments: [
            .init(id: "Principal", value: 447, color: Palette.accent),
            .init(id: "Interest", value: 3_083, color: Palette.accentHover),
            .init(id: "Taxes", value: 542, color: Palette.scenario2),
            .init(id: "Insurance", value: 135, color: Palette.scenario3),
            .init(id: "PMI", value: 0, color: Palette.warn)
        ])
        HStack(spacing: Spacing.s16) {
            DataRow(label: "Principal", value: "$447", showDivider: false)
            DataRow(label: "Interest", value: "$3,083", showDivider: false)
        }
    }
    .padding()
    .background(Palette.surfaceRaised)
}
