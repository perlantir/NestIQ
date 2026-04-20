// RefinanceScreen.swift
// Per design/screens/Refinance.jsx. Option tabs (Current/A/B/C) +
// winner hero + 3-col KPI + cumulative savings chart + side-by-side
// table + stress toggle.

import SwiftUI
import Charts
import SwiftData
import QuotientFinance
import QuotientNarration
import QuotientPDF

struct RefinanceScreen: View {
    var initialInputs: RefinanceFormInputs?
    var existingScenario: Scenario?

    @State private var viewModel = RefinanceViewModel()
    @State private var showingStress = false
    @State private var showingNarration = false
    @State private var justSaved = false
    @State private var shareBundle: ShareBundle?
    @State private var showingSaveNamePrompt: Bool = false
    @State private var saveNameDraft: String = ""

    @Environment(\.modelContext)
    private var modelContext

    @Query private var profiles: [LenderProfile]

    private let scenarioColors: [Color] = [
        Palette.inkTertiary, Palette.accent, Palette.scenario2, Palette.scenario3,
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                borrowerBlock
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)
                    .padding(.bottom, Spacing.s16)

                optionTabs
                    .padding(.horizontal, Spacing.s20)
                    .padding(.bottom, 1)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                    }

                winnerHero
                chartSection
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s20)
                tableSection
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s20)
                narrativeSection
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s20)

                Spacer(minLength: 140)
            }
        }
        .background(Palette.surface)
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Eyebrow("03 · Refinance")
            }
        }
        .overlay(alignment: .bottom) { bottomDock }
        .saveScenarioNameAlert(
            isPresented: $showingSaveNamePrompt,
            name: $saveNameDraft,
            defaultName: defaultSaveName,
            onSave: { saveScenario(name: $0) }
        )
        .onAppear {
            if let initialInputs { viewModel.inputs = initialInputs }
            if viewModel.result == nil { viewModel.compute() }
        }
        .onChange(of: viewModel.inputs) {
            viewModel.compute()
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
    }

    private var narrationFacts: ScenarioFacts {
        let savings = "$\(MoneyFormat.shared.decimalString(viewModel.monthlySavings))"
        let be = viewModel.breakEvenMonth.map { "\($0) mo" } ?? "—"
        return ScenarioFacts(
            scenarioType: .refinance,
            borrowerFirstName: viewModel.borrower?.firstName,
            numericFacts: [savings, be],
            fields: [
                "monthlySavings": savings,
                "breakEven": be,
            ]
        )
    }

    // MARK: Borrower

    private var borrowerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow("Borrower")
            Text(viewModel.borrower?.fullName ?? "Untitled refi")
                .textStyle(Typography.title.withSize(22, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text(currentLine)
                .textStyle(Typography.num.withSize(12.5))
                .foregroundStyle(Palette.inkSecondary)
        }
    }

    private var currentLine: String {
        let cur = MoneyFormat.shared.decimalString(viewModel.inputs.currentBalance)
        let rate = displayRateAndAPR(rate: viewModel.inputs.currentRate, decimalAPR: viewModel.inputs.currentAPR)
        return "Current: $\(cur) · \(rate) · \(viewModel.inputs.currentRemainingYears) yr remaining"
    }

    // MARK: Option tabs

    private var optionTabs: some View {
        HStack(spacing: Spacing.s4) {
            tab(index: 0, label: "Current")
            ForEach(Array(viewModel.inputs.options.enumerated()), id: \.element.id) { idx, opt in
                tab(index: idx + 1, label: "Option \(opt.label)")
            }
        }
    }

    private func tab(index: Int, label: String) -> some View {
        let active = index == viewModel.selectedOptionIndex
        let color = scenarioColors[min(index, scenarioColors.count - 1)]
        return Button {
            viewModel.selectedOptionIndex = index
        } label: {
            HStack(spacing: Spacing.s8) {
                Rectangle().fill(color).frame(width: 7, height: 7)
                Text(label)
                    .textStyle(Typography.num.withSize(12, weight: active ? .semibold : .medium))
                    .foregroundStyle(active ? Palette.ink : Palette.inkTertiary)
                if index == 1 && index == viewModel.selectedOptionIndex {
                    Text("BEST")
                        .textStyle(Typography.num.withSize(9))
                        .foregroundStyle(Palette.accent)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Palette.accentTint)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.monoChip))
                }
            }
            .padding(.horizontal, Spacing.s8)
            .padding(.vertical, Spacing.s8)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(active ? Palette.accent : Color.clear)
                    .frame(height: 2)
                    .offset(y: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Winner hero

    private var winnerHero: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow(optionHeader)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Save")
                    .textStyle(Typography.num.withSize(13))
                    .foregroundStyle(Palette.inkTertiary)
                Text("$")
                    .textStyle(Typography.num.withSize(13))
                    .foregroundStyle(Palette.inkTertiary)
                Text(MoneyFormat.shared.decimalString(viewModel.monthlySavings))
                    .textStyle(Typography.num.withSize(40, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.ink)
                Text("/mo")
                    .textStyle(Typography.num.withSize(13))
                    .foregroundStyle(Palette.inkTertiary)
            }
            heroKpiRow
                .padding(.top, Spacing.s8)
        }
        .padding(.horizontal, Spacing.s20)
        .padding(.vertical, Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surfaceRaised)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.borderSubtle).frame(height: 1)
        }
    }

    private var optionHeader: String {
        let idx = viewModel.selectedOptionIndex
        if idx == 0 {
            let rate = displayRateAndAPR(rate: viewModel.inputs.currentRate, decimalAPR: viewModel.inputs.currentAPR)
            return "Current · \(rate)"
        }
        guard idx - 1 < viewModel.inputs.options.count else { return "—" }
        let opt = viewModel.inputs.options[idx - 1]
        let closing = MoneyFormat.shared.decimalString(opt.closingCosts)
        let rate = displayRateAndAPR(rate: opt.rate, decimalAPR: opt.aprRate)
        return "Option \(opt.label) · \(rate) · \(opt.termYears) yr · $\(closing) closing"
    }

    private var heroKpiRow: some View {
        HStack(spacing: 0) {
            kpiCell(
                label: "Break-even",
                value: viewModel.breakEvenMonth.map { "\($0) mo" } ?? "—",
                sub: breakEvenDateLabel
            )
            kpiCell(
                label: "Lifetime Δ",
                value: signedLifetime,
                sub: "saved",
                valueColor: viewModel.lifetimeDelta >= 0 ? Palette.gain : Palette.loss,
                leadingDivider: true
            )
            kpiCell(
                label: "NPV @ 5%",
                value: signedNPV,
                sub: "discounted",
                valueColor: viewModel.npvDelta >= 0 ? Palette.gain : Palette.loss,
                leadingDivider: true
            )
        }
    }

    private var breakEvenDateLabel: String {
        guard let be = viewModel.breakEvenMonth else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        let date = Calendar.current.date(byAdding: .month, value: be, to: Date()) ?? Date()
        return f.string(from: date)
    }

    private var signedLifetime: String {
        let v = viewModel.lifetimeDelta
        let s = v >= 0 ? "+" : "-"
        return "\(s)$\(MoneyFormat.shared.dollarsShort(abs(v)).replacingOccurrences(of: "$", with: ""))"
    }

    private var signedNPV: String {
        let v = viewModel.npvDelta
        let s = v >= 0 ? "+" : "-"
        return "\(s)$\(MoneyFormat.shared.dollarsShort(abs(v)).replacingOccurrences(of: "$", with: ""))"
    }

    private func kpiCell(
        label: String,
        value: String,
        sub: String,
        valueColor: Color = Palette.ink,
        leadingDivider: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .textStyle(Typography.micro.withSize(9.5))
                .foregroundStyle(Palette.inkTertiary)
            Text(value)
                .textStyle(Typography.num.withSize(16, weight: .medium, design: .monospaced))
                .foregroundStyle(valueColor)
            Text(sub)
                .textStyle(Typography.num.withSize(10.5))
                .foregroundStyle(Palette.inkTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, leadingDivider ? 10 : 0)
        .overlay(alignment: .leading) {
            if leadingDivider {
                Rectangle().fill(Palette.borderSubtle).frame(width: 1)
            }
        }
    }

    // MARK: Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("Cumulative savings")
                .textStyle(Typography.section)
                .foregroundStyle(Palette.ink)
            Text("Net of closing costs. Intersects zero at break-even.")
                .textStyle(Typography.body.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
                .padding(.bottom, Spacing.s12)
            Chart {
                ForEach(Array(viewModel.inputs.options.enumerated()), id: \.element.id) { idx, _ in
                    ForEach(viewModel.cumulativeSavings(for: idx + 1, monthsCap: 60), id: \.0) { m, v in
                        LineMark(
                            x: .value("Month", m),
                            y: .value("Savings", Double(truncating: v as NSNumber))
                        )
                        .foregroundStyle(by: .value("Option", "Option \(viewModel.inputs.options[idx].label)"))
                        .lineStyle(StrokeStyle(
                            lineWidth: idx + 1 == viewModel.selectedOptionIndex ? 1.8 : 1.2,
                            lineCap: .round
                        ))
                        .opacity(idx + 1 == viewModel.selectedOptionIndex ? 1.0 : 0.5)
                    }
                }
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(Palette.inkTertiary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                if let be = viewModel.breakEvenMonth {
                    RuleMark(x: .value("Break-even", be))
                        .foregroundStyle(Palette.accent.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
                    PointMark(x: .value("Break-even", be), y: .value("Savings", 0))
                        .foregroundStyle(Palette.accent)
                        .symbolSize(80)
                    PointMark(x: .value("Break-even", be), y: .value("Savings", 0))
                        .foregroundStyle(Palette.surface)
                        .symbolSize(40)
                }
            }
            .chartForegroundStyleScale([
                "Option A": Palette.accent,
                "Option B": Palette.scenario2,
                "Option C": Palette.scenario3,
            ])
            .chartLegend(.hidden)
            .frame(height: 190)
        }
    }

    // MARK: Table

    private var tableSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Side by side")
                .textStyle(Typography.section)
                .foregroundStyle(Palette.ink)
            RefinanceTableView(viewModel: viewModel, scenarioColors: scenarioColors)
        }
    }

    // MARK: Narrative

    private var narrativeSection: some View {
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
        let name = viewModel.borrower?.firstName ?? "the borrower"
        let savings = MoneyFormat.shared.decimalString(viewModel.monthlySavings)
        let lifetime = MoneyFormat.shared.dollarsShort(abs(viewModel.lifetimeDelta))
        let be = viewModel.breakEvenMonth.map { "\($0) months" } ?? "not recouped in the horizon"
        return "The selected option saves \(name) $\(savings)/mo and an estimated \(lifetime) "
            + "over the loan's life. Break-even: \(be)."
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
            calculator: "Refi"
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

    private func saveScenario(name: String) {
        let snap = viewModel.buildScenarioSnapshot()
        if let existing = existingScenario {
            existing.inputsJSON = snap.inputsJSON
            existing.keyStatLine = snap.keyStat
            existing.name = name
            existing.updatedAt = Date()
        } else {
            let scenario = Scenario(
                borrower: viewModel.borrower,
                calculatorType: .refinance,
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
            let url = try PDFBuilder.buildRefinancePDF(
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
            print("[RefinanceScreen] PDF gen failed: \(error)")
            #endif
        }
    }
}

// RefinanceTableView extracted to RefinanceTableView.swift.
