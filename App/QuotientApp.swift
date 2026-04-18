// QuotientApp.swift
// Main app entry. Registers bundled fonts before any view renders so
// `.font(.custom("SourceSerif4", size:))` resolves throughout, and
// installs the SwiftData container for LenderProfile / Borrower /
// Scenario.
//
// Launch-arg bypasses (DEBUG only, consumed by UI tests):
//   -uitestReset      clear any persisted profile/borrowers/scenarios
//   -uitestSeedProfile  seed a pre-onboarded LenderProfile so the UI
//                      test can skip Sign in with Apple and Face ID.

import SwiftUI
import SwiftData
import CoreText

@main
struct QuotientApp: App {

    let container: ModelContainer

    init() {
        Self.registerBundledFonts()
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

    /// Register every TrueType font under `App/Resources/Fonts/` with
    /// the Core Text font manager.
    private static func registerBundledFonts() {
        let extensions = ["ttf", "otf"]
        for ext in extensions {
            let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            for url in urls {
                var error: Unmanaged<CFError>?
                if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    #if DEBUG
                    if let cfErr = error?.takeRetainedValue() {
                        let msg = CFErrorCopyDescription(cfErr) as String? ?? "unknown"
                        print("[QuotientApp] font register skipped for \(url.lastPathComponent): \(msg)")
                    }
                    #endif
                }
            }
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
