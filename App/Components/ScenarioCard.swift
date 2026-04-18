// ScenarioCard.swift
// List-card used in Saved Scenarios and Home's "recent" stack.
// Calculator label pill (mono) + borrower name + mono key stat +
// right-aligned timestamp. Row radius 10pt per README.
//
// Tokens consumed: Palette.surfaceRaised / accentTint / accent /
// borderSubtle / ink / inkSecondary / inkTertiary, Typography.num /
// title / bodyLg / eyebrow, Radius.listCard, Radius.monoChip.

import SwiftUI

public struct ScenarioCard: View {
    let calculatorLabel: String
    let calculatorColor: Color
    let borrowerName: String
    let keyStat: String
    let timestamp: String
    let onTap: () -> Void

    public init(
        calculatorLabel: String,
        calculatorColor: Color = Palette.accent,
        borrowerName: String,
        keyStat: String,
        timestamp: String,
        onTap: @escaping () -> Void = {}
    ) {
        self.calculatorLabel = calculatorLabel
        self.calculatorColor = calculatorColor
        self.borrowerName = borrowerName
        self.keyStat = keyStat
        self.timestamp = timestamp
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                HStack(spacing: Spacing.s8) {
                    calcChip
                    Spacer()
                    Text(timestamp)
                        .textStyle(Typography.num)
                        .foregroundStyle(Palette.inkTertiary)
                }
                Text(borrowerName)
                    .textStyle(Typography.bodyLg)
                    .foregroundStyle(Palette.ink)
                MonoNumber(keyStat, size: .large, color: Palette.ink)
            }
            .padding(Spacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surfaceRaised)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.listCard)
                    .stroke(Palette.borderSubtle, lineWidth: Tokens.Stroke.hairline)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
        }
        .buttonStyle(.plain)
    }

    private var calcChip: some View {
        Text(calculatorLabel.uppercased())
            .textStyle(Typography.micro)
            .foregroundStyle(calculatorColor)
            .padding(.horizontal, Spacing.s8)
            .padding(.vertical, 2)
            .background(Palette.accentTint)
            .clipShape(RoundedRectangle(cornerRadius: Radius.monoChip))
    }
}

#Preview {
    VStack(spacing: Spacing.s12) {
        ScenarioCard(
            calculatorLabel: "Amortization",
            borrowerName: "John & Maya Smith",
            keyStat: "$4,207 / mo",
            timestamp: "2h ago"
        )
        ScenarioCard(
            calculatorLabel: "Refinance",
            calculatorColor: Palette.scenario2,
            borrowerName: "Abimbola Okonkwo",
            keyStat: "+$212 savings",
            timestamp: "yesterday"
        )
        ScenarioCard(
            calculatorLabel: "HELOC",
            calculatorColor: Palette.scenario3,
            borrowerName: "Delphine Araujo",
            keyStat: "blended 6.84%",
            timestamp: "Apr 2"
        )
    }
    .padding()
    .background(Palette.surface)
}
