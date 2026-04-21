// ComplianceDetailScreens.swift
// Two push-destination Settings screens backing the
// "Disclaimers · compliance" group:
//
//   - NMLSDisplayFormatPicker — three presentation options for the
//     NMLS line on the borrower-facing PDF.
//   - EqualHousingLanguagePicker — EN/ES picker for the federal EHO
//     statement rendered on the PDF disclaimers page.

import SwiftUI
import SwiftData
import QuotientCompliance
import QuotientFinance

// MARK: - NMLS display format

struct NMLSDisplayFormatPicker: View {
    @Bindable var profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                Text("Controls how the NMLS line surfaces on the borrower-facing PDF "
                    + "footer. The in-app display and the Profile card are always 'ID only'.")
                    .textStyle(Typography.body.withSize(13))
                    .foregroundStyle(Palette.inkSecondary)
                    .padding(.horizontal, Spacing.s20)

                VStack(spacing: 0) {
                    ForEach(Array(NMLSDisplayFormat.allCases.enumerated()), id: \.element) { idx, format in
                        formatRow(format: format)
                        if idx < NMLSDisplayFormat.allCases.count - 1 {
                            Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                        }
                    }
                }
                .background(Palette.surfaceRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.listCard)
                        .stroke(Palette.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
                .padding(.horizontal, Spacing.s20)
            }
            .padding(.top, Spacing.s16)
            .padding(.bottom, Spacing.s32)
        }
        .background(Palette.surface)
        .scrollIndicators(.hidden)
        .navigationTitle("NMLS display")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatRow(format: NMLSDisplayFormat) -> some View {
        let selected = profile.nmlsDisplayFormat == format
        return Button {
            profile.nmlsDisplayFormat = format
            profile.updatedAt = Date()
            try? modelContext.save()
        } label: {
            HStack(spacing: Spacing.s12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(format.display)
                        .textStyle(Typography.bodyLg.withSize(15, weight: .medium))
                        .foregroundStyle(Palette.ink)
                    Text(previewText(for: format))
                        .textStyle(Typography.num.withSize(11))
                        .foregroundStyle(Palette.inkTertiary)
                }
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

    private func previewText(for format: NMLSDisplayFormat) -> String {
        let id = profile.nmlsId.isEmpty ? "1428391" : profile.nmlsId
        switch format {
        case .idOnly:   return "NMLS #\(id)"
        case .idAndURL: return "NMLS #\(id) · nmlsconsumeraccess.org/…/\(id)"
        case .none:     return "Omitted from PDF footer"
        }
    }
}

// MARK: - Equal Housing language

struct EqualHousingLanguagePicker: View {
    @Bindable var profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                Text("Federal Equal Housing Opportunity statement printed on the PDF "
                    + "disclaimers page. Stays independent of the app's language so "
                    + "EN-speaking LOs can still issue ES-locale statements.")
                    .textStyle(Typography.body.withSize(13))
                    .foregroundStyle(Palette.inkSecondary)
                    .padding(.horizontal, Spacing.s20)

                VStack(spacing: 0) {
                    ForEach(Array(EHOLanguage.allCases.enumerated()), id: \.element) { idx, lang in
                        languageRow(lang: lang)
                        if idx < EHOLanguage.allCases.count - 1 {
                            Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                        }
                    }
                }
                .background(Palette.surfaceRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.listCard)
                        .stroke(Palette.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
                .padding(.horizontal, Spacing.s20)

                preview
                    .padding(.horizontal, Spacing.s20)
            }
            .padding(.top, Spacing.s16)
            .padding(.bottom, Spacing.s32)
        }
        .background(Palette.surface)
        .scrollIndicators(.hidden)
        .navigationTitle("Equal Housing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func languageRow(lang: EHOLanguage) -> some View {
        let selected = profile.ehoLanguage == lang
        return Button {
            profile.ehoLanguage = lang
            profile.updatedAt = Date()
            try? modelContext.save()
        } label: {
            HStack(spacing: Spacing.s12) {
                Text(lang.display)
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

    private var preview: some View {
        let locale = profile.ehoLanguage == .es
            ? Locale(identifier: "es_MX")
            : Locale(identifier: "en_US")
        let statement = equalHousingOpportunityStatement(locale: locale)
        return VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Preview")
            Text(statement)
                .textStyle(Typography.body.withSize(12.5))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Spacing.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.surfaceRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.listCard)
                        .stroke(Palette.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
        }
    }
}
