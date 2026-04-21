// CalculatorDock.swift
// Shared 3-button bottom dock (Narrate / Save / Share as PDF) used by
// every calculator results screen. Matches the Amortization flagship
// styling (text-label buttons against an ultra-thin material) rather
// than the icon+text `BottomActionDock` component — the design README's
// per-calculator screens show text-only buttons, and the flagship
// pattern is what Nick asked to replicate across Income / Refi / TCA /
// HELOC in Session 4.5.

import SwiftUI

struct CalculatorDock: View {
    let saveLabel: String
    let onNarrate: () -> Void
    let onSave: () -> Void
    let onShare: (() -> Void)?

    init(
        saveLabel: String = "Save",
        onNarrate: @escaping () -> Void,
        onSave: @escaping () -> Void,
        onShare: (() -> Void)? = nil
    ) {
        self.saveLabel = saveLabel
        self.onNarrate = onNarrate
        self.onSave = onSave
        self.onShare = onShare
    }

    var body: some View {
        HStack(spacing: Spacing.s8) {
            Button(action: onNarrate) {
                Text("Narrate")
                    .textStyle(Typography.bodyLg)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s12)
                    .background(Palette.surfaceRaised)
                    .overlay(border)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("dock.narrate")

            // WARNING: do NOT add `.layoutPriority` to any button in
            // this HStack. With all three labels at `.frame(maxWidth:
            // .infinity)`, bumping one's priority squashes the other
            // two to ~0 pt; they remain in the AX tree (so
            // `XCUIElement.tap()` thinks it has a target) but the
            // visible-and-tappable area belongs to the priority button.
            // That's the Session 5E.1 root cause for Save looking
            // broken in Nick's QA.
            Button(action: onSave) {
                Text(saveLabel)
                    .textStyle(Typography.bodyLg)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s12)
                    .background(Palette.surfaceRaised)
                    .overlay(border)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("dock.save")

            if let onShare {
                Button(action: onShare) {
                    Text("Share as PDF")
                        .textStyle(Typography.bodyLg.withWeight(.semibold))
                        .foregroundStyle(Palette.accentFG)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.s12)
                        .background(Palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("dock.share")
            }
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.top, Spacing.s12)
        .padding(.bottom, Spacing.s32)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle().fill(Palette.borderSubtle).frame(height: 1),
            alignment: .top
        )
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: Radius.listCard)
            .stroke(Palette.borderSubtle, lineWidth: 1)
    }
}
