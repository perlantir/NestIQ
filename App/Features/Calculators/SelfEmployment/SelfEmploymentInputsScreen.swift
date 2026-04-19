// SelfEmploymentInputsScreen.swift
// Three-mode Inputs screen for the Self-Employment calculator:
// Schedule C / 1120S / 1065, each with a Year 1 + Year 2 subform.
// Compute pushes SelfEmploymentResultsScreen; the result flows back
// to IncomeQual via the onDone closure when presented as a sheet.

import SwiftUI
import QuotientFinance

struct SelfEmploymentInputsScreen: View {
    let borrower: Borrower?
    var initialInputs: SelfEmploymentFormInputs?
    var existingScenario: Scenario?
    /// Present-as-sheet import hook. When non-nil, the Results view's
    /// "Use this income" button calls this with the qualifying monthly
    /// value and the calling sheet dismisses.
    var onImportMonthly: ((Decimal) -> Void)?

    @State var viewModel = SelfEmploymentViewModel()
    @State private var navigationActive: Bool = false
    @State private var showingBorrowerPicker: Bool = false
    @State private var selectedBorrower: Borrower?

    @Environment(\.dismiss)
    private var dismiss

    init(
        borrower: Borrower? = nil,
        initialInputs: SelfEmploymentFormInputs? = nil,
        existingScenario: Scenario? = nil,
        onImportMonthly: ((Decimal) -> Void)? = nil
    ) {
        self.borrower = borrower
        self.initialInputs = initialInputs
        self.existingScenario = existingScenario
        self.onImportMonthly = onImportMonthly
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)
                typeSegmented
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s16)

                switch viewModel.inputs.businessType {
                case .scheduleC:
                    scheduleCYearCard(title: "Year 1 — Schedule C", isY1: true)
                        .padding(.top, Spacing.s24)
                    scheduleCYearCard(title: "Year 2 — Schedule C", isY1: false)
                        .padding(.top, Spacing.s16)
                case .form1120S:
                    form1120SYearCard(title: "Year 1 — 1120S K-1", isY1: true)
                        .padding(.top, Spacing.s24)
                    form1120SYearCard(title: "Year 2 — 1120S K-1", isY1: false)
                        .padding(.top, Spacing.s16)
                case .form1065:
                    form1065YearCard(title: "Year 1 — 1065 K-1", isY1: true)
                        .padding(.top, Spacing.s24)
                    form1065YearCard(title: "Year 2 — 1065 K-1", isY1: false)
                        .padding(.top, Spacing.s16)
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
                if onImportMonthly != nil {
                    Text("Self-Employment Income")
                        .textStyle(Typography.bodyLg.withSize(15, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                } else {
                    Eyebrow("06 · Self-employment")
                }
            }
            if onImportMonthly != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("selfEmployment.cancel")
                }
            }
        }
        .navigationDestination(isPresented: $navigationActive) {
            SelfEmploymentResultsScreen(
                viewModel: viewModel,
                existingScenario: existingScenario,
                onImportMonthly: onImportMonthly
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
            if let initialInputs { viewModel.inputs = initialInputs }
            if selectedBorrower == nil {
                selectedBorrower = borrower
                viewModel.borrower = borrower
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("New analysis")
                .textStyle(Typography.display.withSize(26, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("Two-year cash-flow analysis per Fannie Mae Form 1084.")
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

    private var typeSegmented: some View {
        Picker("Business type", selection: Binding(
            get: { viewModel.inputs.businessType },
            set: { viewModel.inputs.businessType = $0 }
        )) {
            Text("Sch C").tag(BusinessType.scheduleC)
            Text("1120S").tag(BusinessType.form1120S)
            Text("1065").tag(BusinessType.form1065)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("selfEmployment.typeToggle")
    }

    private var computeCTA: some View {
        VStack(spacing: Spacing.s8) {
            PrimaryButton("Analyze self-employment income") {
                viewModel.compute()
                navigationActive = true
            }
            .accessibilityIdentifier("selfEmployment.compute")
            Text("Two-year average + trend + qualifying monthly on the next screen.")
                .textStyle(Typography.body.withSize(11))
                .foregroundStyle(Palette.inkTertiary)
                .italic()
        }
    }
}
