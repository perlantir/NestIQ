// TCAScreen.swift
// Per design/screens/TCA.jsx. 2-4 scenario columns × horizon rows
// (5/7/10/15/30). Winner per row bolded + gain color.

import SwiftUI
import SwiftData
import QuotientFinance
import QuotientNarration
import QuotientPDF

@Observable
@MainActor
final class TCAViewModel {
    var inputs: TCAFormInputs
    var borrower: Borrower?
    var result: QuotientFinance.ComparisonResult?
    /// Session 5M.5: one amortization schedule per scenario, aligned to
    /// `inputs.scenarios` by index. Populated by `compute()` so the
    /// interest-vs-principal / unrecoverable / equity sections can read
    /// horizon-scoped cumulative values without re-running amortize().
    var scenarioSchedules: [AmortizationSchedule] = []

    init(inputs: TCAFormInputs = .sampleDefault, borrower: Borrower? = nil) {
        self.inputs = inputs
        self.borrower = borrower
    }

    func compute() {
        result = compareScenarios(inputs.scenarioInputs(), horizons: inputs.horizonsYears)
        scenarioSchedules = inputs.scenarioInputs().map { amortize(loan: $0.loan) }
    }
}

struct TCAScreen: View {
    var initialInputs: TCAFormInputs?
    var existingScenario: Scenario?

    // State/env members that TCAScreen+Actions.swift needs are internal
    // (not private) so the extension can reach them.
    @State var viewModel = TCAViewModel()
    @State private var showingNarration = false
    @State var justSaved = false
    @State var shareBundle: ShareBundle?
    @State var showingSaveNamePrompt: Bool = false
    @State var saveNameDraft: String = ""

    @Environment(\.modelContext)
    var modelContext

    @Query var profiles: [LenderProfile]

    private let scenarioColors: [Color] = [
        Palette.accent, Palette.scenario2, Palette.scenario3, Palette.scenario4,
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                borrowerBlock
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)
                    .padding(.bottom, Spacing.s16)

                legendChips
                    .padding(.horizontal, Spacing.s20)
                    .padding(.bottom, Spacing.s16)

                alignedScenarioSpecs
                    .padding(.horizontal, Spacing.s20)
                    .padding(.bottom, Spacing.s24)

                matrix
                    .padding(.horizontal, Spacing.s20)
                    .padding(.bottom, Spacing.s24)

                interestPrincipalSection
                    .padding(.horizontal, Spacing.s20)
                    .padding(.bottom, Spacing.s24)

                unrecoverableCostsSection
                    .padding(.horizontal, Spacing.s20)
                    .padding(.bottom, Spacing.s24)

                breakEvenSection
                    .padding(.horizontal, Spacing.s20)
                    .padding(.bottom, Spacing.s24)

                narrative
                    .padding(.horizontal, Spacing.s20)
                    .padding(.bottom, Spacing.s24)

