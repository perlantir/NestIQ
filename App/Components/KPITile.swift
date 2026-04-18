// KPITile.swift
// Large-number + micro-label tile used in hero KPI strips (Refi
// winner, TCA row summary, Share cover). Sizes pair with the numeric
// typography scale: `.hero` pairs with numHero + micro, `.regular`
// pairs with numLg + eyebrow.
//
// Tokens consumed: Typography.numHero / numLg / micro / eyebrow,
// Palette.ink / inkTertiary, Spacing.s4.

import SwiftUI

public struct KPITile: View {
    public enum Size { case hero, regular }

    let label: String
    let value: String
    let subLabel: String?
    let size: Size
    let valueColor: Color

    public init(
        label: String,
        value: String,
        subLabel: String? = nil,
        size: Size = .regular,
        valueColor: Color = Palette.ink
    ) {
        self.label = label
        self.value = value
        self.subLabel = subLabel
        self.size = size
        self.valueColor = valueColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Eyebrow(label)
            MonoNumber(value, size: size == .hero ? .hero : .large, color: valueColor)
            if let subLabel {
                Text(subLabel)
                    .textStyle(Typography.num)
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
    }
}

#Preview("KPITile · hero + grid") {
    VStack(alignment: .leading, spacing: Spacing.s24) {
        KPITile(label: "Monthly PITI", value: "$4,207.00", size: .hero)
        HStack(spacing: Spacing.s24) {
            KPITile(label: "Break-even", value: "24 mo", subLabel: "Mar 2028")
            KPITile(label: "Lifetime Δ", value: "+$18,400", valueColor: Palette.gain)
            KPITile(label: "NPV @ 5%", value: "$12,840")
            KPITile(label: "Rate", value: "6.250%")
        }
    }
    .padding()
    .background(Palette.surfaceRaised)
}
