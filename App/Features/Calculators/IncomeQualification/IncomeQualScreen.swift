// IncomeQualScreen.swift
// Per design/screens/Income.jsx. Hero max-loan number + DTI dials +
// income and debts lists + "Run scenario" CTA → opens Amortization
// pre-filled.

import SwiftUI
import SwiftData
import QuotientNarration
import QuotientPDF

struct IncomeQualScreen: View {
    var initialInputs: IncomeQualFormInputs?
    var existingScenario: Scenario?

    // viewModel is `internal` (not private) so the reserves extension in
    // IncomeQualScreen+Reserves.swift can read + write it.
    @State var viewModel = IncomeQualViewModel()
    @State private var navigateToAmortization = false
    @State private var showingBorrowerPicker = false
    @State private var showingNarration = false
    @State private var justSaved = false
    @State private var shareBundle: ShareBundle?
    @State private var showingSaveNamePrompt: Bool = false
    @State private var saveNameDraft: String = ""

    @Environment(\.modelContext)
    private var modelContext

    @Query private var profiles: [LenderProfile]

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
                IncomeListView(
                    incomes: viewModel.inputs.incomes,
                    total: viewModel.qualifyingIncome
                )
                .padding(.top, Spacing.s24)
                DebtsListView(
                    debts: viewModel.inputs.debts,
                    total: viewModel.totalDebt
                )
                .padding(.top, Spacing.s24)

                reservesSection
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s24)

                runScenarioLink
                    .padding(.horizontal, Spacing.s20)
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
        .saveScenarioNameAlert(
            isPresented: $showingSaveNamePrompt,
            name: $saveNameDraft,
            defaultName: defaultSaveName,
            onSave: { saveScenario(name: $0) }
        )
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
        .sheet(isPresented: $showingNarration) {
            NarrationSheet(facts: narrationFacts) { _ in }
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $shareBundle) { bundle in
            QuotientSharePreview(
                profile: bundle.profile,
                borrower: viewModel.borrower,
                pdfURL: bundle.url,
                pageCount: bundle.pageCount,
                onDismiss: {}
            )
            .presentationDetents([.large])
        }
        .onAppear {
            if let initialInputs { viewModel.inputs = initialInputs }
        }
    }

    // MARK: Narration facts

    private var narrationFacts: ScenarioFacts {
        let maxLoan = "$\(MoneyFormat.shared.decimalString(viewModel.maxLoan))"
        let front = String(format: "%.1f%%", viewModel.frontEndDTI * 100)
        let back = String(format: "%.1f%%", viewModel.backEndDTIIncludingDebts * 100)
        return ScenarioFacts(
            scenarioType: .incomeQualification,
            borrowerFirstName: viewModel.borrower?.firstName,
            numericFacts: [maxLoan, front, back],
            fields: [
                "maxLoan": maxLoan,
                "frontEndDTI": front,
                "backEndDTI": back,
            ]
        )
    }

    // The reserves selector lives in IncomeQualScreen+Reserves.swift to
    // keep this struct under SwiftLint's type_body_length cap.

    private var runScenarioLink: some View {
        Button { runScenario() } label: {
            HStack {
                Text("Run in Amortization")
                    .textStyle(Typography.bodyLg.withWeight(.semibold))
                    .foregroundStyle(Palette.accent)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.accent)
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
            .background(Palette.surfaceRaised)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.listCard)
                    .stroke(Palette.accent.opacity(0.4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("income.runScenario")
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
            if viewModel.inputs.mode == .refinance, let refiLine = refiStatusLine {
                Text(refiLine)
                    .textStyle(Typography.num.withSize(12))
                    .foregroundStyle(viewModel.inputs.currentLoanBalance <= viewModel.maxLoan
                                     ? Palette.gain : Palette.warn)
            }

            HStack(spacing: 0) {
                kpiCell(
                    label: viewModel.inputs.mode == .refinance ? "Current PITI" : "Max PITI",
                    value: "$\(MoneyFormat.shared.decimalString(viewModel.maxPITI))"
                )
                kpiCell(
                    label: viewModel.inputs.mode == .refinance ? "Current LTV" : "Max purchase",
                    value: refiHeroSecondaryValue,
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
        if viewModel.inputs.mode == .refinance {
            return "at \(rate)% · \(viewModel.inputs.termYears)-yr · $\(taxIns)/mo tax & ins"
        }
        return "at \(rate)% · \(viewModel.inputs.termYears)-yr · \(down)% down · $\(taxIns)/mo tax & ins"
    }

    /// Refi-mode status line shown below the hero value: "Qualified —
    /// current balance $X is within the $Y cap" or a delta if short.
    private var refiStatusLine: String? {
        let balance = viewModel.inputs.currentLoanBalance
        guard balance > 0 else { return nil }
        let balanceStr = MoneyFormat.shared.dollarsShort(balance)
        let maxStr = MoneyFormat.shared.dollarsShort(viewModel.maxLoan)
        if balance <= viewModel.maxLoan {
            return "Qualified — current balance \(balanceStr) ≤ max \(maxStr)"
        }
        let short = balance - viewModel.maxLoan
        return "Short — current \(balanceStr) exceeds max \(maxStr) by \(MoneyFormat.shared.dollarsShort(short))"
    }

    /// Second hero KPI: "Max purchase" in purchase mode, "Current LTV"
    /// in refinance mode. Purpose of the slot shifts with mode.
    private var refiHeroSecondaryValue: String {
        switch viewModel.inputs.mode {
        case .purchase:
            return "$\(MoneyFormat.shared.decimalString(viewModel.maxPurchase))"
        case .refinance:
            let ltv = viewModel.inputs.currentRefiLTV
            guard viewModel.inputs.currentHomeValue > 0 else { return "—" }
            return String(format: "%.1f%%", ltv * 100)
        }
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

    // MARK: Dock

    private var bottomDock: some View {
        CalculatorDock(
            saveLabel: justSaved ? "Saved" : "Save",
            onNarrate: { showingNarration = true },
            onSave: { promptSaveScenarioName() },
            onShare: { generatePDFAndShare() }
        )
    }

    private var defaultSaveName: String {
        SaveScenarioDefaults.name(
            borrower: viewModel.borrower,
            calculator: "Income Qual"
        )
    }

    private func promptSaveScenarioName() {
        // When the scenario was loaded from the Saved tab, overwrite in
        // place without prompting for a new name.
        if let existing = existingScenario {
            saveScenario(name: existing.name)
            return
        }
        saveNameDraft = defaultSaveName
        showingSaveNamePrompt = true
    }

    private func runScenario() {
        // "Run scenario" silently persists with the default name and jumps
        // to Amortization. The explicit Save button still opens the prompt.
        saveScenario(name: defaultSaveName)
        navigateToAmortization = true
    }

    private func saveScenario(name: String) {
        let snap = viewModel.buildScenario()
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
        justSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { justSaved = false }
    }

    private func generatePDFAndShare() {
        guard let profile = profiles.first else { return }
        do {
            let url = try PDFBuilder.buildIncomeQualPDF(
                profile: profile,
                borrower: viewModel.borrower,
                viewModel: viewModel,
                narrative: ""
            )
            shareBundle = ShareBundle(
                url: url,
                pageCount: PDFInspector(url: url)?.pageCount ?? 1,
                profile: profile
            )
        } catch {
            #if DEBUG
            print("[IncomeQualScreen] PDF gen failed: \(error)")
            #endif
        }
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
