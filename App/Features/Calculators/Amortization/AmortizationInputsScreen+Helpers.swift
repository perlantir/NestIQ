// AmortizationInputsScreen+Helpers.swift
// Shared field-group / divider helpers plus the purchase-mode
// Value → Rate → APR → Term → Biweekly → Down payment → Loan amount
// (derived) flow. Split off from AmortizationInputsScreen to keep the
// parent struct under SwiftLint's type_body_length cap.
// Same pattern already used by RefinanceInputsScreen and TCAInputsScreen.

import SwiftUI

extension AmortizationInputsScreen {
    @ViewBuilder
    func fieldGroup<Content: View>(
        header: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(header)
                .padding(.horizontal, Spacing.s20)
                .padding(.bottom, Spacing.s8)
            VStack(spacing: 0) { content() }
                .background(Palette.surfaceRaised)
                .overlay(
                    VStack(spacing: 0) {
                        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                        Spacer()
                        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                    }
                )
        }
    }

    var divider: some View {
        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
    }

    // MARK: Purchase / existing loan sections

    var purchaseLoanSection: some View {
        fieldGroup(header: "Loan") {
            FieldRow(
                label: "Value",
                prefix: "$",
                hint: "home purchase price",
                decimal: Binding(
                    get: { viewModel.inputs.propertyDP.purchasePrice },
                    set: { newValue in
                        viewModel.inputs.propertyDP.purchasePrice = newValue
                        viewModel.inputs.loanAmount =
                            viewModel.inputs.propertyDP.derivedLoanAmount
                    }
                )
            )
            divider
            FieldRow(
                label: "Interest rate",
                suffix: "%",
                decimal: Binding(
                    get: { Decimal(viewModel.inputs.annualRate) },
                    set: { viewModel.inputs.annualRate = Double(truncating: $0 as NSNumber) }
                ),
                fractionDigits: 3
            )
            divider
            APRFieldRow(aprRate: $viewModel.inputs.aprRate)
            divider
            termRow
            divider
            biweeklyRow
            divider
            downPaymentRows
            divider
            derivedLoanAmountRow
            divider
            startDateRow
        }
    }

    var existingLoanSection: some View {
        fieldGroup(header: "Loan") {
            FieldRow(
                label: "Loan amount",
                prefix: "$",
                decimal: Binding(
                    get: { viewModel.inputs.loanAmount },
                    set: { viewModel.inputs.loanAmount = $0 }
                )
            )
            divider
            FieldRow(
                label: "Interest rate",
                suffix: "%",
                decimal: Binding(
                    get: { Decimal(viewModel.inputs.annualRate) },
                    set: { viewModel.inputs.annualRate = Double(truncating: $0 as NSNumber) }
                ),
                fractionDigits: 3
            )
            divider
            APRFieldRow(aprRate: $viewModel.inputs.aprRate)
            divider
            termRow
            divider
            biweeklyRow
            divider
            startDateRow
        }
    }

    // MARK: Down payment (purchase)

    @ViewBuilder var downPaymentRows: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.s12) {
                Text("Down payment")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Picker("", selection: Binding(
                    get: { viewModel.inputs.propertyDP.useDownPaymentDollar },
                    set: { newValue in
                        viewModel.inputs.propertyDP.useDownPaymentDollar = newValue
                        viewModel.inputs.loanAmount =
                            viewModel.inputs.propertyDP.derivedLoanAmount
                    }
                )) {
                    Text("%").tag(false)
                    Text("$").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 84)
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
            divider
            downPaymentAmountRow
        }
    }

    @ViewBuilder var downPaymentAmountRow: some View {
        if viewModel.inputs.propertyDP.useDownPaymentDollar {
            FieldRow(
                label: "Amount",
                prefix: "$",
                hint: dpPercentHint,
                decimal: Binding(
                    get: { viewModel.inputs.propertyDP.downPaymentDollar },
                    set: { newValue in
                        viewModel.inputs.propertyDP.downPaymentDollar = newValue
                        viewModel.inputs.loanAmount =
                            viewModel.inputs.propertyDP.derivedLoanAmount
                    }
                )
            )
        } else {
            dpPercentStepperRow
        }
    }

    var dpPercentHint: String {
        guard viewModel.inputs.propertyDP.purchasePrice > 0 else { return "" }
        return String(
            format: "%.1f%% of price",
            viewModel.inputs.propertyDP.downPaymentPct * 100
        )
    }

    var dpPercentStepperRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Amount")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("$\(MoneyFormat.shared.decimalString(viewModel.inputs.propertyDP.downPaymentAmount)) at current price")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Stepper(
                value: Binding(
                    get: { Int((viewModel.inputs.propertyDP.downPaymentPercent * 100).rounded()) },
                    set: { newValue in
                        viewModel.inputs.propertyDP.downPaymentPercent = Double(newValue) / 100
                        viewModel.inputs.loanAmount =
                            viewModel.inputs.propertyDP.derivedLoanAmount
                    }
                ),
                in: 0...80,
                step: 1
            ) { EmptyView() }
                .labelsHidden()
            Text(String(format: "%d%%",
                        Int((viewModel.inputs.propertyDP.downPaymentPercent * 100).rounded())))
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 52, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    var derivedLoanAmountRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Loan amount")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("value − down payment")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Text("$\(MoneyFormat.shared.decimalString(viewModel.inputs.propertyDP.derivedLoanAmount))")
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    // MARK: Borrower mortgage prefill (existing-loan mode)

    /// Pull individual fields off the selected borrower's currentMortgage
    /// into the existing-loan form. Only populates fields the LO hasn't
    /// already typed (source field == 0). Skipped in purchase mode —
    /// purchase scenarios don't reference the borrower's existing loan.
    /// Term / start date are only synced from a fully-valid mortgage
    /// since those fields carry non-zero defaults in a partial draft
    /// and we can't tell "user typed" from "still default".
    func applyBorrowerCurrentMortgage(_ borrower: Borrower?, force: Bool = false) {
        guard viewModel.inputs.mode == .existingLoan else { return }
        guard let mortgage = borrower?.currentMortgage else { return }
        // `force` fires on an explicit picker-driven selection — user
        // wants this borrower's data, so we overwrite sampleDefault
        // seed values. Without force (onAppear / mode-flip hydration),
        // the `== 0` guard preserves existing input.
        if mortgage.currentBalance > 0,
           force || viewModel.inputs.loanAmount == 0 {
            viewModel.inputs.loanAmount = mortgage.currentBalance
        }
        if mortgage.currentRatePercent > 0,
           force || viewModel.inputs.annualRate == 0 {
            viewModel.inputs.annualRate =
                Double(truncating: mortgage.currentRatePercent as NSNumber)
        }
        if mortgage.isValid {
            viewModel.inputs.termYears = mortgage.originalTermYears
            viewModel.inputs.startDate = mortgage.loanStartDate
        }
    }

    // MARK: Seeding

    /// When a legacy scenario (or the sample default) comes in with a
    /// loanAmount but no purchase price, back-compute a price at the
    /// current DP % so the new Value-first purchase flow renders
    /// consistent numbers on open. Skipped in existingLoan mode.
    func seedPurchasePriceIfNeeded() {
        guard viewModel.inputs.mode == .purchase else { return }
        guard viewModel.inputs.propertyDP.purchasePrice == 0 else { return }
        guard viewModel.inputs.loanAmount > 0 else { return }
        let pct = max(0.0, min(0.95, viewModel.inputs.propertyDP.downPaymentPercent))
        let retained = 1 - pct
        guard retained > 0 else { return }
        viewModel.inputs.propertyDP.purchasePrice =
            viewModel.inputs.loanAmount / Decimal(retained)
    }
}
