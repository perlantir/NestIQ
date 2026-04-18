// RootView.swift
// Session 1 placeholder root view. Session 3 replaces this with:
//   AuthGate → Onboarding (if profile unset) → Root Tab Bar (per
//   design/screens/Home.jsx).
//
// For Session 1 we show a minimal "engine ready" screen so the app target
// builds and runs. No design tokens, no theme — those land in Session 2.

import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Quotient")
                .font(.largeTitle.weight(.semibold))
            Text("Session 1 — finance engine ready")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    RootView()
}
