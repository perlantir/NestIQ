// RootTabBar.swift
// Three-tab bar per design/screens/Home.jsx — Calculators / Scenarios /
// Settings. Hosts the feature stacks. Session 3.2 wires the Home stack;
// Session 3.3 wires Settings; Scenarios opens the Saved list.

import SwiftUI

enum RootTab: Hashable, CaseIterable {
    case calculators, scenarios, settings
}

struct RootTabBar: View {
    let profile: LenderProfile
    @State private var selection: RootTab = .calculators

    var body: some View {
        TabView(selection: $selection) {
            HomeScreen(
                profile: profile,
                onSeeAllRecent: { selection = .scenarios }
            )
                .tabItem { Label("Calculators", systemImage: "list.number") }
                .tag(RootTab.calculators)

            SavedScenariosScreen()
                .tabItem { Label("Scenarios", systemImage: "text.alignleft") }
                .tag(RootTab.scenarios)

            SettingsScreen(profile: profile)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(RootTab.settings)
        }
        .tint(Palette.accent)
    }
}
