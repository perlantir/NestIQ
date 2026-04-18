// DatePill.swift
// Section header for the Saved screen's date buckets ("Today" /
// "This week" / "Earlier"). Lightweight capsule on surfaceSunken.
//
// Tokens consumed: Typography.eyebrow, Palette.surfaceSunken,
// Palette.inkSecondary, Radius.pill, Spacing.s4 / s12.

import SwiftUI

public struct DatePill: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text.uppercased())
            .textStyle(Typography.eyebrow)
            .foregroundStyle(Palette.inkSecondary)
            .padding(.horizontal, Spacing.s12)
            .padding(.vertical, Spacing.s4)
            .background(Palette.surfaceSunken)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.s16) {
        DatePill("Today")
        DatePill("This week")
        DatePill("Earlier")
    }
    .padding()
    .background(Palette.surface)
}
