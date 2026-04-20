// BorrowerPicker.swift
// Per design/screens/BorrowerPicker.jsx. Bottom sheet with grabber,
// search, 3 tabs (Recents / Contacts / New). Contacts invokes
// CNContactPickerViewController via UIKit bridge; new-borrower tab is
// a small form that creates a Borrower record.

import SwiftUI
import SwiftData
import Contacts
import ContactsUI

public enum BorrowerPickerTab: Hashable, CaseIterable {
    case recents, contacts, new

    var label: String {
        switch self {
        case .recents: "Recents"
        case .contacts: "Contacts"
        case .new: "New"
        }
    }
}

struct BorrowerPicker: View {
    @Binding var isPresented: Bool
    let onSelect: (Borrower) -> Void

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \Borrower.updatedAt, order: .reverse)
    private var borrowers: [Borrower]

    @State private var tab: BorrowerPickerTab = .recents
    @State private var search: String = ""
    @State private var contactsPickerShown = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabsRow
                    .padding(.horizontal, Spacing.s16)
                    .padding(.bottom, Spacing.s8)

                if tab != .new {
                    searchRow
                        .padding(.horizontal, Spacing.s16)
                        .padding(.bottom, Spacing.s12)
                }

                Group {
                    switch tab {
                    case .recents:
                        recentsList
                    case .contacts:
                        contactsPrompt
                    case .new:
                        NewBorrowerForm { borrower in
                            modelContext.insert(borrower)
                            try? modelContext.save()
                            onSelect(borrower)
                            isPresented = false
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                bottomAction
            }
            .background(Palette.surface)
            .navigationTitle("Borrower")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New") { tab = .new }
                        .fontWeight(.semibold)
                        .foregroundStyle(Palette.accent)
                }
            }
            .sheet(isPresented: $contactsPickerShown) {
                ContactPickerSheet { contact in
                    let b = Borrower(
                        firstName: contact.givenName,
                        lastName: contact.familyName,
                        email: contact.emailAddresses.first.map { String($0.value as String) },
                        phone: contact.phoneNumbers.first.map { $0.value.stringValue },
                        source: .contacts,
                        contactIdentifier: contact.identifier
                    )
                    modelContext.insert(b)
                    try? modelContext.save()
                    onSelect(b)
                    isPresented = false
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: Tabs row

    private var tabsRow: some View {
        HStack(spacing: Spacing.s4) {
            ForEach(BorrowerPickerTab.allCases, id: \.self) { t in
                Button { tab = t } label: {
                    Text(t.label)
                        .textStyle(Typography.num.withSize(12, weight: t == tab ? .semibold : .medium))
                        .foregroundStyle(t == tab ? Palette.accentFG : Palette.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.s8)
                        .background(t == tab ? Palette.accent : Palette.surfaceSunken)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.segmented)
                                .stroke(t == tab ? Palette.accent : Palette.borderSubtle,
                                        lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Radius.segmented))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Search

    private var searchRow: some View {
        HStack(spacing: Spacing.s8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.inkTertiary)
            TextField("Search contacts or past borrowers", text: $search)
                .textStyle(Typography.body)
                .foregroundStyle(Palette.ink)
                .submitLabel(.search)
        }
        .padding(.horizontal, Spacing.s12)
        .padding(.vertical, 9)
        .background(Palette.surfaceSunken)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
    }

    // MARK: Recents list

    @ViewBuilder private var recentsList: some View {
        let matches = borrowers.filter { b in
            search.isEmpty || b.fullName.localizedCaseInsensitiveContains(search)
        }
        if matches.isEmpty {
            VStack(spacing: Spacing.s8) {
                Text("No borrowers yet.")
                    .textStyle(Typography.bodyLg)
                    .foregroundStyle(Palette.inkSecondary)
                Text("Add one from Contacts or create a new one.")
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.inkTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.s32)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(matches, id: \.id) { b in
                        borrowerRow(b)
                        HairlineDivider().padding(.leading, 62)
                    }
                }
                .background(Palette.surfaceRaised)
            }
        }
    }

    private func borrowerRow(_ b: Borrower) -> some View {
        Button {
            onSelect(b)
            isPresented = false
        } label: {
            HStack(spacing: Spacing.s12) {
                Circle()
                    .fill(Palette.surfaceSunken)
                    .overlay(Circle().stroke(Palette.borderSubtle, lineWidth: 1))
                    .overlay(
                        Text(b.initials)
                            .textStyle(Typography.num.withSize(12, weight: .semibold))
                            .foregroundStyle(Palette.inkSecondary)
                    )
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text(b.fullName)
                        .textStyle(Typography.bodyLg.withSize(14.5, weight: .medium))
                        .foregroundStyle(Palette.ink)
                    Text(b.email ?? (b.phone ?? "\(b.scenarios.count) scenarios"))
                        .textStyle(Typography.body.withSize(12))
                        .foregroundStyle(Palette.inkSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Contacts prompt

    private var contactsPrompt: some View {
        VStack(spacing: Spacing.s16) {
            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Palette.inkTertiary)
            Text("Pull from Contacts")
                .textStyle(Typography.h2)
                .foregroundStyle(Palette.ink)
            Text("Add borrowers from your iPhone contacts in one tap. NestIQ only reads the contact you pick.")
                .textStyle(Typography.body)
                .foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.s24)
            PrimaryButton("Choose a contact") {
                contactsPickerShown = true
            }
            .padding(.horizontal, Spacing.s32)
            .padding(.top, Spacing.s8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.s40)
    }

    // MARK: Bottom action

    private var bottomAction: some View {
        VStack {
            SecondaryButton("+ New borrower") { tab = .new }
                .padding(.horizontal, Spacing.s16)
                .padding(.top, Spacing.s12)
                .padding(.bottom, Spacing.s16)
        }
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Palette.borderSubtle).frame(height: 1),
                 alignment: .top)
    }
}

// MARK: - CNContactPickerViewController bridge

struct ContactPickerSheet: UIViewControllerRepresentable {
    let onPick: (CNContact) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let vc = CNContactPickerViewController()
        vc.delegate = context.coordinator
        vc.displayedPropertyKeys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
        ]
        return vc
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController,
                                context: Context) {}

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onPick: (CNContact) -> Void
        init(onPick: @escaping (CNContact) -> Void) { self.onPick = onPick }
        func contactPicker(_ picker: CNContactPickerViewController,
                           didSelect contact: CNContact) {
            onPick(contact)
        }
    }
}

