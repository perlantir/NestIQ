// HairlineDivider.swift
// 1pt horizontal divider in Palette.borderSubtle. The design policy per
// README is "hierarchy by rule and space" — this is the rule.
//
// Tokens consumed: Tokens.Stroke.hairline, Palette.borderSubtle.

import SwiftUI

public struct HairlineDivider: View {
    let color: Color

    public init(color: Color = Palette.borderSubtle) {
        self.color = color
    }

    public var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: Tokens.Stroke.hairline)
    }
}

#Preview {
    VStack(spacing: 12) {
        Text("Row 1").textStyle(Typography.body)
        HairlineDivider()
        Text("Row 2").textStyle(Typography.body)
        HairlineDivider(color: Palette.borderDefault)
        Text("Row 3").textStyle(Typography.body)
    }
    .padding()
    .background(Palette.surface)
}
