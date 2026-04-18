// RootView.swift
// Session 2 placeholder root view. Session 3 replaces this with:
//   AuthGate → Onboarding (if profile unset) → Root Tab Bar (per
//   design/screens/Home.jsx).
//
// During Session 2 design QA we surface the Theme and Component galleries
// directly so Nick can scroll them on-device alongside the Foundations.jsx
// specimen. `#if DEBUG` — release builds still show the "engine ready" stub.

import SwiftUI

struct RootView: View {
    #if DEBUG
    @State private var tab: Tab = .components

    enum Tab: Hashable { case engine, theme, components }
    #endif

    var body: some View {
        #if DEBUG
        TabView(selection: $tab) {
            engineStub
                .tabItem { Label("Engine", systemImage: "function") }
                .tag(Tab.engine)
            ThemePreview()
                .tabItem { Label("Theme", systemImage: "paintpalette") }
                .tag(Tab.theme)
            ComponentGallery()
                .tabItem { Label("Components", systemImage: "rectangle.3.group") }
                .tag(Tab.components)
        }
        #else
        engineStub
        #endif
    }

    private var engineStub: some View {
        VStack(spacing: 16) {
            Text("Quotient")
                .font(.largeTitle.weight(.semibold))
            Text("Session 2 — finance handlers + compliance + theme + components")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    RootView()
}
