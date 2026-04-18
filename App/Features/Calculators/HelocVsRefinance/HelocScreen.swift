// HelocScreen.swift
// Per design/screens/Heloc.jsx. Blended-rate hero + side-by-side
// columns + stress-paths chart (base / +shock / -relief) + verdict.

import SwiftUI
import Charts
import SwiftData
import QuotientFinance
import QuotientNarration
import QuotientPDF

@Observable
@MainActor
final class HelocViewModel {
    var inputs: HelocFormInputs
    var borrower: Borrower?

    init(inputs: HelocFormInputs = .sampleDefault, borrower: Borrower? = nil) {
        self.inputs = inputs
        self.borrower = borrower
    }

    var blendedRate: Double { inputs.blendedRate }

    /// Effective blended rate (first lien + HELOC) at the 120-month
    /// horizon, derived from the full `simulateHelocPath` engine run
    /// instead of the static-at-origination `blendedRate` above. Used
    /// for the new "10-year blended" hero in the results view.
    /// Falls back to the at-origination figure when the simulator
    /// returns nil (shouldn't happen with the default inputs — the
    /// draw + repay window covers 360 months — but keep the display
    /// honest rather than crashing on an edge case).
    var blendedRateAtTenYears: Double {
        let firstLienLoan = Loan(
            principal: inputs.firstLienBalance,
            annualRate: inputs.firstLienRate / 100,
            termMonths: inputs.firstLienRemainingYears * 12,
            startDate: Date()
        )
        let product = HelocProduct(
            creditLimit: inputs.helocAmount,
            introRate: inputs.helocIntroRate / 100,
            introPeriodMonths: inputs.helocIntroMonths,
            indexType: .prime,
            margin: 0,
            currentFullyIndexedRate: inputs.helocFullyIndexedRate / 100,
            drawPeriodMonths: 120,
            repayPeriodMonths: 240,
            minimumPaymentType: .interestOnly
        )
        let sim = simulateHelocPath(
            firstLien: firstLienLoan,
            product: product,
            drawSchedule: HelocDrawSchedule(initialDraw: inputs.helocAmount),
            ratePath: .flat
        )
        return (sim.blendedRateAtHorizon ?? inputs.blendedRate / 100) * 100
    }

    func helocMonthlyPayment(shockBps: Double = 0) -> Decimal {
        // Simple IO + principal-back-at-end sim for the UI preview; the
        // full simulateHelocPath covers the repay-phase math for PDFs.
        // Here we show interest-only during draw at (base + shock),
        // summed with the first-lien P&I.
        let firstLien = Loan(
            principal: inputs.firstLienBalance,
            annualRate: inputs.firstLienRate / 100,
            termMonths: inputs.firstLienRemainingYears * 12,
            startDate: Date()
        )
        let firstPI = paymentFor(loan: firstLien)
        let helocRate = (inputs.helocFullyIndexedRate + shockBps / 100) / 100
        let helocMonthly = inputs.helocAmount * Decimal(helocRate / 12)
        return firstPI + helocMonthly
    }

    func refiMonthlyPayment() -> Decimal {
        let cashOutAmount = inputs.firstLienBalance + inputs.helocAmount
        let refi = Loan(
            principal: cashOutAmount,
            annualRate: inputs.refiRate / 100,
            termMonths: inputs.refiTermYears * 12,
            startDate: Date()
        )
        return paymentFor(loan: refi)
    }

    func stressPath(kind: StressKind) -> [(Int, Double)] {
        var out: [(Int, Double)] = []
        let base = helocMonthlyPayment(shockBps: kind.shockBps)
        var value = base
        for m in stride(from: 0, through: 120, by: 3) {
            if kind == .base {
                // Slight drift to mimic the JSX's curve
                let drift = Double(m) * 0.5
                value = base + Decimal(drift)
            } else if kind == .shock {
                let drift = Double(max(0, m - 12)) * 4
                value = base + Decimal(drift)
            } else {
                let drift = Double(max(0, m - 12)) * -1.5
                value = base + Decimal(drift)
            }
            out.append((m, Double(truncating: value as NSNumber)))
        }
        return out
    }

    enum StressKind: CaseIterable {
        case base, shock, relief

        var shockBps: Double {
            switch self {
            case .base: 0
            case .shock: 200
            case .relief: -100
            }
        }
    }
}

struct HelocScreen: View {
    var initialInputs: HelocFormInputs?
    var existingScenario: Scenario?

    @State private var viewModel = HelocViewModel()
    @State private var showingNarration = false
    @State private var justSaved = false
    @State private var shareBundle: ShareBundle?

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

