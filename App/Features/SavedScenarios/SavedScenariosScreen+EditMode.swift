// SavedScenariosScreen+EditMode.swift
// Session 5F.2: Edit-mode toolbar button, multi-select dock, selection
// helpers, and delete commit. Lives in an extension to keep the parent
// struct under SwiftLint's type_body_length cap — same pattern TCA uses.

import SwiftUI
import SwiftData

extension SavedScenariosScreen {

    /// Either a single scenario (swipe-to-delete path) or a set
    /// (multi-select-Edit-mode path). Presented via `.alert(item:)` so
    /// the destructive confirmation is unambiguous regardless of entry
    /// point.
    struct PendingDelete: Identifiable {
        let scenarios: [Scenario]
        var id: String { scenarios.map { $0.id.uuidString }.joined(separator: ",") }
        var count: Int { scenarios.count }
    }

    @ViewBuilder var editToolbarButton: some View {
        if isEditMode {
            Button("Cancel") { exitEditMode() }
                .accessibilityIdentifier("saved.editCancel")
        } else {
            Button("Edit") { enterEditMode() }
                .disabled(scenarios.isEmpty)
                .accessibilityIdentifier("saved.edit")
        }
    }

    var editModeDock: some View {
        HStack(spacing: Spacing.s12) {
            Text(selectedIDs.isEmpty
                 ? "Select scenarios to delete"
                 : "\(selectedIDs.count) selected")
                .textStyle(Typography.body.withWeight(.medium))
                .foregroundStyle(Palette.inkSecondary)
            Spacer()
            Button {
                guard !selectedIDs.isEmpty else { return }
                let toDelete = filteredScenarios.filter { selectedIDs.contains($0.id) }
                pendingDelete = PendingDelete(scenarios: toDelete)
            } label: {
                Text("Delete (\(selectedIDs.count))")
                    .textStyle(Typography.bodyLg.withWeight(.semibold))
                    .foregroundStyle(selectedIDs.isEmpty ? Palette.inkTertiary : .white)
                    .padding(.horizontal, Spacing.s16)
                    .padding(.vertical, Spacing.s8)
                    .background(selectedIDs.isEmpty ? Palette.surfaceSunken : Palette.loss)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
            }
            .buttonStyle(.plain)
            .disabled(selectedIDs.isEmpty)
            .accessibilityIdentifier("saved.deleteSelected")
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.top, Spacing.s12)
        .padding(.bottom, Spacing.s32)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle().fill(Palette.borderSubtle).frame(height: 1),
            alignment: .top
        )
    }

    func enterEditMode() {
        isEditMode = true
        selectedIDs = []
    }

    func exitEditMode() {
        isEditMode = false
        selectedIDs = []
    }

    func selectAll() {
        selectedIDs = Set(filteredScenarios.map { $0.id })
    }

    func toggle(scenario: Scenario) {
        if selectedIDs.contains(scenario.id) {
            selectedIDs.remove(scenario.id)
        } else {
            selectedIDs.insert(scenario.id)
        }
    }

    func commitDelete(_ scenarios: [Scenario]) {
        for s in scenarios {
            modelContext.delete(s)
        }
        try? modelContext.save()
        let removed = Set(scenarios.map { $0.id })
        selectedIDs.subtract(removed)
        if isEditMode, selectedIDs.isEmpty {
            exitEditMode()
        }
    }
}
