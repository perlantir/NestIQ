// TCAInputs+Engine.swift
// Session 5R.2 — extracts `scenarioInputs()` + MI plumbing from
// TCAInputs.swift to stay under SwiftLint's file_length cap.
//
// Two 5R.2 fixes live here:
//   1. No double-charging points. `ClosingCostBreakdown` (5B.5)
//      established that `scenario.closingCosts` is all-in (includes
//      the dollar value of any point buydowns). The pre-5R.2 helper
//      added `principal × points / 100` on top, inflating break-even
//      month + unrecoverable cost + horizon totals.
//   2. Monthly MI is now forwarded to the engine via an
//      `AmortizationOptions.pmiSchedule`. Before, MI was collected
//      on the Inputs screen and displayed on the results spec card
//      but silently dropped by `scenarioInputs()` — `cumulativeMI`
//      returned zero and unrecoverable costs understated by MI.

import Foundation
import QuotientFinance

extension TCAFormInputs {

    func scenarioInputs() -> [ScenarioInput] {
        scenarios.map { s in
            ScenarioInput(
                name: s.label,
                loan: Loan(
                    principal: effectiveLoanAmount(for: s),
                    annualRate: s.rate / 100,
                    termMonths: s.termYears * 12,
                    startDate: Date()
                ),
                closingCosts: s.closingCosts,
                monthlyTaxes: monthlyTaxes,
                monthlyInsurance: monthlyInsurance,
                monthlyHOA: monthlyHOA,
                options: amortizationOptionsForMI(scenario: s)
            )
        }
    }

    /// Build AmortizationOptions carrying the per-scenario PMI
    /// schedule. Drops at HPA 78% when the originating home value is
    /// known; treats MI as permanent when it isn't (conservative —
    /// LO-entered MI without an appraised value flows through
    /// life-of-loan so unrecoverable costs don't silently zero out
    /// after the first few months).
    func amortizationOptionsForMI(scenario: TCAScenario) -> AmortizationOptions {
        guard scenario.monthlyMI > 0 else { return .none }
        let appraised: Decimal = {
            switch mode {
            case .purchase: return scenario.propertyDP.purchasePrice
            case .refinance: return homeValue
            }
        }()
        if appraised > 0 {
            return AmortizationOptions(
                pmiSchedule: PMISchedule(
                    monthlyAmount: scenario.monthlyMI,
                    originalValue: appraised,
                    dropAtLTV: 0.78,
                    minimumPeriods: 0,
                    isPermanent: false
                )
            )
        }
        return AmortizationOptions(
            pmiSchedule: PMISchedule(
                monthlyAmount: scenario.monthlyMI,
                originalValue: 0,
                dropAtLTV: 0.78,
                minimumPeriods: 0,
                isPermanent: true
            )
        )
    }
}
