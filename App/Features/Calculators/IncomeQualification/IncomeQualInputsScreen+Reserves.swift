// IncomeQualInputsScreen+Reserves.swift
// Session 5P.4: the reserves-months selector moved from the Income
// Qualification Results screen to Inputs. LOs set the reserve
// requirement before compute so Results shows a settled number,
// not a post-hoc knob. Extracted to a separate file to keep the
// parent struct under SwiftLint's type_body_length cap.

import SwiftUI

extension IncomeQualInputsScreen {

    var reservesSection: some View {
        fieldGroup(header: "Reserves") {
            reservesRow
        }
    }

    private var reservesRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Months required")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("0-36 · conventional 0-6, jumbo / investor up to 24+")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
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
            Text(IncomeQualScreen.reservesLabel(for: viewModel.inputs.reservesMonths))
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 72, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }
}
