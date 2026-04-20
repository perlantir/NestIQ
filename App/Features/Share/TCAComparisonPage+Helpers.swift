// TCAComparisonPage+Helpers.swift
// Session 5M.7: pure helper methods extracted from TCAComparisonPage
// so the main struct stays under SwiftLint's type_body_length cap
// once the 5M analytics summaries (unrecoverable, break-even) land.

import Foundation
import SwiftUI
import QuotientFinance

extension TCAComparisonPage {

    /// Session 5M.8: compact reinvestment summary per non-baseline
    /// scenario — longest-horizon invest balance + payoff acceleration
    /// snapshot. Full per-horizon breakdown + disclaimer live on the
    /// in-app Results view; the PDF glossary footer carries the
    /// "illustrative" caveat.
    @ViewBuilder var reinvestmentSummary: some View {
        if viewModel.inputs.mode == .refinance,
           viewModel.inputs.scenarios.count > 1,
           !viewModel.scenarioSchedules.isEmpty,
           let metrics = viewModel.result?.scenarioMetrics {
            let payments = metrics.map(\.payment)
            let longest = viewModel.inputs.horizonsYears.max() ?? 30
            let ratePct = viewModel.inputs.reinvestmentRate.asDouble * 100
            let parts = reinvestmentParts(
                longest: longest,
                monthlyPayments: payments
            )
            VStack(alignment: .leading, spacing: 2) {
                Text("Reinvest @ " + String(format: "%.2f%%", ratePct))
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255))
                    .padding(.leading, 16)
                Text(parts.joined(separator: "  ·  "))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x0F / 255))
                    .padding(.leading, 16)
            }
        }
    }

    /// Session 5M.9: compact equity summary for the PDF — one line of
    /// per-scenario longest-horizon equity values. Full per-horizon
    /// matrix lives on the in-app Results view.
    @ViewBuilder var equitySummary: some View {
        if !viewModel.scenarioSchedules.isEmpty {
            let longest = viewModel.inputs.horizonsYears.max() ?? 30
            let parts = equityParts(longest: longest)
            if !parts.isEmpty {
                HStack(spacing: 6) {
                    Text("Equity @ \(longest)yr")
                        .font(.system(size: 9.5, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255))
                    Text(parts.joined(separator: "  ·  "))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x0F / 255))
                }
                .padding(.leading, 16)
            }
        }
    }

    private func equityParts(longest: Int) -> [String] {
        Array(viewModel.inputs.scenarios.enumerated()).compactMap { idx, s -> String? in
            guard idx < viewModel.scenarioSchedules.count else { return nil }
            let equity = viewModel.inputs.equityAtHorizon(
                scenarioIndex: idx,
                schedule: viewModel.scenarioSchedules[idx],
                years: longest
            )
            return "\(s.label): " + MoneyFormat.shared.dollarsShort(equity)
        }
    }

    private func reinvestmentParts(longest: Int, monthlyPayments: [Decimal]) -> [String] {
        Array(viewModel.inputs.scenarios.enumerated()).compactMap { idx, s -> String? in
            guard idx > 0 else { return nil }
            let invest = viewModel.inputs.pathAInvestmentBalance(
                scenarioIndex: idx,
                months: longest * 12,
                monthlyPayments: monthlyPayments
            )
            let investStr = MoneyFormat.shared.dollarsShort(invest)
            guard idx < viewModel.scenarioSchedules.count,
                  let pathB = viewModel.inputs.pathBExtraPrincipal(
                    scenarioIndex: idx,
                    schedule: viewModel.scenarioSchedules[idx],
                    monthlyPayments: monthlyPayments
                  )
            else {
                return "\(s.label): inv \(investStr) @ \(longest)yr"
            }
            let monthsSaved = pathB.originalPayoffMonth - pathB.newPayoffMonth
            let wealth = MoneyFormat.shared.dollarsShort(pathB.wealthBuilt)
            return "\(s.label): inv \(investStr) @ \(longest)yr · payoff -\(monthsSaved)mo (\(wealth))"
        }
    }

    /// Compact unrecoverable $ per scenario for the PDF summary row.
    /// Returns "—" when we don't have a schedule for that scenario yet.
    func unrecoverableDollar(
        scenarioIndex: Int,
        scenario: TCAScenario,
        years: Int,
        schedules: [AmortizationSchedule]
    ) -> String {
        guard scenarioIndex < schedules.count else { return "—" }
        let unrecoverable = viewModel.inputs.unrecoverableCost(
            scenario: scenario,
            schedule: schedules[scenarioIndex],
            years: years
        )
        return MoneyFormat.shared.dollarsShort(unrecoverable)
    }

    /// Interest vs principal split for a given scenario's schedule at
    /// the specified horizon years. Formats "XX% int / YY% prin".
    func interestPrincipalSplit(schedule: AmortizationSchedule, years: Int) -> String {
        let month = years * 12
        let interest = schedule.cumulativeInterest(throughMonth: month)
        let principal = schedule.cumulativePrincipal(throughMonth: month)
        let total = interest + principal
        guard total > 0 else { return "—" }
        let intPct = (interest.asDouble / total.asDouble) * 100
        let prinPct = 100 - intPct
        return String(format: "%.0f%% int / %.0f%% prin", intPct, prinPct)
    }
}
