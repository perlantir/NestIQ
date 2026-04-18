// Spacing.swift
// 4pt grid per design README. Every layout value the app uses comes from
// this scale — if a view needs a gap that isn't in the scale, the design
// is wrong. No inter-scale values (6, 14, 18, 28…).

import Foundation

public enum Spacing {
    public static let s0: CGFloat = 0
    public static let s4: CGFloat = 4
    public static let s8: CGFloat = 8
    public static let s12: CGFloat = 12
    public static let s16: CGFloat = 16
    public static let s20: CGFloat = 20
    public static let s24: CGFloat = 24
    public static let s32: CGFloat = 32
    public static let s40: CGFloat = 40
    public static let s48: CGFloat = 48
    public static let s64: CGFloat = 64
    public static let s80: CGFloat = 80
    public static let s96: CGFloat = 96

    /// Ordered scale values for UI previews / iteration.
    public static let all: [CGFloat] = [
        s0, s4, s8, s12, s16, s20, s24, s32, s40, s48, s64, s80, s96
    ]
}
