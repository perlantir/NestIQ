// Links.swift
// Session 6.2 — production URLs for privacy / terms / support / feedback.
// Centralized so Settings, Onboarding, and future surfaces reference
// one source of truth. Any domain change ripples from here.

import Foundation

enum Links {
    static let privacyURL = "https://nestiq.mortgage/privacy"
    static let termsURL = "https://nestiq.mortgage/terms"
    static let supportURL = "https://nestiq.mortgage/support"
    static let feedbackMailto = "mailto:support@nestiq.mortgage?subject=NestIQ%20feedback"
    static let supportEmail = "support@nestiq.mortgage"

    /// URL() getters that fall back to the nestiq.mortgage root on the
    /// theoretical failure case (compile-time constants never trip it
    /// at runtime, but the non-optional shape keeps `Link(destination:)`
    /// call sites force-unwrap-free).
    static var privacyURLValue: URL { url(privacyURL) }
    static var termsURLValue: URL { url(termsURL) }
    static var supportURLValue: URL { url(supportURL) }
    static var feedbackMailtoValue: URL { url(feedbackMailto) }

    private static let fallbackURL = URL(string: "https://nestiq.mortgage") ?? URL(fileURLWithPath: "/")

    private static func url(_ string: String) -> URL {
        URL(string: string) ?? fallbackURL
    }
}
