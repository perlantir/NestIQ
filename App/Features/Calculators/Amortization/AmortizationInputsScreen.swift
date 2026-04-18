// AmortizationInputsScreen.swift
// Per design/screens/Inputs.jsx. Loan section + Property section +
// Advanced accordion + compute CTA. The view model is the single
// source of truth — Compute populates the schedule and navigates to
// the results screen. After that, input edits in the results view
// trigger a live recompute automatically.

import SwiftUI
import QuotientFinance

struct AmortizationInputsScreen: View {
    let borrower: Borrower?
    var initialInputs: AmortizationFormInputs?
    var existingScenario: Scenario?

    @State private var viewModel = AmortizationViewModel()
    @State private var navigationActive: Bool = false
    @State private var showingAdvanced: Bool = false
    @State private var showingBorrowerPicker: Bool = false
    @State private var selectedBorrower: Borrower?

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    init(
        borrower: Borrower? = nil,
        initialInputs: AmortizationFormInputs? = nil,
        existingScenario: Scenario? = nil
    ) {
        self.borrower = borrower
        self.initialInputs = initialInputs
        self.existingScenario = existingScenario
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)

                loanSection
                    .padding(.top, Spacing.s16)
                PropertyDownPaymentSection(
                    config: Binding(
                        get: { viewModel.inputs.propertyDP },
                        set: { viewModel.inputs.propertyDP = $0 }
                    ),
                    externalLoanAmount: viewModel.inputs.loanAmount
                )
                .padding(.top, Spacing.s24)
                propertySection
                    .padding(.top, Spacing.s24)
                advancedSection
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s24)
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
                Eyebrow("01 · Amortization")
            }
        }
        .navigationDestination(isPresented: $navigationActive) {
            AmortizationResultsScreen(
                viewModel: viewModel,
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
        .onAppear {
            if let initialInputs {
                viewModel.inputs = initialInputs
            }
            if selectedBorrower == nil {
                selectedBorrower = borrower
                viewModel.borrower = borrower
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("New scenario")
                .textStyle(Typography.display.withSize(26, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("Enter loan terms and property details. Results update live.")
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

    // MARK: Loan section

    private var loanSection: some View {
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
            termRow
            divider
            startDateRow
        }
    }

    private var termRow: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            HStack {
                Text("Term")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("\(viewModel.inputs.termYears) yr")
                    .textStyle(Typography.num.withSize(15, weight: .medium))
                    .foregroundStyle(Palette.ink)
            }
            HStack(spacing: Spacing.s4) {
                ForEach([10, 15, 20, 25, 30, 40], id: \.self) { yr in
                    let active = yr == viewModel.inputs.termYears
                    Button {
                        viewModel.inputs.termYears = yr
                    } label: {
                        Text("\(yr)")
                            .textStyle(Typography.num.withSize(12, weight: active ? .semibold : .medium))
                            .foregroundStyle(active ? Palette.accentFG : Palette.inkSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(active ? Palette.accent : Palette.surfaceSunken)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.segmented)
                                    .stroke(active ? Palette.accent : Palette.borderSubtle,
                                            lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Radius.segmented))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    private var startDateRow: some View {
        DatePicker(
            selection: Binding(
                get: { viewModel.inputs.startDate },
                set: { viewModel.inputs.startDate = $0 }
            ),
            displayedComponents: [.date]
        ) {
            Text("Start date")
                .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                .foregroundStyle(Palette.ink)
        }
        .tint(Palette.accent)
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    // MARK: Property section

    private var propertySection: some View {
        fieldGroup(header: "Property") {
            FieldRow(
                label: "Annual taxes",
                prefix: "$",
                hint: taxHint,
                decimal: Binding(
                    get: { viewModel.inputs.annualTaxes },
                    set: { viewModel.inputs.annualTaxes = $0 }
                )
            )
            divider
            FieldRow(
                label: "Insurance",
                prefix: "$",
                hint: "annual",
                decimal: Binding(
                    get: { viewModel.inputs.annualInsurance },
                    set: { viewModel.inputs.annualInsurance = $0 }
                )
            )
            divider
            FieldRow(
                label: "HOA",
                prefix: "$",
                hint: "monthly (optional)",
                decimal: Binding(
                    get: { viewModel.inputs.monthlyHOA },
                    set: { viewModel.inputs.monthlyHOA = $0 }
                )
            )
            divider
            VStack(spacing: 0) {
                pmiRow
                if viewModel.inputs.includePMI {
                    divider
                    FieldRow(
                        label: "Monthly PMI",
                        prefix: "$",
                        hint: "until removal at 78% LTV",
                        decimal: Binding(
                            get: { viewModel.inputs.manualMonthlyPMI },
                            set: { viewModel.inputs.manualMonthlyPMI = $0 }
                        )
                    )
                    .transition(pmiReveal)
                }
            }
            .animation(
                reduceMotion ? nil : Motion.defaultEaseOut,
                value: viewModel.inputs.includePMI
            )
        }
    }

    private var pmiReveal: AnyTransition {
        if reduceMotion { return .opacity }
        return .opacity.combined(with: .move(edge: .top))
    }

    private var taxHint: String {
        let value = viewModel.inputs.propertyValueGuess
        guard value > 0 else { return "" }
        let ratio = Double(truncating: (viewModel.inputs.annualTaxes / value) as NSNumber)
        return String(format: "%.2f%% of value", ratio * 100)
    }

    private var pmiRow: some View {
        HStack(spacing: Spacing.s12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Include PMI")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("auto · LTV 78%")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { viewModel.inputs.includePMI },
                set: { viewModel.inputs.includePMI = $0 }
            ))
            .labelsHidden()
            .tint(Palette.accent)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    // MARK: Advanced

    private var advancedSection: some View {
        DisclosureGroup(isExpanded: $showingAdvanced) {
            VStack(alignment: .leading, spacing: Spacing.s12) {
                FieldRow(
                    label: "Extra principal",
                    prefix: "$",
                    hint: "monthly",
                    decimal: Binding(
                        get: { viewModel.inputs.extraPrincipalMonthly },
                        set: { viewModel.inputs.extraPrincipalMonthly = $0 }
                    )
                )
                HStack {
                    VStack(alignment: .leading) {
                        Text("Biweekly cadence")
                            .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                            .foregroundStyle(Palette.ink)
                        Text("26 payments per year")
                            .textStyle(Typography.num.withSize(11))
                            .foregroundStyle(Palette.inkTertiary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { viewModel.inputs.biweekly },
                        set: { viewModel.inputs.biweekly = $0 }
                    ))
                    .labelsHidden()
                    .tint(Palette.accent)
                }
            }
            .padding(.top, Spacing.s12)
        } label: {
            HStack {
                Text("Advanced")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("Extra principal · Biweekly")
                    .textStyle(Typography.num.withSize(12))
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

    // MARK: Compute CTA

    private var computeCTA: some View {
        VStack(spacing: Spacing.s8) {
            PrimaryButton("Compute amortization") {
                viewModel.compute()
                navigationActive = true
            }
            .accessibilityIdentifier("amort.compute")
            Text("Results live-update as you adjust inputs.")
                .textStyle(Typography.body.withSize(11))
                .foregroundStyle(Palette.inkTertiary)
                .italic()
        }
    }

    // MARK: Shared field group

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

// FieldRow now lives in App/Components/FieldRow.swift — shared by all
// calculator Inputs screens.
