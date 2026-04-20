// TCAInputsScreen+CurrentMortgage.swift
// Session 5P.8 — Current Mortgage section on the TCA Inputs screen
// (refinance mode only). Hydrated from the selected borrower's
// currentMortgage when present; otherwise the LO fills inline. The
// draft synchronously flows into viewModel.inputs.currentMortgage,
// which becomes the break-even baseline (5P.9) and the "Current"
// column anchor on Results (5P.10 / 5P.11).
//
// Session 5Q.3 — adds an optional "Save to borrower profile" toggle
// below the section. When ON and a borrower is attached, the Compute
// CTA writes `viewModel.inputs.currentMortgage` back onto the
// borrower so the next session with the same borrower is pre-filled.
// OFF → values stay local to the scenario snapshot. No borrower →
// toggle is disabled with a hint. TCA refi is the only surface that
// gets this toggle in 5Q because it's the only refi calculator that
// captures the full 7-field `CurrentMortgage` shape; Refinance
// Comparison + HELOC vs Refi continue one-way prefill from the
// borrower (5P.12 / 5P.13) without a reverse save path.

import SwiftUI
import SwiftData
import QuotientFinance

extension TCAInputsScreen {

    var currentMortgageSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Current mortgage")
            CurrentMortgageSection(
                draft: Binding(
                    get: { currentMortgageDraft },
                    set: { newValue in
                        currentMortgageDraft = newValue
                        applyDraftToInputs(newValue)
                    }
                ),
                isExpanded: Binding(
                    get: { currentMortgageExpanded },
                    set: { currentMortgageExpanded = $0 }
                ),
                showValidationHint: true
            )
            saveToBorrowerToggle
        }
    }

    @ViewBuilder private var saveToBorrowerToggle: some View {
        let borrowerAttached = selectedBorrower != nil
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: Binding(
                get: { saveToBorrowerOnCompute && borrowerAttached },
                set: { saveToBorrowerOnCompute = $0 }
            )) {
                Text("Save to borrower profile")
                    .textStyle(Typography.bodyLg.withSize(13, weight: .medium))
                    .foregroundStyle(borrowerAttached ? Palette.ink : Palette.inkTertiary)
            }
            .toggleStyle(.switch)
            .disabled(!borrowerAttached)
            .accessibilityIdentifier("tca.currentMortgage.saveToBorrower")

            Text(saveToBorrowerHint(borrowerAttached: borrowerAttached))
                .textStyle(Typography.body.withSize(11))
                .foregroundStyle(Palette.inkTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
    }

    private func saveToBorrowerHint(borrowerAttached: Bool) -> String {
        guard borrowerAttached else {
            return "Select a borrower to enable."
        }
        let name = selectedBorrower?.firstName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let name, !name.isEmpty {
            return "Next time you work with \(name), these details will be pre-filled."
        }
        return "Next time you work with this borrower, these details will be pre-filled."
    }

    /// Populate the draft from the selected borrower's currentMortgage
    /// (first pull) or from a loaded scenario's snapshot (when the
    /// Inputs screen opens with an existingScenario whose JSON carries
    /// a currentMortgage). If both are absent, the draft stays blank.
    func hydrateCurrentMortgageDraft() {
        if let snapshot = viewModel.inputs.currentMortgage {
            currentMortgageDraft = CurrentMortgageDraft(from: snapshot)
            currentMortgageExpanded = true
            return
        }
        if let borrowerMortgage = selectedBorrower?.currentMortgage {
            currentMortgageDraft = CurrentMortgageDraft(from: borrowerMortgage)
            viewModel.inputs.currentMortgage = borrowerMortgage
            currentMortgageExpanded = true
        }
    }

    /// Write the draft into viewModel.inputs.currentMortgage only when
    /// it's either fully valid (commit) or fully blank (clear). Partial
    /// drafts hold in the local @State without corrupting the inputs
    /// snapshot — break-even math falls back to the legacy
    /// scenario-vs-scenario baseline while the LO is mid-edit.
    func applyDraftToInputs(_ draft: CurrentMortgageDraft) {
        if draft.isBlank {
            viewModel.inputs.currentMortgage = nil
        } else if let mortgage = draft.toMortgage() {
            viewModel.inputs.currentMortgage = mortgage
        }
    }

    /// Session 5Q.3 — called from the Compute CTA. Commits the
    /// inputs' currentMortgage snapshot back onto the attached
    /// borrower so the next session pre-fills from it. No-op when
    /// the toggle is off, no borrower is attached, or the inputs
    /// have no mortgage to save (purchase mode / blank refi draft).
    func persistCurrentMortgageToBorrowerIfNeeded() {
        _ = TCACurrentMortgagePersistence.persist(
            mortgage: viewModel.inputs.currentMortgage,
            to: selectedBorrower,
            saveToBorrower: saveToBorrowerOnCompute,
            context: modelContext
        )
    }
}

/// Pure helper so the save-back semantics are unit-testable without
/// spinning up the TCAInputsScreen SwiftUI view. Returns `true` when
/// it actually wrote to the borrower.
@MainActor
enum TCACurrentMortgagePersistence {
    @discardableResult
    static func persist(
        mortgage: CurrentMortgage?,
        to borrower: Borrower?,
        saveToBorrower: Bool,
        context: ModelContext
    ) -> Bool {
        guard saveToBorrower,
              let borrower,
              let mortgage else { return false }
        borrower.currentMortgage = mortgage
        borrower.updatedAt = Date()
        try? context.save()
        return true
    }
}
