// SelfEmploymentResultsScreen.swift
// Results view for the Self-Employment calculator. Hero qualifying
// monthly + trend badge + per-year cards + two-year average block.
// When invoked from IncomeQual (onImportMonthly non-nil) the dock
// swaps the Save button for "Use this income."

import SwiftUI
import SwiftData
import QuotientFinance
import QuotientPDF

struct SelfEmploymentResultsScreen: View {
    @Bindable var viewModel: SelfEmploymentViewModel
    var existingScenario: Scenario?
    var onImportMonthly: ((Decimal) -> Void)?

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    @State private var justSaved = false
    @State private var shareBundle: ShareBundle?
    @State private var expandedYear1: Bool = false
    @State private var expandedYear2: Bool = false

    @Query private var profiles: [LenderProfile]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                borrowerHeader
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s8)
                    .padding(.bottom, Spacing.s16)

                heroBlock

                yearBreakdown
                    .padding(.horizontal, Spacing.s20)
                    .padding(.top, Spacing.s24)

                twoYearBlock
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
                Eyebrow("06 · Self-employment")
            }
        }
        .safeAreaInset(edge: .bottom) { bottomDock }
        .onAppear {
            if viewModel.output == nil { viewModel.compute() }
        }
        .onChange(of: viewModel.inputs) {
            viewModel.compute()
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

    // MARK: Header

    private var borrowerHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow("Borrower")
            Text(viewModel.borrower?.fullName ?? "Self-employment analysis")
                .textStyle(Typography.title.withSize(22, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("\(viewModel.inputs.businessType.display) · 2-year analysis")
                .textStyle(Typography.num.withSize(12.5))
                .foregroundStyle(Palette.inkSecondary)
        }
    }

    // MARK: Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Qualifying monthly income")
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .textStyle(Typography.num.withSize(14))
                    .foregroundStyle(Palette.inkTertiary)
                Text(MoneyFormat.shared.decimalString(viewModel.qualifyingMonthly))
                    .textStyle(Typography.numHero)
                    .foregroundStyle(Palette.ink)
            }
            Text(assumptionLine)
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.inkTertiary)
            trendBadge
                .padding(.top, Spacing.s8)
            if let note = viewModel.output?.trendNotes {
                Text(note)
                    .textStyle(Typography.body.withSize(12))
                    .foregroundStyle(Palette.inkSecondary)
                    .padding(.top, Spacing.s4)
            }
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
        guard let out = viewModel.output else { return "Running analysis…" }
        let annual = MoneyFormat.shared.dollarsShort(out.twoYearAverage.qualifyingAnnualIncome)
        return "2-yr qualifying annual \(annual) ÷ 12"
    }

    @ViewBuilder private var trendBadge: some View {
        let trend = viewModel.output?.twoYearAverage.trend ?? .stable
        let color: Color = {
            switch trend {
            case .stable, .increasing: return Palette.gain
            case .declining: return Palette.warn
            case .significantDecline: return Palette.loss
            }
        }()
        Text(trend.display.uppercased())
            .textStyle(Typography.num.withSize(10.5, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.s8)
            .padding(.vertical, 3)
            .overlay(
                Capsule().stroke(color, lineWidth: 1)
            )
    }

    // MARK: Year breakdown

    private var yearBreakdown: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Eyebrow("Per-year cash flow")
            if let out = viewModel.output {
                yearCard(result: out.year1, expanded: $expandedYear1)
                yearCard(result: out.year2, expanded: $expandedYear2)
            }
        }
    }

    private func yearCard(
        result: SelfEmploymentYearResult,
        expanded: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Year \(result.year)")
                        .textStyle(Typography.bodyLg.withSize(14, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text("Annual cash flow")
                        .textStyle(Typography.num.withSize(11))
                        .foregroundStyle(Palette.inkTertiary)
                }
                Spacer()
                Text("$\(MoneyFormat.shared.decimalString(result.cashFlow))")
                    .textStyle(Typography.num.withSize(17, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.ink)
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
            .contentShape(Rectangle())
            .onTapGesture { expanded.wrappedValue.toggle() }

            if expanded.wrappedValue {
                divider
                lineItemBreakdown(result: result)
            }
        }
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
    }

    private func lineItemBreakdown(result: SelfEmploymentYearResult) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(result.addbacks.enumerated()), id: \.offset) { _, ab in
                lineItemRow(label: ab.label, amount: ab.amount, isDeduction: false)
            }
            ForEach(Array(result.deductions.enumerated()), id: \.offset) { _, d in
                lineItemRow(label: d.label, amount: d.amount, isDeduction: true)
            }
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s8)
    }

    private func lineItemRow(
        label: String,
        amount: Decimal,
        isDeduction: Bool
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .textStyle(Typography.body.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
            Spacer()
            Text((isDeduction ? "−$" : "+$") + MoneyFormat.shared.decimalString(amount))
                .textStyle(Typography.num.withSize(12, design: .monospaced))
                .foregroundStyle(isDeduction ? Palette.loss : Palette.gain)
        }
        .padding(.vertical, 3)
    }

    // MARK: Two-year block

    private var twoYearBlock: some View {
        guard let out = viewModel.output else { return AnyView(EmptyView()) }
        let avg = out.twoYearAverage
        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.s12) {
                Eyebrow("Two-year average")
                VStack(spacing: 0) {
                    twoYearRow("Year \(out.year1.year)", value: "$\(MoneyFormat.shared.decimalString(avg.year1CashFlow))")
                    divider
                    twoYearRow("Year \(out.year2.year)", value: "$\(MoneyFormat.shared.decimalString(avg.year2CashFlow))")
                    divider
                    twoYearRow("Average annual", value: "$\(MoneyFormat.shared.decimalString(avg.average))")
                    divider
                    twoYearRow("Qualifying annual",
                               value: "$\(MoneyFormat.shared.decimalString(avg.qualifyingAnnualIncome))",
                               accent: true)
                    divider
                    twoYearRow("Qualifying monthly",
                               value: "$\(MoneyFormat.shared.decimalString(avg.qualifyingMonthlyIncome))",
                               accent: true)
                }
                .background(Palette.surfaceRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.listCard)
                        .stroke(Palette.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
            }
        )
    }

    private func twoYearRow(_ label: String, value: String, accent: Bool = false) -> some View {
        HStack {
            Text(label)
                .textStyle(Typography.body.withSize(13, weight: accent ? .semibold : .regular))
                .foregroundStyle(accent ? Palette.ink : Palette.inkSecondary)
            Spacer()
            Text(value)
                .textStyle(Typography.num.withSize(14, weight: accent ? .semibold : .medium, design: .monospaced))
                .foregroundStyle(accent ? Palette.accent : Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    private var divider: some View {
        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
    }

    // MARK: Dock

    private var bottomDock: some View {
        if onImportMonthly != nil {
            return AnyView(importDock)
        }
        return AnyView(CalculatorDock(
            saveLabel: justSaved ? "Saved" : "Save",
            onNarrate: {},
            onSave: { saveScenario() },
            onShare: { generatePDFAndShare() }
        ))
    }

    private var importDock: some View {
        HStack(spacing: Spacing.s12) {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
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

            Button {
                onImportMonthly?(viewModel.qualifyingMonthly)
                dismiss()
            } label: {
                Text("Use this income")
                    .textStyle(Typography.bodyLg.withWeight(.semibold))
                    .foregroundStyle(Palette.accentFG)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s12)
                    .background(Palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("selfEmployment.useIncome")
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.top, Spacing.s12)
        .padding(.bottom, Spacing.s32)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle().fill(Palette.borderSubtle).frame(height: 1),
            alignment: .top
        )
    }

    // MARK: Save + share

    private func saveScenario() {
        let snap = viewModel.buildScenario()
        let name = viewModel.borrower?.fullName ?? "Self-employment"
        if let existing = existingScenario {
            existing.inputsJSON = snap.inputsJSON
            existing.keyStatLine = snap.keyStat
            existing.borrower = viewModel.borrower
            existing.name = name
            existing.updatedAt = Date()
        } else {
            let s = Scenario(
                borrower: viewModel.borrower,
                calculatorType: .selfEmployment,
                name: name,
                inputsJSON: snap.inputsJSON,
                keyStatLine: snap.keyStat
            )
            modelContext.insert(s)
        }
        try? modelContext.save()
        justSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { justSaved = false }
    }

    private func generatePDFAndShare() {
        guard let profile = profiles.first else { return }
        do {
            let url = try PDFBuilder.buildSelfEmploymentPDF(
                profile: profile,
                borrower: viewModel.borrower,
                viewModel: viewModel
            )
            shareBundle = ShareBundle(
                url: url,
                pageCount: PDFInspector(url: url)?.pageCount ?? 1,
                profile: profile
            )
        } catch {
            #if DEBUG
            print("[SelfEmploymentResultsScreen] PDF gen failed: \(error)")
            #endif
        }
    }
}
