// MonoNumber.swift
// Numeric display in SF Mono with tabular digits — every financial figure
// in Quotient uses this. Three sizes match the Typography scale:
//   - .hero (46pt)   — PITI hero, Max Qualifying Loan
//   - .large (26pt)  — secondary KPIs (break-even, lifetime delta)
//   - .regular (13pt) — schedule rows, delta chips, rate cells
//
// Tokens consumed: Typography.numHero / numLg / num, Palette.ink (default).

import SwiftUI

public struct MonoNumber: View {
    public enum Size {
        case hero, large, regular
    }

    let text: String
    let size: Size
    let color: Color

    public init(_ text: String, size: Size = .regular, color: Color = Palette.ink) {
        self.text = text
        self.size = size
        self.color = color
    }

    public var body: some View {
        Text(text)
            .textStyle(style)
            .foregroundStyle(color)
    }

    private var style: TextStyle {
        switch size {
        case .hero:    return Typography.numHero
        case .large:   return Typography.numLg
        case .regular: return Typography.num
        }
    }
}

#Preview("MonoNumber") {
    VStack(alignment: .leading, spacing: 16) {
        MonoNumber("$4,207.00", size: .hero)
        MonoNumber("24 mo", size: .large)
        MonoNumber("547,553.02")
        MonoNumber("+$212 / mo", size: .large, color: Palette.gain)
        MonoNumber("−$87 / mo", size: .large, color: Palette.loss)
    }
    .padding()
    .background(Palette.surface)
}
