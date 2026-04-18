// SegmentedControl.swift
// Term selector (and similar small-set pickers) per Foundations.jsx:
// equal-width mono segments on surfaceSunken, selected segment fills
// with accent. Selection updates animate in 180ms (opacity-only under
// reduced motion).
//
// Tokens consumed: Typography.num, Palette.accent / accentFG /
// surfaceSunken / borderSubtle / ink / inkSecondary, Radius.segmented,
// Motion.defaultEaseOut.

import SwiftUI

public struct SegmentedControl<Option: Hashable>: View {
    let options: [Option]
    let label: (Option) -> String
    @Binding var selection: Option

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    public init(
        options: [Option],
        selection: Binding<Option>,
        label: @escaping (Option) -> String
    ) {
        self.options = options
        self._selection = selection
        self.label = label
    }

    public var body: some View {
        HStack(spacing: Spacing.s4) {
            ForEach(options, id: \.self) { option in
                segment(for: option)
            }
        }
    }

    private func segment(for option: Option) -> some View {
        let isSelected = option == selection
        return Button {
            selection = option
        } label: {
            Text(label(option))
                .textStyle(Typography.num)
                .foregroundStyle(isSelected ? Palette.accentFG : Palette.inkSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s8)
                .background(isSelected ? Palette.accent : Palette.surfaceSunken)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.segmented)
                        .stroke(
                            isSelected ? Palette.accent : Palette.borderSubtle,
                            lineWidth: Tokens.Stroke.hairline
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.segmented))
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : Motion.defaultEaseOut, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    StatefulPreview(initialValue: 30) { binding in
        VStack(alignment: .leading, spacing: Spacing.s16) {
            Eyebrow("Term · years")
            SegmentedControl(
                options: [10, 15, 20, 25, 30, 40],
                selection: binding,
                label: { "\($0)" }
            )
        }
        .padding()
        .background(Palette.surface)
    }
}

// MARK: - Preview helper

private struct StatefulPreview<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View { content($value) }
}
