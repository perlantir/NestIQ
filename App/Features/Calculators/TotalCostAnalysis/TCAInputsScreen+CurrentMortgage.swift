// TCAInputsScreen+CurrentMortgage.swift
// Session 5P.8 — Current Mortgage section on the TCA Inputs screen
// (refinance mode only). Hydrated from the selected borrower's
// currentMortgage when present; otherwise the LO fills inline. The
// draft synchronously flows into viewModel.inputs.currentMortgage,
// which becomes the break-even baseline (5P.9) and the "Current"
// column anchor on Results (5P.10 / 5P.11).

import SwiftUI
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
        }
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
}
