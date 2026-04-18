// CalculatorListRow.swift
// Home-screen numbered calculator row (01 · Amortization, 02 · Income
// Qualification, ...). Number eyebrow on left, title in sans, SF Mono
// counter on right (for "N scenarios" or similar).
//
// Tokens consumed: Typography.title / num / eyebrow, Palette.ink /
// inkTertiary / borderSubtle, Spacing.s8 / s16, HairlineDivider.

import SwiftUI

public struct CalculatorListRow: View {
    let number: String      // "01", "02", ...
    let title: String
    let metric: String?     // right-aligned mono metric
    let onTap: () -> Void

    public init(
        number: String,
        title: String,
        metric: String? = nil,
        onTap: @escaping () -> Void = {}
    ) {
        self.number = number
        self.title = title
        self.metric = metric
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s16) {
                Text(number)
                    .textStyle(Typography.num)
                    .foregroundStyle(Palette.inkTertiary)
                Text(title)
                    .textStyle(Typography.title)
                    .foregroundStyle(Palette.ink)
                Spacer()
                if let metric {
                    MonoNumber(metric, color: Palette.inkSecondary)
                }
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.accent)
            }
            .padding(.vertical, Spacing.s16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 0) {
        CalculatorListRow(number: "01", title: "Amortization", metric: "12 saved")
        HairlineDivider()
        CalculatorListRow(number: "02", title: "Income Qualification", metric: "4 saved")
        HairlineDivider()
        CalculatorListRow(number: "03", title: "Refinance Comparison", metric: nil)
        HairlineDivider()
        CalculatorListRow(number: "04", title: "Total Cost Analysis", metric: "2 saved")
        HairlineDivider()
        CalculatorListRow(number: "05", title: "HELOC vs Refinance", metric: nil)
    }
    .padding(.horizontal, Spacing.s16)
    .background(Palette.surface)
}
