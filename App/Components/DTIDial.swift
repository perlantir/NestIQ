// DTIDial.swift
// Gauge-style circular progress for Income Qualification — front-end and
// back-end DTI against the agency limit (28 / 43–50%). Arc sweeps clockwise
// from the 6-o'clock position; warn color past the limit.
//
// Tokens consumed: Palette.accent / warn / loss / accentTint / grid,
// Typography.numLg / eyebrow / num, Spacing.s8.

import SwiftUI

public struct DTIDial: View {
    let title: String
    let ratio: Double        // 0..1.25 typically — can exceed 1 when over limit
    let limit: Double        // 0..1 where the dial turns warn/loss
    let size: CGFloat

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    public init(title: String, ratio: Double, limit: Double, size: CGFloat = 140) {
        self.title = title
        self.ratio = ratio
        self.limit = limit
        self.size = size
    }

    public var body: some View {
        VStack(spacing: Spacing.s8) {
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Palette.grid, style: strokeStyle)
                    .rotationEffect(.degrees(135))
                Circle()
                    .trim(from: 0, to: min(ratio, 1) * 0.75)
                    .stroke(arcColor, style: strokeStyle)
                    .rotationEffect(.degrees(135))
                    .animation(
                        reduceMotion ? nil : Motion.chartDrawEaseInOut,
                        value: ratio
                    )
                VStack(spacing: 2) {
                    MonoNumber(String(format: "%.0f%%", ratio * 100), size: .large, color: arcColor)
                    Eyebrow("Limit \(Int(limit * 100))%")
                }
            }
            .frame(width: size, height: size)
            Text(title)
                .textStyle(Typography.eyebrow)
                .foregroundStyle(Palette.inkTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(Int(ratio * 100)) percent of the \(Int(limit * 100)) percent limit.")
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: 10, lineCap: .round)
    }

    private var arcColor: Color {
        if ratio > 1 { return Palette.loss }
        if ratio > limit { return Palette.warn }
        return Palette.accent
    }
}

#Preview {
    HStack(spacing: Spacing.s24) {
        DTIDial(title: "Front-end", ratio: 0.21, limit: 0.28)
        DTIDial(title: "Back-end", ratio: 0.42, limit: 0.43)
        DTIDial(title: "Back-end (over)", ratio: 0.51, limit: 0.43)
    }
    .padding()
    .background(Palette.surface)
}
