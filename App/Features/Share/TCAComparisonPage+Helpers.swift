// TCAComparisonPage+Helpers.swift
// Session 5M.7: pure helper methods extracted from TCAComparisonPage
// so the main struct stays under SwiftLint's type_body_length cap
// once the 5M analytics summaries (unrecoverable, break-even) land.

import Foundation
import QuotientFinance

extension TCAComparisonPage {

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
