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
import QuotientCompliance

struct SettingsScreen: View {
    let profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    @State private var showingProfileEditor = false
    @State private var showingReplayConfirmation = false
    @State private var showingFeedbackSheet = false

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
            .confirmationDialog(
                "Replay the onboarding tour?",
                isPresented: $showingReplayConfirmation,
                titleVisibility: .visible
            ) {
                Button("Replay tour") { replayOnboarding() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Eyebrow("Settings")
            Text(profile.fullName.isEmpty ? "Profile" : profile.fullName)
                .textStyle(Typography.display.withSize(28, weight: .bold))
                .foregroundStyle(Palette.ink)
        }
    }

    // MARK: Profile hero

    private var profileHero: some View {
        HStack(spacing: Spacing.s12) {
            Circle()
                .fill(Palette.surfaceSunken)
                .overlay(Circle().stroke(Palette.borderSubtle, lineWidth: 1))
                .overlay(
                    Text(profile.initials.isEmpty ? "NM" : profile.initials)
                        .font(.custom(Typography.serifFamily, size: 20))
                        .foregroundStyle(Palette.inkSecondary)
                )
                .frame(width: 58, height: 58)
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
            settingsNavRow(
                label: "Signature block",
                trailing: profile.tagline?.isEmpty == false ? "Custom" : "Default"
            ) {
                SignatureBlockEditor(profile: profile)
            }
        }
    }

    private var accentColorLabel: String {
        let hex = profile.brandColorHex.lowercased()
        return AccentColorPickerScreen.palette
            .first(where: { $0.hex.lowercased() == hex })?
            .name ?? "Custom"
    }

    @ViewBuilder private var complianceSection: some View {
        settingsGroup(header: "Disclaimers · compliance") {
            settingsNavRow(
                label: "Per-state disclosures",
                trailing: profile.licensedStates.isEmpty ? "None" : "\(profile.licensedStates.count) states"
            ) {
                PerStateDisclosuresPreview(profile: profile)
            }
            divider
            settingsNavRow(
                label: "NMLS display",
                trailing: profile.nmlsDisplayFormat.display
            ) {
                NMLSDisplayFormatPicker(profile: profile)
            }
            divider
            settingsNavRow(
                label: "Equal Housing language",
                trailing: profile.ehoLanguage.display
            ) {
                EqualHousingLanguagePicker(profile: profile)
            }
        }
    }

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
            SettingsRow(
                label: "App language",
                trailing: .value(profile.preferredLanguage == "es" ? "Español" : "English"),
                onTap: { toggleLanguage() }
            )
            divider
            SettingsRow(
                label: "Borrower-facing PDF",
                trailing: .value(profile.pdfLanguage == "es" ? "Español" : "English"),
                onTap: { togglePDFLanguage() }
            )
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
            SettingsRow(label: "Erase local data",
                        trailing: .disclosure,
                        onTap: { eraseData() })
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
            #if DEBUG
            divider
            NavigationLink {
                ComponentGallery()
                    .navigationTitle("Component gallery")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    Text("Component gallery")
                        .font(.system(size: 17))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text("DEBUG")
                        .textStyle(Typography.num.withSize(10.5))
                        .foregroundStyle(Palette.inkTertiary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.inkTertiary)
                }
                .padding(.horizontal, Spacing.s16)
                .padding(.vertical, Spacing.s12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            #endif
            divider
            SettingsRow(label: "Version",
                        trailing: .value(versionDisplay),
                        onTap: nil)
        }
    }

    private var versionDisplay: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) · build \(build)"
    }

    private var footer: some View {
        Text("Quotient — made in Portland, OR")
            .font(.custom(Typography.serifFamily + "-It", size: 11))
            .foregroundStyle(Palette.inkTertiary)
            .frame(maxWidth: .infinity)
    }

    // MARK: Helpers

    @ViewBuilder
    private func settingsGroup<Content: View>(
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

    private var divider: some View {
        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
    }

    /// NavigationLink styled to match `SettingsRow` — same padding, same
    /// label typography, trailing value + chevron, hairline divider
    /// stitched below. Used for rows that push a detail screen rather
    /// than opening a sheet or toggling state.
    @ViewBuilder
    private func settingsNavRow<Destination: View>(
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

    private func toggleLanguage() {
        profile.preferredLanguage = profile.preferredLanguage == "es" ? "en" : "es"
        profile.updatedAt = Date()
        try? modelContext.save()
    }

    private func togglePDFLanguage() {
        profile.pdfLanguage = profile.pdfLanguage == "es" ? "en" : "es"
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
    }
}

// ProfileEditor + LicensedStatesPicker live in ProfileEditor.swift.
