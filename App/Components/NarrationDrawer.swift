// NarrationDrawer.swift
// Streaming narration sheet — renders token-by-token text as it arrives
// from `QuotientNarration` (Session 4 wires the stream). Exposes
// "Regenerate" and "Accept" actions at the bottom.
//
// Tokens consumed: Typography.h2 / serifNarrative / bodyLg,
// Palette.surfaceRaised / ink / inkSecondary, Radius.iosGroupedList,
// Spacing.s16 / s24, Motion.defaultEaseOut.

import SwiftUI

public struct NarrationDrawer: View {
    let streamedText: String
    let isStreaming: Bool
    let onRegenerate: () -> Void
    let onAccept: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    public init(
        streamedText: String,
        isStreaming: Bool,
        onRegenerate: @escaping () -> Void = {},
        onAccept: @escaping () -> Void = {}
    ) {
        self.streamedText = streamedText
        self.isStreaming = isStreaming
        self.onRegenerate = onRegenerate
        self.onAccept = onAccept
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            HStack {
                Text("Narrative")
                    .textStyle(Typography.h2)
                    .foregroundStyle(Palette.ink)
                Spacer()
                if isStreaming {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            ScrollView {
                Text(streamedText)
                    .textStyle(Typography.serifNarrative)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(
                        reduceMotion ? nil : Motion.defaultEaseOut,
                        value: streamedText
                    )
            }
            HStack(spacing: Spacing.s12) {
                SecondaryButton("Regenerate", action: onRegenerate)
                PrimaryButton("Accept", action: onAccept)
            }
        }
        .padding(Spacing.s24)
        .background(Palette.surfaceRaised)
        .clipShape(
            RoundedRectangle(cornerRadius: Radius.iosGroupedList, style: .continuous)
        )
    }
}

#Preview {
    let sample = """
        Your refinance into a 6.25% 30-year fixed would reduce the monthly \
        principal and interest payment by $212 versus your current 7.5% loan. \
        Over ten years, this saves an estimated $18,400 after closing costs \
        are recovered at month 24.
        """
    return NarrationDrawer(streamedText: sample, isStreaming: false)
        .padding()
        .frame(height: 420)
        .background(Palette.surface)
}
