// TCAInputsScreen.swift
// Inputs for the Total Cost Analysis flow: one shared loan amount +
// escrow block, up to four scenario tabs (each with its own rate /
// term / points / closing-cost config), and a horizon chip group
// (5 / 7 / 10 / 15 / 30 yr). "Compute total cost analysis" pushes
// the existing TCAScreen with the configured inputs.

import SwiftUI
import QuotientFinance

struct TCAInputsScreen: View {
    let borrower: Borrower?
    var existingScenario: Scenario?

    @State var viewModel: TCAViewModel
    @State private var navigationActive: Bool = false
    @State private var showingBorrowerPicker: Bool = false
    @State private var selectedBorrower: Borrower?
    @State private var activeTab: Int = 0

    init(
        borrower: Borrower? = nil,
        existingScenario: Scenario? = nil
    ) {
        self.borrower = borrower
        self.existingScenario = existingScenario
        _viewModel = State(initialValue: TCAViewModel(
            inputs: Self.defaultInputs,
            borrower: borrower
        ))
        _selectedBorrower = State(initialValue: borrower)
    }

    private static let defaultInputs = TCAFormInputs(
        mode: .refinance,
        loanAmount: 548_000,
        homeValue: 710_000,
        monthlyTaxes: 542,
        monthlyInsurance: 135,
        monthlyHOA: 0,
        scenarios: [
            TCAScenario(
                label: "A",
                name: "Conv 30",
                rate: 6.750,
                termYears: 30
            ),
            TCAScenario(
                label: "B",
                name: "Conv 15",
                rate: 5.875,
                termYears: 15
            ),
            TCAScenario(
                label: "C",
                name: "FHA 30",
                rate: 6.375,
                termYears: 30,
                points: 0.5
            ),
            TCAScenario(
                label: "D",
                name: "Buydown",
                rate: 4.750,
                termYears: 30,
                points: 2.75,
                closingCosts: 15_100
            ),
        ],
        horizonsYears: [5, 7, 10, 15, 30]
    )

