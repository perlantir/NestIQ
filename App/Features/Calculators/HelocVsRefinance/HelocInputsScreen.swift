// HelocInputsScreen.swift
// Inputs for the HELOC vs Refinance flow: current first lien, the
// cash-out target, the cash-out refi option, and the HELOC's intro +
// fully-indexed rates. "Compare options" pushes the existing
// HelocScreen with the configured inputs.
//
// Notes: the HelocFormInputs schema doesn't currently carry index
// type / margin / draw period / repay period fields, so those are
// out of scope for this pass — we surface the rates the model does
// consume (intro, fully-indexed) and leave the richer term layout
// for a follow-up.

import SwiftUI
import QuotientFinance

struct HelocInputsScreen: View {
    let borrower: Borrower?
    var existingScenario: Scenario?

    @State private var viewModel: HelocViewModel
    @State private var navigationActive: Bool = false
    @State private var showingBorrowerPicker: Bool = false
    @State private var selectedBorrower: Borrower?

    init(
        borrower: Borrower? = nil,
        existingScenario: Scenario? = nil
    ) {
        self.borrower = borrower
        self.existingScenario = existingScenario
        _viewModel = State(initialValue: HelocViewModel(
            inputs: Self.defaultInputs,
            borrower: borrower
        ))
        _selectedBorrower = State(initialValue: borrower)
    }

    /// Fresh-launch inputs — blank-slate per 5H.5 spec. Term fields
    /// default to 30 yr (standard starting point); every other numeric
    /// field is 0. Saved scenarios bypass this and load their own
    /// values unchanged.
    private static let defaultInputs = HelocFormInputs(
        firstLienBalance: 0,
        firstLienRate: 0,
        firstLienRemainingYears: 30,
        helocAmount: 0,
        helocIntroRate: 0,
        helocIntroMonths: 0,
        helocFullyIndexedRate: 0,
        refiRate: 0,
        refiTermYears: 30,
        refiMonthlyMI: 0,
        homeValue: 0,
        stressShockBps: 200
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)

