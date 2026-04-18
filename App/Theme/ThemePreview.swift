// ThemePreview.swift
// Eyeball-compare surface for the Theme layer vs. the designer's
// Foundations.jsx specimen sheet.
//
// Not shipped in release. Used during Session 2 design QA only — scrolls
// every color swatch, every type specimen, every spacing/radius/motion
// value side-by-side. Groupings and order mirror Foundations.jsx
// ("Palette", "Type", "Components", "Principles") so the two can be held
// up next to each other on a designer's screen.

#if DEBUG
import SwiftUI

public struct ThemePreview: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s32) {
                eyebrow("Foundations · Theme layer")
                Text("Quotient — design system")
                    .textStyle(Typography.serifDisplay)
                    .foregroundStyle(Palette.ink)

                paletteSection
                typeSection
                spacingSection
                radiusSection
                motionSection
                principlesSection
            }
            .padding(.horizontal, Spacing.s32)
            .padding(.vertical, Spacing.s32)
        }
        .background(Palette.surface.ignoresSafeArea())
    }

    // MARK: Palette

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            eyebrow("Palette")
            LazyVGrid(columns: sixColumns, spacing: Spacing.s12) {
                swatch("Surface", Palette.surface, "#FAF9F5")
                swatch("Raised", Palette.surfaceRaised, "#FFFFFE")
                swatch("Sunken", Palette.surfaceSunken, "#F0EDE4")
                swatch("Deep", Palette.surfaceDeep, "#E8E4D7")
                swatch("Border", Palette.borderDefault, "#D3CEBE")
                swatch("Grid", Palette.grid, "#ECE8DC")
            }
            LazyVGrid(columns: sixColumns, spacing: Spacing.s12) {
                swatch("Ink", Palette.ink, "#17160F")
                swatch("Ink 2", Palette.inkSecondary, "#4A4840")
                swatch("Ink 3", Palette.inkTertiary, "#85816F")
                swatch("Ink 4", Palette.inkQuaternary, "#B8B4A3")
                swatch("Accent", Palette.accent, "#1F4D3F")
                swatch("Accent tint", Palette.accentTint, "#DFE6E0")
            }
            LazyVGrid(columns: sixColumns, spacing: Spacing.s12) {
                swatch("Gain", Palette.gain, "#2D6A4E")
                swatch("Gain tint", Palette.gainTint, "#DDE8DF")
                swatch("Loss", Palette.loss, "#8A3D34")
                swatch("Loss tint", Palette.lossTint, "#EDDAD4")
                swatch("Warn", Palette.warn, "#8C6A1E")
                swatch("Warn tint", Palette.warnTint, "#EDE2CA")
            }
            LazyVGrid(columns: fourColumns, spacing: Spacing.s12) {
                swatch("Scenario 1 · green", Palette.scenario1, "#1F4D3F")
                swatch("Scenario 2 · blue", Palette.scenario2, "#264B6A")
                swatch("Scenario 3 · wine", Palette.scenario3, "#6A3F5A")
                swatch("Scenario 4 · umber", Palette.scenario4, "#73522A")
            }
        }
    }

    // MARK: Type

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            eyebrow("Type")
            typeRow(
                label: "Display · SF Pro 34 / 700",
                sample: "Good morning, Nick.",
                style: Typography.display
            )
            typeRow(
                label: "Title · SF Pro 26 / 700",
                sample: "John & Maya Smith",
                style: Typography.title
            )
            typeRow(
                label: "H2 · SF Pro 22 / 700",
                sample: "Save $212 / mo",
                style: Typography.h2
            )
            typeRow(
                label: "Section · SF Pro 15 / 600",
                sample: "Balance over time",
                style: Typography.section
            )
            typeRow(
                label: "Body-lg · SF Pro 14 / 500",
                sample: "Results update live as you adjust inputs.",
                style: Typography.bodyLg
            )
            typeRow(
                label: "Body · SF Pro 13",
                sample: "30-year fixed at 6.500% with $4,500 closing costs.",
                style: Typography.body
            )
            typeRow(
                label: "Body-sm · SF Pro 12.5",
                sample: "Not a Loan Estimate. Not a commitment to lend.",
                style: Typography.bodySm
            )
            typeRow(
                label: "Eyebrow · SF Pro 11 / 600 / tracked",
                sample: "TODAY · NATIONAL AVERAGE",
                style: Typography.eyebrow
            )
            typeRow(
                label: "Micro · SF Pro 10.5 / 600 / tracked",
                sample: "BREAK-EVEN",
                style: Typography.micro
            )
            typeRow(
                label: "Num-hero · SF Mono 46",
                sample: "$4,207.00",
                style: Typography.numHero
            )
            typeRow(
                label: "Num-lg · SF Mono 26",
                sample: "24 mo",
                style: Typography.numLg
            )
            typeRow(
                label: "Num · SF Mono 13",
                sample: "547,553.02",
                style: Typography.num
            )
            typeRow(
                label: "Serif display · Source Serif 4 34",
                sample: "Quotient",
                style: Typography.serifDisplay
            )
            typeRow(
                label: "Serif step title · Source Serif 4 Semibold 20",
                sample: "Compare up to four scenarios",
                style: Typography.serifStepTitle
            )
            typeRow(
                label: "Serif italic · Source Serif 4 It 26",
                sample: "For John & Maya Smith",
                style: Typography.serifTitleItalic
            )
            typeRow(
                label: "Serif narrative · Source Serif 4 16",
                sample: "Your refinance would save an estimated $212 a month.",
                style: Typography.serifNarrative
            )
        }
    }

    // MARK: Spacing

    private var spacingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            eyebrow("Spacing · 4pt grid")
            VStack(alignment: .leading, spacing: Spacing.s8) {
                ForEach(Spacing.all, id: \.self) { value in
                    HStack(spacing: Spacing.s12) {
                        Text("\(Int(value))")
                            .textStyle(Typography.num)
                            .foregroundStyle(Palette.inkTertiary)
                            .frame(width: 32, alignment: .trailing)
                        Rectangle()
                            .fill(Palette.accent)
                            .frame(width: max(value, 1), height: 12)
                    }
                }
            }
        }
    }

    // MARK: Radius

    private var radiusSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            eyebrow("Radius")
            LazyVGrid(columns: threeColumns, spacing: Spacing.s16) {
                radiusChip("2 · chartBar", Radius.chartBar)
                radiusChip("3 · monoChip", Radius.monoChip)
                radiusChip("4 · swatch", Radius.swatch)
                radiusChip("6 · segmented", Radius.segmented)
                radiusChip("8 · default", Radius.default)
                radiusChip("10 · listCard", Radius.listCard)
                radiusChip("12 · cta", Radius.cta)
                radiusChip("14 · groupedList", Radius.groupedList)
                radiusChip("26 · iosGroupedList", Radius.iosGroupedList)
                radiusChip("999 · pill", Radius.pill)
            }
        }
    }

    // MARK: Motion

    private var motionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            eyebrow("Motion · durations")
            ForEach(motionSpec, id: \.label) { row in
                HStack {
                    Text(row.label)
                        .textStyle(Typography.body)
                        .foregroundStyle(Palette.inkSecondary)
                    Spacer()
                    Text("\(Int(row.seconds * 1000)) ms")
                        .textStyle(Typography.num)
                        .foregroundStyle(Palette.ink)
                }
                .padding(.vertical, Spacing.s8)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Palette.borderSubtle)
                        .frame(height: Tokens.Stroke.hairline)
                }
            }
        }
    }

    // MARK: Principles

    private var principlesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            eyebrow("Principles")
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: Spacing.s20),
                          GridItem(.flexible(), spacing: Spacing.s20)],
                alignment: .leading,
                spacing: Spacing.s16
            ) {
                principle(
                    title: "Numbers are the protagonist.",
                    body: "Every financial figure uses SF Mono with tabular numerals so " +
                          "columns align; never mix sans into a column of numbers."
                )
                principle(
                    title: "Hierarchy by rule and space.",
                    body: "Division comes from hairline rules and negative space, not " +
                          "boxes-within-boxes."
                )
                principle(
                    title: "One accent, used like a highlighter.",
                    body: "Ledger green marks active state, primary CTA, links, and " +
                          "winning scenarios. Nothing else."
                )
                principle(
                    title: "Editorial charts.",
                    body: "No thick strokes, no chartjunk. Labels anchor to lines; grids " +
                          "are whispered, not stated."
                )
            }
        }
    }

    // MARK: - Helpers

    private func eyebrow(_ text: String) -> some View {
        Text(text.uppercased())
            .textStyle(Typography.eyebrow)
            .foregroundStyle(Palette.inkTertiary)
    }

    private func swatch(_ name: String, _ color: Color, _ hex: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            color.frame(height: 54)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).textStyle(Typography.eyebrow)
                    .foregroundStyle(Palette.ink)
                Text(hex).textStyle(Typography.num)
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.horizontal, Spacing.s8)
            .padding(.vertical, Spacing.s8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Radius.swatch)
                .stroke(Palette.borderSubtle, lineWidth: Tokens.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.swatch))
    }

    private func typeRow(label: String, sample: String, style: TextStyle) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s16) {
            Text(label)
                .textStyle(Typography.num)
                .foregroundStyle(Palette.inkTertiary)
                .frame(width: 220, alignment: .leading)
            Text(sample)
                .textStyle(style)
                .foregroundStyle(Palette.ink)
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.s8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Palette.borderSubtle)
                .frame(height: Tokens.Stroke.hairline)
        }
    }

    private func radiusChip(_ name: String, _ radius: CGFloat) -> some View {
        VStack(spacing: Spacing.s8) {
            RoundedRectangle(cornerRadius: radius)
                .fill(Palette.accentTint)
                .frame(height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(Palette.accent, lineWidth: Tokens.Stroke.hairline)
                )
            Text(name).textStyle(Typography.num)
                .foregroundStyle(Palette.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func principle(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(title).textStyle(Typography.bodyLg)
                .foregroundStyle(Palette.ink)
            Text(body).textStyle(Typography.body)
                .foregroundStyle(Palette.inkSecondary)
        }
    }

    // MARK: - Layout columns

    private var sixColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Spacing.s12), count: 6)
    }
    private var fourColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Spacing.s12), count: 4)
    }
    private var threeColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Spacing.s16), count: 3)
    }

    private struct MotionRow {
        let label: String
        let seconds: Double
    }

    private var motionSpec: [MotionRow] {
        [
            .init(label: "fast — hover / focus", seconds: Motion.fast),
            .init(label: "standard — tab / chip / toggle", seconds: Motion.standard),
            .init(label: "slow — sheet / onboarding step", seconds: Motion.slow),
            .init(label: "numberTween — input change", seconds: Motion.numberTween),
            .init(label: "chartDraw — first-draw stagger", seconds: Motion.chartDraw)
        ]
    }
}

#Preview("Theme · light") {
    ThemePreview().preferredColorScheme(.light)
}

#Preview("Theme · dark") {
    ThemePreview().preferredColorScheme(.dark)
}

#Preview("Theme · Accessibility5") {
    ThemePreview()
        .environment(\.dynamicTypeSize, .accessibility5)
}
#endif
