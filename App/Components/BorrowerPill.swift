// BorrowerPill.swift
// Rounded pill at top of every calculator / scenario screen. Tapping
// it opens the borrower picker bottom sheet (Session 3 wires that).
//
// Tokens consumed: Typography.bodyLg, Palette.surfaceSunken, Palette.ink,
// Palette.inkTertiary, Radius.pill, Spacing.s8 / s12.

import SwiftUI

public struct BorrowerPill: View {
    let fullName: String
    let onTap: () -> Void

    public init(fullName: String, onTap: @escaping () -> Void = {}) {
        self.fullName = fullName
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.s8) {
                Circle()
                    .fill(Palette.accentTint)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Text(initials)
                            .textStyle(Typography.micro)
                            .foregroundStyle(Palette.accent)
                    )
                Text(fullName)
                    .textStyle(Typography.bodyLg)
                    .foregroundStyle(Palette.ink)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.horizontal, Spacing.s12)
            .padding(.vertical, Spacing.s8)
            .background(Palette.surfaceSunken)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change borrower. Currently \(fullName).")
    }

    private var initials: String {
        let parts = fullName.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.s16) {
        BorrowerPill(fullName: "John & Maya Smith")
        BorrowerPill(fullName: "Abimbola Okonkwo")
    }
    .padding()
    .background(Palette.surface)
}
