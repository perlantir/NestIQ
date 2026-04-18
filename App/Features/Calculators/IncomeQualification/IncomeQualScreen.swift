// IncomeQualScreen.swift
// Per design/screens/Income.jsx. Hero max-loan number + DTI dials +
// income and debts lists + "Run scenario" CTA → opens Amortization
// pre-filled.

import SwiftUI
import SwiftData

struct IncomeQualScreen: View {
    var initialInputs: IncomeQualFormInputs?
    var existingScenario: Scenario?

    @State private var viewModel = IncomeQualViewModel()
    @State private var navigateToAmortization = false
    @State private var showingBorrowerPicker = false

    @Environment(\.modelContext)
    private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                borrowerBlock
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)
                    .padding(.bottom, Spacing.s16)

                maxLoanHero
                dtiSection
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s24)
                incomeSection
                    .padding(.top, Spacing.s24)
                debtsSection
                    .padding(.top, Spacing.s24)

                Spacer(minLength: 140)
            }
        }
        .background(Palette.surface)
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Eyebrow("02 · Income qualification")
            }
        }
        .overlay(alignment: .bottom) { bottomDock }
        .navigationDestination(isPresented: $navigateToAmortization) {
            AmortizationInputsScreen(
                borrower: viewModel.borrower,
                initialInputs: viewModel.prefilledAmortizationInputs()
            )
        }
        .sheet(isPresented: $showingBorrowerPicker) {
            BorrowerPicker(isPresented: $showingBorrowerPicker) { b in
                viewModel.borrower = b
            }
            .presentationDetents([.large])
        }
        .onAppear {
            if let initialInputs { viewModel.inputs = initialInputs }
        }
    }

    // MARK: Borrower

    private var borrowerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow("Borrower")
            HStack(alignment: .firstTextBaseline) {
                Button { showingBorrowerPicker = true } label: {
                    Text(viewModel.borrower?.fullName ?? "Choose borrower")
                        .textStyle(Typography.title.withSize(22, weight: .bold))
                        .foregroundStyle(Palette.ink)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            HStack(spacing: Spacing.s8) {
                Text("CONV · \(viewModel.inputs.creditScore)")
                    .textStyle(Typography.num.withSize(10.5))
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Palette.accentTint)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.monoChip))
                Text("Dual income · W-2")
                    .textStyle(Typography.num.withSize(12.5))
                    .foregroundStyle(Palette.inkSecondary)
            }
        }
    }

    // MARK: Max loan hero

    private var maxLoanHero: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Max loan · qualifying")
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .textStyle(Typography.num.withSize(14))
                    .foregroundStyle(Palette.inkTertiary)
                Text(MoneyFormat.shared.decimalString(viewModel.maxLoan))
                    .textStyle(Typography.numHero)
                    .foregroundStyle(Palette.ink)
            }
            Text(assumptionLine)
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.inkTertiary)

            HStack(spacing: 0) {
                kpiCell(
                    label: "Max PITI",
                    value: "$\(MoneyFormat.shared.decimalString(viewModel.maxPITI))"
                )
                kpiCell(
                    label: "Max purchase",
                    value: "$\(MoneyFormat.shared.decimalString(viewModel.maxPurchase))",
                    leadingDivider: true
                )
                kpiCell(
                    label: "Reserves",
                    value: String(format: "%.1f mo", viewModel.reserveMonths),
                    valueColor: Palette.gain,
                    leadingDivider: true
                )
            }
            .padding(.top, Spacing.s12)
        }
        .padding(.horizontal, Spacing.s20)
        .padding(.vertical, Spacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surfaceRaised)
        .overlay(
            VStack(spacing: 0) {
                Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                Spacer()
                Rectangle().fill(Palette.borderSubtle).frame(height: 1)
            }
        )
    }

    private var assumptionLine: String {
        let rate = String(format: "%.3f", viewModel.inputs.annualRate)
        let down = Int(viewModel.inputs.downPaymentPercent * 100)
        let taxIns = MoneyFormat.shared.decimalString(
            viewModel.inputs.monthlyTax + viewModel.inputs.monthlyInsurance
        )
        return "at \(rate)% · \(viewModel.inputs.termYears)-yr · \(down)% down · $\(taxIns)/mo tax & ins"
    }

    private func kpiCell(
        label: String,
        value: String,
        valueColor: Color = Palette.ink,
        leadingDivider: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .textStyle(Typography.micro.withSize(9.5))
                .foregroundStyle(Palette.inkTertiary)
            Text(value)
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, leadingDivider ? 10 : 0)
        .overlay(alignment: .leading) {
            if leadingDivider {
                Rectangle().fill(Palette.borderSubtle).frame(width: 1)
            }
        }
    }

    // MARK: DTI dials

    private var dtiSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Debt-to-income")
                .textStyle(Typography.section)
                .foregroundStyle(Palette.ink)
            Text("Front = housing only. Back = housing + monthly debts.")
                .textStyle(Typography.body.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
                .padding(.bottom, Spacing.s12)
            HStack {
                Spacer()
                DTIDialView(
                    label: "Front-end",
                    value: viewModel.frontEndDTI * 100,
                    limit: viewModel.inputs.frontEndLimit * 100
                )
                Spacer()
                DTIDialView(
                    label: "Back-end",
                    value: viewModel.backEndDTIIncludingDebts * 100,
                    limit: viewModel.inputs.backEndLimit * 100
                )
                Spacer()
            }

            advisoryCard
        }
    }

    private var advisoryCard: some View {
        HStack(alignment: .top, spacing: Spacing.s8) {
            Rectangle()
                .fill(viewModel.backEndDTIIncludingDebts * 100 > viewModel.inputs.backEndLimit * 100
                      ? Palette.loss : Palette.warn)
                .frame(width: 7, height: 7)
                .cornerRadius(1)
                .padding(.top, 5)
            Text(advisoryCopy)
                .textStyle(Typography.body.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(3)
        }
        .padding(.horizontal, Spacing.s12)
        .padding(.vertical, Spacing.s12)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.default)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.default))
        .padding(.top, Spacing.s8)
    }

    private var advisoryCopy: String {
        let back = viewModel.backEndDTIIncludingDebts * 100
        let lim = viewModel.inputs.backEndLimit * 100
        if back <= 36 {
            return "Back-end DTI is in the comfort zone — ample room before agency limits."
        } else if back <= lim {
            let fmt = "Back-end sits %.1f pts above the 36%% comfort zone but within agency %.0f%% limit."
            return String(format: fmt, back - 36, lim)
        } else {
            let fmt = "Back-end exceeds the agency %.0f%% ceiling by %.1f pts — consider paying down debts first."
            return String(format: fmt, lim, back - lim)
        }
    }

    // MARK: Income + debts

    private var incomeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Qualifying income · monthly")
                .padding(.horizontal, Spacing.s20)
                .padding(.bottom, Spacing.s8)
            VStack(spacing: 0) {
                ForEach(viewModel.inputs.incomes) { item in
                    incomeRow(item)
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                }
                totalRow(label: "Total qualifying",
                         value: viewModel.qualifyingIncome)
            }
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

    private func incomeRow(_ item: IncomeSource) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(item.label) · \(item.kind.display)")
                    .textStyle(Typography.bodyLg.withSize(13.5, weight: .medium))
                    .foregroundStyle(Palette.ink)
                if item.weightPercent < 1 {
                    Text(String(format: "%.0f%% of $%@",
                                item.weightPercent * 100,
                                MoneyFormat.shared.decimalString(item.monthlyAmount)))
                        .textStyle(Typography.num.withSize(10.5))
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            Spacer()
            Text("$\(MoneyFormat.shared.decimalString(item.qualifyingMonthly))")
                .textStyle(Typography.num.withSize(14, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    private var debtsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Monthly debts")
                .padding(.horizontal, Spacing.s20)
                .padding(.bottom, Spacing.s8)
            VStack(spacing: 0) {
                ForEach(viewModel.inputs.debts) { debt in
                    debtRow(debt)
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                }
                totalRow(label: "Total", value: viewModel.totalDebt)
            }
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

    private func debtRow(_ debt: MonthlyDebt) -> some View {
        HStack {
            Text(debt.label)
                .textStyle(Typography.bodyLg.withSize(13.5, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text("$\(MoneyFormat.shared.decimalString(debt.monthlyAmount))")
                .textStyle(Typography.num.withSize(14, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    private func totalRow(label: String, value: Decimal) -> some View {
        HStack {
            Text(label)
                .textStyle(Typography.bodyLg.withSize(13.5, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text("$\(MoneyFormat.shared.decimalString(value))")
                .textStyle(Typography.num.withSize(14, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    // MARK: Dock

    private var bottomDock: some View {
        HStack(spacing: Spacing.s8) {
            Button {} label: {
                Text("Adjust inputs")
                    .textStyle(Typography.bodyLg)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s12)
                    .background(Palette.surfaceRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.listCard)
                            .stroke(Palette.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
            }
            .buttonStyle(.plain)
            Button { runScenario() } label: {
                Text("Run scenario")
                    .textStyle(Typography.bodyLg.withWeight(.semibold))
                    .foregroundStyle(Palette.accentFG)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s12)
                    .background(Palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
            }
            .buttonStyle(.plain)
            .layoutPriority(1)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.top, Spacing.s12)
        .padding(.bottom, Spacing.s32)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Palette.borderSubtle).frame(height: 1),
                 alignment: .top)
    }

    private func runScenario() {
        // Save an IncomeQual scenario alongside prefilling the
        // Amortization flow, so the Income-qual record shows up in Saved
        // independent of the derived amortization scenario.
        let snap = viewModel.buildScenario()
        let name = viewModel.borrower?.fullName ?? "Income qualification"
        if let existing = existingScenario {
            existing.inputsJSON = snap.inputsJSON
            existing.keyStatLine = snap.keyStat
            existing.borrower = viewModel.borrower
            existing.name = name
            existing.updatedAt = Date()
        } else {
            let scenario = Scenario(
                borrower: viewModel.borrower,
                calculatorType: .incomeQualification,
                name: name,
                inputsJSON: snap.inputsJSON,
                keyStatLine: snap.keyStat
            )
            modelContext.insert(scenario)
        }
        try? modelContext.save()
        navigateToAmortization = true
    }
}

// MARK: - DTI dial view

struct DTIDialView: View {
    let label: String
    let value: Double
    let limit: Double

    var body: some View {
        VStack(spacing: Spacing.s8) {
            ZStack {
                Circle()
                    .stroke(Palette.grid, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: min(value / (limit * 1.4), 1.0))
                    .stroke(
                        isOver ? Palette.warn : Palette.accent,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .textStyle(Typography.num.withSize(20, weight: .medium, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                    Text("% · lim \(Int(limit))")
                        .textStyle(Typography.num.withSize(9.5))
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            .frame(width: 98, height: 98)
            Text(label.uppercased())
                .textStyle(Typography.micro.withSize(10))
                .foregroundStyle(Palette.inkTertiary)
        }
    }

    private var isOver: Bool { value > limit }
}
