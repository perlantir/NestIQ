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
                Text("Reserves: \(months) \(months == 1 ? "month" : "months")")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("0-12 · conventional loans typically 0-6")
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
                set: { viewModel.inputs.reservesMonths = max(0, min($0, 12)) }
            ),
            in: 0...12,
            step: 1
        ) {
            EmptyView()
        }
        .labelsHidden()
        .accessibilityIdentifier("incomeQual.reservesStepper")
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
