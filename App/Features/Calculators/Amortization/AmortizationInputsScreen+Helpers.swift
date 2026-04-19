// AmortizationInputsScreen+Helpers.swift
// Shared field-group / divider helpers split off from AmortizationInputsScreen
// to keep the parent struct under SwiftLint's type_body_length cap.
// Same pattern already used by RefinanceInputsScreen and TCAInputsScreen.

import SwiftUI

extension AmortizationInputsScreen {
    @ViewBuilder
    func fieldGroup<Content: View>(
        header: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(header)
                .padding(.horizontal, Spacing.s20)
                .padding(.bottom, Spacing.s8)
            VStack(spacing: 0) { content() }
                .background(Palette.surfaceRaised)
                .overlay(
                    VStack(spacing: 0) {
                        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                        Spacer()
                        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                    }
                )
        }
    }

    var divider: some View {
        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
    }
}
