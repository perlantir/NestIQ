// RefinanceInputsScreen.swift
// Inputs for the Refinance Comparison flow: current loan + up to 3
// refi options. Tapping "Compare scenarios" pushes the existing
// RefinanceScreen with the configured inputs.
//
// Matches the AmortizationInputsScreen pattern: @Observable view model,
// FieldRow for numeric entry, borrower pill at top, Compute CTA at
// bottom.

import SwiftUI
import QuotientFinance

struct RefinanceInputsScreen: View {
    let borrower: Borrower?
    var existingScenario: Scenario?

    @State private var viewModel: RefinanceViewModel
    @State private var navigationActive: Bool = false
    @State private var showingBorrowerPicker: Bool = false
    @State private var selectedBorrower: Borrower?

    init(
        borrower: Borrower? = nil,
        existingScenario: Scenario? = nil
    ) {
        self.borrower = borrower
        self.existingScenario = existingScenario
        _viewModel = State(initialValue: RefinanceViewModel(
            inputs: Self.defaultInputs,
            borrower: borrower
        ))
        _selectedBorrower = State(initialValue: borrower)
    }

    private static let defaultInputs = RefinanceFormInputs(
        currentBalance: 412_300,
        currentRate: 7.375,
        currentRemainingYears: 28,
        monthlyTaxes: 542,
        monthlyInsurance: 135,
        monthlyHOA: 0,
        options: [
            RefiOption(label: "A", rate: 6.125, termYears: 30, points: 0.5, closingCosts: 9_800),
            RefiOption(label: "B", rate: 6.500, termYears: 25, points: 0, closingCosts: 5_200),
            RefiOption(label: "C", rate: 5.875, termYears: 30, points: 1.5, closingCosts: 14_800),
        ],
        horizonsYears: [5, 7, 10, 15, 30],
        stressTestHorizonYears: 5
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)

                currentLoanSection.padding(.top, Spacing.s16)
                escrowSection.padding(.top, Spacing.s24)

