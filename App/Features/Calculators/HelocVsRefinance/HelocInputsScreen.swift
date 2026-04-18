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

    private static let defaultInputs = HelocFormInputs(
        firstLienBalance: 318_000,
        firstLienRate: 3.125,
        firstLienRemainingYears: 22,
        helocAmount: 80_000,
        helocIntroRate: 6.990,
        helocIntroMonths: 12,
        helocFullyIndexedRate: 8.750,
        refiRate: 6.125,
        refiTermYears: 30,
        stressShockBps: 200
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)

                firstLienSection.padding(.top, Spacing.s16)
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
            stepperRow(
                label: "Term",
                value: Binding(
                    get: { viewModel.inputs.refiTermYears },
                    set: { viewModel.inputs.refiTermYears = $0 }
                ),
                range: 5...40,
                suffix: "yr"
            )
        }
    }

    // MARK: HELOC option

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
                range: 0...60,
                step: 6,
                suffix: "mo"
            )
            divider
            FieldRow(
                label: "Fully-indexed rate",
                suffix: "%",
                hint: "after intro · margin + index",
                decimal: Binding(
                    get: { Decimal(viewModel.inputs.helocFullyIndexedRate) },
                    set: { viewModel.inputs.helocFullyIndexedRate = Double(truncating: $0 as NSNumber) }
                ),
                fractionDigits: 3
            )
            divider
            stepperRow(
                label: "Stress shock",
                value: Binding(
                    get: { viewModel.inputs.stressShockBps },
                    set: { viewModel.inputs.stressShockBps = $0 }
                ),
                range: 0...500,
                step: 25,
                suffix: "bps"
            )
        }
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
