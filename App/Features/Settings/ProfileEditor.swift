// ProfileEditor.swift
// Form sheet for editing LenderProfile. Opens from the Edit button on
// the Settings profile hero.
//
// Covers every field the PDF renderer consumes: name, NMLS (with live
// validation via QuotientCompliance's nmlsConsumerAccessURL), licensed
// states (multi-select from USState.allCases), company / phone / email,
// and app language. The PDF language is deliberately NOT edited here —
// it has a dedicated Settings row so an EN-speaking LO can still issue
// ES-locale borrower PDFs.

import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import QuotientCompliance

struct ProfileEditor: View {
    @Bindable var profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    @State private var selectedStates: Set<USState> = []
    @State private var showingStatePicker = false
    @State private var nmlsError: String?
    @State private var photoSelection: PhotosPickerItem?
    @State private var photoError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    photoRow
                } header: {
                    Text("Photo")
                } footer: {
                    if let photoError {
                        Text(photoError).foregroundStyle(.red)
                    } else {
                        Text("Rendered on borrower-facing PDFs when "
                            + "'Show photo on PDF' is enabled in Brand settings.")
                    }
                }
                Section("Name") {
                    TextField("First name", text: $profile.firstName)
                        .textInputAutocapitalization(.words)
                    TextField("Last name", text: $profile.lastName)
                        .textInputAutocapitalization(.words)
                }
                Section {
                    TextField("NMLS ID", text: $profile.nmlsId)
                        .keyboardType(.numberPad)
                        .onChange(of: profile.nmlsId) { _, _ in validateNMLS() }
                    Button {
                        showingStatePicker = true
                    } label: {
                        HStack {
                            Text("Licensed states")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(licensedStatesSummary)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("License")
                } footer: {
                    if let nmlsError {
                        Text(nmlsError).foregroundStyle(.red)
                    }
                }
                Section("Company") {
                    TextField("Company name", text: $profile.companyName)
                        .textInputAutocapitalization(.words)
                    TextField("Phone", text: $profile.phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $profile.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    Picker("App language", selection: $profile.preferredLanguage) {
                        Text("English").tag("en")
                        Text("Español").tag("es")
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text("Borrower-facing PDF language lives in Settings › Language · haptics.")
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        commit()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(nmlsError != nil)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingStatePicker) {
                LicensedStatesPicker(selection: $selectedStates)
                    .presentationDetents([.large])
            }
            .onChange(of: photoSelection) { _, new in
                Task { await loadPhoto(from: new) }
            }
            .onAppear {
                selectedStates = Set(profile.licensedStates
                    .compactMap { USState(rawValue: $0) })
                validateNMLS()
            }
        }
    }

    private var photoRow: some View {
        let hasPhoto = profile.photoData != nil
        return HStack(spacing: 16) {
            photoThumbnail
            VStack(alignment: .leading, spacing: 6) {
                PhotosPicker(
                    selection: $photoSelection,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text(hasPhoto ? "Replace" : "Add photo")
                        .font(.body.weight(.medium))
                }
                if hasPhoto {
                    Button("Remove photo", role: .destructive) {
                        removePhoto()
                    }
                    .font(.caption)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private var photoThumbnail: some View {
        if let data = profile.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
        } else {
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .overlay(
                    Text(profile.initials.isEmpty ? "NM" : profile.initials)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.secondary)
                )
                .frame(width: 56, height: 56)
        }
    }

    /// JPEG-compress at ~0.7 quality. Limits the persisted blob to a
    /// reasonable size (photo libraries often hand out 10+ MB HEICs).
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                photoError = "Couldn't read the selected photo."
                return
            }
            guard let compressed = image.jpegData(compressionQuality: 0.7) else {
                photoError = "Couldn't process the selected photo."
                return
            }
            await MainActor.run {
                profile.photoData = compressed
                profile.updatedAt = Date()
                try? modelContext.save()
                photoError = nil
            }
        } catch {
            photoError = error.localizedDescription
        }
    }

    private func removePhoto() {
        profile.photoData = nil
        profile.updatedAt = Date()
        try? modelContext.save()
    }

    private var licensedStatesSummary: String {
        let states = selectedStates.map(\.rawValue).sorted()
        if states.isEmpty { return "None" }
        if states.count <= 5 { return states.joined(separator: " · ") }
        return "\(states.count) states"
    }

    private func validateNMLS() {
        let trimmed = profile.nmlsId.trimmingCharacters(in: .whitespaces)
        // Empty is allowed during onboarding — only fail on non-numeric.
        if trimmed.isEmpty {
            nmlsError = nil
            return
        }
        do {
            _ = try nmlsConsumerAccessURL(for: trimmed)
            nmlsError = nil
        } catch ComplianceError.invalidNMLS(let message) {
            nmlsError = message
        } catch {
            nmlsError = error.localizedDescription
        }
    }

    private func commit() {
        profile.licensedStates = selectedStates.map(\.rawValue).sorted()
        profile.updatedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Licensed states picker sheet

/// Sheet wrapper around `LicensedStatesPicker` for direct entry from
/// Settings row / Per-State Disclosures (Session 5L.4). Seeds the
/// selection from `profile.licensedStates` and commits back on dismiss
/// so both entry points share identical persistence semantics with the
/// in-ProfileEditor picker.
struct LicensedStatesPickerSheet: View {
    @Bindable var profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    @State private var selection: Set<USState> = []

    var body: some View {
        LicensedStatesPicker(selection: $selection)
            .onAppear {
                selection = Set(profile.licensedStates.compactMap { USState(rawValue: $0) })
            }
            .onDisappear { commit() }
    }

    private func commit() {
        profile.licensedStates = selection.map(\.rawValue).sorted()
        profile.updatedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Licensed states picker

struct LicensedStatesPicker: View {
    @Binding var selection: Set<USState>

    @Environment(\.dismiss)
    private var dismiss

    @State private var search: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text(countLabel)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("licensedStates.count")
                        Spacer()
                        Button {
                            selectAllVisible()
                        } label: {
                            Text("Select all")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.borderless)
                        .disabled(selectAllDisabled)
                        .accessibilityIdentifier("licensedStates.selectAll")
                        Text("·")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                        Button {
                            deselectAllVisible()
                        } label: {
                            Text("Deselect all")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.borderless)
                        .disabled(deselectAllDisabled)
                        .accessibilityIdentifier("licensedStates.deselectAll")
                    }
                }
                if !fullStates.isEmpty {
                    Section {
                        ForEach(fullStates, id: \.self) { state in
                            stateRow(state: state, hasFullText: true)
                        }
                    } header: {
                        Text("Full disclosure")
                    } footer: {
                        Text("State-specific disclosure text reviewed by counsel is available.")
                    }
                }
                if !fallbackStates.isEmpty {
                    Section {
                        ForEach(fallbackStates, id: \.self) { state in
                            stateRow(state: state, hasFullText: false)
                        }
                    } header: {
                        Text("Fallback")
                    } footer: {
                        Text("Generic disclaimer until state-specific text lands — "
                            + "counsel review still pending.")
                    }
                }
            }
            .searchable(text: $search, prompt: "Search")
            .navigationTitle("Licensed states")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private var countLabel: String {
        "Licensed in \(selection.count) of \(USState.allCases.count) states"
    }

    /// Target set for bulk actions — respects the current search filter so
    /// an LO can narrow with search and bulk-select the subset.
    private var visibleStates: [USState] { allFiltered }

    private var selectAllDisabled: Bool {
        !visibleStates.contains { !selection.contains($0) }
    }

    private var deselectAllDisabled: Bool {
        !visibleStates.contains { selection.contains($0) }
    }

    private func selectAllVisible() {
        selection.formUnion(visibleStates)
    }

    private func deselectAllVisible() {
        selection.subtract(visibleStates)
    }

    @ViewBuilder
    private func stateRow(state: USState, hasFullText: Bool) -> some View {
        Button {
            toggle(state)
        } label: {
            HStack(spacing: 10) {
                Text(state.rawValue)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(width: 34, alignment: .leading)
                Text(state.displayName)
                    .foregroundStyle(.primary)
                Spacer()
                Text(hasFullText ? "Full text available" : "Generic disclaimer")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if selection.contains(state) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Palette.accent)
                }
            }
        }
    }

    private static func hasNamedDisclosure(for state: USState) -> Bool {
        requiredDisclosures(for: .amortization, propertyState: state)
            .first?.provenance == DisclosureProvenance.stateSpecific
    }

    private var allFiltered: [USState] {
        let all = USState.allCases.sorted { $0.displayName < $1.displayName }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return all }
        return all.filter {
            $0.displayName.lowercased().contains(q) || $0.rawValue.lowercased().contains(q)
        }
    }

    private var fullStates: [USState] {
        allFiltered.filter(Self.hasNamedDisclosure)
    }

    private var fallbackStates: [USState] {
        allFiltered.filter { !Self.hasNamedDisclosure(for: $0) }
    }

    private func toggle(_ state: USState) {
        if selection.contains(state) {
            selection.remove(state)
        } else {
            selection.insert(state)
        }
    }
}