                optionsHeader
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s24)
                    .padding(.bottom, Spacing.s8)

                ForEach(Array(viewModel.inputs.options.enumerated()), id: \.element.id) { idx, _ in
                    optionCard(index: idx)
                        .padding(.horizontal, Spacing.s20)
                        .padding(.bottom, Spacing.s12)
                }

                computeCTA
                    .padding(.horizontal, Spacing.s20)
                    .padding(.vertical, Spacing.s24)
            }
            .padding(.bottom, Spacing.s96)
        }
        .background(Palette.surface)
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Eyebrow("03 · Refinance")
            }
        }
        .navigationDestination(isPresented: $navigationActive) {
            RefinanceScreen(
                initialInputs: viewModel.inputs,
                existingScenario: existingScenario
            )
        }
        .sheet(isPresented: $showingBorrowerPicker) {
            BorrowerPicker(
                isPresented: $showingBorrowerPicker,
                onSelect: { selected in
                    selectedBorrower = selected
                    viewModel.borrower = selected
                }
            )
            .presentationDetents([.large])
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("New scenario")
                .textStyle(Typography.display.withSize(26, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("Compare the current loan against up to three refi options.")
                .textStyle(Typography.body)
                .foregroundStyle(Palette.inkSecondary)
            borrowerChip
                .padding(.top, Spacing.s12)
        }
    }

    @ViewBuilder private var borrowerChip: some View {
        Button { showingBorrowerPicker = true } label: {
            HStack(spacing: Spacing.s8) {
                Circle()
                    .fill(Palette.surfaceSunken)
                    .overlay(
                        Text(selectedBorrower?.initials ?? "—")
                            .textStyle(Typography.num.withSize(9, weight: .semibold))
                            .foregroundStyle(Palette.inkSecondary)
                    )
                    .frame(width: 20, height: 20)
                Text(selectedBorrower?.fullName ?? "Choose borrower")
                    .textStyle(Typography.body.withSize(12.5))
                    .foregroundStyle(Palette.ink)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.horizontal, Spacing.s12)
            .padding(.vertical, 6)
            .background(Palette.surfaceRaised)
            .overlay(Capsule().stroke(Palette.borderSubtle, lineWidth: 1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Current loan

    private var currentLoanSection: some View {
        fieldGroup(header: "Current loan") {
            FieldRow(
                label: "Balance",
                prefix: "$",
                decimal: Binding(
                    get: { viewModel.inputs.currentBalance },
                    set: { viewModel.inputs.currentBalance = $0 }
                )
            )
            divider
            FieldRow(
                label: "Rate",
                suffix: "%",
                decimal: Binding(
                    get: { Decimal(viewModel.inputs.currentRate) },
                    set: { viewModel.inputs.currentRate = Double(truncating: $0 as NSNumber) }
                ),
                fractionDigits: 3
            )
            divider
            stepperRow(
                label: "Years remaining",
                value: Binding(
                    get: { viewModel.inputs.currentRemainingYears },
                    set: { viewModel.inputs.currentRemainingYears = $0 }
                ),
                range: 1...40,
                suffix: "yr"
            )
            divider
            monthlyPIRow
        }
    }

    /// Auto-calc of current monthly P&I. Read-only — users who need to
    /// override can tweak rate / balance / years until the derived
    /// value matches their statement.
    private var monthlyPIRow: some View {
        let loan = Loan(
            principal: viewModel.inputs.currentBalance,
            annualRate: viewModel.inputs.currentRate / 100,
            termMonths: max(viewModel.inputs.currentRemainingYears, 1) * 12,
            startDate: Date()
        )
        let monthly = paymentFor(loan: loan)
        return HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Monthly P&I")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("auto · derived from balance + rate + years")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Text("$\(MoneyFormat.shared.decimalString(monthly))")
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.inkSecondary)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    // MARK: Escrow

    private var escrowSection: some View {
        fieldGroup(header: "Escrow · monthly") {
            FieldRow(
                label: "Taxes",
                prefix: "$",
                decimal: Binding(
                    get: { viewModel.inputs.monthlyTaxes },
                    set: { viewModel.inputs.monthlyTaxes = $0 }
                )
            )
            divider
            FieldRow(
                label: "Insurance",
                prefix: "$",
                decimal: Binding(
                    get: { viewModel.inputs.monthlyInsurance },
                    set: { viewModel.inputs.monthlyInsurance = $0 }
                )
            )
            divider
            FieldRow(
                label: "HOA",
                prefix: "$",
                hint: "optional",
                decimal: Binding(
                    get: { viewModel.inputs.monthlyHOA },
                    set: { viewModel.inputs.monthlyHOA = $0 }
                )
            )
        }
    }

    // MARK: Refi options

    private var optionsHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Eyebrow("Refi options")
            Spacer()
            Text("\(viewModel.inputs.options.count) · A · B · C")
                .textStyle(Typography.num.withSize(11))
                .foregroundStyle(Palette.inkTertiary)
        }
    }

    private func optionCard(index: Int) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Option \(viewModel.inputs.options[index].label)")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                Spacer()
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.top, Spacing.s12)
            .padding(.bottom, Spacing.s4)

            FieldRow(
                label: "Rate",
                suffix: "%",
                decimal: Binding(
                    get: { Decimal(viewModel.inputs.options[index].rate) },
                    set: { viewModel.inputs.options[index].rate = Double(truncating: $0 as NSNumber) }
                ),
                fractionDigits: 3
            )
            divider
            stepperRow(
                label: "Term",
                value: Binding(
                    get: { viewModel.inputs.options[index].termYears },
                    set: { viewModel.inputs.options[index].termYears = $0 }
                ),
                range: 5...40,
                suffix: "yr"
            )
            divider
            FieldRow(
                label: "Points",
                suffix: "pts",
                decimal: Binding(
                    get: { Decimal(viewModel.inputs.options[index].points) },
                    set: { viewModel.inputs.options[index].points = Double(truncating: $0 as NSNumber) }
                ),
                fractionDigits: 2
            )
            divider
            FieldRow(
                label: "Closing costs",
                prefix: "$",
                decimal: Binding(
                    get: { viewModel.inputs.options[index].closingCosts },
                    set: { viewModel.inputs.options[index].closingCosts = $0 }
                )
            )
        }
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
    }

    // MARK: Compute CTA

    private var computeCTA: some View {
        VStack(spacing: Spacing.s8) {
            PrimaryButton("Compare scenarios") {
                navigationActive = true
            }
            .accessibilityIdentifier("refi.compute")
            Text("Break-even, NPV, and winner curve on the next screen.")
                .textStyle(Typography.body.withSize(11))
                .foregroundStyle(Palette.inkTertiary)
                .italic()
        }
    }

    // MARK: Shared

    private func stepperRow(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int = 1,
        suffix: String
    ) -> some View {
        HStack {
            Text(label)
                .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
            Stepper(value: value, in: range, step: step) { EmptyView() }
                .labelsHidden()
            Text("\(value.wrappedValue) \(suffix)")
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 60, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    @ViewBuilder
    private func fieldGroup<Content: View>(
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

    private var divider: some View {
        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
    }
}
