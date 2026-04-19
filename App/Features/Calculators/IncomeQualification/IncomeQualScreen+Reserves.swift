// IncomeQualScreen+Reserves.swift
// Session 5F.6: reserves-months stepper + live $ readout, hosted on the
// Income Qualification Results view. Extracted from IncomeQualScreen so
// the parent struct stays under SwiftLint's type_body_length cap.

import SwiftUI

extension IncomeQualScreen {

    var reservesSection: some View {
        let months = viewModel.inputs.reservesMonths
        let reservesTotal = viewModel.maxPITI * Decimal(months)
        return VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Reserves required")
            reservesCard(months: months)
            reservesTotalLine(months: months, total: reservesTotal)
                .padding(.top, Spacing.s4)
        }
    }

    private func reservesCard(months: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Reserves: \(Self.reservesLabel(for: months))")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("0-36 · conventional 0-6, jumbo / investor up to 24+")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            reservesStepper
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

    private var reservesStepper: some View {
        Stepper(
            value: Binding(
                get: { viewModel.inputs.reservesMonths },
                set: { viewModel.inputs.reservesMonths = max(0, min($0, 36)) }
            ),
            in: 0...36,
            step: 1
        ) {
            EmptyView()
        }
        .labelsHidden()
        .accessibilityIdentifier("incomeQual.reservesStepper")
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

    private func reservesTotalLine(months: Int, total: Decimal) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s4) {
            Text("Reserves:")
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.inkTertiary)
            Text("$\(MoneyFormat.shared.decimalString(total))")
                .textStyle(Typography.num.withSize(13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.ink)
            Text("(\(months) × PITI)")
                .textStyle(Typography.num.withSize(11))
                .foregroundStyle(Palette.inkTertiary)
        }
    }
}
