// ComplianceDetailScreens.swift
// Three push-destination Settings screens backing the
// "Disclaimers · compliance" group:
//
//   - PerStateDisclosuresPreview — preview-only (no editing) for the
//     LO's licensed states. Per Session 5A scope, this preserves the
//     QuotientCompliance CounselReviewStatus architecture from Session
//     2: LOs see counsel-review badges beside every disclosure but
//     cannot edit the text from the app.
//   - NMLSDisplayFormatPicker — three presentation options for the
//     NMLS line on the borrower-facing PDF.
//   - EqualHousingLanguagePicker — EN/ES picker for the federal EHO
//     statement rendered on the PDF disclaimers page.

import SwiftUI
import SwiftData
import QuotientCompliance
import QuotientFinance

// MARK: - Per-state disclosures preview

struct PerStateDisclosuresPreview: View {
    @Bindable var profile: LenderProfile

    @State private var expandedState: USState?
    @State private var showingLicensedStatesPicker = false

    private var licensedStates: [USState] {
        profile.licensedStates
            .compactMap { USState(rawValue: $0) }
            .sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                Text("Preview only. Disclosure text is maintained in QuotientCompliance "
                    + "and reviewed by counsel — you can't edit it from the app.")
                    .textStyle(Typography.body.withSize(13))
                    .foregroundStyle(Palette.inkSecondary)
                    .padding(.horizontal, Spacing.s20)

                editStatesButton
                    .padding(.horizontal, Spacing.s20)

                if licensedStates.isEmpty {
                    emptyState
                        .padding(.horizontal, Spacing.s20)
                } else {
                    VStack(spacing: Spacing.s12) {
                        ForEach(licensedStates, id: \.self) { state in
                            stateCard(state: state)
                        }
                    }
                    .padding(.horizontal, Spacing.s20)
                }
            }
            .padding(.top, Spacing.s16)
            .padding(.bottom, Spacing.s32)
        }
        .background(Palette.surface)
        .scrollIndicators(.hidden)
        .navigationTitle("Per-state disclosures")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingLicensedStatesPicker) {
            LicensedStatesPickerSheet(profile: profile)
                .presentationDetents([.large])
        }
    }

    private var editStatesButton: some View {
        Button {
            showingLicensedStatesPicker = true
        } label: {
            HStack(spacing: Spacing.s8) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .semibold))
                Text("Edit licensed states")
                    .textStyle(Typography.body.withWeight(.medium))
            }
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Palette.accentTint)
            .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("perState.editLicensedStates")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("No licensed states set.")
                .textStyle(Typography.bodyLg.withSize(15, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Text("Add states in Edit profile to see the required disclosures here.")
                .textStyle(Typography.body)
                .foregroundStyle(Palette.inkSecondary)
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

    @ViewBuilder
    private func stateCard(state: USState) -> some View {
        let disclosures = requiredDisclosures(for: .amortization, propertyState: state)
        let expanded = expandedState == state
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    expandedState = expanded ? nil : state
                }
            } label: {
                HStack(spacing: Spacing.s8) {
                    Text(state.rawValue)
                        .textStyle(Typography.num.withSize(11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Palette.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Palette.accentTint)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.monoChip))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.displayName)
                            .textStyle(Typography.bodyLg.withSize(15, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                        counselBadge(for: disclosures)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            .buttonStyle(.plain)

            if expanded {
                disclosureBlock(disclosures: disclosures)
                    .padding(.top, Spacing.s8)
            }
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

    @ViewBuilder
    private func counselBadge(for disclosures: [Disclosure]) -> some View {
        let statuses = Set(disclosures.map(\.counselReviewStatus.label))
        let pending = disclosures.contains {
            if case .pendingReview = $0.counselReviewStatus { return true }
            return false
        }
        HStack(spacing: Spacing.s4) {
            ForEach(Array(statuses), id: \.self) { label in
                HStack(spacing: 3) {
                    Circle()
                        .fill(pending ? Palette.warn : Palette.gain)
                        .frame(width: 5, height: 5)
                    Text(label.uppercased())
                        .textStyle(Typography.num.withSize(10, weight: .semibold))
                        .tracking(0.7)
                        .foregroundStyle(pending ? Palette.warn : Palette.gain)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(pending ? Palette.warn.opacity(0.12) : Palette.gain.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Radius.monoChip))
            }
        }
    }

    private func disclosureBlock(disclosures: [Disclosure]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            ForEach(Array(disclosures.enumerated()), id: \.offset) { _, d in
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    Eyebrow("English")
                    Text(d.textEN)
                        .textStyle(Typography.body.withSize(12.5))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                    Eyebrow("Español")
                        .padding(.top, Spacing.s4)
                    Text(d.textES)
                        .textStyle(Typography.body.withSize(12.5))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                    HStack(spacing: Spacing.s8) {
                        Text(d.sourceCitation)
                            .textStyle(Typography.num.withSize(10.5))
                            .foregroundStyle(Palette.inkTertiary)
                        Spacer()
                        Text("Retrieved \(shortDate(d.retrievalDate))")
                            .textStyle(Typography.num.withSize(10.5))
                            .foregroundStyle(Palette.inkTertiary)
                    }
                    .padding(.top, Spacing.s4)
                }
            }
        }
    }

    private func shortDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: d)
    }
}

private extension CounselReviewStatus {
    var label: String {
        switch self {
        case .pendingReview: return "Pending review"
        case .reviewedApproved: return "Approved"
        case .reviewedNeedsRevision: return "Needs revision"
        }
    }
}

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
