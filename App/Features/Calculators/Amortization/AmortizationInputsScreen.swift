// AmortizationInputsScreen.swift — Session 3.4 builds the full form.
// Stubbed for 3.2 so HomeScreen's "New scenario" navigation wires up.

import SwiftUI

struct AmortizationInputsScreen: View {
    var body: some View {
        VStack(spacing: Spacing.s16) {
            Eyebrow("01 · Amortization")
            Text("Inputs ship in Session 3.4.")
                .textStyle(Typography.h2)
                .foregroundStyle(Palette.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
        .navigationBarTitleDisplayMode(.inline)
    }
}
