// IncomeQualScreen+Reserves.swift
// Session 5F.6: reserves-months stepper originally lived on the Income
// Qualification Results view.
// Session 5P.4: the stepper moved to the Inputs screen — LOs set the
// reserve requirement before compute. This extension now renders a
// read-only summary card on Results showing the selected value and
// dollar total so the LO still sees "what was chosen" without a knob
// that changes results after the fact.

import SwiftUI

extension IncomeQualScreen {

    var reservesSection: some View {
        let months = viewModel.inputs.reservesMonths
        let reservesTotal = viewModel.maxPITI * Decimal(months)
        return VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Reserves required")
            reservesSummaryCard(months: months, total: reservesTotal)
        }
    }

    private func reservesSummaryCard(months: Int, total: Decimal) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Reserves: \(Self.reservesLabel(for: months))")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("Adjust on the previous screen.")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(MoneyFormat.shared.decimalString(total))")
                    .textStyle(Typography.num.withSize(15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.ink)
                Text("\(months) × PITI")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
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

    /// Month-count label with year collapsing at the 12 / 24 / 36 pivots.
    /// Any other count renders in months so LOs can read the exact value.
    static func reservesLabel(for months: Int) -> String {
        switch months {
        case 12: return "1 year"
        case 24: return "2 years"
        case 36: return "3 years"
        case 1:  return "1 month"
        default: return "\(months) months"
        }
    }
}
