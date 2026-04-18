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

    init(inputs: TCAFormInputs = .sampleDefault, borrower: Borrower? = nil) {
        self.inputs = inputs
        self.borrower = borrower
    }

    func compute() {
        result = compareScenarios(inputs.scenarioInputs(), horizons: inputs.horizonsYears)
    }
}

struct TCAScreen: View {
    var initialInputs: TCAFormInputs?
    var existingScenario: Scenario?

    @State private var viewModel = TCAViewModel()
    @State private var showingNarration = false
    @State private var justSaved = false
    @State private var shareBundle: ShareBundle?

    @Environment(\.modelContext)
    private var modelContext

    @Query private var profiles: [LenderProfile]

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

                scenarioSpecGrid
                    .padding(.horizontal, Spacing.s20)
                    .padding(.bottom, Spacing.s24)

                matrix
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
        let amt = MoneyFormat.shared.decimalString(viewModel.inputs.loanAmount)
        return "Loan $\(amt) · \(viewModel.inputs.scenarios.count) scenarios"
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
        HStack(spacing: Spacing.s8) {
            ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.element.id) { idx, s in
                HStack(spacing: Spacing.s4) {
                    Rectangle().fill(scenarioColors[min(idx, 3)]).frame(width: 7, height: 7)
                    Text("\(s.label) · \(s.name)")
                        .textStyle(Typography.num.withSize(11))
                        .foregroundStyle(Palette.inkSecondary)
                }
                .padding(.horizontal, Spacing.s8)
                .padding(.vertical, 5)
                .overlay(Capsule().stroke(Palette.borderSubtle, lineWidth: 1))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: Scenario spec grid

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
                    Text(String(format: "%.3f", s.rate))
                        .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                    Text("pts \(String(format: "%.2f", s.points))")
                        .textStyle(Typography.num.withSize(10.5))
                        .foregroundStyle(Palette.inkTertiary)
                    Text("\(s.termYears)y")
                        .textStyle(Typography.num.withSize(12))
                        .foregroundStyle(Palette.inkSecondary)
                    Text("Mo " + monthlyPaymentDisplay(for: s, at: idx))
                        .textStyle(Typography.num.withSize(10.5))
                        .foregroundStyle(Palette.inkSecondary)
                    Text("Close " + closingDisplay(for: s))
                        .textStyle(Typography.num.withSize(10.5))
                        .foregroundStyle(Palette.inkTertiary)
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
            loanAmount: viewModel.inputs.loanAmount
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
        let costs = result.scenarioTotalCosts.map { $0[hIdx] }
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

    private var narrative: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Narrative")
            Text(narrativeText)
                .textStyle(Typography.body.withSize(13.5))
                .foregroundStyle(Palette.ink)
                .lineSpacing(3)
                .padding(.horizontal, Spacing.s16)
                .padding(.vertical, Spacing.s12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.surfaceRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.listCard)
                        .stroke(Palette.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
        }
    }

    private var narrativeText: String {
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
            onSave: { save() },
            onShare: { generatePDFAndShare() }
        )
    }

    private func generatePDFAndShare() {
        guard let profile = profiles.first else { return }
        do {
            let url = try PDFBuilder.buildTCAPDF(
                profile: profile,
                borrower: viewModel.borrower,
                viewModel: viewModel,
                narrative: narrativeText
            )
            shareBundle = ShareBundle(
                url: url,
                pageCount: PDFInspector(url: url)?.pageCount ?? 1,
                profile: profile
            )
        } catch {
            #if DEBUG
            print("[TCAScreen] PDF gen failed: \(error)")
            #endif
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = (try? encoder.encode(viewModel.inputs)) ?? Data()
        let name = viewModel.borrower?.fullName ?? "TCA"
        let key = "\(viewModel.inputs.scenarios.count) scenarios · 10-yr horizon"
        if let existing = existingScenario {
            existing.inputsJSON = data
            existing.keyStatLine = key
            existing.name = name
            existing.updatedAt = Date()
        } else {
            let s = Scenario(
                borrower: viewModel.borrower,
                calculatorType: .totalCostAnalysis,
                name: name,
                inputsJSON: data,
                keyStatLine: key
            )
            modelContext.insert(s)
        }
        try? modelContext.save()
        justSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { justSaved = false }
    }
}
