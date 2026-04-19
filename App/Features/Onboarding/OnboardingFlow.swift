// OnboardingFlow.swift
// 6-step tour per design/screens/Onboarding.jsx. Step 0 is welcome;
// steps 1-5 each introduce one calculator with an in-situ miniature of
// its signature output.
//
// The flow owns paging + progress dots + bottom dock. Each step uses
// the shared `OnboardingStep` component for its content block. Miniatures
// are local SwiftUI reconstructions of the JSX SVG-based demos.
//
// On completion (Get started / Skip), the caller marks the profile's
// `hasCompletedOnboarding = true` and RootView advances to the tab bar.

import SwiftUI

public enum OnboardingStepID: Int, CaseIterable, Sendable {
    case welcome, amortization, incomeQual, refinance, tca, heloc
}

struct OnboardingFlow: View {
    let onFinish: () -> Void

    @State private var index: Int = 0

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, Spacing.s8)
                ScrollView {
                    stepBody
                        .padding(.top, Spacing.s24)
                        .padding(.bottom, 140)
                }
                .scrollIndicators(.hidden)
                .transition(.opacity)
                .id(index)
            }

            bottomDock
        }
        .animation(reduceMotion ? .linear(duration: Motion.slow) : Motion.slowEaseOut,
                   value: index)
    }

    // MARK: Subviews

    private var topBar: some View {
        HStack(spacing: Spacing.s16) {
            HStack(spacing: 4) {
                ForEach(0..<6, id: \.self) { i in
                    Capsule()
                        .fill(i <= index ? Palette.accent : Palette.borderSubtle)
                        .frame(width: 22, height: 3)
                }
            }
            Spacer()
            Button {
                onFinish()
            } label: {
                Text("Skip")
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
        .padding(.horizontal, Spacing.s20)
    }

    @ViewBuilder private var stepBody: some View {
        switch OnboardingStepID.allCases[index] {
        case .welcome:
            VStack(alignment: .center, spacing: Spacing.s8) {
                Image("Wordmark-A")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 48)
                    .padding(.top, Spacing.s8)
                    .padding(.bottom, Spacing.s16)
            }
            .frame(maxWidth: .infinity)
            stepContent(
                eyebrow: "Welcome",
                title: "",
                paragraph: OnboardingCopy.welcome
            ) { WelcomeMiniature() }
        case .amortization:
            stepContent(
                eyebrow: "01 · Amortization",
                title: "The schedule, settled.",
                paragraph: OnboardingCopy.amortization
            ) { AmortizationMiniature() }
        case .incomeQual:
            stepContent(
                eyebrow: "02 · Income qualification",
                title: "Max loan, fast.",
                paragraph: OnboardingCopy.incomeQual
            ) { IncomeQualMiniature() }
        case .refinance:
            stepContent(
                eyebrow: "03 · Refinance comparison",
                title: "Break-even, not broad strokes.",
                paragraph: OnboardingCopy.refinance
            ) { RefinanceMiniature() }
        case .tca:
            stepContent(
                eyebrow: "04 · Total cost analysis",
                title: "Two to four scenarios, side by side.",
                paragraph: OnboardingCopy.tca
            ) { TCAMiniature() }
        case .heloc:
            stepContent(
                eyebrow: "05 · HELOC vs refinance",
                title: "When keeping the first mortgage wins.",
                paragraph: OnboardingCopy.heloc
            ) { HelocMiniature() }
        }
    }

    @ViewBuilder
    private func stepContent<Mini: View>(
        eyebrow: String,
        title: String,
        paragraph: String,
        @ViewBuilder miniature: () -> Mini
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s24) {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                Text(eyebrow.uppercased())
                    .textStyle(Typography.eyebrow)
                    .foregroundStyle(Palette.accent)
                if !title.isEmpty {
                    Text(title)
                        .font(.custom(Typography.serifFamily, size: 32))
                        .foregroundStyle(Palette.ink)
                        .tracking(32 * -0.02)
                }
                Text(paragraph)
                    .textStyle(Typography.bodyLg)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, Spacing.s12)
            miniature()
        }
        .padding(.horizontal, Spacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomDock: some View {
        HStack(alignment: .center, spacing: Spacing.s8) {
            Text("\(index + 1) / 6")
                .textStyle(Typography.num)
                .foregroundStyle(Palette.inkTertiary)
                .padding(.leading, Spacing.s8)
            Spacer()
            Button {
                if index == OnboardingStepID.allCases.count - 1 {
                    onFinish()
                } else {
                    index += 1
                }
            } label: {
                Text(index == OnboardingStepID.allCases.count - 1 ? "Get started" : "Continue")
                    .textStyle(Typography.bodyLg.withWeight(.semibold))
                    .foregroundStyle(Palette.accentFG)
                    .padding(.horizontal, Spacing.s32)
                    .padding(.vertical, Spacing.s12)
                    .background(Palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.cta, style: .continuous))
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
}
