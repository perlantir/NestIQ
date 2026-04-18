// OnboardingStep.swift
// One step of the 6-step onboarding tour: eyebrow + Source Serif 4
// title + body paragraph + lower-60% miniature slot. The host view
// owns paging / progress / dock; this component just lays out the
// content block.
//
// Tokens consumed: Typography.eyebrow / serifStepTitle / body,
// Palette.ink / inkSecondary, Spacing.s8 / s16 / s32.

import SwiftUI

public struct OnboardingStep<Miniature: View>: View {
    let eyebrow: String
    let title: String
    let paragraph: String
    let miniature: Miniature

    public init(
        eyebrow: String,
        title: String,
        paragraph: String,
        @ViewBuilder miniature: () -> Miniature
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.paragraph = paragraph
        self.miniature = miniature()
    }

    public var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: Spacing.s32) {
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    Eyebrow(eyebrow)
                    Text(title)
                        .textStyle(Typography.serifStepTitle)
                        .foregroundStyle(Palette.ink)
                    Text(paragraph)
                        .textStyle(Typography.body)
                        .foregroundStyle(Palette.inkSecondary)
                        .lineSpacing(2)
                }
                miniature
                    .frame(height: proxy.size.height * 0.6, alignment: .bottom)
            }
            .padding(Spacing.s32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    OnboardingStep(
        eyebrow: "Amortization",
        title: "See every dollar — principal, interest, PMI — over 360 months.",
        paragraph: "The amortization engine handles extras, recasts, biweekly, and PMI drop automatically."
    ) {
        KPITile(label: "Monthly PITI", value: "$4,207.00", size: .hero)
    }
    .frame(height: 600)
    .background(Palette.surface)
}
