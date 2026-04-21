// HapticFeedback.swift
// Session 7.5 — single call site for the compute-button haptic tick.
// Session 7.6 — sound-on-share sibling. Both gated by the matching
// LenderProfile toggle (hapticsEnabled / soundsEnabled).

import UIKit
import AudioToolbox

enum HapticFeedback {

    /// Medium-impact tick when the LO taps Compute on any calculator.
    /// No-op when the user has turned haptics off or when no profile
    /// exists yet (pre-onboarding).
    @MainActor
    static func fireOnCompute(profile: LenderProfile?) {
        guard profile?.hapticsEnabled ?? false else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

enum SoundFeedback {

    /// SystemSoundID 1008 — the "tock" / shutter click used for the
    /// share confirmation. No-op unless the LO has the sound toggle on.
    @MainActor
    static func fireOnShare(profile: LenderProfile?) {
        guard profile?.soundsEnabled ?? false else { return }
        AudioServicesPlaySystemSound(1008)
    }
}
