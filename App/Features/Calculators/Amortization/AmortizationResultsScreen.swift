// AmortizationResultsScreen.swift
// Per design/screens/Amortization.jsx. Hero PITI block (46pt mono) +
// 4-col KPI row + balance-over-time chart + PITI breakdown + schedule
// table + bottom dock. Inputs edits live-update every derived display
// because the view model is `@Observable`.

import SwiftUI
import Charts
import SwiftData
import QuotientFinance
import QuotientCompliance
import QuotientNarration
import QuotientPDF

struct AmortizationResultsScreen: View {
    @Bindable var viewModel: AmortizationViewModel
    var existingScenario: Scenario?

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    @State private var showingShare = false
    @State private var showingNarration = false
    @State private var justSaved: Bool = false
    @State private var saveError: String?
    @State private var sharePDFURL: URL?
    @State private var sharePageCount: Int = 0

    @Query private var profiles: [LenderProfile]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                borrowerHeader
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)
                    .padding(.bottom, Spacing.s16)

                heroBlock

                balanceSection
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s24)

                AmortizationBreakdownView(viewModel: viewModel)
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s24)

                AmortizationScheduleView(viewModel: viewModel)
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
                Eyebrow("01 · Amortization")
            }
        }
        .safeAreaInset(edge: .bottom) { bottomDock }
        .onAppear {
            if viewModel.schedule == nil { viewModel.compute() }
        }
        .onChange(of: viewModel.inputs) {
            if viewModel.hasComputed { viewModel.compute() }
        }
        .sheet(isPresented: $showingNarration) {
            NarrationSheet(facts: narrationFacts) { _ in }
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingShare) {
            if let url = sharePDFURL, let profile = profiles.first {
                QuotientSharePreview(
                    profile: profile,
                    borrower: viewModel.borrower,
                    pdfURL: url,
                    pageCount: sharePageCount,
                    onDismiss: {}
                )
                .presentationDetents([.large])
            }
        }
    }

    // MARK: Header

    private var borrowerHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow("Borrower")
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.borrower?.fullName ?? "Untitled scenario")
                    .textStyle(Typography.title.withSize(22, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                QMBadge()
            }
            Text(termsSubline)
                .textStyle(Typography.num.withSize(12.5))
                .foregroundStyle(Palette.inkSecondary)
        }
    }

    private var termsSubline: String {
        let money = MoneyFormat.shared.currencyCompact(viewModel.inputs.loanAmount)
        let rate = String(format: "%.3f", viewModel.inputs.annualRate)
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"
        let start = fmt.string(from: viewModel.inputs.startDate)
        return "\(money) · \(viewModel.inputs.termYears)-yr · \(rate)% · start \(start)"
    }

    // MARK: Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Eyebrow("Monthly payment · PITI")
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .textStyle(Typography.num.withSize(13))
                    .foregroundStyle(Palette.inkTertiary)
                Text(MoneyFormat.shared.currencyCompact(viewModel.monthlyPITI))
                    .textStyle(Typography.numHero)
                    .foregroundStyle(Palette.ink)
                Text(".00")
                    .textStyle(Typography.num.withSize(13))
                    .foregroundStyle(Palette.inkTertiary)
            }
            if let miLine = miDropoffLine {
                Text(miLine)
                    .textStyle(Typography.num.withSize(12))
                    .foregroundStyle(Palette.inkSecondary)
            }
            kpiRow
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

    private var miDropoffLine: String? {
        guard let period = viewModel.miDropoffPeriod else { return nil }
        let date = viewModel.miDropoffDate
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"
        let dateStr = date.map { " · \(fmt.string(from: $0))" } ?? ""
        let total = MoneyFormat.shared.dollarsShort(viewModel.totalMIPaid)
        return "MI drops off month \(period)\(dateStr) · \(total) total MI"
    }

    private var kpiRow: some View {
        var items: [(label: String, value: String)] = [
            ("Total interest", MoneyFormat.shared.dollarsShort(viewModel.totalInterest)),
            ("Payoff", payoffShort),
            ("Total paid", MoneyFormat.shared.dollarsShort(viewModel.totalPaid)),
            ("LTV", String(format: "%.0f%%", viewModel.ltv * 100)),
        ]
        // When MI is active, promote "Total MI paid" into the last
        // slot; LTV is still visible on the Property & down-payment
        // section of the Inputs screen.
        if viewModel.miDropoffPeriod != nil {
            items[3] = ("Total MI",
                        MoneyFormat.shared.dollarsShort(viewModel.totalMIPaid))
        }
        return HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, kv in
                VStack(alignment: .leading, spacing: 3) {
                    Text(kv.label.uppercased())
                        .textStyle(Typography.micro.withSize(9.5))
                        .foregroundStyle(Palette.inkTertiary)
                    Text(kv.value)
                        .textStyle(Typography.num.withSize(14, weight: .medium, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, idx == 0 ? 0 : 10)
                .padding(.trailing, idx == 3 ? 0 : 10)
                .overlay(alignment: .leading) {
                    if idx > 0 {
                        Rectangle().fill(Palette.borderSubtle).frame(width: 1)
                    }
                }
            }
        }
    }

    private var payoffShort: String {
        guard let d = viewModel.payoffDate else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: d)
    }

    // MARK: Balance chart

    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            HStack(alignment: .firstTextBaseline) {
                Text("Balance over time")
                    .textStyle(Typography.section)
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("\(viewModel.inputs.termYears) yr")
                    .textStyle(Typography.num)
                    .foregroundStyle(Palette.inkTertiary)
            }
            Text("Principal remaining, year by year.")
                .textStyle(Typography.body.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
                .padding(.bottom, Spacing.s12)

            Chart {
                ForEach(viewModel.yearlyBalances, id: \.year) { p in
                    let v = Double(truncating: p.balance as NSNumber)
                    LineMark(x: .value("Year", p.year), y: .value("Balance", v))
                        .foregroundStyle(Palette.accent)
                        .interpolationMethod(.monotone)
                    AreaMark(x: .value("Year", p.year), y: .value("Balance", v))
                        .foregroundStyle(Palette.accentTint.opacity(0.7))
                        .interpolationMethod(.monotone)
                }
                if viewModel.yearlyBalances.count > 10 {
                    let year10 = viewModel.yearlyBalances[10]
                    PointMark(
                        x: .value("Year", year10.year),
                        y: .value("Balance", Double(truncating: year10.balance as NSNumber))
                    )
                    .symbol(.circle)
                    .foregroundStyle(Palette.accent)
                    .symbolSize(60)
                    RuleMark(x: .value("Year", year10.year))
                        .foregroundStyle(Palette.inkTertiary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 10)) { value in
                    AxisValueLabel {
                        if let year = value.as(Int.self) {
                            let yearNum = 2026 + year
                            Text("'\(String(yearNum).suffix(2))")
                                .textStyle(Typography.num.withSize(9.5))
                                .foregroundStyle(Palette.inkTertiary)
                        }
                    }
                    AxisGridLine().foregroundStyle(Palette.grid)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let bal = value.as(Double.self) {
                            Text("\(Int(bal / 1000))k")
                                .textStyle(Typography.num.withSize(9.5))
                                .foregroundStyle(Palette.inkTertiary)
                        }
                    }
                    AxisGridLine().foregroundStyle(Palette.grid)
                }
            }
            .frame(height: 170)

            if viewModel.yearlyBalances.count > 10 {
                let year10 = viewModel.yearlyBalances[10]
                Text("Year 10 · \(MoneyFormat.shared.dollarsLong(year10.balance)) remaining")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
                    .padding(.top, Spacing.s4)
            }
        }
    }

    // MARK: Bottom dock

    private var bottomDock: some View {
        CalculatorDock(
            saveLabel: justSaved ? "Saved" : "Save",
            onNarrate: { showingNarration = true },
            onSave: { saveScenario() },
            onShare: { generatePDFAndShare() }
        )
    }

    // MARK: Narration facts

    private var narrationFacts: ScenarioFacts {
        let rate = String(format: "%.3f%%", viewModel.inputs.annualRate)
        let piti = "$\(MoneyFormat.shared.decimalString(viewModel.monthlyPITI))"
        let interest = MoneyFormat.shared.dollarsShort(viewModel.totalInterest)
        return ScenarioFacts(
            scenarioType: .amortization,
            borrowerFirstName: viewModel.borrower?.firstName,
            numericFacts: [piti, rate, "\(viewModel.inputs.termYears)", interest],
            fields: [
                "monthlyPITI": piti,
                "rate": rate,
                "termYears": "\(viewModel.inputs.termYears)",
                "totalInterest": interest,
            ]
        )
    }

    // MARK: PDF

    private func generatePDFAndShare() {
        guard let profile = profiles.first else { return }
        do {
            let url = try PDFBuilder.buildAmortizationPDF(
                profile: profile,
                borrower: viewModel.borrower,
                viewModel: viewModel,
                narrative: viewModel.schedule?.payments.first.map { _ in "" } ?? ""
            )
            sharePDFURL = url
            sharePageCount = PDFInspector(url: url)?.pageCount ?? 1
            showingShare = true
        } catch {
            saveError = error.localizedDescription
        }
    }

    // MARK: Save

    private func saveScenario() {
        let snapshot = viewModel.buildScenario()
        let name = viewModel.borrower?.fullName ?? "Amortization \(Date().formatted(date: .numeric, time: .omitted))"
        if let existing = existingScenario {
            existing.inputsJSON = snapshot.inputsJSON
            existing.outputsJSON = snapshot.outputsJSON
            existing.keyStatLine = snapshot.keyStat
            existing.borrower = viewModel.borrower
            existing.name = name
            existing.updatedAt = Date()
        } else {
            let s = Scenario(
                borrower: viewModel.borrower,
                calculatorType: .amortization,
                name: name,
                inputsJSON: snapshot.inputsJSON,
                outputsJSON: snapshot.outputsJSON,
                keyStatLine: snapshot.keyStat
            )
            modelContext.insert(s)
        }
        do {
            try modelContext.save()
            justSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                justSaved = false
            }
        } catch {
            saveError = error.localizedDescription
        }
    }
}

// MARK: - QM badge

private struct QMBadge: View {
    var body: some View {
        Text("GEN-QM")
            .textStyle(Typography.num.withSize(10.5, weight: .regular, design: .monospaced))
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Palette.accentTint)
            .clipShape(RoundedRectangle(cornerRadius: Radius.monoChip))
    }
}
