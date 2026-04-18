// Colors.swift
// Semantic color palette from design README, backed by Asset Catalog
// ColorSets in App/Resources/Assets.xcassets. Every token is defined in
// Any+Dark pairs so iOS light/dark switching is automatic.
//
// README-vs-CSS conflict resolution: the design README wins (per
// DECISIONS.md 2026-04-17). Ledger green accent `#1F4D3F` light /
// `#4F9E7D` dark.
//
// Dark-mode synthesis (where the README was silent):
//   - `inkQuaternary` dark: `#5A5648` — proportional to the light scale.
//   - `gainTint` dark: `#1F3329` — gain tint paired with `gain` on
//     surface-dark; mirrors the `accentTint` dark value pattern.
//   - `lossTint` dark: `#3A211D`
//   - `warnTint` dark: `#3B2F1C`
//   These are tracked as Session 2 decisions in DECISIONS.md; Session 5
//   design QA may adjust.

import SwiftUI

public enum Palette {

    // MARK: Surfaces

    public static let surface = Color("Surface")
    public static let surfaceRaised = Color("SurfaceRaised")
    public static let surfaceSunken = Color("SurfaceSunken")
    public static let surfaceDeep = Color("SurfaceDeep")

    // MARK: Borders

    public static let borderSubtle = Color("BorderSubtle")
    public static let borderDefault = Color("BorderDefault")
    public static let borderStrong = Color("BorderStrong")

    // MARK: Ink (text)

    public static let ink = Color("Ink")
    public static let inkSecondary = Color("InkSecondary")
    public static let inkTertiary = Color("InkTertiary")
    public static let inkQuaternary = Color("InkQuaternary")

    // MARK: Accent

    /// Referenced as `AccentColor` (not `Accent`) so the Asset Catalog's
    /// `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME` build setting +
    /// launch-screen `UIColorName` pick up the same ColorSet automatically.
    public static let accent = Color("AccentColor")
    public static let accentHover = Color("AccentHover")
    public static let accentFG = Color("AccentFG")
    public static let accentTint = Color("AccentTint")

    // MARK: Semantic

    public static let gain = Color("Gain")
    public static let gainTint = Color("GainTint")
    public static let loss = Color("Loss")
    public static let lossTint = Color("LossTint")
    public static let warn = Color("Warn")
    public static let warnTint = Color("WarnTint")

    // MARK: Chart

    public static let grid = Color("Grid")

    // MARK: 4-scenario palette

    public static let scenario1 = Color("Scenario1")
    public static let scenario2 = Color("Scenario2")
    public static let scenario3 = Color("Scenario3")
    public static let scenario4 = Color("Scenario4")

    /// Ordered scenario colors — index-0..3 aligns with the 4-scenario
    /// comparison slot order on Refi / TCA screens.
    public static let scenarios: [Color] = [scenario1, scenario2, scenario3, scenario4]
}
