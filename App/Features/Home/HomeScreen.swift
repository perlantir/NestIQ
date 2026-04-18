// HomeScreen.swift — Session 3.2 wires the real screen.

import SwiftUI

struct HomeScreen: View {
    let profile: LenderProfile
    var body: some View {
        Text("Home — Session 3.2")
            .textStyle(Typography.h2)
            .foregroundStyle(Palette.ink)
    }
}
