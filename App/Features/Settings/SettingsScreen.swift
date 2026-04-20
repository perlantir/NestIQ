// SettingsScreen.swift
// Per design/screens/Settings.jsx. 10 logical sections grouped into 6
// visual headers per the JSX (Profile hero / Brand · PDF export /
// Disclaimers · compliance / Appearance / Language · haptics /
// Privacy · data / Support · about).
//
// Session 5 relocates the DEBUG Component gallery entry point here per
// DECISIONS.md 2026-04-17; the row is conditional-compile-only.

import SwiftUI
import SwiftData
import UIKit
import QuotientCompliance

struct SettingsScreen: View {
    let profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    @State private var showingProfileEditor = false
    @State private var showingReplayConfirmation = false
    @State private var showingFeedbackSheet = false
    @State private var showingEraseConfirmation = false
    @State private var showingDeleteAccount = false
    // `internal` (not private) so SettingsScreen+Compliance can flip
    // the flag from the Licensed states row's onTap closure.
    @State var showingLicensedStatesPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, Spacing.s20)
                        .padding(.top, Spacing.s12)
                        .padding(.bottom, Spacing.s16)

                    profileHero

                    brandSection
                    complianceSection
                    appearanceSection
                    languageAndHapticsSection
                    privacyAndDataSection
                    accountSection
                    supportAndAboutSection

                    footer
                        .padding(.horizontal, Spacing.s20)
                        .padding(.top, Spacing.s24)
                        .padding(.bottom, Spacing.s64)
                }
            }
            .background(Palette.surface)
            .scrollIndicators(.hidden)
            .sheet(isPresented: $showingProfileEditor) {
                ProfileEditor(profile: profile)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showingFeedbackSheet) {
                FeedbackMailSheet()
            }
            .sheet(isPresented: $showingLicensedStatesPicker) {
                LicensedStatesPickerSheet(profile: profile)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showingDeleteAccount) {
                DeleteAccountFlow(profile: profile)
                    .presentationDetents([.large])
            }
            .confirmationDialog(
                "Replay the onboarding tour?",
                isPresented: $showingReplayConfirmation,
                titleVisibility: .visible
            ) {
                Button("Replay tour") { replayOnboarding() }
                Button("Cancel", role: .cancel) {}
            }
            .alert(
                "Erase local data?",
                isPresented: $showingEraseConfirmation
            ) {
                Button("Erase", role: .destructive) { eraseData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all saved scenarios, "
                    + "borrowers, and preferences. Your account will remain.")
            }
        }
    }

    // MARK: Header

    private var header: some View {
        // Was a second render of `profile.fullName` here (duplicated the
        // profile hero directly below). Swapped for the NestIQ wordmark
        // per user ask 2026-04-20 so the Settings top anchors on brand,
        // not a repeat of the name card.
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow("Settings")
            Image("Wordmark-A")
                .resizable()
                .scaledToFit()
                .frame(height: 28)
                .accessibilityLabel("NestIQ")
                .accessibilityIdentifier("settings.brand.wordmark")
        }
    }

    // MARK: Profile hero

    private var profileHero: some View {
        HStack(spacing: Spacing.s12) {
            profileAvatar
                .frame(width: 58, height: 58)
                .accessibilityIdentifier("settings.profile.avatar")
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.fullName.isEmpty ? "Add your name" : profile.fullName)
                    .textStyle(Typography.bodyLg.withSize(15, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Text(profileSubline)
                    .textStyle(Typography.num.withSize(11.5))
                    .foregroundStyle(Palette.inkSecondary)
                stateChips
            }
            Spacer()
            Button {
                showingProfileEditor = true
            } label: {
                Text("Edit")
                    .textStyle(Typography.body.withWeight(.medium))
                    .foregroundStyle(Palette.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.s20)
        .padding(.vertical, Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surfaceRaised)
        .overlay(
            VStack(spacing: 0) {
                Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                Spacer()
                Rectangle().fill(Palette.borderSubtle).frame(height: 1)
            }
        )
    }

    /// Upper-right / hero profile avatar. Renders the uploaded photo if
    /// any, falling back to the NestIQ monogram (5I.4.d placement
    /// guide). Prior to 5I.3 the hero always rendered initials —
    /// photoData was saved by ProfileEditor but never consumed here.
    @ViewBuilder private var profileAvatar: some View {
        if let data = profile.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .overlay(Circle().stroke(Palette.borderSubtle, lineWidth: 1))
        } else {
            Image("Monogram-Accent")
                .resizable()
                .scaledToFit()
                .padding(6)
                .background(Palette.surfaceSunken)
                .clipShape(Circle())
                .overlay(Circle().stroke(Palette.borderSubtle, lineWidth: 1))
        }
    }

    private var profileSubline: String {
        let parts = [
            profile.nmlsId.isEmpty ? nil : "NMLS \(profile.nmlsId)",
            profile.companyName.isEmpty ? nil : profile.companyName,
        ].compactMap { $0 }
        return parts.isEmpty ? "Tap Edit to set up your profile" : parts.joined(separator: " · ")
    }

    private var stateChips: some View {
        HStack(spacing: Spacing.s4) {
            ForEach(profile.licensedStates.prefix(5), id: \.self) { s in
                Text(s.uppercased())
                    .textStyle(Typography.num.withSize(9.5))
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Palette.accentTint)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.monoChip))
            }
        }
        .padding(.top, Spacing.s4)
    }

    // MARK: Sections

    @ViewBuilder private var brandSection: some View {
        settingsGroup(header: "Brand · PDF export") {
            settingsNavRow(label: "Accent color", trailing: accentColorLabel) {
                AccentColorPickerScreen(profile: profile)
            }
            divider
            settingsNavRow(
                label: "Logo",
                trailing: profile.companyLogoData == nil ? "Not set" : "Uploaded"
            ) {
                LogoPickerScreen(profile: profile)
            }
            divider
            SettingsRow(
                label: "Show photo on PDF",
                trailing: .toggle(Binding(
                    get: { profile.showPhotoOnPDF },
                    set: { set(\.showPhotoOnPDF, $0) }
                ))
            )
        }
    }

    private var accentColorLabel: String {
        let hex = profile.brandColorHex.lowercased()
        return AccentColorPickerScreen.palette
            .first(where: { $0.hex.lowercased() == hex })?
            .name ?? "Custom"
    }

    // complianceSection + licensedStatesPreview live in
    // SettingsScreen+Compliance.swift (Session 5L.5 extraction).

    private var appearanceSection: some View {
        settingsGroup(header: "Appearance") {
            appearanceSegmented
        }
    }

    private var appearanceSegmented: some View {
        HStack(spacing: Spacing.s16) {
            Text("Theme")
                .textStyle(Typography.bodyLg.withSize(14.5, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
            Picker("", selection: Binding(
                get: { profile.appearance },
                set: { setAppearance($0) }
            )) {
                Text("Light").tag(AppearancePreference.light)
                Text("Dark").tag(AppearancePreference.dark)
                Text("Auto").tag(AppearancePreference.system)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    @ViewBuilder private var languageAndHapticsSection: some View {
        settingsGroup(header: "Language · haptics") {
            settingsNavRow(
                label: "App language",
                trailing: profile.preferredLanguage == "es" ? "Español" : "English"
            ) {
                AppLanguagePickerScreen(profile: profile)
            }
            divider
            settingsNavRow(
                label: "Borrower-facing PDF",
                trailing: profile.pdfLanguage == "es" ? "Español" : "English"
            ) {
                PDFLanguagePickerScreen(profile: profile)
            }
            divider
            SettingsRow(label: "Haptics on calculate",
                        trailing: .toggle(Binding(
                            get: { profile.hapticsEnabled },
                            set: { set(\.hapticsEnabled, $0) }
                        )))
            divider
            SettingsRow(label: "Sound on share",
                        trailing: .toggle(Binding(
                            get: { profile.soundsEnabled },
                            set: { set(\.soundsEnabled, $0) }
                        )))
        }
    }

    private var privacyAndDataSection: some View {
        settingsGroup(header: "Privacy · data") {
            SettingsRow(label: "Face ID to open",
                        trailing: .toggle(Binding(
                            get: { profile.faceIDEnabled },
                            set: { set(\.faceIDEnabled, $0) }
                        )))
        }
    }

    /// Apple Guideline 5.1.1(v) — apps that create accounts must expose
    /// in-app deletion. "Erase local data" wipes content while leaving
    /// the SIWA session attached; "Delete account" nukes everything.
    private var accountSection: some View {
        settingsGroup(header: "Account") {
            SettingsRow(label: "Erase local data",
                        trailing: .disclosure,
                        onTap: { showingEraseConfirmation = true })
            divider
            SettingsRow(
                label: "Delete account",
                labelColor: Palette.loss,
                trailing: .disclosure,
                onTap: { showingDeleteAccount = true }
            )
            .accessibilityIdentifier("settings.deleteAccount")
        }
    }

    @ViewBuilder private var supportAndAboutSection: some View {
        settingsGroup(header: "Support · about") {
            SettingsRow(
                label: "Send feedback",
                onTap: { showingFeedbackSheet = true }
            )
            divider
            settingsNavRow(label: "Help center", trailing: "") {
                HelpCenterView()
            }
            divider
            settingsNavRow(label: "Licenses & legal", trailing: "") {
                LicensesLegalView()
            }
            divider
            SettingsRow(label: "Replay onboarding tour",
                        onTap: { showingReplayConfirmation = true })
            // Component gallery removed from user-facing Settings per
            // Session 5B.1.e. The ComponentGallery view stays in the
            // codebase and will be rewired behind a DEBUG-only
            // shake-gesture dev menu in a later session.
            divider
            aboutRow
        }
    }

    /// About hero — Wordmark-A at 28pt over version string in SF Mono,
    /// per the NestIQ placement guide (5I.4.d). Replaces the bare
    /// "Version" trailing-value row so the About surface actually feels
    /// like one.
    private var aboutRow: some View {
        VStack(spacing: 6) {
            Image("Wordmark-A")
                .resizable()
                .scaledToFit()
                .frame(height: 28)
            Text("v\(versionDisplay)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Palette.inkTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s16)
    }

    private var versionDisplay: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) · build \(build)"
    }

    private var footer: some View {
        Text("NestIQ · Powered by Perlantir")
            .font(.custom(Typography.serifFamily + "-It", size: 11))
            .foregroundStyle(Palette.inkTertiary)
            .frame(maxWidth: .infinity)
    }

    // MARK: Helpers

    // `internal` so extension files in this folder (e.g.
    // SettingsScreen+Compliance) can build rows using the shared group
    // / divider / nav-row styling.
    @ViewBuilder
    func settingsGroup<Content: View>(
        header: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(header)
                .padding(.horizontal, Spacing.s20)
                .padding(.top, Spacing.s24)
                .padding(.bottom, Spacing.s8)
            VStack(spacing: 0) { content() }
                .background(Palette.surfaceRaised)
                .overlay(
                    VStack(spacing: 0) {
                        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                        Spacer()
                        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                    }
                )
        }
    }

    var divider: some View {
        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
    }

    /// NavigationLink styled to match `SettingsRow` — same padding, same
    /// label typography, trailing value + chevron, hairline divider
    /// stitched below. Used for rows that push a detail screen rather
    /// than opening a sheet or toggling state.
    @ViewBuilder
    func settingsNavRow<Destination: View>(
        label: String,
        trailing: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: Spacing.s16) {
                Text(label)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Palette.ink)
                Spacer()
                if !trailing.isEmpty {
                    Text(trailing)
                        .textStyle(Typography.body)
                        .foregroundStyle(Palette.inkSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    private func set<Value>(
        _ keyPath: ReferenceWritableKeyPath<LenderProfile, Value>,
        _ value: Value
    ) {
        profile[keyPath: keyPath] = value
        profile.updatedAt = Date()
        try? modelContext.save()
    }

    private func setAppearance(_ a: AppearancePreference) {
        profile.appearance = a
        profile.updatedAt = Date()
        try? modelContext.save()
    }

    private func replayOnboarding() {
        profile.hasCompletedOnboarding = false
        profile.updatedAt = Date()
        try? modelContext.save()
    }

    private func eraseData() {
        try? modelContext.delete(model: Scenario.self)
        try? modelContext.delete(model: Borrower.self)
        try? modelContext.save()
        if profile.hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// ProfileEditor + LicensedStatesPicker live in ProfileEditor.swift.
