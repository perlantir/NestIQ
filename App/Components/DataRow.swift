// DataRow.swift
// Label-on-left / mono-value-on-right row with a bottom hairline. The
// default amortization/PITI/scheduling breakdown row.
//
// Tokens consumed: Typography.body, Typography.num, Palette.inkSecondary,
// Palette.ink, Spacing.s8, HairlineDivider.

import SwiftUI

public struct DataRow: View {
    let label: String
    let value: String
    let valueColor: Color
    let showDivider: Bool

    public init(
        label: String,
        value: String,
        valueColor: Color = Palette.ink,
        showDivider: Bool = true
    ) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.showDivider = showDivider
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.inkSecondary)
                Spacer(minLength: Spacing.s8)
                MonoNumber(value, color: valueColor)
            }
            .padding(.vertical, Spacing.s8)
            if showDivider {
                HairlineDivider()
            }
        }
    }
}

#Preview("DataRow · PITI breakdown") {
    VStack(alignment: .leading, spacing: 0) {
        DataRow(label: "Principal", value: "$447")
        DataRow(label: "Interest", value: "$3,083")
        DataRow(label: "Taxes", value: "$542")
        DataRow(label: "Insurance", value: "$135")
        DataRow(label: "HOA", value: "$0", showDivider: false)
    }
    .padding()
    .background(Palette.surfaceRaised)
}

#Preview("DataRow · dark") {
    DataRow(label: "Break-even", value: "24 mo", valueColor: Palette.accent)
        .padding()
        .background(Palette.surface)
        .preferredColorScheme(.dark)
}
