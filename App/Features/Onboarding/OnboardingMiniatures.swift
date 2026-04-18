// OnboardingMiniatures.swift
// Per-step signature-output miniatures drawn from design/screens/Onboarding.jsx.
// No interactive data — each pane is a typographic diagram of the
// calculator's hero output, rendered from static sample values.

import SwiftUI

// MARK: - Welcome

struct WelcomeMiniature: View {
    var body: some View {
        VStack(spacing: Spacing.s8) {
            Text("Q")
                .font(.custom(Typography.serifFamily, size: 72))
                .foregroundStyle(Palette.ink)
            Text("QUOTIENT")
                .textStyle(Typography.eyebrow)
                .foregroundStyle(Palette.inkTertiary)
                .tracking(11 * 0.14)
            Text("v 1.2.4")
                .textStyle(Typography.num)
                .foregroundStyle(Palette.inkTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, Spacing.s20)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.cta, style: .continuous)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.cta, style: .continuous))
    }
}

// MARK: - Amortization

struct AmortizationMiniature: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Eyebrow("Monthly PITI")
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("$")
                    .textStyle(Typography.num)
                    .foregroundStyle(Palette.inkTertiary)
                MonoNumber("3,284", size: .hero)
            }
            BalanceCurve()
                .fill(Palette.accent.opacity(0.18))
                .frame(height: 80)
                .overlay(
                    BalanceCurve(stroked: true)
                        .stroke(Palette.accent, lineWidth: 1.5)
                )
                .padding(.top, Spacing.s4)
            Text("Payoff · 2056")
                .textStyle(Typography.num)
                .foregroundStyle(Palette.inkTertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(Spacing.s16)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.cta, style: .continuous)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.cta, style: .continuous))
    }
}

private struct BalanceCurve: Shape {
    var stroked: Bool = false
    func path(in rect: CGRect) -> Path {
        let pts: [(CGFloat, CGFloat)] = [
            (0.033, 0.92), (0.20, 0.77), (0.37, 0.58), (0.53, 0.38),
            (0.70, 0.23), (0.87, 0.13), (0.97, 0.08),
        ]
        var p = Path()
        let first = pts[0]
        p.move(to: CGPoint(x: rect.width * first.0, y: rect.height * first.1))
        for pt in pts.dropFirst() {
            p.addLine(to: CGPoint(x: rect.width * pt.0, y: rect.height * pt.1))
        }
        if !stroked {
            p.addLine(to: CGPoint(x: rect.width * 0.97, y: rect.height))
            p.addLine(to: CGPoint(x: rect.width * 0.033, y: rect.height))
            p.closeSubpath()
        }
        return p
    }
}

// MARK: - Income qualification

struct IncomeQualMiniature: View {
    var body: some View {
        HStack(spacing: Spacing.s32) {
            DemoDial(label: "Front", value: 24.2, limit: 28)
            DemoDial(label: "Back", value: 38.1, limit: 43)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.s20)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.cta, style: .continuous)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.cta, style: .continuous))
    }
}

private struct DemoDial: View {
    let label: String
    let value: Double
    let limit: Double

    var body: some View {
        VStack(spacing: Spacing.s4) {
            ZStack {
                Circle()
                    .stroke(Palette.grid, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: min(value / (limit * 1.4), 1))
                    .stroke(Palette.accent,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 1) {
                    Text(String(format: "%.1f", value))
                        .textStyle(Typography.num.withSize(17, weight: .medium, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                    Text("% · lim \(Int(limit))")
                        .textStyle(Typography.num.withSize(8.5, design: .monospaced))
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            .frame(width: 88, height: 88)
            Text(label.uppercased())
                .textStyle(Typography.micro)
                .foregroundStyle(Palette.inkTertiary)
        }
    }
}

// MARK: - Refinance

struct RefinanceMiniature: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Eyebrow("Cumulative savings")
            ZStack {
                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    let bePts = CGPoint(x: w * 0.45, y: h * 0.55)

                    // Zero line
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h * 0.55))
                        p.addLine(to: CGPoint(x: w, y: h * 0.55))
                    }
                    .stroke(Palette.inkTertiary.opacity(0.5),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    // Curve
                    Path { p in
                        p.move(to: CGPoint(x: w * 0.03, y: h * 0.85))
                        p.addLine(to: CGPoint(x: w * 0.20, y: h * 0.75))
                        p.addLine(to: CGPoint(x: w * 0.37, y: h * 0.65))
                        p.addLine(to: CGPoint(x: bePts.x, y: bePts.y))
                        p.addLine(to: CGPoint(x: w * 0.60, y: h * 0.38))
                        p.addLine(to: CGPoint(x: w * 0.80, y: h * 0.16))
                        p.addLine(to: CGPoint(x: w * 0.97, y: h * 0.02))
                    }
                    .stroke(Palette.accent, lineWidth: 1.75)

                    // Break-even vertical
                    Path { p in
                        p.move(to: CGPoint(x: bePts.x, y: 0))
                        p.addLine(to: CGPoint(x: bePts.x, y: h))
                    }
                    .stroke(Palette.accent.opacity(0.6),
                            style: StrokeStyle(lineWidth: 1, dash: [2, 2]))

                    // Break-even marker
                    Circle()
                        .stroke(Palette.accent, lineWidth: 1.75)
                        .background(Circle().fill(Palette.surfaceRaised))
                        .frame(width: 8, height: 8)
                        .position(bePts)

                    Text("24 mo")
                        .textStyle(Typography.num.withWeight(.semibold))
                        .foregroundStyle(Palette.accent)
                        .position(x: bePts.x + 20, y: bePts.y - 10)
                }
            }
            .frame(height: 110)

