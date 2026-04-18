// SettingsScreen.swift — Session 3.3 wires the real 10-section list
// and the `Replay tour` entry point under About.

import SwiftUI
import SwiftData

struct SettingsScreen: View {
    let profile: LenderProfile
    @Environment(\.modelContext)
    private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.s24) {
                Text("Settings — Session 3.3")
                    .textStyle(Typography.h2)
                    .foregroundStyle(Palette.ink)
                SecondaryButton("Replay onboarding") {
                    profile.hasCompletedOnboarding = false
                    profile.updatedAt = Date()
                    try? modelContext.save()
                }
                .padding(.horizontal, Spacing.s32)
            }
        }
    }
}
