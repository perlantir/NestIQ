// Buttons.swift
// Four button variants per design README + Foundations.jsx component panel:
//   - PrimaryButton    — accent fill, accent-fg label
//   - SecondaryButton  — surface fill, border, ink label
//   - GhostButton      — transparent, accent label
//   - DestructiveButton — loss fill, accent-fg label
//
// All four share geometry (12pt CTA radius, standard paddings) and
// animate a 180ms press transition (opacity only under reduced-motion).
//
// Tokens consumed: Typography.bodyLg, Palette.*, Radius.cta, Spacing.s12,
// Motion.fastEaseOut.

import SwiftUI

private struct QuotientButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color
    let border: Color?

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(Typography.bodyLg)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s12)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.cta)
                    .stroke(border ?? .clear, lineWidth: Tokens.Stroke.hairline)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.cta))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(reduceMotion || !configuration.isPressed ? 1 : 0.98)
            .animation(reduceMotion ? nil : Motion.fastEaseOut, value: configuration.isPressed)
    }
}

// MARK: - Public wrappers

public struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void = {}) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(title, action: action)
            .buttonStyle(QuotientButtonStyle(
                background: Palette.accent,
                foreground: Palette.accentFG,
                border: nil
            ))
    }
}

public struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void = {}) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(title, action: action)
            .buttonStyle(QuotientButtonStyle(
                background: Palette.surface,
                foreground: Palette.ink,
                border: Palette.borderDefault
            ))
    }
}

public struct GhostButton: View {
    let title: String
    let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void = {}) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(title, action: action)
            .buttonStyle(QuotientButtonStyle(
                background: .clear,
                foreground: Palette.accent,
                border: nil
            ))
    }
}

public struct DestructiveButton: View {
    let title: String
    let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void = {}) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(title, action: action)
            .buttonStyle(QuotientButtonStyle(
                background: Palette.loss,
                foreground: Palette.accentFG,
                border: nil
            ))
    }
}

#Preview("Buttons · light") {
    VStack(spacing: Spacing.s12) {
        PrimaryButton("Compute amortization")
        SecondaryButton("Save scenario")
        GhostButton("Cancel")
        DestructiveButton("Delete scenario")
    }
    .padding()
    .background(Palette.surface)
}

#Preview("Buttons · dark") {
    VStack(spacing: Spacing.s12) {
        PrimaryButton("Compute amortization")
        SecondaryButton("Save scenario")
        GhostButton("Cancel")
        DestructiveButton("Delete scenario")
    }
    .padding()
    .background(Palette.surface)
    .preferredColorScheme(.dark)
}

#Preview("Buttons · Accessibility5") {
    VStack(spacing: Spacing.s12) {
        PrimaryButton("Compute amortization")
        SecondaryButton("Save scenario")
    }
    .padding()
    .background(Palette.surface)
    .environment(\.dynamicTypeSize, .accessibility5)
}
