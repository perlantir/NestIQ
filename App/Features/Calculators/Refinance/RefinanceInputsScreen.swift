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

    // `viewModel` is `internal` (not private) so the per-option-card
    // extension helpers below can read viewModel.inputs.options directly.
    @State var viewModel: RefinanceViewModel
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

    /// Default landing state: 2 blank options at term=30, rate=0, every
    /// other field zero — per 5F.3 spec the LO fills in just the values
    /// that matter. Loading a saved scenario overrides this with the
    /// persisted inputs.
    private static let defaultInputs = RefinanceFormInputs(
        currentBalance: 0,
        currentRate: 0,
        currentRemainingYears: 30,
        currentMonthlyMI: 0,
        homeValue: 0,
        monthlyTaxes: 0,
        monthlyInsurance: 0,
        monthlyHOA: 0,
        options: [
            RefinanceFormInputs.blankOption(label: "A"),
            RefinanceFormInputs.blankOption(label: "B"),
        ],
        horizonsYears: [5, 7, 10, 15, 30],
        stressTestHorizonYears: 5,
        scenarioCount: 2
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)

                currentLoanSection.padding(.top, Spacing.s16)
                propertyValueSection.padding(.top, Spacing.s24)
                escrowSection.padding(.top, Spacing.s24)

                scenarioCountSelector
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s24)

                optionsHeader
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s16)
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
            APRFieldRow(aprRate: $viewModel.inputs.currentAPR)
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
            FieldRow(
                label: "Monthly MI",
                prefix: "$",
                hint: "optional · enter 0 if none",
                decimal: Binding(
                    get: { viewModel.inputs.currentMonthlyMI },
                    set: { viewModel.inputs.currentMonthlyMI = $0 }
                )
            )
            divider
            monthlyPIRow
        }
    }

    // MARK: Property value

    private var propertyValueSection: some View {
        fieldGroup(header: "Property") {
            FieldRow(
                label: "Current home value",
                prefix: "$",
                hint: "LTV denominator for every option below",
                decimal: Binding(
                    get: { viewModel.inputs.homeValue },
                    set: { viewModel.inputs.homeValue = $0 }
                )
            )
            divider
            currentLTVRow
        }
    }

    private var currentLTVRow: some View {
        let lt = viewModel.inputs.currentLTV
        let miReq = lt > 0.80
        return HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("LTV · current")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text(miReq
                     ? "above 80% — MI typical"
                     : viewModel.inputs.homeValue > 0
                        ? "at or below 80% — no MI"
                        : "enter home value for live LTV")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(miReq ? Palette.warn : Palette.inkTertiary)
            }
            Spacer()
            Text(viewModel.inputs.homeValue > 0
                 ? String(format: "%.1f%%", lt * 100)
                 : "—")
                .textStyle(Typography.num.withSize(18, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
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

    private var scenarioCountSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Scenarios")
            Picker("Scenarios", selection: Binding(
                get: { viewModel.inputs.scenarioCount },
                set: { newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.inputs.resizeOptions(to: newValue)
                    }
                }
            )) {
                Text("2").tag(2)
                Text("3").tag(3)
                Text("4").tag(4)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("refi.scenarioCount")
        }
    }

    private var optionsHeader: some View {
        let labels = viewModel.inputs.options.map(\.label).joined(separator: " · ")
        return HStack(alignment: .firstTextBaseline) {
            Eyebrow("Refi options")
            Spacer()
            Text("\(viewModel.inputs.options.count) · \(labels)")
                .textStyle(Typography.num.withSize(11))
                .foregroundStyle(Palette.inkTertiary)
        }
    }

    // `optionCard` / `loanAmountHint` / `optionLTVRow` live in the shared
    // helpers extension below to keep this struct under SwiftLint's
    // type_body_length cap.

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

}

// MARK: - Shared helpers

extension RefinanceInputsScreen {
    func stepperRow(
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

    // MARK: Per-option card (moved here from the parent struct)

    func optionCard(index: Int) -> some View {
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
                label: "New loan amount",
                prefix: "$",
                hint: loanAmountHint(index: index),
                decimal: Binding(
                    get: { viewModel.inputs.options[index].newLoanAmount },
                    set: { viewModel.inputs.options[index].newLoanAmount = $0 }
                )
            )
            divider
            optionLTVRow(index: index)
            divider
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
            APRFieldRow(aprRate: $viewModel.inputs.options[index].aprRate)
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
                label: "Monthly MI",
                prefix: "$",
                hint: "optional · per-option",
                decimal: Binding(
                    get: { viewModel.inputs.options[index].monthlyMI },
                    set: { viewModel.inputs.options[index].monthlyMI = $0 }
                )
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

    func loanAmountHint(index: Int) -> String {
        viewModel.inputs.options[index].newLoanAmount > 0
            ? "overrides current balance"
            : "leave 0 to use current balance"
    }

    func optionLTVRow(index: Int) -> some View {
        let opt = viewModel.inputs.options[index]
        let lt = viewModel.inputs.ltv(for: opt)
        let loan = viewModel.inputs.effectiveLoanAmount(for: opt)
        let miReq = lt > 0.80
        return HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("LTV")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text(viewModel.inputs.homeValue > 0
                     ? String(format: "$%@ ÷ $%@",
                              MoneyFormat.shared.decimalString(loan),
                              MoneyFormat.shared.decimalString(viewModel.inputs.homeValue))
                     : "enter home value above")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(miReq ? Palette.warn : Palette.inkTertiary)
            }
            Spacer()
            Text(viewModel.inputs.homeValue > 0
                 ? String(format: "%.1f%%", lt * 100)
                 : "—")
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(miReq ? Palette.warn : Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }
}