    private let horizonChoices = [5, 7, 10, 15, 30]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)

                modeToggle
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s16)

                if viewModel.inputs.mode == .refinance {
                    loanSection.padding(.top, Spacing.s16)
                    homeValueSection.padding(.top, Spacing.s24)
                }
                escrowSection.padding(.top, Spacing.s24)

                scenarioSection
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s24)

                if viewModel.inputs.mode == .refinance {
                    includeDebtsToggleSection
                        .padding(.horizontal, Spacing.s20)
                        .padding(.top, Spacing.s24)
                    if viewModel.inputs.includeDebts {
                        currentDebtsSection.padding(.top, Spacing.s24)
                    }
                }

                horizonSection
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
                Eyebrow("04 · Total cost")
            }
        }
        .navigationDestination(isPresented: $navigationActive) {
            TCAScreen(
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
            Text("Compare up to four scenarios across 5, 7, 10, 15, and 30-yr horizons.")
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

    // MARK: Mode toggle

    private var modeToggle: some View {
        Picker("Mode", selection: Binding(
            get: { viewModel.inputs.mode },
            set: { viewModel.inputs.mode = $0 }
        )) {
            Text("Purchase").tag(TCAMode.purchase)
            Text("Refinance").tag(TCAMode.refinance)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("tca.modeToggle")
    }

    // MARK: Loan (refinance-mode fallback)

    private var loanSection: some View {
        fieldGroup(header: "Loan amount · refinance default") {
            FieldRow(
                label: "Default loan amount",
                prefix: "$",
                hint: "scenarios can override below",
                decimal: Binding(
                    get: { viewModel.inputs.loanAmount },
                    set: { viewModel.inputs.loanAmount = $0 }
                )
            )
        }
    }

    // MARK: Home value (refinance mode — shared LTV denominator)

    private var homeValueSection: some View {
        fieldGroup(header: "Property") {
            FieldRow(
                label: "Current home value",
                prefix: "$",
                hint: "shared LTV denominator for all scenarios",
                decimal: Binding(
                    get: { viewModel.inputs.homeValue },
                    set: { viewModel.inputs.homeValue = $0 }
                )
            )
        }
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

    // MARK: Scenario tabs

    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Eyebrow("Scenarios")
            SegmentedControl(
                options: Array(viewModel.inputs.scenarios.indices),
                selection: $activeTab,
                label: { viewModel.inputs.scenarios[$0].label }
            )
            scenarioCard(index: clampedTab)
        }
    }

    private var clampedTab: Int {
        max(0, min(activeTab, viewModel.inputs.scenarios.count - 1))
    }

    private func scenarioCard(index: Int) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.inputs.scenarios[index].name)
                    .textStyle(Typography.bodyLg.withSize(14, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                Spacer()
                Text(viewModel.inputs.scenarios[index].label.uppercased())
                    .textStyle(Typography.num.withSize(10.5))
                    .foregroundStyle(Palette.inkTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.monoChip)
                            .stroke(Palette.borderSubtle, lineWidth: 1)
                    )
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.top, Spacing.s12)
            .padding(.bottom, Spacing.s4)

            if viewModel.inputs.mode == .purchase {
                purchaseDPSection(index: index)
                divider
            } else {
                refiLoanSection(index: index)
                divider
            }

            FieldRow(
                label: "Rate",
                suffix: "%",
                decimal: Binding(
                    get: { Decimal(viewModel.inputs.scenarios[index].rate) },
                    set: { viewModel.inputs.scenarios[index].rate = Double(truncating: $0 as NSNumber) }
                ),
                fractionDigits: 3
            )
            divider
            stepperRow(
                label: "Term",
                value: Binding(
                    get: { viewModel.inputs.scenarios[index].termYears },
                    set: { viewModel.inputs.scenarios[index].termYears = $0 }
                ),
                range: 5...40,
                suffix: "yr"
            )
            divider
            FieldRow(
                label: "Points",
                suffix: "pts",
                decimal: Binding(
                    get: { Decimal(viewModel.inputs.scenarios[index].points) },
                    set: { viewModel.inputs.scenarios[index].points = Double(truncating: $0 as NSNumber) }
                ),
                fractionDigits: 2
            )
            divider
            FieldRow(
                label: "Monthly MI",
                prefix: "$",
                hint: miHint(index: index),
                decimal: Binding(
                    get: { viewModel.inputs.scenarios[index].monthlyMI },
                    set: { viewModel.inputs.scenarios[index].monthlyMI = $0 }
                )
            )
            divider
            FieldRow(
                label: "Closing costs",
                prefix: "$",
                decimal: Binding(
                    get: { viewModel.inputs.scenarios[index].closingCosts },
                    set: { viewModel.inputs.scenarios[index].closingCosts = $0 }
                )
            )
            if viewModel.inputs.mode == .refinance, viewModel.inputs.includeDebts {
                divider
                scenarioDebtsRows(index: index)
            }
        }
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
    }

    // MARK: Horizon chips

    private var horizonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Horizons")
            Text("Hold-period windows to compare total cost across.")
                .textStyle(Typography.body.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
            HStack(spacing: Spacing.s8) {
                ForEach(horizonChoices, id: \.self) { years in
                    horizonChip(years: years)
                }
            }
            .padding(.top, Spacing.s4)
        }
    }

    // MARK: Compute CTA

    private var computeCTA: some View {
        VStack(spacing: Spacing.s8) {
            PrimaryButton("Compute total cost analysis") {
                navigationActive = true
            }
            .accessibilityIdentifier("tca.compute")
            Text("Winner per horizon and narrative on the next screen.")
                .textStyle(Typography.body.withSize(11))
                .foregroundStyle(Palette.inkTertiary)
                .italic()
        }
    }

}

// MARK: - Horizon chip + toggle

extension TCAInputsScreen {
    func horizonChip(years: Int) -> some View {
        let isOn = viewModel.inputs.horizonsYears.contains(years)
        return Button {
            toggleHorizon(years)
        } label: {
            HStack(spacing: Spacing.s4) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isOn ? Palette.accent : Palette.inkTertiary)
                Text("\(years) yr")
                    .textStyle(Typography.num.withSize(12, weight: .medium))
                    .foregroundStyle(isOn ? Palette.ink : Palette.inkSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(isOn ? Palette.accentTint : Palette.surfaceRaised)
            .overlay(
                Capsule().stroke(
                    isOn ? Palette.accent : Palette.borderSubtle,
                    lineWidth: 1
                )
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    func toggleHorizon(_ years: Int) {
        var set = Set(viewModel.inputs.horizonsYears)
        if set.contains(years) {
            // Keep at least one horizon selected so the comparison has
            // something to report on.
            if set.count > 1 { set.remove(years) }
        } else {
            set.insert(years)
        }
        viewModel.inputs.horizonsYears = set.sorted()
    }
}

// MARK: - Shared helpers

extension TCAInputsScreen {
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
}
