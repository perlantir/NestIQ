// BottomActionDock.swift
// Three-action dock pinned to the bottom of every calculator Results
// screen: Narrate / Save / Share as PDF. Translucent background with
// hairline top border, respects safe area.
//
// Tokens consumed: Palette.surface / accent / ink / borderSubtle,
// Typography.bodyLg, Spacing.s8 / s12 / s16.

import SwiftUI

public struct BottomActionDock: View {
    let onNarrate: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void

    public init(
        onNarrate: @escaping () -> Void = {},
        onSave: @escaping () -> Void = {},
        onShare: @escaping () -> Void = {}
    ) {
        self.onNarrate = onNarrate
        self.onSave = onSave
        self.onShare = onShare
    }

    public var body: some View {
        VStack(spacing: 0) {
            HairlineDivider()
            HStack(spacing: Spacing.s12) {
                dockButton(label: "Narrate", systemImage: "waveform", action: onNarrate)
                dockButton(label: "Save", systemImage: "bookmark", action: onSave)
                dockButton(label: "Share", systemImage: "square.and.arrow.up", action: onShare)
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
        }
        .background(Palette.surface.opacity(0.92))
    }

    private func dockButton(
        label: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.s4) {
                Image(systemName: systemImage)
                    .font(.system(size: Tokens.IconSize.default, weight: .regular))
                    .foregroundStyle(Palette.accent)
                Text(label)
                    .textStyle(Typography.bodyLg)
                    .foregroundStyle(Palette.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        BottomActionDock()
    }
    .frame(height: 200)
    .background(Palette.surface)
}
