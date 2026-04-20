// TCAInputsScreen+DebtsAndLTV.swift
// Per-scenario helpers split off from TCAInputsScreen to keep the
// parent struct under SwiftLint's type_body_length cap:
//   - Property & DP (purchase) / loan-amount + LTV (refinance)
//   - Per-scenario "Debts remaining" rows (refinance mode)
//   - Form-level "Other debts · today" section (refinance mode)
//   - MI / loan-amount hints that read scenario state.

import SwiftUI
import QuotientFinance

extension TCAInputsScreen {

    // MARK: Per-scenario property / loan helpers

    func purchaseDPSection(index: Int) -> some View {
        PropertyDownPaymentSection(
            config: Binding(
                get: { viewModel.inputs.scenarios[index].propertyDP },
                set: { viewModel.inputs.scenarios[index].propertyDP = $0 }
            ),
            externalLoanAmount: viewModel.inputs.loanAmount,
            header: "Property & DP — scenario \(viewModel.inputs.scenarios[index].label)"
        )
    }

    func refiLoanSection(index: Int) -> some View {
        VStack(spacing: 0) {
            FieldRow(
                label: "Loan amount",
                prefix: "$",
                hint: loanHint(index: index),
                decimal: Binding(
                    get: { viewModel.inputs.scenarios[index].loanAmount },
                    set: { viewModel.inputs.scenarios[index].loanAmount = $0 }
                )
            )
            divider
            ltvRow(index: index)
        }
    }

    func loanHint(index: Int) -> String {
        viewModel.inputs.scenarios[index].loanAmount > 0
            ? "overrides default"
            : "leave 0 to use default"
    }

    func ltvRow(index: Int) -> some View {
        let lt = viewModel.inputs.ltv(for: viewModel.inputs.scenarios[index])
        let hv = viewModel.inputs.homeValue
        return HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("LTV")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text(hv > 0 ? "vs home value above" : "enter home value for live LTV")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Text(hv > 0 ? String(format: "%.1f%%", lt * 100) : "—")
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(lt > 0.80 ? Palette.warn : Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    func miHint(index: Int) -> String {
        let lt = viewModel.inputs.ltv(for: viewModel.inputs.scenarios[index])
        guard lt > 0 else { return "optional" }
        return lt > 0.80
            ? String(format: "LTV %.1f%% — MI typical", lt * 100)
            : String(format: "LTV %.1f%% — no MI typical", lt * 100)
    }

    // MARK: Other debts (refinance mode only)

    func scenarioDebtsRows(index: Int) -> some View {
        VStack(spacing: 0) {
            FieldRow(
                label: "Remaining debt balance",
                prefix: "$",
                hint: "after this option's cash-out consolidates some/all",
                decimal: Binding(
                    get: { viewModel.inputs.scenarios[index].otherDebts?.totalBalance ?? 0 },
                    set: { newValue in
                        let current = viewModel.inputs.scenarios[index].otherDebts ?? OtherDebts.zero()
                        let updated = OtherDebts(
                            totalBalance: newValue,
                            monthlyPayment: current.monthlyPayment
                        )
                        viewModel.inputs.scenarios[index].otherDebts =
                            updated.isZero ? nil : updated
                    }
                )
            )
            divider
            FieldRow(
                label: "Remaining debt monthly",
                prefix: "$",
                decimal: Binding(
                    get: { viewModel.inputs.scenarios[index].otherDebts?.monthlyPayment ?? 0 },
                    set: { newValue in
                        let current = viewModel.inputs.scenarios[index].otherDebts ?? OtherDebts.zero()
                        let updated = OtherDebts(
                            totalBalance: current.totalBalance,
                            monthlyPayment: newValue
                        )
                        viewModel.inputs.scenarios[index].otherDebts =
                            updated.isZero ? nil : updated
                    }
                )
            )
        }
    }

    var includeDebtsToggleSection: some View {
        HStack(spacing: Spacing.s12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Include consumer debts in analysis")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("off → winner uses PITI only · on → PITI + remaining debt monthly")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { viewModel.inputs.includeDebts },
                set: { viewModel.inputs.includeDebts = $0 }
            ))
            .labelsHidden()
            .tint(Palette.accent)
            .accessibilityIdentifier("tca.includeDebts")
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

    var currentDebtsSection: some View {
        fieldGroup(header: "Other debts · today") {
            FieldRow(
                label: "Total balance",
                prefix: "$",
                hint: "aggregate across cards, auto, student, etc.",
                decimal: Binding(
                    get: { viewModel.inputs.currentOtherDebts?.totalBalance ?? 0 },
                    set: { newValue in
                        let current = viewModel.inputs.currentOtherDebts ?? OtherDebts.zero()
                        let updated = OtherDebts(
                            totalBalance: newValue,
                            monthlyPayment: current.monthlyPayment
                        )
                        viewModel.inputs.currentOtherDebts = updated.isZero ? nil : updated
                    }
                )
            )
            divider
            FieldRow(
                label: "Monthly payment",
                prefix: "$",
                hint: "combined minimum monthly across those debts",
                decimal: Binding(
                    get: { viewModel.inputs.currentOtherDebts?.monthlyPayment ?? 0 },
                    set: { newValue in
                        let current = viewModel.inputs.currentOtherDebts ?? OtherDebts.zero()
                        let updated = OtherDebts(
                            totalBalance: current.totalBalance,
                            monthlyPayment: newValue
                        )
                        viewModel.inputs.currentOtherDebts = updated.isZero ? nil : updated
                    }
                )
            )
        }
    }

    // MARK: - 5M.8 Reinvestment rate

    /// Single FieldRow driving `TCAFormInputs.reinvestmentRate`. The
    /// reinvestment-strategy section on Results (and the PDF summary)
    /// use this value as the annualized return on invested savings.
    var reinvestmentRateSection: some View {
        fieldGroup(header: "Reinvestment assumption") {
            FieldRow(
                label: "Return rate",
                suffix: "%",
                hint: "Annualized — for 'Invest the savings' path",
                decimal: Binding(
                    get: { viewModel.inputs.reinvestmentRate * 100 },
                    set: { viewModel.inputs.reinvestmentRate = $0 / 100 }
                ),
                fractionDigits: 2
            )
        }
    }
}
