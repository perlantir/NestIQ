// QuotientApp.swift
// Main app entry. Registers bundled fonts before any view renders so
// `.font(.custom("SourceSerif4", size:))` resolves throughout, and
// installs the SwiftData container for LenderProfile / Borrower /
// Scenario.

import SwiftUI
import SwiftData
import CoreText

@main
struct QuotientApp: App {

    let container: ModelContainer

    init() {
        Self.registerBundledFonts()
        self.container = QuotientSchema.makeContainer()
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
}