                Spacer(minLength: 140)
            }
        }
        .background(Palette.surface)
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Eyebrow("04 · Total cost")
            }
        }
        .overlay(alignment: .bottom) { bottomDock }
        .saveScenarioNameAlert(
            isPresented: $showingSaveNamePrompt,
            name: $saveNameDraft,
            defaultName: defaultSaveName,
            onSave: { save(name: $0) }
        )
        .onAppear {
            if let initialInputs { viewModel.inputs = initialInputs }
            if viewModel.result == nil { viewModel.compute() }
        }
        .onChange(of: viewModel.inputs) { viewModel.compute() }
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
    }

    private var narrationFacts: ScenarioFacts {
        let winnerIndex = viewModel.result?.winnerByHorizon.last ?? 0
        let winnerName = viewModel.inputs.scenarios.indices.contains(winnerIndex)
            ? viewModel.inputs.scenarios[winnerIndex].name : "—"
        return ScenarioFacts(
            scenarioType: .totalCostAnalysis,
            borrowerFirstName: viewModel.borrower?.firstName,
            numericFacts: [],
            fields: [
                "lifeWinner": winnerName,
            ]
        )
    }

    private var subline: String {
        let count = viewModel.inputs.scenarios.count
        switch viewModel.inputs.mode {
        case .purchase:
            return "Purchase · \(count) scenarios"
        case .refinance:
            let amt = MoneyFormat.shared.decimalString(viewModel.inputs.loanAmount)
            return "Refi · default loan $\(amt) · \(count) scenarios"
        }
    }

    // MARK: Borrower

    private var borrowerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow("Borrower")
            Text(viewModel.borrower?.fullName ?? "Total cost analysis")
                .textStyle(Typography.title.withSize(22, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text(subline)
                .textStyle(Typography.num.withSize(12.5))
                .foregroundStyle(Palette.inkSecondary)
        }
    }

    // MARK: Legend

    private var legendChips: some View {
        // Single-letter chips (A / B / C / D) with a 7pt color dot. The
        // full product name ("Conv 30", "FHA 30", etc.) still renders in
        // the scenario spec grid below — chips in 4-across used to wrap
        // mid-label when both pieces shared the chip.
        HStack(spacing: Spacing.s8) {
            ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.element.id) { idx, s in
                HStack(spacing: Spacing.s4) {
                    Rectangle().fill(scenarioColors[min(idx, 3)]).frame(width: 7, height: 7)
                    Text(s.label.uppercased())
                        .textStyle(Typography.num.withSize(11, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                }
                .padding(.horizontal, Spacing.s12)
                .padding(.vertical, 5)
                .overlay(Capsule().stroke(Palette.borderSubtle, lineWidth: 1))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: Scenario spec grid

    /// Wraps `scenarioSpecGrid` with a 52-pt leading gutter so the top
    /// cards align column-for-column with the horizon matrix rows below.
    private var alignedScenarioSpecs: some View {
        HStack(alignment: .top, spacing: 0) {
            Color.clear.frame(width: 52)
            scenarioSpecGrid
        }
    }

    private var scenarioSpecGrid: some View {
        LazyVGrid(
            columns: Array(repeating: .init(.flexible(), spacing: 0),
                           count: viewModel.inputs.scenarios.count),
            spacing: 0
        ) {
            ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.element.id) { idx, s in
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.label.uppercased())
                        .textStyle(Typography.micro.withSize(9.5))
                        .foregroundStyle(scenarioColors[min(idx, 3)])
                    Text(String(format: "%.3f%%", s.rate))
                        .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                    if let apr = s.aprRate {
                        Text(String(format: "%.3f%% APR", apr.asDouble))
                            .textStyle(Typography.num.withSize(10.5))
                            .foregroundStyle(Palette.inkTertiary)
                    }
                    Text("pts \(String(format: "%.2f", s.points))")
                        .textStyle(Typography.num.withSize(10.5))
                        .foregroundStyle(Palette.inkTertiary)
                    Text("\(s.termYears)y")
                        .textStyle(Typography.num.withSize(12))
                        .foregroundStyle(Palette.inkSecondary)
                    Text("Loan " + loanAmountDisplay(for: s))
                        .textStyle(Typography.num.withSize(10.5))
                        .foregroundStyle(Palette.inkSecondary)
                    if let ltvText = ltvDisplay(for: s) {
                        Text("LTV " + ltvText)
                            .textStyle(Typography.num.withSize(10.5))
                            .foregroundStyle(Palette.inkTertiary)
                    }
                    if s.monthlyMI > 0 {
                        Text("MI $\(MoneyFormat.shared.decimalString(s.monthlyMI))/mo")
                            .textStyle(Typography.num.withSize(10.5))
                            .foregroundStyle(Palette.inkTertiary)
                    }
                    Text("Mo " + monthlyPaymentDisplay(for: s, at: idx))
                        .textStyle(Typography.num.withSize(10.5))
                        .foregroundStyle(Palette.inkSecondary)
                    if let impact = monthlyImpactDisplay(for: s, at: idx) {
                        Text("Mo total " + impact.total)
                            .textStyle(Typography.num.withSize(10.5, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                        Text(impact.delta)
                            .textStyle(Typography.num.withSize(10))
                            .foregroundStyle(impact.isSavings ? Palette.gain : Palette.loss)
                    }
                    Text("Close " + closingDisplay(for: s))
                        .textStyle(Typography.num.withSize(10.5))
                        .foregroundStyle(Palette.inkTertiary)
                    Text("Approx cash " + cashToCloseDisplay(for: s))
                        .textStyle(Typography.num.withSize(10.5, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                }
                .padding(.horizontal, Spacing.s8)
                .padding(.vertical, Spacing.s8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) {
                    if idx < viewModel.inputs.scenarios.count - 1 {
                        Rectangle().fill(Palette.borderSubtle).frame(width: 1)
                    }
                }
            }
        }
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.default)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.default))
    }

    private func loanAmountDisplay(for scenario: TCAScenario) -> String {
        MoneyFormat.shared.dollarsShort(viewModel.inputs.effectiveLoanAmount(for: scenario))
    }

    /// Session 5M.3: approximate cash-to-close per scenario.
    /// "Approximate" to distinguish from a regulated Loan Estimate.
    private func cashToCloseDisplay(for scenario: TCAScenario) -> String {
        MoneyFormat.shared.dollarsShort(viewModel.inputs.approximateCashToClose(for: scenario))
    }

    private struct MonthlyImpact {
        let total: String
        let delta: String
        let isSavings: Bool
    }

    /// Refinance mode + debts-set only: PITI + scenario debts remaining
    /// monthly payment, plus signed Δ vs. current (PITI already paid
    /// by the borrower today isn't known here, so we compare against
    /// the "current" row which the compareScenarios engine computes as
    /// scenario index 0 in refi mode — but TCA doesn't carry a distinct
    /// "current" PITI. So the Δ is scenario-vs-scenario-A when
    /// currentOtherDebts is set; it's the debt-service-only savings
    /// otherwise.)
    private func monthlyImpactDisplay(for scenario: TCAScenario, at index: Int)
        -> MonthlyImpact?
    {
        guard viewModel.inputs.mode == .refinance else { return nil }
        guard viewModel.inputs.includeDebts else { return nil }
        guard let metrics = viewModel.result?.scenarioMetrics,
              index < metrics.count else { return nil }
        let debts = scenario.otherDebts ?? viewModel.inputs.currentOtherDebts
        guard let debts, !debts.isZero else { return nil }
        let total = metrics[index].payment + debts.monthlyPayment
        let currentDebts = viewModel.inputs.currentOtherDebts?.monthlyPayment ?? 0
        let currentBaseline = metrics[0].payment + currentDebts
        let savings = currentBaseline - total
        let deltaStr: String
        if savings > 0 {
            deltaStr = "Saves \(MoneyFormat.shared.currency(savings))/mo vs current"
        } else if savings < 0 {
            deltaStr = "Costs \(MoneyFormat.shared.currency(abs(savings)))/mo more"
        } else {
            deltaStr = "Matches current monthly"
        }
        return MonthlyImpact(
            total: MoneyFormat.shared.currency(total),
            delta: deltaStr,
            isSavings: savings >= 0
        )
    }

    private func ltvDisplay(for scenario: TCAScenario) -> String? {
        let lt = viewModel.inputs.ltv(for: scenario)
        guard lt > 0 else { return nil }
        return String(format: "%.1f%%", lt * 100)
    }

    private func monthlyPaymentDisplay(for scenario: TCAScenario, at index: Int) -> String {
        guard let metrics = viewModel.result?.scenarioMetrics,
              index < metrics.count else { return "—" }
        return "$\(MoneyFormat.shared.decimalString(metrics[index].payment))"
    }

    /// "Closing" display applies the Session 5B.5.3 convention: the
    /// user-entered total already includes points. We show the combined
    /// all-in number here with the points share as a compact hint.
    private func closingDisplay(for scenario: TCAScenario) -> String {
        let breakdown = ClosingCostBreakdown(
            totalClosingCosts: scenario.closingCosts,
            pointsPercentage: scenario.points,
            loanAmount: viewModel.inputs.effectiveLoanAmount(for: scenario)
        )
        let total = MoneyFormat.shared.dollarsShort(breakdown.totalClosingCosts)
        return total
    }

    // MARK: Matrix

    private var matrix: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("Total cost · by horizon")
                .textStyle(Typography.section)
                .foregroundStyle(Palette.ink)
            Text("Principal + interest + points. Winner highlighted per row.")
                .textStyle(Typography.body.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
                .padding(.bottom, Spacing.s12)

            header
            ForEach(Array(viewModel.inputs.horizonsYears.enumerated()), id: \.offset) { hIdx, years in
                matrixRow(hIdx: hIdx, years: years)
                Rectangle().fill(Palette.borderSubtle).frame(height: 1)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 52)
            ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.element.id) { idx, s in
                Text(s.label.uppercased())
                    .textStyle(Typography.micro.withSize(9))
                    .foregroundStyle(scenarioColors[min(idx, 3)])
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, Spacing.s8)
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.borderSubtle).frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.borderSubtle).frame(height: 1)
        }
    }

    private func matrixRow(hIdx: Int, years: Int) -> some View {
        guard let result = viewModel.result,
              hIdx < (result.scenarioTotalCosts.first?.count ?? 0) else {
            return AnyView(EmptyView())
        }
        // Winner determination honors the "Include consumer debts" toggle:
        // when on (and in refi mode), each scenario's horizon cost adds
        // its remaining-debt monthly × horizon months. When off — or in
        // purchase mode — costs are the engine's PITI-only totals.
        let horizonMonths = Decimal(years * 12)
        let costs: [Decimal] = result.scenarioTotalCosts.indices.map { i in
            let piti = result.scenarioTotalCosts[i][hIdx]
            guard viewModel.inputs.mode == .refinance,
                  viewModel.inputs.includeDebts,
                  i < viewModel.inputs.scenarios.count,
                  let d = viewModel.inputs.scenarios[i].otherDebts
                        ?? viewModel.inputs.currentOtherDebts,
                  !d.isZero else {
                return piti
            }
            return piti + d.monthlyPayment * horizonMonths
        }
        let winner = costs.indices.reduce(0) { costs[$1] < costs[$0] ? $1 : $0 }
        return AnyView(
            HStack(spacing: 0) {
                Text("\(years)-yr")
                    .textStyle(Typography.num.withSize(11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.inkSecondary)
                    .frame(width: 52, alignment: .leading)
                ForEach(costs.indices, id: \.self) { i in
                    let value = costs[i]
                    let isW = i == winner
                    HStack(spacing: 2) {
                        if isW {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Palette.gain)
                        }
                        Text(dollarsShort(value))
                            .textStyle(Typography.num.withSize(12.5, weight: isW ? .semibold : .medium, design: .monospaced))
                            .foregroundStyle(isW ? Palette.gain : Palette.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.vertical, Spacing.s8)
        )
    }

    private func dollarsShort(_ value: Decimal) -> String {
        let d = Double(truncating: value as NSNumber)
        if d >= 1_000_000 {
            return String(format: "$%.2fM", d / 1_000_000)
        }
        return String(format: "$%.0fk", d / 1_000)
    }

    // MARK: Narrative

    // `narrative` + `narrativeText` live in TCAScreen+BreakdownSections
    // (moved there in 5M.5 to keep TCAScreen under the type_body_length
    // cap once the interest-vs-principal section landed).

    var narrativeText: String {
        guard let result = viewModel.result, !result.winnerByHorizon.isEmpty else {
            return "Running comparison…"
        }
        let scenarios = viewModel.inputs.scenarios
        let counts = Dictionary(result.winnerByHorizon.map { ($0, 1) }, uniquingKeysWith: +)
        if let (idx, _) = counts.max(by: { $0.value < $1.value }),
           idx < scenarios.count {
            let n = scenarios[idx].name
            let w = counts[idx] ?? 0
            let total = result.horizons.count
            return "\(n) wins \(w) of \(total) horizons. Shorter-horizon winners may differ from "
                + "life-of-loan winners — pick the horizon that matches your hold period."
        }
        return "Horizons trade off upfront cost against monthly savings. "
            + "Check your likely hold period before committing."
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

    var defaultSaveName: String {
        SaveScenarioDefaults.name(
            borrower: viewModel.borrower,
            calculator: "TCA"
        )
    }

    func promptSaveScenarioName() {
        // When the scenario was loaded from the Saved tab, overwrite in
        // place without prompting for a new name.
        if let existing = existingScenario {
            save(name: existing.name)
            return
        }
        saveNameDraft = defaultSaveName
        showingSaveNamePrompt = true
    }

    // PDF / save helpers live in TCAScreen+Actions.swift to keep this
    // struct under the SwiftLint type_body_length cap.
}
