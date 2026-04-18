// Radius.swift
// Corner-radius table per design README. Values named by usage so call
// sites read intent, not magic numbers: `.cornerRadius(Radius.cta)` is
// the 12pt hero/CTA radius the designer specified.

import Foundation

public enum Radius {
    /// 2pt — chart bars.
    public static let chartBar: CGFloat = 2
    /// 3pt — mono chips (label pills for calculator types, QM badges).
    public static let monoChip: CGFloat = 3
    /// 4pt — color swatches in Settings/Brand.
    public static let swatch: CGFloat = 4
    /// 6pt — segmented controls (term selector).
    public static let segmented: CGFloat = 6
    /// 8pt — default container radius.
    public static let `default`: CGFloat = 8
    /// 10pt — list cards (scenario cards on Home/Saved).
    public static let listCard: CGFloat = 10
    /// 12pt — CTAs, hero surfaces.
    public static let cta: CGFloat = 12
    /// 14pt — grouped-list row background.
    public static let groupedList: CGFloat = 14
    /// 26pt — iOS grouped-list section container (Settings inset cards).
    public static let iosGroupedList: CGFloat = 26
    /// 999pt — pills (filter chips, borrower pill, rate ribbon).
    public static let pill: CGFloat = 999
}
