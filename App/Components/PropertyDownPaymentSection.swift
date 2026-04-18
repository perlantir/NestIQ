// PropertyDownPaymentSection.swift
// Reusable Inputs-screen section: purchase price, down-payment
// toggle (% vs $), live LTV readout, conditional MI field + 80%
// removal toggle. Drives a bound `PropertyDownPaymentConfig`.
//
// Scope per Session 5B.5: this section is additive to the existing
// loan-amount fields each calculator already carries. The loan
// amount passed in as `externalLoanAmount` is used for the LTV
// readout so the LO sees a coherent % against whatever number their
// existing inputs derive. Removing the hardcoded loan-amount entry
// and routing everything through `config.derivedLoanAmount` is a
// follow-up cleanup.

import SwiftUI

struct PropertyDownPaymentSection: View {
    @Binding var config: PropertyDownPaymentConfig
    /// Loan amount from the host calculator's existing fields — shown
    /// in the LTV readout so the numbers line up with the rest of the
    /// form while the hardcoded loan-amount entry still coexists.
    let externalLoanAmount: Decimal
    var header: String = "Property & down payment"

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(header)
                .padding(.horizontal, Spacing.s20)
                .padding(.bottom, Spacing.s8)
            VStack(spacing: 0) {
                FieldRow(
                    label: "Purchase price",
                    prefix: "$",
                    decimal: $config.purchasePrice
                )
                divider
                modeToggleRow
                divider
                dpAmountRow
                divider
                ltvRow
                if config.miRequired(loanAmount: activeLoanAmount) {
                    divider
                    miFieldsGroup
                        .transition(reveal)
                }
            }
            .background(Palette.surfaceRaised)
            .overlay(
                VStack(spacing: 0) {
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                    Spacer()
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                }
            )
            .animation(
                reduceMotion ? nil : Motion.defaultEaseOut,
                value: config.miRequired(loanAmount: activeLoanAmount)
            )
        }
    }

    /// LTV readout uses the derived loan when a purchase price is
    /// present; otherwise falls back to the host calculator's loan
    /// amount so the LO sees something useful on first open.
    private var activeLoanAmount: Decimal {
        config.purchasePrice > 0 ? config.derivedLoanAmount : externalLoanAmount
    }

    private var reveal: AnyTransition {
        if reduceMotion { return .opacity }
        return .opacity.combined(with: .move(edge: .top))
    }

    // MARK: Rows

    private var modeToggleRow: some View {
        HStack(spacing: Spacing.s12) {
            Text("Down payment")
                .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
            Picker("", selection: $config.useDownPaymentDollar) {
                Text("%").tag(false)
                Text("$").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 84)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    @ViewBuilder private var dpAmountRow: some View {
        if config.useDownPaymentDollar {
            FieldRow(
                label: "Amount",
                prefix: "$",
                hint: dpPercentHint,
                decimal: $config.downPaymentDollar
            )
        } else {
            percentStepperRow
        }
    }

    private var dpPercentHint: String {
        let pct = config.downPaymentPct * 100
        guard config.purchasePrice > 0 else { return "" }
        return String(format: "%.1f%% of price", pct)
    }

    private var percentStepperRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Amount")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text(String(format: "$%@ at current price",
                            MoneyFormat.shared.decimalString(config.downPaymentAmount)))
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Stepper(
                value: Binding(
                    get: { Int((config.downPaymentPercent * 100).rounded()) },
                    set: { config.downPaymentPercent = Double($0) / 100 }
                ),
                in: 0...80,
                step: 1
            ) { EmptyView() }
                .labelsHidden()
            Text(String(format: "%d%%", Int((config.downPaymentPercent * 100).rounded())))
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 52, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    private var ltvRow: some View {
        let lt = config.ltv(loanAmount: activeLoanAmount)
        let miReq = config.miRequired(loanAmount: activeLoanAmount)
        return HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("LTV")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text(miReq
                     ? "above 80% — mortgage insurance required"
                     : "at or below 80% — no MI")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(miReq ? Palette.warn : Palette.inkTertiary)
            }
            Spacer()
            Text(String(format: "%.1f%%", lt * 100))
                .textStyle(Typography.num.withSize(18, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    private var miFieldsGroup: some View {
        VStack(spacing: 0) {
            FieldRow(
                label: "Monthly MI",
                prefix: "$",
                hint: "manual entry · auto-calc in a later release",
                decimal: $config.manualMonthlyMI
            )
            divider
            HStack(spacing: Spacing.s12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Request removal at 80%")
                        .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                        .foregroundStyle(Palette.ink)
                    Text("shortens dropoff from 78% · requires appraisal")
                        .textStyle(Typography.num.withSize(11))
                        .foregroundStyle(Palette.inkTertiary)
                }
                Spacer()
                Toggle("", isOn: $config.requestMIRemovalAt80)
                    .labelsHidden()
                    .tint(Palette.accent)
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
        }
    }

    private var divider: some View {
        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
    }
}
