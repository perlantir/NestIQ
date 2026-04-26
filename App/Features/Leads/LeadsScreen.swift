// LeadsScreen.swift
// 4th root tab — flat list of every saved Borrower (name, email, phone).
// Backed by the same SwiftData store as BorrowerPicker, so creates from
// any calculator flow land here and edits / deletes made here propagate
// to every picker instance.

import SwiftUI
import SwiftData

struct LeadsScreen: View {
    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \Borrower.updatedAt, order: .reverse)
    private var borrowers: [Borrower]

    @State private var creatingBorrower: Bool = false
    @State private var editingBorrower: Borrower?
    @State private var borrowerToDelete: Borrower?
    @State private var showDeleteToast: Bool = false
    @State private var search: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if borrowers.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Palette.surface)
            .navigationTitle("Leads")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        creatingBorrower = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .tint(Palette.accent)
                    .accessibilityIdentifier("leads.new")
                }
            }
            .sheet(isPresented: $creatingBorrower) {
                NavigationStack {
                    BorrowerForm(mode: .create) { borrower in
                        modelContext.insert(borrower)
                        try? modelContext.save()
                        creatingBorrower = false
                    }
                    .navigationTitle("New lead")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { creatingBorrower = false }
                        }
                    }
                }
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
                        flashDeleteToast()
                    }
                )
                .navigationTitle("Edit lead")
                .navigationBarTitleDisplayMode(.inline)
            }
            .alert(
                "Delete lead?",
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
                Text("\(borrower.fullName) will be removed. Saved scenarios remain intact.")
            }
            .overlay(alignment: .top) { deleteToast }
        }
    }

    // MARK: List

    private var matches: [Borrower] {
        guard !search.isEmpty else { return borrowers }
        return borrowers.filter { b in
            b.fullName.localizedCaseInsensitiveContains(search)
                || (b.email ?? "").localizedCaseInsensitiveContains(search)
                || (b.phone ?? "").localizedCaseInsensitiveContains(search)
        }
    }

    @ViewBuilder private var list: some View {
        List {
            ForEach(matches, id: \.id) { b in
                leadRow(b)
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
                        .accessibilityIdentifier("leadRow.edit")
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            borrowerToDelete = b
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .accessibilityIdentifier("leadRow.delete")
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
        .background(Palette.surface)
        .searchable(text: $search, prompt: "Search leads")
    }

    private func leadRow(_ b: Borrower) -> some View {
        Button {
            editingBorrower = b
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(b.fullName)
                        .textStyle(Typography.bodyLg.withSize(14.5, weight: .medium))
                        .foregroundStyle(Palette.ink)
                    if let email = b.email, !email.isEmpty {
                        Text(email)
                            .textStyle(Typography.body.withSize(12))
                            .foregroundStyle(Palette.inkSecondary)
                    }
                    if let phone = b.phone, !phone.isEmpty {
                        Text(phone)
                            .textStyle(Typography.num.withSize(12))
                            .foregroundStyle(Palette.inkTertiary)
                    }
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

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.s12) {
            Image(systemName: "person.2")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Palette.inkTertiary)
            Text("No leads yet")
                .textStyle(Typography.h2)
                .foregroundStyle(Palette.ink)
            Text("Add a lead from Contacts or create one manually. Leads created here are available in every calculator's borrower picker.")
                .textStyle(Typography.body)
                .foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.s40)
            PrimaryButton("+ New lead") {
                creatingBorrower = true
            }
            .padding(.horizontal, Spacing.s32)
            .padding(.top, Spacing.s8)
            .accessibilityIdentifier("leads.emptyNew")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.s32)
    }

    // MARK: Delete

    private func deleteBorrower(_ borrower: Borrower) {
        modelContext.delete(borrower)
        try? modelContext.save()
        borrowerToDelete = nil
        flashDeleteToast()
    }

    private func flashDeleteToast() {
        withAnimation { showDeleteToast = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showDeleteToast = false }
        }
    }

    @ViewBuilder private var deleteToast: some View {
        if showDeleteToast {
            Text("Lead deleted")
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
                .accessibilityIdentifier("leads.deleteToast")
        }
    }
}
