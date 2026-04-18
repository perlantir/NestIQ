// TogglePill.swift
// 42×24 pill toggle matching the design README (named TogglePill to
// avoid shadowing SwiftUI's built-in `Toggle`). Thumb animates at 180ms
// ease-out; reduced motion swaps the translation for an opacity fade.
//
// Tokens consumed: Palette.accent / surfaceSunken / ink / accentFG,
// Radius.pill, Motion.defaultEaseOut.

import SwiftUI

public struct TogglePill: View {
    @Binding var isOn: Bool
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    public init(isOn: Binding<Bool>) {
        self._isOn = isOn
    }

    public var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Palette.accent : Palette.surfaceSunken)
                    .frame(width: 42, height: 24)
                    .overlay(
                        Capsule().stroke(
                            isOn ? Palette.accent : Palette.borderDefault,
                            lineWidth: Tokens.Stroke.hairline
                        )
                    )
                Circle()
                    .fill(isOn ? Palette.accentFG : Palette.surfaceRaised)
                    .frame(width: 18, height: 18)
                    .padding(.horizontal, 3)
                    .shadow(
                        color: Palette.ink.opacity(0.08),
                        radius: 1,
                        y: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : Motion.defaultEaseOut, value: isOn)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

#Preview {
    StatefulTogglePreview()
        .padding()
        .background(Palette.surface)
}

private struct StatefulTogglePreview: View {
    @State private var a = true
    @State private var b = false
    @State private var c = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            row("Face ID unlock", $a)
            row("Share app analytics", $b)
            row("Haptics", $c)
        }
    }

    private func row(_ label: String, _ bind: Binding<Bool>) -> some View {
        HStack {
            Text(label).textStyle(Typography.bodyLg)
                .foregroundStyle(Palette.ink)
            Spacer()
            TogglePill(isOn: bind)
        }
    }
}