            Text("break-even · month 24")
                .textStyle(Typography.num)
                .foregroundStyle(Palette.inkSecondary)
        }
        .padding(Spacing.s16)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.cta, style: .continuous)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.cta, style: .continuous))
    }
}

// MARK: - TCA

struct TCAMiniature: View {
    private let rows: [(String, [Int])] = [
        ("5-yr", [238, 289, 241, 211]),
        ("10-yr", [456, 495, 461, 428]),
        ("30-yr", [1181, 1104, 1198, 1168]),
    ]
    private let colors: [Color] = [
        Palette.accent, Palette.scenario2, Palette.scenario3, Palette.scenario4,
    ]
    private let headers = ["A", "B", "C", "D"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear.frame(width: 44)
                ForEach(Array(headers.enumerated()), id: \.offset) { idx, h in
                    Text(h)
                        .textStyle(Typography.micro)
                        .foregroundStyle(colors[idx])
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.vertical, Spacing.s4)
            HairlineDivider()
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                let min = row.1.min() ?? 0
                HStack(spacing: 0) {
                    Text(row.0)
                        .textStyle(Typography.num)
                        .foregroundStyle(Palette.inkSecondary)
                        .frame(width: 44, alignment: .leading)
                    ForEach(Array(row.1.enumerated()), id: \.offset) { _, v in
                        Text("$\(v)k")
                            .textStyle(Typography.num.withWeight(v == min ? .semibold : .regular))
                            .foregroundStyle(v == min ? Palette.gain : Palette.ink)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.vertical, Spacing.s8)
                if idx < rows.count - 1 { HairlineDivider() }
            }
        }
        .padding(Spacing.s16)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.cta, style: .continuous)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.cta, style: .continuous))
    }
}

// MARK: - Heloc

struct HelocMiniature: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Eyebrow("Blended rate")
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                MonoNumber("4.85", size: .hero)
                Text("%")
                    .textStyle(Typography.num.withSize(14, design: .monospaced))
                    .foregroundStyle(Palette.inkTertiary)
                Spacer()
                Text("vs refi 6.125%")
                    .textStyle(Typography.num)
                    .foregroundStyle(Palette.inkTertiary)
            }
            HStack(spacing: 0) {
                Rectangle().fill(Palette.accent).frame(maxWidth: .infinity)
                Rectangle().fill(Palette.scenario2).frame(maxWidth: .infinity)
            }
            .frame(height: 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.grid)
            .mask {
                GeometryReader { g in
                    HStack(spacing: 0) {
                        Rectangle().frame(width: g.size.width * 0.8)
                        Rectangle().frame(width: g.size.width * 0.2)
                    }
                }
            }
            HStack {
                Text("1st · 3.125%")
                    .textStyle(Typography.num)
                    .foregroundStyle(Palette.inkTertiary)
                Spacer()
                Text("HELOC · 8.75%")
                    .textStyle(Typography.num)
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
        .padding(Spacing.s16)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.cta, style: .continuous)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.cta, style: .continuous))
    }
}

// MARK: - TextStyle helpers (shared across Session 3/4 features)

extension TextStyle {
    func withSize(_ size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> TextStyle {
        let base: Font
        if design == .monospaced {
            base = .system(size: size, weight: weight, design: .monospaced).monospacedDigit()
        } else {
            base = .system(size: size, weight: weight)
        }
        return TextStyle(font: base, tracking: tracking, lineSpacing: lineSpacing)
    }

    func withWeight(_ weight: Font.Weight) -> TextStyle {
        TextStyle(font: font.weight(weight), tracking: tracking, lineSpacing: lineSpacing)
    }
}
