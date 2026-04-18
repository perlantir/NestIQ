// Compare.swift
// Backbone for Refinance Comparison + Total Cost Analysis.
//
// For each scenario we amortize once, then compute per-horizon total cost
// and a bundle of comparison metrics relative to `scenarios[0]` (the
// baseline). Day-count convention is inherited from each scenario's loan.
//
// Total-cost framing at horizon H years:
//   total = closingCosts
//         + Σ (payment + pmi + extraPrincipal) for periods 1..H×12
//         + balance at period H×12 (payoff if sold)
//         + (monthlyTaxes + monthlyInsurance + monthlyHOA) × H×12
//
// Rationale: this mirrors how LOs present TCA — "cumulative cash out-of-
// pocket through the sale". Including the remaining balance at horizon makes
// scenarios with different terms directly comparable; excluding it would
// unfairly favor longer terms that defer principal.
//
// `breakEvenMonth` uses the simple (undiscounted) LO framing:
//   ceil((candidateClosingCosts − baselineClosingCosts) / (basePI − candPI))
//
// `npvAt5pct` is the present value of all outgoing cash flows at 5% annual
// discounted monthly, over `min(longestHorizon × 12, schedule.payments.count)`
// months. Signed negative (loans are costs).

import Foundation

/// Compare scenarios across horizons. See `ComparisonResult` / `ScenarioMetrics`.
///
/// - Parameters:
///   - scenarios: Ordered list; index 0 is the baseline for deltas and
///     break-even. An empty array produces an empty result.
///   - horizons: Horizons in years (e.g. `[5, 7, 10, 15, 30]`). Non-positive
///     values are accepted and produce total costs equal to closing costs
///     alone; duplicates are preserved; order is preserved.
/// - Returns: `ComparisonResult` with parallel-indexed total costs, per-
///   horizon winners, and per-scenario metrics.
public func compareScenarios(
    _ scenarios: [ScenarioInput],
    horizons: [Int]
) -> ComparisonResult {
    guard !scenarios.isEmpty else {
        return ComparisonResult(
            scenarioTotalCosts: [],
            winnerByHorizon: [],
            horizons: horizons,
            scenarioMetrics: []
        )
    }

    let schedules = scenarios.map { amortize(loan: $0.loan, options: $0.options) }

    let totalsByScenario: [[Decimal]] = zip(scenarios, schedules).map { sc, sch in
        horizons.map { years in
            totalCostAtHorizon(
                schedule: sch,
                years: years,
                closingCosts: sc.closingCosts,
                monthlyTaxes: sc.monthlyTaxes,
                monthlyInsurance: sc.monthlyInsurance,
                monthlyHOA: sc.monthlyHOA
            )
        }
    }

    let winners: [Int] = horizons.indices.map { hIdx in
        var minIdx = 0
        var minCost = totalsByScenario[0][hIdx]
        for sIdx in 1..<totalsByScenario.count where totalsByScenario[sIdx][hIdx] < minCost {
            minCost = totalsByScenario[sIdx][hIdx]
            minIdx = sIdx
        }
        return minIdx
    }

    let baseline = scenarios[0]
    let baselineSchedule = schedules[0]
    let basePayment = baselineSchedule.scheduledPeriodicPayment
    let longestHorizonYears = horizons.max() ?? 30
    let baselineLongestCost = totalsByScenario[0].last ?? 0

    let metrics: [ScenarioMetrics] = scenarios.indices.map { i in
        let sc = scenarios[i]
        let sch = schedules[i]
        let payment = sch.scheduledPeriodicPayment
        let delta = payment - basePayment

        let breakEven: Int? = i == 0 ? nil : breakEvenVsBaseline(
            candidate: sc,
            candidatePayment: payment,
            baseline: baseline,
            baselinePayment: basePayment
        )

        let npv5 = npvOfScenario(
            scenario: sc,
            schedule: sch,
            annualDiscount: 0.05,
            horizonMonths: longestHorizonYears * 12
        )

        let lifetimeDelta = (totalsByScenario[i].last ?? 0) - baselineLongestCost

        return ScenarioMetrics(
            payment: payment,
            totalInterest: sch.totalInterest,
            totalPaid: sch.totalPayments,
            breakEvenMonth: breakEven,
            npvAt5pct: npv5,
            monthlyPIDelta: delta,
            lifetimeCostDelta: lifetimeDelta
        )
    }

    return ComparisonResult(
        scenarioTotalCosts: totalsByScenario,
        winnerByHorizon: winners,
        horizons: horizons,
        scenarioMetrics: metrics
    )
}

// MARK: - Internals

func totalCostAtHorizon(
    schedule: AmortizationSchedule,
    years: Int,
    closingCosts: Decimal,
    monthlyTaxes: Decimal,
    monthlyInsurance: Decimal,
    monthlyHOA: Decimal
) -> Decimal {
    guard years > 0 else { return closingCosts }

    let monthsInHorizon = years * 12
    let cutoff = min(monthsInHorizon, schedule.payments.count)

    var cumulative: Decimal = closingCosts
    for row in schedule.payments.prefix(cutoff) {
        cumulative += row.payment + row.pmi + row.extraPrincipal
    }

    let balanceAtHorizon: Decimal
    if cutoff == 0 {
        balanceAtHorizon = schedule.loan.principal
    } else {
        balanceAtHorizon = schedule.payments[cutoff - 1].balance
    }
    cumulative += balanceAtHorizon

    let carryingMonths = Decimal(monthsInHorizon)
    cumulative += (monthlyTaxes + monthlyInsurance + monthlyHOA) * carryingMonths

    return cumulative.money()
}

func breakEvenVsBaseline(
    candidate: ScenarioInput,
    candidatePayment: Decimal,
    baseline: ScenarioInput,
    baselinePayment: Decimal
) -> Int? {
    let monthlySavings = baselinePayment - candidatePayment
    guard monthlySavings > 0 else { return nil }

    let upfront = candidate.closingCosts - baseline.closingCosts
    // Candidate already saves money and has no net closing-cost overhang —
    // break-even is immediate.
    if upfront <= 0 { return 0 }

    let ratio = upfront.asDouble / monthlySavings.asDouble
    return Int(ratio.rounded(.up))
}

/// Present value of scenario cash outflows at 5% annual, discounted monthly.
/// Outflows = upfront closing costs at month 0 + (payment + pmi + extra +
/// taxes + insurance + HOA) each month up to `horizonMonths` (or schedule
/// end, whichever comes first). Result is negative.
func npvOfScenario(
    scenario: ScenarioInput,
    schedule: AmortizationSchedule,
    annualDiscount: Double,
    horizonMonths: Int
) -> Decimal {
    let monthlyRate = annualDiscount / 12.0
    let cutoff = min(horizonMonths, schedule.payments.count)
    let carrying = scenario.monthlyTaxes + scenario.monthlyInsurance + scenario.monthlyHOA

    var acc = -scenario.closingCosts.asDouble
    for i in 0..<cutoff {
        let row = schedule.payments[i]
        let outflow = (row.payment + row.pmi + row.extraPrincipal + carrying).asDouble
        acc -= outflow / pow(1.0 + monthlyRate, Double(i + 1))
    }
    return acc.asDecimal.money()
}
