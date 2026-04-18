// Tokens.swift
// Umbrella namespace for design tokens other than spacing/radius/motion,
// which live in their own files because they're referenced heavily.
//
// Icon sizes are the only tokens that land here directly; everything else
// cross-references into Spacing/Radius/Motion/Colors/Typography.

import Foundation

public enum Tokens {}

extension Tokens {
    /// Icon point sizes per design README: 1.5pt stroke line icons at
    /// three standard sizes. SF Symbols callers pick the matching token
    /// to keep stroke weight proportional.
    public enum IconSize {
        /// 14pt — inline icon in text rows.
        public static let inline: CGFloat = 14
        /// 20pt — default line icon everywhere else.
        public static let `default`: CGFloat = 20
        /// 22pt — navigation bar icons.
        public static let nav: CGFloat = 22
    }

    /// Stroke weights used by `Shape`-based custom drawings and inline SVGs
    /// reconstructed in SwiftUI (amortization/recast/biweekly custom glyphs).
    public enum Stroke {
        /// 1.5pt — icon line weight.
        public static let icon: CGFloat = 1.5
        /// 1pt — default hairline divider width.
        public static let hairline: CGFloat = 1
        /// 2pt — active-state tab underline.
        public static let activeUnderline: CGFloat = 2
    }
}
