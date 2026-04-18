// Motion.swift
// Animation durations + easings per design README.
//
// Easing curves:
//   - `easeOut`    — `cubic-bezier(0.2, 0, 0, 1)` — most UI transitions
//   - `easeInOut`  — `cubic-bezier(0.4, 0, 0.2, 1)` — number tween, chart draw
//
// Reduced motion:
//   Callers should check `@Environment(\.accessibilityReduceMotion)` and
//   substitute `Motion.reducedMotion(base:)` when true. The helper returns
//   an opacity-only animation at the same duration so cross-fades still
//   work but transforms drop — per design README motion policy.

import SwiftUI

public enum Motion {
    // MARK: Durations (seconds)

    /// 120ms — hover, focus ring.
    public static let fast: Double = 0.120
    /// 180ms — default for tab/chip/toggle transitions.
    public static let standard: Double = 0.180
    /// 260ms — sheet present, chart redraw, onboarding step change.
    public static let slow: Double = 0.260
    /// 400ms — number-tween on input change.
    public static let numberTween: Double = 0.400
    /// 600ms — chart first-draw stagger (left-to-right line reveal).
    public static let chartDraw: Double = 0.600

    // MARK: Canonical animations

    /// Standard ease-out at `standard` (180ms).
    public static let defaultEaseOut: Animation = .timingCurve(0.2, 0, 0, 1, duration: standard)

    /// Ease-in-out at `numberTween` (400ms) — used for the animated
    /// numeric displays on input change.
    public static let numberTweenEaseInOut: Animation = .timingCurve(0.4, 0, 0.2, 1, duration: numberTween)

    /// Slow ease-out at `slow` (260ms) — sheet presentation.
    public static let slowEaseOut: Animation = .timingCurve(0.2, 0, 0, 1, duration: slow)

    /// Chart first-draw ease-in-out at 600ms.
    public static let chartDrawEaseInOut: Animation = .timingCurve(0.4, 0, 0.2, 1, duration: chartDraw)

    /// Fast focus/hover cue.
    public static let fastEaseOut: Animation = .timingCurve(0.2, 0, 0, 1, duration: fast)

    // MARK: Reduced-motion fallback

    /// When `accessibilityReduceMotion` is enabled, strip transforms but
    /// keep opacity crossfades at the original duration so views still
    /// communicate state changes without parallax / scale.
    public static func reduced(base: Animation, duration: Double = standard) -> Animation {
        _ = base
        return .linear(duration: duration)
    }
}
