// IncomeQualInputsScreen.swift
// First leg of the Income Qualification flow: the loan officer enters
// the borrower's gross monthly income, debts, loan terms, and DTI
// caps; tapping "Run scenario" pushes the existing IncomeQualScreen
// results view with the configured inputs.
//
// Matches the AmortizationInputsScreen pattern: @Observable view model,
// FieldRow for numeric entry, sectioned field groups, borrower pill at
// top, Compute CTA at bottom.

import SwiftUI
import QuotientFinance

struct IncomeQualInputsScreen: View {
    let borrower: Borrower?
    var initialInputs: IncomeQualFormInputs?
    var existingScenario: Scenario?

    // viewModel, showingSelfEmployment, and selectedBorrower are
    // `internal` (not private) so the SE-import extension can reach
    // them — the sheet content lives over there to keep this struct
    // under the SwiftLint type_body_length cap.
    @State var viewModel: IncomeQualViewModel
    @State private var navigationActive: Bool = false
    @State private var showingBorrowerPicker: Bool = false
    @State var showingSelfEmployment: Bool = false
    @State var selectedBorrower: Borrower?

    init(
        borrower: Borrower? = nil,
        initialInputs: IncomeQualFormInputs? = nil,
        existingScenario: Scenario? = nil
    ) {
        self.borrower = borrower
        self.initialInputs = initialInputs
        self.existingScenario = existingScenario
        _viewModel = State(initialValue: IncomeQualViewModel(
            inputs: initialInputs ?? Self.defaultInputs,
            borrower: borrower
        ))
        _selectedBorrower = State(initialValue: borrower)
    }

    /// Baked-in defaults — we intentionally avoid `.sampleDefault` on
    /// the Inputs screens so this surface is the single source of truth
    /// for "what does a fresh Income Qualification scenario look like?"
    private static let defaultInputs = IncomeQualFormInputs(
        loanType: LoanType.conventional.rawValue,
        creditScore: 740,
        frontEndLimit: 0.28,
        backEndLimit: 0.43,
        annualRate: 6.750,
        termYears: 30,
        annualTaxes: 6_500,
        annualInsurance: 1_620,
        monthlyHOA: 0,
        downPaymentPercent: 0.20,
        incomes: [IncomeSource(label: "Gross monthly income", monthlyAmount: 16_050)],
        debts: [MonthlyDebt(label: "Monthly debts", monthlyAmount: 827)]
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)

