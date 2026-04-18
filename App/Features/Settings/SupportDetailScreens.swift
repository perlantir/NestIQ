// SupportDetailScreens.swift
// Three support / about detail screens for Settings:
//
//   - FeedbackMailSheet — MFMailComposeViewController wrapped for
//     SwiftUI. Prefills the support address + a subject line that
//     carries the app version + build so Nick can triage by release.
//     Falls back to `UIApplication.open(mailto:)` when Mail isn't set
//     up on the device (simulator, or device with no Mail account).
//   - HelpCenterView — WKWebView wrapper. Placeholder URL until Nick
//     provisions the real help center; TODO flagged.
//   - LicensesLegalView — static attributions page. Bundled-font
//     licenses, privacy / terms URL placeholders.
//
// The email address and both URLs are Nick-blockers flagged in
// SESSION-5A-SUMMARY; TODOs are inline below for grep discovery.

import SwiftUI
import MessageUI
import UIKit
import WebKit

// MARK: - Feedback mail sheet

// TODO: real support email before TestFlight
private let supportEmail = "support@quotient.app"

// Placeholder URLs — string constants stay parseable so we can
// reconstruct URL() safely. TODO: swap for real values before TestFlight.
private let helpCenterURLString = "https://quotient.app/help-placeholder"
private let privacyURLString = "https://quotient.app/privacy-placeholder"
private let termsURLString = "https://quotient.app/terms-placeholder"

private func placeholderURL(_ string: String) -> URL {
    URL(string: string) ?? URL(string: "https://quotient.app")
        ?? URL(fileURLWithPath: "/")
}

struct FeedbackMailSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        Group {
            if MFMailComposeViewController.canSendMail() {
                MailComposerRepresentable(
                    recipient: supportEmail,
                    subject: subject
                )
                .ignoresSafeArea()
            } else {
                mailUnavailableFallback
            }
        }
    }

    private var subject: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Quotient feedback - v\(version) build \(build)"
    }

    private var mailUnavailableFallback: some View {
        VStack(spacing: Spacing.s16) {
            Image(systemName: "envelope")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Palette.inkTertiary)
            Text("Mail isn't set up on this device")
                .textStyle(Typography.bodyLg.withSize(16, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Text("Send feedback directly to")
                .textStyle(Typography.body)
                .foregroundStyle(Palette.inkSecondary)
            Text(supportEmail)
                .textStyle(Typography.num.withSize(13, weight: .medium))
                .foregroundStyle(Palette.accent)
            HStack(spacing: Spacing.s12) {
                Button("Copy address") {
                    UIPasteboard.general.string = supportEmail
                }
                .textStyle(Typography.body.withWeight(.medium))
                .foregroundStyle(Palette.accent)
                Button("Open mailto") {
                    if let url = URL(string: "mailto:\(supportEmail)?subject=\(subject.urlEncoded)") {
                        UIApplication.shared.open(url)
                    }
                }
                .textStyle(Typography.body.withWeight(.medium))
                .foregroundStyle(Palette.accent)
            }
            .padding(.top, Spacing.s8)
            Button("Close") { dismiss() }
                .textStyle(Typography.body)
                .foregroundStyle(Palette.inkSecondary)
                .padding(.top, Spacing.s16)
        }
        .padding(Spacing.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
    }
}

private struct MailComposerRepresentable: UIViewControllerRepresentable {
    let recipient: String
    let subject: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        nonisolated func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith _: MFMailComposeResult,
            error _: (any Error)?
        ) {
            Task { @MainActor in
                controller.dismiss(animated: true)
            }
        }
    }
}

private extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}

// MARK: - Help center

struct HelpCenterView: View {
    var body: some View {
        WebView(url: placeholderURL(helpCenterURLString))
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Help center")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView()
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_: WKWebView, context _: Context) {}
}

// MARK: - Licenses & legal

struct LicensesLegalView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s24) {
                attributionsSection
                legalLinksSection
                copyrightSection
            }
            .padding(.horizontal, Spacing.s20)
            .padding(.vertical, Spacing.s20)
            .padding(.bottom, Spacing.s48)
        }
        .background(Palette.surface)
        .scrollIndicators(.hidden)
        .navigationTitle("Licenses & legal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var attributionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Bundled fonts")
            attribution(
                name: "Source Serif 4",
                license: "SIL Open Font License 1.1",
                body: "Copyright 2014 – 2023 Adobe (http://www.adobe.com/), "
                    + "with Reserved Font Name 'Source'. This Font Software is "
                    + "licensed under the SIL Open Font License, Version 1.1."
            )
            attribution(
                name: "SF Pro · SF Mono",
                license: "Apple system font",
                body: "Bundled with iOS 18. No external license required when "
                    + "used in an App Store-distributed iOS application."
            )
        }
    }

    private func attribution(name: String, license: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            HStack {
                Text(name)
                    .textStyle(Typography.bodyLg.withSize(14, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Text("· \(license)")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
                Spacer()
            }
            Text(body)
                .textStyle(Typography.body.withSize(12.5))
                .foregroundStyle(Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
    }

    private var legalLinksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Legal")
            VStack(spacing: 0) {
                Link(destination: placeholderURL(privacyURLString)) {
                    legalRow(label: "Privacy policy", subtitle: privacyURLString)
                }
                Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                Link(destination: placeholderURL(termsURLString)) {
                    legalRow(label: "Terms of service", subtitle: termsURLString)
                }
            }
            .background(Palette.surfaceRaised)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.listCard)
                    .stroke(Palette.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
        }
    }

    private func legalRow(label: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text(subtitle)
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.inkTertiary)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    private var copyrightSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("© 2026 Perlantir AI Studio")
                .textStyle(Typography.body.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
            Text("Quotient is a calculation tool. It is not a loan offer, "
                + "a commitment to lend, or a pre-qualification.")
                .textStyle(Typography.body.withSize(11.5))
                .foregroundStyle(Palette.inkTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
