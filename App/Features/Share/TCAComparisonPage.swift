// TCAComparisonPage.swift
// Landscape (792×612) PDF page for Total Cost Analysis. Two stacked
// blocks — scenario spec grid (rate, pts, term, monthly P&I, closing
// costs) + horizons × total cost matrix with per-row winner highlight.

import SwiftUI
import QuotientFinance

struct TCAComparisonPage: View {
    let borrowerName: String
    let generatedDate: String
    let loFullName: String
    let loNMLSLine: String
    let viewModel: TCAViewModel
    let disclaimer: String
    let ehoStatement: String
    let accentHex: String
    let scenarioColors: [Color]
    let pageIndex: Int
    let pageCount: Int

    private let inkPrimary = Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x0F / 255)
    private let inkSecondary = Color(red: 0x4A / 255, green: 0x48 / 255, blue: 0x40 / 255)
    private let inkTertiary = Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255)
    private let border = Color(red: 0xE5 / 255, green: 0xE1 / 255, blue: 0xD5 / 255)
    private var accent: Color { Color(brandHex: accentHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PDFPageHeader(pageIndex: pageIndex, pageCount: pageCount, date: generatedDate)
                .padding(.bottom, 20)
            header
            scenarioSpecGrid
                .padding(.top, 18)
            matrix
                .padding(.top, 14)
            interestPrincipalMatrix
                .padding(.top, 10)
            unrecoverableSummary
                .padding(.top, 10)
            breakEvenSummary
                .padding(.top, 8)
            reinvestmentSummary
                .padding(.top, 6)
            equitySummary
                .padding(.top, 6)
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 28)
        .frame(width: 792, height: 612)
        .background(Color.white)
    }

    /// Session 5M.5: "Interest vs principal" compact matrix beneath the
    /// total-cost matrix on the comparison page. Same row layout; each
    /// cell renders "XX% int / YY% prin".
    private var interestPrincipalMatrix: some View {
        let schedules = viewModel.scenarioSchedules
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("Int vs principal")
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(inkTertiary)
                    .frame(width: 92, alignment: .leading)
                    .padding(.leading, 16)
                ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.element.id) { idx, _ in
                    Color.clear
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.trailing, 16)
                        .id(idx)
                }
            }
            .padding(.vertical, 6)
            .overlay(alignment: .bottom) {
                Rectangle().fill(border).frame(height: 1)
            }
            ForEach(Array(viewModel.inputs.horizonsYears.enumerated()), id: \.offset) { _, years in
                HStack(spacing: 0) {
                    Text("\(years)-yr")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(inkSecondary)
                        .frame(width: 92, alignment: .leading)
                        .padding(.leading, 16)
                    ForEach(Array(schedules.enumerated()), id: \.offset) { _, schedule in
                        Text(interestPrincipalSplit(schedule: schedule, years: years))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(inkPrimary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 16)
                    }
                }
                .padding(.vertical, 6)
                Rectangle().fill(border).frame(height: 1)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// Session 5M.6: compact unrecoverable summary for the PDF. One
    /// line of horizon totals per scenario (for the longest horizon +
    /// one shorter), plus an "Ongoing housing" line derived from
    /// taxes + insurance + HOA × horizon months. Full per-horizon
    /// matrix lives on the in-app Results view — the PDF would overflow
    /// with another 5-row matrix.
    private var unrecoverableSummary: some View {
        let schedules = viewModel.scenarioSchedules
        let longest = viewModel.inputs.horizonsYears.max() ?? 30
        let monthlyOngoing = viewModel.inputs.monthlyTaxes
            + viewModel.inputs.monthlyInsurance
            + viewModel.inputs.monthlyHOA
        let ongoing = monthlyOngoing * Decimal(longest * 12)
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 0) {
                Text("Unrecoverable @ \(longest)yr")
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(inkTertiary)
                    .frame(width: 92, alignment: .leading)
                    .padding(.leading, 16)
                ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.offset) { idx, s in
                    Text(unrecoverableDollar(scenarioIndex: idx, scenario: s, years: longest, schedules: schedules))
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(inkPrimary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 16)
                }
            }
            Text("Ongoing housing @ \(longest)yr: \(MoneyFormat.shared.dollarsShort(ongoing)) (tax/ins/HOA — paid regardless)")
                .font(.system(size: 8.5))
                .foregroundStyle(inkTertiary)
                .padding(.leading, 16)
        }
    }

    /// Session 5M.7: refinance-mode break-even summary per scenario.
    /// Compact one-liner (full graph lives on the in-app Results view —
    /// the comparison PDF page is already dense). Only rendered in
    /// refi mode with > 1 scenario; otherwise an empty view.
    @ViewBuilder private var breakEvenSummary: some View {
        if viewModel.inputs.mode == .refinance,
           viewModel.inputs.scenarios.count > 1,
           let metrics = viewModel.result?.scenarioMetrics {
            let payments = metrics.map(\.payment)
            let parts = Array(viewModel.inputs.scenarios.enumerated()).compactMap { idx, s -> String? in
                guard idx > 0 else { return nil }
                if let month = viewModel.inputs.breakEvenMonth(
                    scenarioIndex: idx,
                    monthlyPayments: payments
                ) {
                    let years = Double(month) / 12.0
                    return String(format: "%@: mo %d (~%.1fyr)", s.label, month, years)
                }
                return "\(s.label): never (within \(s.termYears)yr)"
            }
            HStack(spacing: 6) {
                Text("Break-even")
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(inkTertiary)
                Text(parts.joined(separator: "  ·  "))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(inkPrimary)
            }
            .padding(.leading, 16)
        }
    }

    // reinvestmentSummary (5M.8) + unrecoverableDollar +
    // interestPrincipalSplit (5M.5/5M.6) live in
    // TCAComparisonPage+Helpers.swift to keep this struct under
    // SwiftLint's type_body_length cap.

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total cost analysis".uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(accent)
            Text("For ")
                .font(.custom("SourceSerif4", size: 26))
                .foregroundStyle(inkPrimary)
                +
                Text(borrowerName)
                .font(.custom("SourceSerif4-It", size: 26))
                .foregroundStyle(inkPrimary)
            Rectangle().fill(inkPrimary).frame(height: 1.5)
        }
    }

    private var scenarioSpecGrid: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 92)
            ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.element.id) { idx, s in
                let metrics = viewModel.result?.scenarioMetrics
                let pmt = metrics.flatMap {
                    idx < $0.count ? MoneyFormat.shared.currency($0[idx].payment) : "—"
                } ?? "—"
                let loan = MoneyFormat.shared.dollarsShort(
                    viewModel.inputs.effectiveLoanAmount(for: s)
                )
                let ltv = viewModel.inputs.ltv(for: s)
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.label.uppercased() + " · " + s.name)
                        .font(.system(size: 10.5, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(scenarioColors[min(idx, scenarioColors.count - 1)])
                    Text(String(format: "%.3f%% · %d yr", s.rate, s.termYears))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(inkPrimary)
                    if let apr = s.aprRate {
                        Text(String(format: "%.3f%% APR", apr.asDouble))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(inkSecondary)
                    }
                    Text("Loan \(loan)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(inkSecondary)
                    if ltv > 0 {
                        Text(String(format: "LTV %.1f%%", ltv * 100))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(inkSecondary)
                    }
                    if s.monthlyMI > 0 {
                        Text("MI " + MoneyFormat.shared.currency(s.monthlyMI) + "/mo")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(inkSecondary)
                    }
                    Text(String(format: "pts %.2f · close $%@",
                                s.points,
                                MoneyFormat.shared.decimalString(s.closingCosts)))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(inkSecondary)
                    Text("Approx cash " + MoneyFormat.shared.dollarsShort(
                        viewModel.inputs.approximateCashToClose(for: s)))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(inkPrimary)
                    Text("Mo " + pmt)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(inkSecondary)
                    if let impact = pdfMonthlyImpact(for: s, at: idx) {
                        Text("Mo total " + impact.total)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(inkPrimary)
                        Text(impact.delta)
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundStyle(inkSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .overlay(alignment: .trailing) {
                    if idx < viewModel.inputs.scenarios.count - 1 {
                        Rectangle().fill(border).frame(width: 1)
                    }
                }
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var matrix: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("Horizon")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(inkTertiary)
                    .frame(width: 92, alignment: .leading)
                    .padding(.leading, 16)
                ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.element.id) { idx, s in
                    Text(s.label.uppercased())
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(scenarioColors[min(idx, scenarioColors.count - 1)])
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 16)
                }
            }
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) {
                Rectangle().fill(border).frame(height: 1)
            }

            ForEach(Array(viewModel.inputs.horizonsYears.enumerated()), id: \.offset) { hIdx, years in
                matrixRow(hIdx: hIdx, years: years)
                Rectangle().fill(border).frame(height: 1)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func matrixRow(hIdx: Int, years: Int) -> some View {
        guard let result = viewModel.result,
              hIdx < (result.scenarioTotalCosts.first?.count ?? 0) else {
            return AnyView(EmptyView())
        }
        // Mirror the in-app rule: when the "Include consumer debts" toggle
        // is on and we're in refi mode, each scenario's horizon cost adds
        // its remaining-debt monthly × horizon months. Matches TCAScreen.
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
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(inkSecondary)
                    .frame(width: 92, alignment: .leading)
                    .padding(.leading, 16)
                ForEach(costs.indices, id: \.self) { i in
                    let value = costs[i]
                    let isW = i == winner
                    HStack(spacing: 3) {
                        if isW {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(accent)
                        }
                        Text(dollarsShort(value))
                            .font(.system(size: 12, weight: isW ? .semibold : .regular, design: .monospaced))
                            .foregroundStyle(isW ? accent : inkPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 16)
                }
            }
            .padding(.vertical, 9)
        )
    }

    private func dollarsShort(_ value: Decimal) -> String {
        let d = Double(truncating: value as NSNumber)
        if d >= 1_000_000 { return String(format: "$%.2fM", d / 1_000_000) }
        return String(format: "$%.0fk", d / 1_000)
    }

    private struct PDFMonthlyImpact {
        let total: String
        let delta: String
    }

    private func pdfMonthlyImpact(for scenario: TCAScenario, at index: Int)
        -> PDFMonthlyImpact?
    {
        guard viewModel.inputs.mode == .refinance else { return nil }
        guard viewModel.inputs.includeDebts else { return nil }
        guard let metrics = viewModel.result?.scenarioMetrics,
              index < metrics.count else { return nil }
        let debts = scenario.otherDebts ?? viewModel.inputs.currentOtherDebts
        guard let debts, !debts.isZero else { return nil }
        let total = metrics[index].payment + debts.monthlyPayment
        let currentDebts = viewModel.inputs.currentOtherDebts?.monthlyPayment ?? 0
        let baseline = metrics[0].payment + currentDebts
        let savings = baseline - total
        let deltaStr: String
        if savings > 0 {
            deltaStr = "Saves \(MoneyFormat.shared.currency(savings))/mo"
        } else if savings < 0 {
            deltaStr = "Costs \(MoneyFormat.shared.currency(abs(savings)))/mo more"
        } else {
            deltaStr = "Matches current monthly"
        }
        return PDFMonthlyImpact(total: MoneyFormat.shared.currency(total), delta: deltaStr)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle().fill(border).frame(height: 1).padding(.bottom, 6)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        "Unrecoverable costs are the portion of your housing cost that doesn't build equity "
                        + "or transfer to you (interest, mortgage insurance, closing costs). Ongoing housing "
                        + "costs (taxes, insurance, HOA) are shown separately because they apply regardless "
                        + "of owning or renting. Reinvestment figures are illustrative — past performance is "
                        + "not indicative of future results."
                    )
                    .font(.system(size: 8.5))
                    .foregroundStyle(inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    Text(disclaimer)
                        .font(.system(size: 8.5))
                        .foregroundStyle(inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(ehoStatement)
                        .font(.system(size: 8.5))
                        .foregroundStyle(inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 16)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(loFullName)
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(inkSecondary)
                    Text(loNMLSLine)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(inkTertiary)
                }
            }
        }
    }
}