                modeToggle
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s16)

                incomeSection.padding(.top, Spacing.s16)
                loanSection.padding(.top, Spacing.s24)
                if viewModel.inputs.mode == .purchase {
                    PropertyDownPaymentSection(
                        config: Binding(
                            get: { viewModel.inputs.propertyDP },
                            set: { viewModel.inputs.propertyDP = $0 }
                        ),
                        externalLoanAmount: viewModel.maxLoan
                    )
                    .padding(.top, Spacing.s24)
                } else {
                    refinanceSection
                        .padding(.top, Spacing.s24)
                }
                propertySection.padding(.top, Spacing.s24)
                dtiSection.padding(.top, Spacing.s24)
                reservesSection.padding(.top, Spacing.s24)

                computeCTA
                    .padding(.horizontal, Spacing.s20)
                    .padding(.vertical, Spacing.s24)
            }
            .padding(.bottom, Spacing.s96)
        }
        .background(Palette.surface)
        .scrollIndicators(.hidden)
        .keyboardDoneToolbar()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Eyebrow("02 · Income qualification")
            }
        }
        .navigationDestination(isPresented: $navigationActive) {
            IncomeQualScreen(
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
        .sheet(isPresented: $showingSelfEmployment) {
            selfEmploymentSheetContent
        }
    }

    // importSelfEmploymentIncome lives in the extension.

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("New scenario")
                .textStyle(Typography.display.withSize(26, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("Enter the borrower's income, debts, and target loan terms.")
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

    // MARK: Income section

    private var incomeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            fieldGroup(header: "Income · debts") {
                FieldRow(
                    label: "Gross monthly income",
                    prefix: "$",
                    hint: primaryIncomeHint,
                    decimal: Binding(
                        get: { viewModel.inputs.incomes.first?.monthlyAmount ?? 0 },
                        set: { setPrimaryIncome($0) }
                    )
                )
                divider
                FieldRow(
                    label: "Monthly debts",
                    prefix: "$",
                    hint: "auto + student + CC min",
                    decimal: Binding(
                        get: { viewModel.inputs.debts.first?.monthlyAmount ?? 0 },
                        set: { setPrimaryDebt($0) }
                    )
                )
            }
            selfEmploymentImportPill
                .padding(.horizontal, Spacing.s20)
        }
    }

    // SE import pill + hint live in IncomeQualInputsScreen+SelfEmployment.swift
    // to stay under SwiftLint's type_body_length cap.

    private func setPrimaryIncome(_ value: Decimal) {
        if viewModel.inputs.incomes.isEmpty {
            viewModel.inputs.incomes = [
                IncomeSource(label: "Gross monthly income", monthlyAmount: value)
            ]
        } else {
            viewModel.inputs.incomes[0].monthlyAmount = value
            viewModel.inputs.incomes[0].weightPercent = 1.0
        }
    }

    private func setPrimaryDebt(_ value: Decimal) {
        if viewModel.inputs.debts.isEmpty {
            viewModel.inputs.debts = [
                MonthlyDebt(label: "Monthly debts", monthlyAmount: value)
            ]
        } else {
            viewModel.inputs.debts[0].monthlyAmount = value
        }
    }

    // MARK: Loan section

    private var loanSection: some View {
        fieldGroup(header: "Loan") {
            FieldRow(
                label: "Target interest rate",
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
        }
    }

    private var termRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Term")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("years")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Stepper(
                value: Binding(
                    get: { viewModel.inputs.termYears },
                    set: { viewModel.inputs.termYears = $0 }
                ),
                in: 5...40,
                step: 5
            ) {
                Text("\(viewModel.inputs.termYears)")
                    .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.ink)
            }
            .labelsHidden()
            Text("\(viewModel.inputs.termYears)")
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 40, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    // MARK: Property section

    private var propertySection: some View {
        fieldGroup(header: "Property") {
            FieldRow(
                label: "Annual taxes",
                prefix: "$",
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
        }
    }

    // MARK: DTI section

    private var dtiSection: some View {
        fieldGroup(header: "DTI caps") {
            dtiRow(
                label: "Front-end cap",
                hint: "housing ÷ income",
                value: Binding(
                    get: { viewModel.inputs.frontEndLimit },
                    set: { viewModel.inputs.frontEndLimit = $0 }
                )
            )
            divider
            dtiRow(
                label: "Back-end cap",
                hint: "housing + debts ÷ income",
                value: Binding(
                    get: { viewModel.inputs.backEndLimit },
                    set: { viewModel.inputs.backEndLimit = $0 }
                )
            )
        }
    }

    private func dtiRow(
        label: String,
        hint: String,
        value: Binding<Double>
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text(hint)
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Stepper(
                value: Binding(
                    get: { Int((value.wrappedValue * 100).rounded()) },
                    set: { value.wrappedValue = Double($0) / 100 }
                ),
                in: 15...55,
                step: 1
            ) {
                EmptyView()
            }
            .labelsHidden()
            Text("\(Int((value.wrappedValue * 100).rounded()))%")
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 52, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    // MARK: Compute CTA

    private var computeCTA: some View {
        VStack(spacing: Spacing.s8) {
            PrimaryButton("Run scenario") {
                navigationActive = true
            }
            .accessibilityIdentifier("incomeQual.compute")
            Text("Max loan, DTI, and reserves update live on the next screen.")
                .textStyle(Typography.body.withSize(11))
                .foregroundStyle(Palette.inkTertiary)
                .italic()
        }
    }

    // MARK: Mode toggle + refinance section

    private var modeToggle: some View {
        Picker("Mode", selection: Binding(
            get: { viewModel.inputs.mode },
            set: { viewModel.inputs.mode = $0 }
        )) {
            Text("Purchase").tag(IncomeQualMode.purchase)
            Text("Refinance").tag(IncomeQualMode.refinance)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("incomeQual.modeToggle")
    }

    private var refinanceSection: some View {
        fieldGroup(header: "Current loan & property") {
            FieldRow(
                label: "Current home value",
                prefix: "$",
                decimal: Binding(
                    get: { viewModel.inputs.currentHomeValue },
                    set: { viewModel.inputs.currentHomeValue = $0 }
                )
            )
            divider
            FieldRow(
                label: "Current loan balance",
                prefix: "$",
                hint: "qualifying against this balance",
                decimal: Binding(
                    get: { viewModel.inputs.currentLoanBalance },
                    set: { viewModel.inputs.currentLoanBalance = $0 }
                )
            )
            divider
            FieldRow(
                label: "Monthly MI",
                prefix: "$",
                hint: "optional",
                decimal: Binding(
                    get: { viewModel.inputs.refiMonthlyMI },
                    set: { viewModel.inputs.refiMonthlyMI = $0 }
                )
            )
            divider
            currentLTVRow
        }
    }

    private var currentLTVRow: some View {
        let lt = viewModel.inputs.currentRefiLTV
        let miReq = lt > 0.80
        return HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Current LTV")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text(viewModel.inputs.currentHomeValue > 0
                     ? (miReq ? "above 80% — MI typical" : "at or below 80% — no MI")
                     : "enter home value for live LTV")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(miReq ? Palette.warn : Palette.inkTertiary)
            }
            Spacer()
            Text(viewModel.inputs.currentHomeValue > 0
                 ? String(format: "%.1f%%", lt * 100) : "—")
                .textStyle(Typography.num.withSize(18, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

}

// MARK: - Shared helpers

extension IncomeQualInputsScreen {
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
