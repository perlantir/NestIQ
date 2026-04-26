// BorrowerForm.swift
// Session 5Q.1: unified create + edit form. Replaces NewBorrowerForm
// (5P.7) which only supported creation. Mode parameter controls
// pre-population, submit-button label, and whether the delete button
// appears. Callers inject the persistence closures so the form stays
// free of SwiftData dependencies.

import SwiftUI

struct BorrowerForm: View {
    enum Mode {
        case create
        case edit(Borrower)
    }

    let mode: Mode
    let onSubmit: (Borrower) -> Void
    let onDelete: () -> Void

    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var mortgageDraft: CurrentMortgageDraft
    @State private var mortgageExpanded: Bool
    @State private var confirmingDelete: Bool = false

    init(
        mode: Mode,
        onSubmit: @escaping (Borrower) -> Void,
        onDelete: @escaping () -> Void = {}
    ) {
        self.mode = mode
        self.onSubmit = onSubmit
        self.onDelete = onDelete
        switch mode {
        case .create:
            _firstName = State(initialValue: "")
            _lastName = State(initialValue: "")
            _email = State(initialValue: "")
            _phone = State(initialValue: "")
            _mortgageDraft = State(initialValue: CurrentMortgageDraft())
            _mortgageExpanded = State(initialValue: false)
        case .edit(let borrower):
            _firstName = State(initialValue: borrower.firstName)
            _lastName = State(initialValue: borrower.lastName)
            _email = State(initialValue: borrower.email ?? "")
            _phone = State(initialValue: borrower.phone ?? "")
            if let mortgage = borrower.currentMortgage {
                _mortgageDraft = State(initialValue: CurrentMortgageDraft(from: mortgage))
                _mortgageExpanded = State(initialValue: true)
            } else {
                _mortgageDraft = State(initialValue: CurrentMortgageDraft())
                _mortgageExpanded = State(initialValue: false)
            }
        }
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var submitLabel: String {
        switch mode {
        case .create: "Create borrower"
        case .edit: "Save changes"
        }
    }

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
                    isExpanded: $mortgageExpanded
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
                        Text(submitLabel).fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!isValid)
                .accessibilityIdentifier("borrowerForm.submit")
            }
            if isEditMode {
                Section {
                    Button(role: .destructive) {
                        confirmingDelete = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete borrower").fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .accessibilityIdentifier("borrowerForm.delete")
                }
            }
        }
        .alert("Delete borrower?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Saved scenarios for this borrower remain intact, but the borrower record will be removed from your list.")
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneToolbar()
    }

    private var isValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty
    }

    private func submit() {
        guard !firstName.isEmpty, !lastName.isEmpty else { return }
        // Persist whatever the LO typed, valid or partial, so mid-entry
        // work isn't lost on Save. Refi calculators gate on
        // `CurrentMortgage.isValid` when they read this back, so partial
        // data stays out of the math.
        let mortgageToSave = mortgageDraft.toMortgageUnchecked()
        switch mode {
        case .create:
            let borrower = Borrower(
                firstName: firstName,
                lastName: lastName,
                email: email.isEmpty ? nil : email,
                phone: phone.isEmpty ? nil : phone,
                source: .manual
            )
            borrower.currentMortgage = mortgageToSave
            onSubmit(borrower)
        case .edit(let borrower):
            borrower.firstName = firstName
            borrower.lastName = lastName
            borrower.email = email.isEmpty ? nil : email
            borrower.phone = phone.isEmpty ? nil : phone
            borrower.currentMortgage = mortgageToSave
            borrower.updatedAt = Date()
            onSubmit(borrower)
        }
    }
}