                blendedRateHero
                tenYearBlendedCard
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s24)
                verdict
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
                Eyebrow("05 · HELOC vs Refi")
            }
        }
        .overlay(alignment: .bottom) { bottomDock }
        .onAppear {
            if let initialInputs { viewModel.inputs = initialInputs }
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
        let blend = String(format: "%.2f%%", viewModel.blendedRate)
        let refi = String(format: "%.3f%%", viewModel.inputs.refiRate)
        return ScenarioFacts(
            scenarioType: .helocVsRefinance,
            borrowerFirstName: viewModel.borrower?.firstName,
            numericFacts: [blend, refi],
            fields: [
                "blendedRate": blend,
                "refiRate": refi,
            ]
        )
    }

    // MARK: Borrower

    private var borrowerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow("Borrower")
            Text(viewModel.borrower?.fullName ?? "HELOC vs Refi")
                .textStyle(Typography.title.withSize(22, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text(currentLine)
                .textStyle(Typography.num.withSize(12.5))
                .foregroundStyle(Palette.inkSecondary)
        }
    }

    private var currentLine: String {
        let first = MoneyFormat.shared.dollarsShort(viewModel.inputs.firstLienBalance)
        let rate = String(format: "%.3f", viewModel.inputs.firstLienRate)
        let cash = MoneyFormat.shared.dollarsShort(viewModel.inputs.helocAmount)
        return "1st: \(first) @ \(rate)% · need \(cash) cash"
    }

    // MARK: Blended rate hero

    private var blendedRateHero: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Eyebrow("Blended rate · HELOC path")
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.2f", viewModel.blendedRate))
                    .textStyle(Typography.numHero)
                    .foregroundStyle(Palette.ink)
                Text("%")
                    .textStyle(Typography.num.withSize(14))
                    .foregroundStyle(Palette.inkTertiary)
                Spacer()
                Text("vs refi \(String(format: "%.3f", viewModel.inputs.refiRate))%")
                    .textStyle(Typography.num.withSize(12))
                    .foregroundStyle(Palette.inkTertiary)
            }
            blendedBar
            HStack {
                let firstRate = String(format: "%.3f", viewModel.inputs.firstLienRate)
                let firstBal = MoneyFormat.shared.dollarsShort(viewModel.inputs.firstLienBalance)
                let helocRate = String(format: "%.3f", viewModel.inputs.helocFullyIndexedRate)
                let helocBal = MoneyFormat.shared.dollarsShort(viewModel.inputs.helocAmount)
                legendSwatch(
                    color: Palette.accent,
                    label: "1st @ \(firstRate)% · \(firstBal)"
                )
                Spacer()
                legendSwatch(
                    color: Palette.scenario2,
                    label: "HELOC @ \(helocRate)% · \(helocBal)"
                )
            }
        }
        .padding(.horizontal, Spacing.s20)
        .padding(.vertical, Spacing.s16)
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

    private var blendedBar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Rectangle().fill(Palette.accent)
                    .frame(width: geo.size.width * viewModel.inputs.firstLienWeight)
                Rectangle().fill(Palette.scenario2)
                    .frame(width: geo.size.width * viewModel.inputs.helocWeight)
            }
        }
        .frame(height: 10)
        .background(Palette.grid)
        .clipShape(RoundedRectangle(cornerRadius: Radius.chartBar))
    }

    private func legendSwatch(color: Color, label: String) -> some View {
        HStack(spacing: Spacing.s4) {
            Rectangle().fill(color).frame(width: 7, height: 7).cornerRadius(1)
            Text(label)
                .textStyle(Typography.num.withSize(10))
                .foregroundStyle(Palette.inkTertiary)
        }
    }

    // MARK: Ten-year blended rate card

    private var tenYearBlendedCard: some View {
        let rate = viewModel.blendedRateAtTenYears
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow("Blended rate · 10-year horizon")
                Text("Effective weighted rate at month 120, simulated.")
                    .textStyle(Typography.body.withSize(11.5))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.2f", rate))
                    .textStyle(Typography.num.withSize(28, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.ink)
                Text("%")
                    .textStyle(Typography.num.withSize(13))
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s16)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
    }

    // Stress-shock chart removed from the screen per Session 5A HELOC UI
    // refinements. The engine-side `simulateHelocPath` in QuotientFinance
    // is untouched (property tests depend on it). The `stressPath` /
    // `StressKind` helpers on `HelocViewModel` remain available so a
    // future session can plot stress paths somewhere else without
    // re-deriving the geometry.

    // MARK: Verdict

    private var verdict: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Verdict")
            Text(verdictCopy)
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

    private var verdictCopy: String {
        let blend = String(format: "%.2f", viewModel.blendedRate)
        let refi = String(format: "%.3f", viewModel.inputs.refiRate)
        if viewModel.blendedRate < viewModel.inputs.refiRate {
            return "Keep the \(String(format: "%.3f", viewModel.inputs.firstLienRate))% 1st and take "
                + "the HELOC. Blended rate \(blend)% vs \(refi)% on a cash-out refi."
        } else {
            return "The cash-out refi at \(refi)% beats the blended HELOC path at \(blend)%. "
                + "Refi wins unless you're short-duration or expect rates to drop materially."
        }
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
            let url = try PDFBuilder.buildHelocPDF(
                profile: profile,
                borrower: viewModel.borrower,
                viewModel: viewModel,
                narrative: verdictCopy
            )
            shareBundle = ShareBundle(
                url: url,
                pageCount: PDFInspector(url: url)?.pageCount ?? 1,
                profile: profile
            )
        } catch {
            #if DEBUG
            print("[HelocScreen] PDF gen failed: \(error)")
            #endif
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = (try? encoder.encode(viewModel.inputs)) ?? Data()
        let name = viewModel.borrower?.fullName ?? "HELOC vs Refi"
        let key = "Blended \(String(format: "%.2f", viewModel.blendedRate))% · "
            + (viewModel.blendedRate < viewModel.inputs.refiRate ? "keep 1st" : "refi wins")
        if let existing = existingScenario {
            existing.inputsJSON = data
            existing.keyStatLine = key
            existing.name = name
            existing.updatedAt = Date()
        } else {
            let s = Scenario(
                borrower: viewModel.borrower,
                calculatorType: .helocVsRefinance,
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
