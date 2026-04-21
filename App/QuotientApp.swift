// QuotientApp.swift
// Main app entry. Installs the SwiftData container for LenderProfile /
// Borrower / Scenario. SourceSerif4 fonts auto-register via the
// `UIAppFonts` key in Info.plist — no runtime registration here.
//
// Launch-arg bypasses (DEBUG only, consumed by UI tests):
//   -uitestReset      clear any persisted profile/borrowers/scenarios
//   -uitestSeedProfile  seed a pre-onboarded LenderProfile so the UI
//                      test can skip Sign in with Apple and Face ID.

import SwiftUI
import SwiftData

@main
struct QuotientApp: App {

    let container: ModelContainer

    init() {
        let isUITest = CommandLine.arguments.contains("-uitestReset")
        self.container = QuotientSchema.makeContainer(inMemory: isUITest)
        #if DEBUG
        Self.applyUITestLaunchArgs(container: container)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }

    #if DEBUG
    @MainActor
    private static func applyUITestLaunchArgs(container: ModelContainer) {
        let args = CommandLine.arguments
        guard args.contains("-uitestSeedProfile") else { return }
        let context = ModelContext(container)
        let profile = LenderProfile(
            appleUserID: "uitest.user",
            firstName: "Nick",
            lastName: "Moretti",
            nmlsId: "1428391",
            licensedStates: ["CA", "OR", "WA"],
            companyName: "Cascade Lending",
            phone: "(415) 555-0123",
            email: "nick@cascade.com",
            faceIDEnabled: false,
            hasCompletedOnboarding: true
        )
        context.insert(profile)
        try? context.save()
    }
    #endif
}
