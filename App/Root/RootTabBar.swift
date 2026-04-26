// RootTabBar.swift
// Four-tab bar — Calculators / Scenarios / Leads / Settings. Hosts the
// feature stacks.

import SwiftUI

enum RootTab: Hashable, CaseIterable {
    case calculators, scenarios, leads, settings
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

            LeadsScreen()
                .tabItem { Label("Leads", systemImage: "person.2") }
                .tag(RootTab.leads)

            SettingsScreen(profile: profile)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(RootTab.settings)
        }
        .tint(Palette.accent)
    }
}
