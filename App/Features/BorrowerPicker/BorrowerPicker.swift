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
    // Session 5Q.2: swipe-action state for the Recents list.
    @State private var editingBorrower: Borrower?
    @State private var borrowerToDelete: Borrower?
    @State private var showDeleteToast: Bool = false

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
                        BorrowerForm(mode: .create) { borrower in
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
            .navigationDestination(item: $editingBorrower) { borrower in
                BorrowerForm(
                    mode: .edit(borrower),
                    onSubmit: { _ in
                        try? modelContext.save()
                        editingBorrower = nil
                    },
                    onDelete: {
                        modelContext.delete(borrower)
                        try? modelContext.save()
                        editingBorrower = nil
                        withAnimation { showDeleteToast = true }
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation { showDeleteToast = false }
                        }
                    }
                )
                .navigationTitle("Edit borrower")
                .navigationBarTitleDisplayMode(.inline)
            }
            .alert(
                "Delete borrower?",
                isPresented: Binding(
                    get: { borrowerToDelete != nil },
                    set: { if !$0 { borrowerToDelete = nil } }
                ),
                presenting: borrowerToDelete
            ) { borrower in
                Button("Delete", role: .destructive) {
                    deleteBorrower(borrower)
                }
                Button("Cancel", role: .cancel) {
                    borrowerToDelete = nil
                }
            } message: { borrower in
                Text("\(borrower.fullName) will be removed from your list. Saved scenarios for this borrower remain intact.")
            }
            .overlay(alignment: .top) { deleteToast }
        }
    }

    private func deleteBorrower(_ borrower: Borrower) {
        modelContext.delete(borrower)
        try? modelContext.save()
        borrowerToDelete = nil
        withAnimation { showDeleteToast = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showDeleteToast = false }
        }
    }

    @ViewBuilder private var deleteToast: some View {
        if showDeleteToast {
            Text("Borrower deleted")
                .textStyle(Typography.body.withSize(13, weight: .medium))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, Spacing.s16)
                .padding(.vertical, Spacing.s12)
                .background(.ultraThinMaterial)
                .overlay(
                    Capsule().stroke(Palette.borderSubtle, lineWidth: 1)
                )
                .clipShape(Capsule())
                .padding(.top, Spacing.s8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityIdentifier("borrowerPicker.deleteToast")
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
            // Session 5Q.2: List (not LazyVStack) so `.swipeActions`
            // picks up the standard iOS left/right swipe affordances.
            // `.plain` list style + per-row background + hidden
            // separator keeps the existing visual — grouped card
            // surface + custom hairline between rows — while the
            // underlying infrastructure is now a native List.
            List {
                ForEach(matches, id: \.id) { b in
                    borrowerRow(b)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Palette.surfaceRaised)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                editingBorrower = b
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Palette.accent)
                            .accessibilityIdentifier("borrowerRow.edit")
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                borrowerToDelete = b
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .accessibilityIdentifier("borrowerRow.delete")
                        }
                    HairlineDivider()
                        .padding(.leading, 62)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Palette.surfaceRaised)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Palette.surfaceRaised)
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

// Session 5Q.1 — NewBorrowerForm absorbed into BorrowerForm (sibling
// file), which also handles the edit / delete paths the borrower list
// needs. `BorrowerForm(mode: .create, onSubmit:)` is the drop-in
// replacement for the old struct.
