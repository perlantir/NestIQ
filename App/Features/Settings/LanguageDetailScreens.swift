// LanguageDetailScreens.swift
// Two Settings detail screens for language preferences:
//
//   - AppLanguagePickerScreen — persists LenderProfile.preferredLanguage
//   - PDFLanguagePickerScreen — persists LenderProfile.pdfLanguage
//
// Both screens store the selection but DO NOT yet translate output.
// Full i18n (app + PDF coordinated, native-speaker reviewed) is
// deferred to a dedicated post-feature-complete session targeting
// pre-TestFlight. The footer on both screens tells the LO so, and the
// selection persists so the user's intent is captured ahead of time.

import SwiftUI
import SwiftData

struct AppLanguagePickerScreen: View {
    @Bindable var profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    var body: some View {
        languageList(
            title: "App language",
            selection: Binding(
                get: { profile.preferredLanguage },
                set: { setLanguage($0) }
            ),
            scopeNote: "Sets the language the in-app UI will render in once translation "
                + "ships. Borrower-facing PDF language lives in its own setting."
        )
        .navigationTitle("App language")
    }

    private func setLanguage(_ code: String) {
        profile.preferredLanguage = code
        profile.updatedAt = Date()
        try? modelContext.save()
    }
}

struct PDFLanguagePickerScreen: View {
    @Bindable var profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    var body: some View {
        languageList(
            title: "Borrower-facing PDF",
            selection: Binding(
                get: { profile.pdfLanguage },
                set: { setLanguage($0) }
            ),
            scopeNote: "Sets the language borrower-facing PDFs will render in once translation ships. Independent of the app language."
        )
        .navigationTitle("Borrower PDF")
    }

    private func setLanguage(_ code: String) {
        profile.pdfLanguage = code
        profile.updatedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Shared list view

@MainActor
@ViewBuilder
private func languageList(
    title: String,
    selection: Binding<String>,
    scopeNote: String
) -> some View {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            Text(scopeNote)
                .textStyle(Typography.body.withSize(13))
                .foregroundStyle(Palette.inkSecondary)
                .padding(.horizontal, Spacing.s20)

            VStack(spacing: 0) {
                languageRow(label: "English", code: "en", selection: selection)
                Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                languageRow(label: "Español", code: "es", selection: selection)
            }
            .background(Palette.surfaceRaised)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.listCard)
                    .stroke(Palette.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
            .padding(.horizontal, Spacing.s20)

            deferralFooter()
                .padding(.horizontal, Spacing.s20)
        }
        .padding(.top, Spacing.s16)
        .padding(.bottom, Spacing.s32)
    }
    .background(Palette.surface)
    .scrollIndicators(.hidden)
    .navigationBarTitleDisplayMode(.inline)
}

@MainActor
private func languageRow(
    label: String,
    code: String,
    selection: Binding<String>
) -> some View {
    let selected = selection.wrappedValue == code
    return Button {
        selection.wrappedValue = code
    } label: {
        HStack(spacing: Spacing.s12) {
            Text(label)
                .textStyle(Typography.bodyLg.withSize(15, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.accent)
            }
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
}

@MainActor
private func deferralFooter() -> some View {
    HStack(alignment: .top, spacing: Spacing.s8) {
        Image(systemName: "clock")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Palette.inkTertiary)
            .padding(.top, 2)
        Text("Full Spanish translation coming in a later release. "
            + "Your selection is saved and will take effect then.")
            .textStyle(Typography.body.withSize(12.5))
            .foregroundStyle(Palette.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
    .padding(Spacing.s12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Palette.surfaceRaised.opacity(0.5))
    .overlay(
        RoundedRectangle(cornerRadius: Radius.default)
            .stroke(Palette.borderSubtle, lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: Radius.default))
}
