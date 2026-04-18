// FilterChip.swift
// Saved-screen filter chip — selectable capsule. When active, fills with
// accent; when idle, outlined on surfaceSunken.
//
// Tokens consumed: Typography.bodyLg, Palette.accent / surfaceSunken /
// borderDefault / ink, Radius.pill, Spacing.s4 / s12, Motion.fastEaseOut.

import SwiftUI

public struct FilterChip: View {
    let label: String
    let isActive: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    public init(label: String, isActive: Bool, onTap: @escaping () -> Void = {}) {
        self.label = label
        self.isActive = isActive
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            Text(label)
                .textStyle(Typography.bodyLg)
                .foregroundStyle(isActive ? Palette.accentFG : Palette.ink)
                .padding(.horizontal, Spacing.s12)
                .padding(.vertical, Spacing.s8)
                .background(isActive ? Palette.accent : Palette.surfaceSunken)
                .overlay(
                    Capsule().stroke(
                        isActive ? Palette.accent : Palette.borderDefault,
                        lineWidth: Tokens.Stroke.hairline
                    )
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(
            reduceMotion ? nil : Motion.fastEaseOut,
            value: isActive
        )
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

#Preview("FilterChip · row") {
    HStack(spacing: Spacing.s8) {
        FilterChip(label: "All", isActive: true)
        FilterChip(label: "Amort", isActive: false)
        FilterChip(label: "Refi", isActive: false)
        FilterChip(label: "TCA", isActive: false)
        FilterChip(label: "HELOC", isActive: false)
    }
    .padding()
    .background(Palette.surface)
}
