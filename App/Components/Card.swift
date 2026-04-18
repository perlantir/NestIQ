// Card.swift
// Flat + raised card containers. Design policy: elevation is effectively
// absent — division comes from hairline rules + negative space. `raised`
// switches to surfaceRaised (subtle inset card); `flat` leaves the
// parent background visible and adds the hairline border.
//
// Tokens consumed: Palette.surface / surfaceRaised / borderSubtle,
// Radius.default, Spacing.s16.

import SwiftUI

public struct Card<Content: View>: View {
    public enum Style { case flat, raised }

    let style: Style
    let padding: CGFloat
    let content: Content

    public init(
        style: Style = .flat,
        padding: CGFloat = Spacing.s16,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.default)
                    .stroke(Palette.borderSubtle, lineWidth: Tokens.Stroke.hairline)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.default))
    }

    private var fillColor: Color {
        switch style {
        case .flat:   return Palette.surface
        case .raised: return Palette.surfaceRaised
        }
    }
}

#Preview("Card · flat + raised") {
    VStack(spacing: Spacing.s16) {
        Card(style: .flat) {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                Eyebrow("Flat card")
                Text("Sits on the page background.")
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.ink)
            }
        }
        Card(style: .raised) {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                Eyebrow("Raised card")
                Text("Uses surfaceRaised for hero containers.")
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.ink)
            }
        }
    }
    .padding()
    .background(Palette.surface)
}
