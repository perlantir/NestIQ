// NarrationSheet.swift
// Presents the NarrationDrawer component against a streaming
// QuotientNarrator for any calculator's facts. Regenerate kicks off
// a fresh stream; Accept dismisses + reports the final text.

import SwiftUI
import QuotientNarration

struct NarrationSheet: View {
    let facts: ScenarioFacts
    let onAccept: (String) -> Void

    @State private var streamed: String = ""
    @State private var isStreaming: Bool = false
    @State private var flaggedNumbers: [String] = []

    @Environment(\.dismiss)
    private var dismiss

    private let narrator = QuotientNarrator()

    var body: some View {
        VStack(spacing: 0) {
            NarrationDrawer(
                streamedText: streamed,
                isStreaming: isStreaming,
                onRegenerate: { Task { await regenerate() } },
                onAccept: {
                    onAccept(streamed)
                    dismiss()
                }
            )
            if !flaggedNumbers.isEmpty {
                flaggedBanner
            }
        }
        .padding(Spacing.s16)
        .background(Palette.surface)
        .task { await regenerate() }
    }

    private var flaggedBanner: some View {
        HStack(alignment: .top, spacing: Spacing.s8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.warn)
            VStack(alignment: .leading, spacing: 2) {
                Text("Flagged numbers")
                    .textStyle(Typography.bodyLg.withWeight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text(flaggedNumbers.joined(separator: ", "))
                    .textStyle(Typography.num.withSize(12))
                    .foregroundStyle(Palette.inkSecondary)
                Text("Review before accepting — these aren't in the known-facts allowlist.")
                    .textStyle(Typography.body.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
        .padding(Spacing.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.warnTint)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.default)
                .stroke(Palette.warn.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.default))
        .padding(.top, Spacing.s8)
    }

    private func regenerate() async {
        streamed = ""
        flaggedNumbers = []
        isStreaming = true
        defer { isStreaming = false }
        do {
            let stream = narrator.narrate(facts)
            for try await chunk in stream {
                streamed += chunk.text
                if !chunk.flaggedUnknownNumbers.isEmpty {
                    flaggedNumbers.append(contentsOf: chunk.flaggedUnknownNumbers)
                }
            }
        } catch {
            streamed += "\n\n[Narration failed: \(error.localizedDescription)]"
        }
    }
}
