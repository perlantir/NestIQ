// RefinanceViewModel.swift
// Runs compareScenarios() against the current loan + up to 3 options.
// Selected option drives the winner hero + bold-winner curve on the
// cumulative-savings chart.

import Foundation
import Observation
import QuotientFinance

@MainActor
@Observable
final class RefinanceViewModel {
    var inputs: RefinanceFormInputs
    var borrower: Borrower?
    var selectedOptionIndex: Int = 1  // 0 = current, 1+ = options
    var result: QuotientFinance.ComparisonResult?

    init(inputs: RefinanceFormInputs = .sampleDefault, borrower: Borrower? = nil) {
        self.inputs = inputs
        self.borrower = borrower
    }

    func compute() {
        let scenarios = inputs.scenarioInputs()
        result = compareScenarios(scenarios, horizons: inputs.horizonsYears)
    }

    var current: ScenarioMetrics? {
        guard let result, !result.scenarioMetrics.isEmpty else { return nil }
        return result.scenarioMetrics[0]
    }

    var selected: ScenarioMetrics? {
        guard let result,
              selectedOptionIndex < result.scenarioMetrics.count else { return nil }
        return result.scenarioMetrics[selectedOptionIndex]
    }

    /// Positive = monthly savings vs current.
    var monthlySavings: Decimal {
        guard let cur = current, let sel = selected else { return 0 }
        return max(cur.payment - sel.payment, 0)
    }

    /// Present value savings = current NPV - selected NPV. Signed: + good.
    var npvDelta: Decimal {
        guard let cur = current, let sel = selected else { return 0 }
        return sel.npvAt5pct - cur.npvAt5pct
    }

    /// Signed savings across the longest horizon. + means the selected
    /// refi saves the borrower that amount over the horizon.
    var lifetimeDelta: Decimal {
        guard let result,
              let lastH = result.horizons.last,
              let hIdx = result.horizons.firstIndex(of: lastH),
              selectedOptionIndex < result.scenarioTotalCosts.count else { return 0 }
        let currentCost = result.scenarioTotalCosts[0][hIdx]
        let selCost = result.scenarioTotalCosts[selectedOptionIndex][hIdx]
        return currentCost - selCost
    }

    var breakEvenMonth: Int? { selected?.breakEvenMonth }

    /// Cumulative-savings curve — net (monthly savings × m) − (closing
    /// cost delta). Sampled monthly for the chart.
    func cumulativeSavings(for optionIndex: Int, monthsCap: Int = 60) -> [(Int, Decimal)] {
        guard let result,
              optionIndex < result.scenarioMetrics.count,
              optionIndex > 0 else { return [] }
        let cur = result.scenarioMetrics[0]
        let sel = result.scenarioMetrics[optionIndex]
        let monthlySavings = max(cur.payment - sel.payment, 0)
        let closingCostDelta = inputs.options[optionIndex - 1].closingCosts
        var rows: [(Int, Decimal)] = []
        for m in 0...monthsCap {
            let v = monthlySavings * Decimal(m) - closingCostDelta
            rows.append((m, v))
        }
        return rows
    }

    func buildScenarioSnapshot() -> AmortizationViewModel.ScenarioSnapshot {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let inputsJSON = (try? encoder.encode(inputs)) ?? Data()
        let monthly = MoneyFormat.shared.decimalString(monthlySavings)
        let be = breakEvenMonth.map { "\($0) mo" } ?? "—"
        let key = "save $\(monthly)/mo · break-even \(be)"
        return AmortizationViewModel.ScenarioSnapshot(
            inputsJSON: inputsJSON,
            outputsJSON: nil,
            keyStat: key
        )
    }
}
