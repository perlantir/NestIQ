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

// MARK: - Licensed states picker

struct LicensedStatesPicker: View {
    @Binding var selection: Set<USState>

    @Environment(\.dismiss)
    private var dismiss

    @State private var search: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredStates, id: \.self) { state in
                    Button {
                        toggle(state)
                    } label: {
                        HStack {
                            Text(state.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(state.rawValue)
                                .foregroundStyle(.tertiary)
                                .monospaced()
                            if selection.contains(state) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Palette.accent)
                                    .padding(.leading, 6)
                            }
                        }
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

    private var filteredStates: [USState] {
        let all = USState.allCases.sorted { $0.displayName < $1.displayName }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return all }
        return all.filter {
            $0.displayName.lowercased().contains(q) || $0.rawValue.lowercased().contains(q)
        }
    }

    private func toggle(_ state: USState) {
        if selection.contains(state) {
            selection.remove(state)
        } else {
            selection.insert(state)
        }
    }
}