// MARK: - New borrower form

struct NewBorrowerForm: View {
    let onCreate: (Borrower) -> Void

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var mortgageDraft = CurrentMortgageDraft()
    @State private var mortgageExpanded: Bool = false
    @State private var showMortgageValidation: Bool = false

    var body: some View {
        Form {
            Section("Name") {
                TextField("First name", text: $firstName)
                TextField("Last name", text: $lastName)
            }
            Section("Contact") {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
            }
            Section {
                CurrentMortgageSection(
                    draft: $mortgageDraft,
                    isExpanded: $mortgageExpanded,
                    showValidationHint: showMortgageValidation
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            Section {
                Button {
                    submit()
                } label: {
                    HStack {
                        Spacer()
                        Text("Create borrower").fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!isValid)
            }
        }
    }

    private var isValid: Bool {
        guard !firstName.isEmpty, !lastName.isEmpty else { return false }
        // Mortgage section: blank or fully valid. Partially filled is
        // rejected so the LO has to either commit to a current mortgage
        // or leave the section empty.
        return mortgageDraft.isBlank || mortgageDraft.isValid
    }

    private func submit() {
        guard !firstName.isEmpty, !lastName.isEmpty else { return }
        // If the draft is non-blank but invalid, surface the hint and
        // abort the submit so the LO can fix it.
        if !mortgageDraft.isBlank, !mortgageDraft.isValid {
            showMortgageValidation = true
            mortgageExpanded = true
            return
        }
        let b = Borrower(
            firstName: firstName,
            lastName: lastName,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            source: .manual
        )
        if let mortgage = mortgageDraft.toMortgage() {
            b.currentMortgage = mortgage
        }
        onCreate(b)
    }
}
