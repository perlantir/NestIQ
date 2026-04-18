// Eyebrow.swift
// Uppercase tracked section label. `Typography.eyebrow` already sets the
// font + tracking — this view adds the uppercase transform and the
// default `inkTertiary` color so call sites read: `Eyebrow("Balance over time")`.
//
// Tokens consumed: Typography.eyebrow, Palette.inkTertiary.

import SwiftUI

public struct Eyebrow: View {
    let text: String
    let color: Color

    public init(_ text: String, color: Color = Palette.inkTertiary) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text.uppercased())
            .textStyle(Typography.eyebrow)
            .foregroundStyle(color)
    }
}

#Preview("Eyebrow · light") {
    VStack(alignment: .leading, spacing: 8) {
        Eyebrow("Today · National average")
        Eyebrow("Break-even")
        Eyebrow("Compliance", color: Palette.loss)
    }
    .padding()
    .background(Palette.surface)
}

#Preview("Eyebrow · dark") {
    Eyebrow("Today · National average")
        .padding()
        .background(Palette.surface)
        .preferredColorScheme(.dark)
}
