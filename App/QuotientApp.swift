// QuotientApp.swift
// Main app entry. Registers bundled fonts before any view renders so that
// `.fontFamily("SourceSerif4")` resolves throughout the hierarchy.

import SwiftUI
import CoreText

@main
struct QuotientApp: App {

    init() {
        Self.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }

    /// Register every TrueType font under `App/Resources/Fonts/` with the
    /// Core Text font manager. Session 3 adds the Typography layer that
    /// names them; Session 1 just ensures they're available.
    private static func registerBundledFonts() {
        let extensions = ["ttf", "otf"]
        for ext in extensions {
            let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            for url in urls {
                var error: Unmanaged<CFError>?
                if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    // Fonts may already be registered on hot reload — that's not
                    // a real error. Log in debug, swallow in release.
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
