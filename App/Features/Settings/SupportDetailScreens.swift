// SupportDetailScreens.swift
// Three support / about detail screens for Settings:
//
//   - FeedbackMailSheet — MFMailComposeViewController wrapped for
//     SwiftUI. Prefills the support address + a subject line that
//     carries the app version + build so Nick can triage by release.
//     Falls back to `UIApplication.open(mailto:)` when Mail isn't set
//     up on the device (simulator, or device with no Mail account).
//   - HelpCenterView — WKWebView wrapper over the production support URL.
//   - LicensesLegalView — static attributions page; pulls privacy /
//     terms URLs from App/Config/Links.swift.

import SwiftUI
import MessageUI
import UIKit
import WebKit

struct FeedbackMailSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        Group {
            if MFMailComposeViewController.canSendMail() {
                MailComposerRepresentable(
                    recipient: Links.supportEmail,
                    subject: subject,
                    messageBody: prefilledBody
                )
                .ignoresSafeArea()
            } else {
                mailUnavailableFallback
            }
        }
    }

    private var subject: String {
        "NestIQ feedback — v\(appVersion) build \(appBuild)"
    }

    /// Prefilled body: diagnostics header up top so Nick can triage by
    /// release / device, then a blank section below the `---` divider
    /// for the user to write in.
    private var prefilledBody: String {
        let device = UIDevice.current
        return """
        App version: \(appVersion)
        Build: \(appBuild)
        iOS version: \(device.systemVersion)
        Device: \(device.model)

        ---

        """
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
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
            Text(Links.supportEmail)
                .textStyle(Typography.num.withSize(13, weight: .medium))
                .foregroundStyle(Palette.accent)
            HStack(spacing: Spacing.s12) {
                Button("Copy address") {
                    UIPasteboard.general.string = Links.supportEmail
                }
                .textStyle(Typography.body.withWeight(.medium))
                .foregroundStyle(Palette.accent)
                Button("Open mailto") {
                    if let url = URL(string: "mailto:\(Links.supportEmail)?subject=\(subject.urlEncoded)") {
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
    let messageBody: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(messageBody, isHTML: false)
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
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                comingSoonPlaceholder
            } else {
                WebView(
                    url: Links.supportURLValue,
                    onLoadFailed: { loadFailed = true }
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationTitle("Help center")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var comingSoonPlaceholder: some View {
        VStack(spacing: Spacing.s12) {
            Spacer()
            Image(systemName: "questionmark.circle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Palette.inkTertiary)
            Text("Help center coming soon")
                .textStyle(Typography.bodyLg.withSize(16, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Text("In the meantime, tap Send feedback to reach us directly.")
                .textStyle(Typography.body.withSize(13))
                .foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.s24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
    }
}

private struct WebView: UIViewRepresentable {
    let url: URL
    let onLoadFailed: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView()
        web.navigationDelegate = context.coordinator
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_: WKWebView, context _: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onLoadFailed: onLoadFailed) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let onLoadFailed: () -> Void
        init(onLoadFailed: @escaping () -> Void) {
            self.onLoadFailed = onLoadFailed
        }
        nonisolated func webView(_: WKWebView, didFail _: WKNavigation!, withError _: any Error) {
            Task { @MainActor in onLoadFailed() }
        }
        nonisolated func webView(
            _: WKWebView,
            didFailProvisionalNavigation _: WKNavigation!,
            withError _: any Error
        ) {
            Task { @MainActor in onLoadFailed() }
        }
    }
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
                Link(destination: Links.privacyURLValue) {
                    legalRow(label: "Privacy policy", subtitle: Links.privacyURL)
                }
                Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                Link(destination: Links.termsURLValue) {
                    legalRow(label: "Terms of service", subtitle: Links.termsURL)
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
            Text("NestIQ is a calculation tool. It is not a loan offer, "
                + "a commitment to lend, or a pre-qualification.")
                .textStyle(Typography.body.withSize(11.5))
                .foregroundStyle(Palette.inkTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