                firstLienSection.padding(.top, Spacing.s16)
                propertyValueSection.padding(.top, Spacing.s24)
                cashOutSection.padding(.top, Spacing.s24)
                refiSection.padding(.top, Spacing.s24)
                helocSection.padding(.top, Spacing.s24)

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
                Eyebrow("05 · HELOC vs Refi")
            }
        }
        .navigationDestination(isPresented: $navigationActive) {
            HelocScreen(
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
            Text("Keep the first lien and layer a HELOC, or do a cash-out refi.")
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

    // MARK: First lien

    private var firstLienSection: some View {
        fieldGroup(header: "First lien") {
            FieldRow(
                label: "Balance",
                prefix: "$",
                decimal: Binding(
                    get: { viewModel.inputs.firstLienBalance },
                    set: { viewModel.inputs.firstLienBalance = $0 }
                )
            )
            divider
            FieldRow(
                label: "Rate",
                suffix: "%",
                decimal: Binding(
                    get: { Decimal(viewModel.inputs.firstLienRate) },
                    set: { viewModel.inputs.firstLienRate = Double(truncating: $0 as NSNumber) }
                ),
                fractionDigits: 3
            )
            divider
            APRFieldRow(
                aprRate: $viewModel.inputs.firstLienAPR,
                hint: "Optional — 1st lien disclosure APR"
            )
            divider
            stepperRow(
                label: "Years remaining",
                value: Binding(
                    get: { viewModel.inputs.firstLienRemainingYears },
                    set: { viewModel.inputs.firstLienRemainingYears = $0 }
                ),
                range: 1...40,
                suffix: "yr"
            )
        }
    }

    // MARK: Property value + LTV / CLTV

    private var propertyValueSection: some View {
        fieldGroup(header: "Property") {
            FieldRow(
                label: "Current home value",
                prefix: "$",
                hint: "drives LTV / CLTV below",
                decimal: Binding(
                    get: { viewModel.inputs.homeValue },
                    set: { viewModel.inputs.homeValue = $0 }
                )
            )
            divider
            ltvRow(
                label: "LTV · 1st lien",
                value: viewModel.inputs.firstLienLTV,
                sub: "first lien ÷ home value"
            )
            divider
            ltvRow(
                label: "CLTV",
                value: viewModel.inputs.cltv,
                sub: "(first lien + HELOC) ÷ home value"
            )
        }
    }

    private func ltvRow(label: String, value: Double, sub: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text(sub)
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Text(viewModel.inputs.homeValue > 0
                 ? String(format: "%.1f%%", value * 100)
                 : "—")
                .textStyle(Typography.num.withSize(18, weight: .medium, design: .monospaced))
                .foregroundStyle(value > 0.80 ? Palette.warn : Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    // MARK: Cash-out target

    private var cashOutSection: some View {
        fieldGroup(header: "Cash-out target") {
            FieldRow(
                label: "Amount",
                prefix: "$",
                hint: "HELOC credit limit or refi cash-out",
                decimal: Binding(
                    get: { viewModel.inputs.helocAmount },
                    set: { viewModel.inputs.helocAmount = $0 }
                )
            )
        }
    }

    // MARK: Refi option

    private var refiSection: some View {
        fieldGroup(header: "Refi option · cash-out") {
            FieldRow(
                label: "Rate",
                suffix: "%",
                decimal: Binding(
                    get: { Decimal(viewModel.inputs.refiRate) },
                    set: { viewModel.inputs.refiRate = Double(truncating: $0 as NSNumber) }
                ),
                fractionDigits: 3
            )
            divider
            APRFieldRow(
                aprRate: $viewModel.inputs.refiAPR,
                hint: "Optional — refi disclosure APR"
            )
            divider
            stepperRow(
                label: "Term",
                value: Binding(
                    get: { viewModel.inputs.refiTermYears },
                    set: { viewModel.inputs.refiTermYears = $0 }
                ),
                range: 5...40,
                suffix: "yr"
            )
            divider
            FieldRow(
                label: "Monthly MI",
                prefix: "$",
                hint: refiMIHint,
                decimal: Binding(
                    get: { viewModel.inputs.refiMonthlyMI },
                    set: { viewModel.inputs.refiMonthlyMI = $0 }
                )
            )
        }
    }

    private var refiMIHint: String {
        let ltv = viewModel.inputs.refiLTV
        guard viewModel.inputs.homeValue > 0 else {
            return "enter if required at your LTV"
        }
        return ltv > 0.80
            ? String(format: "refi LTV %.1f%% — MI typical", ltv * 100)
            : String(format: "refi LTV %.1f%% — no MI typical", ltv * 100)
    }

    // MARK: HELOC option

    /// Assumed Prime rate — reasonable snapshot for the UI preview. The
    /// engine doesn't care about the Prime/margin split; it reads the
    /// already-combined `helocFullyIndexedRate` on the form input.
    private let assumedPrime: Double = 7.50

    private var helocSection: some View {
        fieldGroup(header: "HELOC option · keep 1st") {
            FieldRow(
                label: "Intro rate",
                suffix: "%",
                decimal: Binding(
                    get: { Decimal(viewModel.inputs.helocIntroRate) },
                    set: { viewModel.inputs.helocIntroRate = Double(truncating: $0 as NSNumber) }
                ),
                fractionDigits: 3
            )
            divider
            stepperRow(
                label: "Intro period",
                value: Binding(
                    get: { viewModel.inputs.helocIntroMonths },
                    set: { viewModel.inputs.helocIntroMonths = $0 }
                ),
                range: 1...24,
                step: 1,
                suffix: "mo"
            )
            divider
            rateMarginRow
            divider
            APRFieldRow(
                aprRate: $viewModel.inputs.helocAPR,
                hint: "Optional — HELOC disclosure APR"
            )
        }
    }

    /// "Prime + X.XX%" row. Reads and writes `helocFullyIndexedRate` so
    /// the engine behavior stays identical; the UI just reshapes the
    /// number as a margin over an assumed Prime value.
    private var rateMarginRow: some View {
        let marginBinding = Binding<Double>(
            get: { max(0, viewModel.inputs.helocFullyIndexedRate - assumedPrime) },
            set: { viewModel.inputs.helocFullyIndexedRate = assumedPrime + $0 }
        )
        return HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Rate margin")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text(String(format: "Prime + %.2f%% → %.3f%% fully indexed",
                            marginBinding.wrappedValue,
                            viewModel.inputs.helocFullyIndexedRate))
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Stepper(
                value: marginBinding,
                in: 0.0...6.0,
                step: 0.25
            ) {
                EmptyView()
            }
            .labelsHidden()
            Text(String(format: "%.2f%%", marginBinding.wrappedValue))
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 64, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    // MARK: Compute CTA

    private var computeCTA: some View {
        VStack(spacing: Spacing.s8) {
            PrimaryButton("Compare options") {
                navigationActive = true
            }
            .accessibilityIdentifier("heloc.compute")
            Text("Blended rate, stress paths, and verdict on the next screen.")
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
                .frame(minWidth: 72, alignment: .trailing)
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
