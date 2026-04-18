// RootView.swift
// Session 3 real root hierarchy:
//   AuthGate → (Onboarding | RootTabBar)
//
// Auth state is owned by `AuthGate` via SwiftData; when a profile exists
// and is unlocked we present either the 6-step onboarding tour (if the
// profile hasn't completed it) or the main tab bar. The Settings → About
// → "Replay tour" entry point toggles `hasCompletedOnboarding` back to
// false from inside the settings stack.

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Query private var profiles: [LenderProfile]

    var body: some View {
        AuthGate { profile in
            if profile.hasCompletedOnboarding {
                RootTabBar(profile: profile)
            } else {
                OnboardingFlow {
                    profile.hasCompletedOnboarding = true
                    profile.updatedAt = Date()
                    try? modelContext.save()
                }
            }
        }
        .preferredColorScheme(preferredScheme)
    }

    private var preferredScheme: ColorScheme? {
        switch profiles.first?.appearance {
        case .light: return .light
        case .dark: return .dark
        default: return nil
        }
    }
}

#Preview {
    RootView()
        .modelContainer(QuotientSchema.makeContainer(inMemory: true))
}
