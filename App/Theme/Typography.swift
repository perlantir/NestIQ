// Typography.swift
// Type scale per design README. SF Pro for UI chrome; SF Mono with
// `.monospacedDigit()` for financial numbers; Source Serif 4 for wordmark
// / onboarding titles / PDF narrative.
//
// Source Serif 4 weights bundled in Session 1 per DECISIONS.md: 400,
// 400-italic, 600, 600-italic. The README's requested 500 weight was
// dropped — static 500 isn't shipped on the Adobe Fonts release branch
// and the design uses serif only for emphasis at 400/600, so nothing
// breaks.
//
// Letter-spacing in the README is expressed in em (e.g., `-0.02em`).
// SwiftUI's `.tracking(_:)` takes points, so the Text helpers here
// pre-multiply em × size to get point-space tracking.

import SwiftUI

public struct TextStyle: Sendable {
    public let font: Font
    /// Additional character spacing in points (positive widens, negative
    /// tightens). Already em-converted at the declaration site.
    public let tracking: CGFloat
    /// Suggested line spacing in points, or `nil` to use the system default.
    public let lineSpacing: CGFloat?

    public init(font: Font, tracking: CGFloat = 0, lineSpacing: CGFloat? = nil) {
        self.font = font
        self.tracking = tracking
        self.lineSpacing = lineSpacing
    }
}

public enum Typography {

    // MARK: Core scale — SF Pro sans

    /// 34pt / 700 / -0.02em — greeting, "New scenario".
    public static let display = TextStyle(
        font: .system(size: 34, weight: .bold),
        tracking: 34 * -0.02
    )

    /// 26pt / 700 / -0.02em — borrower names (hero). Design README lists
    /// 26-28pt for the title slot; 26pt is the default.
    public static let title = TextStyle(
        font: .system(size: 26, weight: .bold),
        tracking: 26 * -0.02
    )

    /// 22pt / 700 / -0.015em — section heroes (e.g. Refinance winner).
    public static let h2 = TextStyle(
        font: .system(size: 22, weight: .bold),
        tracking: 22 * -0.015
    )

    /// 15pt / 600 / -0.01em — "Balance over time" section headers.
    public static let section = TextStyle(
        font: .system(size: 15, weight: .semibold),
        tracking: 15 * -0.01
    )

    /// 14pt / 500 — larger body (e.g. description block under hero).
    public static let bodyLg = TextStyle(
        font: .system(size: 14, weight: .medium)
    )

    /// 13pt / 400 — default body.
    public static let body = TextStyle(
        font: .system(size: 13, weight: .regular)
    )

    /// 12.5pt / 400 — fine print / compliance body.
    public static let bodySm = TextStyle(
        font: .system(size: 12.5, weight: .regular)
    )

    /// 11pt / 600 / +0.09em uppercase tracked — section eyebrows, KPI labels.
    public static let eyebrow = TextStyle(
        font: .system(size: 11, weight: .semibold),
        tracking: 11 * 0.09
    )

    /// 10.5pt / 600 / +0.08em tracked — micro KPI labels.
    public static let micro = TextStyle(
        font: .system(size: 10.5, weight: .semibold),
        tracking: 10.5 * 0.08
    )

    // MARK: Numeric scale — SF Mono + tabular numerals

    /// 46pt mono / 500 / -0.02em / tnum — hero KPI (PITI, max qualifying loan).
    public static let numHero = TextStyle(
        font: .system(size: 46, weight: .medium, design: .monospaced).monospacedDigit(),
        tracking: 46 * -0.02
    )

    /// 22-26pt mono / 500 / -0.01em / tnum — secondary KPIs (default 26pt).
    public static let numLg = TextStyle(
        font: .system(size: 26, weight: .medium, design: .monospaced).monospacedDigit(),
        tracking: 26 * -0.01
    )

    /// 12-15pt mono / tnum — schedule-table cells, delta chips (default 13pt).
    public static let num = TextStyle(
        font: .system(size: 13, weight: .regular, design: .monospaced).monospacedDigit()
    )

    // MARK: Serif — Source Serif 4 (wordmark, onboarding titles, PDF only)

    /// The bundled Source Serif 4 PostScript name. Registered in
    /// `QuotientApp.init()` via `CTFontManagerRegisterFontsForURL`.
    public static let serifFamily = "SourceSerif4"

    /// 34pt Source Serif 4 400 — Quotient wordmark.
    public static let serifDisplay = TextStyle(
        font: .custom(serifFamily, size: 34),
        tracking: 34 * -0.02
    )

    /// 26pt Source Serif 4 400 italic — onboarding and PDF "For {Name}"
    /// italic emphasis.
    public static let serifTitleItalic = TextStyle(
        font: .custom(serifFamily + "-It", size: 26),
        tracking: 26 * -0.02
    )

    /// 16pt Source Serif 4 400 — PDF narrative paragraphs.
    public static let serifNarrative = TextStyle(
        font: .custom(serifFamily, size: 16),
        lineSpacing: 4
    )

    /// 20pt Source Serif 4 600 — onboarding step titles.
    public static let serifStepTitle = TextStyle(
        font: .custom(serifFamily + "-Semibold", size: 20),
        tracking: 20 * -0.015
    )
}

// MARK: - View modifier

public extension View {
    /// Apply a `TextStyle` to any text-bearing view. Use on `Text` for
    /// tracking / line-spacing fidelity; on other views it applies font
    /// only and the tracking / line-spacing fields are ignored.
    func textStyle(_ style: TextStyle) -> some View {
        modifier(TextStyleModifier(style: style))
    }
}

struct TextStyleModifier: ViewModifier {
    let style: TextStyle
    func body(content: Content) -> some View {
        let base = content
            .font(style.font)
            .tracking(style.tracking)
        if let spacing = style.lineSpacing {
            return AnyView(base.lineSpacing(spacing))
        }
        return AnyView(base)
    }
}
