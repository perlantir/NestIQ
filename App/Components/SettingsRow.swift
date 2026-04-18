// SettingsRow.swift
// `SettingsSection` + `SettingsRow` — iOS grouped list with the 26pt inset
// card radius per design README. Sections carry an eyebrow title; rows
// use 17pt text per README.
//
// Tokens consumed: Typography.bodyLg / eyebrow / num / body,
// Palette.surfaceRaised / inkSecondary / borderSubtle / inkTertiary /
// accent, Radius.iosGroupedList, Spacing.s8 / s16 / s20.

import SwiftUI

public struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow(title)
                .padding(.horizontal, Spacing.s16)
            VStack(spacing: 0) {
                content
            }
            .background(Palette.surfaceRaised)
            .clipShape(
                RoundedRectangle(cornerRadius: Radius.iosGroupedList, style: .continuous)
            )
        }
    }
}

public struct SettingsRow: View {
    public enum Trailing {
        case value(String)
        case toggle(Binding<Bool>)
        case disclosure
        case none
    }

    let label: String
    let trailing: Trailing
    let onTap: (() -> Void)?

    public init(label: String, trailing: Trailing = .disclosure, onTap: (() -> Void)? = nil) {
        self.label = label
        self.trailing = trailing
        self.onTap = onTap
    }

    public var body: some View {
        VStack(spacing: 0) {
            Button {
                onTap?()
            } label: {
                HStack(spacing: Spacing.s16) {
                    Text(label)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    trailingView
                }
                .padding(.horizontal, Spacing.s16)
                .padding(.vertical, Spacing.s12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(onTap == nil && !isInteractive)
            HairlineDivider()
                .padding(.leading, Spacing.s16)
        }
    }

    private var isInteractive: Bool {
        if case .toggle = trailing { return true }
        return false
    }

    @ViewBuilder private var trailingView: some View {
        switch trailing {
        case let .value(value):
            Text(value)
                .textStyle(Typography.body)
                .foregroundStyle(Palette.inkSecondary)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.inkTertiary)
        case let .toggle(binding):
            TogglePill(isOn: binding)
        case .disclosure:
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.inkTertiary)
        case .none:
            EmptyView()
        }
    }
}

#Preview {
    StatefulSettingsPreview()
        .padding()
        .background(Palette.surface)
}

private struct StatefulSettingsPreview: View {
    @State private var faceID = true
    @State private var haptics = true
    @State private var analytics = false

    var body: some View {
        VStack(spacing: Spacing.s20) {
            SettingsSection(title: "Profile") {
                SettingsRow(label: "Name", trailing: .value("Nick Gallick"), onTap: {})
                SettingsRow(label: "NMLS #", trailing: .value("2043012"), onTap: {})
                SettingsRow(label: "Licensed states", trailing: .value("CA · TX"), onTap: {})
            }
            SettingsSection(title: "Privacy") {
                SettingsRow(label: "Face ID unlock", trailing: .toggle($faceID))
                SettingsRow(label: "Share app analytics", trailing: .toggle($analytics))
                SettingsRow(label: "Haptics & sounds", trailing: .toggle($haptics))
            }
        }
    }
}
