// IncomeQualInputsScreen+SelfEmployment.swift
// Session 5G.6: pill + hint + import handler wiring the Self-Employment
// calculator into the Income Qualification inputs flow. Extracted to
// keep the parent struct under SwiftLint's type_body_length cap.

import SwiftUI
import QuotientFinance

extension IncomeQualInputsScreen {

    var primaryIncomeHint: String {
        let first = viewModel.inputs.incomes.first
        if first?.kind == .selfEmployed,
           first?.label.contains("Self-employment") == true {
            return "imported from Self-Employment analysis"
        }
        return "W-2 gross · base + overtime + bonus"
    }

    /// Small link under the income FieldRow that opens the Self-Employment
    /// calculator as a sheet. The sheet's "Use this income" button feeds
    /// the qualifying monthly back here via onImportMonthly.
    var selfEmploymentImportPill: some View {
        Button {
            showingSelfEmployment = true
        } label: {
            HStack(spacing: Spacing.s4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 11, weight: .medium))
                Text("or use Self-Employment analysis")
                    .textStyle(Typography.num.withSize(12, weight: .medium))
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, Spacing.s12)
            .padding(.vertical, 6)
            .overlay(
                Capsule()
                    .stroke(Palette.accent.opacity(0.4), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("incomeQual.openSelfEmployment")
    }

    /// Called when the SE sheet's Results dock taps "Use this income".
    /// Replaces the primary income with a Self-Employment-sourced one
    /// and relabels it so the UI can show the provenance.
    func importSelfEmploymentIncome(_ monthly: Decimal) {
        let imported = IncomeSource(
            label: "Self-employment analysis",
            monthlyAmount: monthly,
            weightPercent: 1.0,
            kind: .selfEmployed
        )
        if viewModel.inputs.incomes.isEmpty {
            viewModel.inputs.incomes = [imported]
        } else {
            viewModel.inputs.incomes[0] = imported
        }
    }
}
