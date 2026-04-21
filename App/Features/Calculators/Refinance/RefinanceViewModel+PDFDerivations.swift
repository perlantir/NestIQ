// RefinanceViewModel+PDFDerivations.swift
// Session 7.3c — derivations backing the v2.1.1 refi PDF template tokens.
//
// Mirrors the HELOC pattern (HelocViewModel+PDFDerivations.swift): pure
// Swift math, no new QuotientFinance additions. The 7.3f builder rewrite
// pulls from these properties instead of hardcoding demo values.

import Foundation
import QuotientFinance

extension RefinanceViewModel {

    // MARK: - Current-loan derivations

    /// Monthly P&I on the borrower's current loan. Drives the
    /// `{{current_monthly_pi_formatted}}` token (page 2 "vs current"
    /// label, page 3 assumptions box).
    var currentMonthlyPI: Decimal {
        guard inputs.currentBalance > 0, inputs.currentRemainingYears > 0 else {
            return 0
        }
        let loan = Loan(
            principal: inputs.currentBalance,
            annualRate: inputs.currentRate / 100,
            termMonths: inputs.currentRemainingYears * 12,
            startDate: Date()
        )
        return paymentFor(loan: loan)
    }

    // MARK: - Per-option derivations

    /// ScenarioMetrics for option A/B/C (optionIndex 0/1/2), or nil
    /// when the scenario hasn't been computed yet.
    func metrics(forOptionAt optionIndex: Int) -> ScenarioMetrics? {
        guard let result,
              optionIndex >= 0,
              optionIndex < inputs.options.count else { return nil }
        let scenarioIndex = optionIndex + 1  // 0 = current in scenarioMetrics
        guard scenarioIndex < result.scenarioMetrics.count else { return nil }
        return result.scenarioMetrics[scenarioIndex]
    }

    /// Signed P&I delta vs the current loan for the given option.
    /// Negative = option saves money monthly (typical).
    func paymentDelta(forOptionAt optionIndex: Int) -> Decimal {
        guard let m = metrics(forOptionAt: optionIndex) else { return 0 }
        return m.payment - currentMonthlyPI
    }

    /// Percent delta vs current payment (signed). E.g., −7.7 for a
    /// 7.7% reduction. Matches `{{option_X_pi_delta_pct}}` semantics
    /// once Swift prefixes the sign + "%".
    func paymentDeltaPct(forOptionAt optionIndex: Int) -> Decimal {
        guard currentMonthlyPI > 0 else { return 0 }
        let delta = paymentDelta(forOptionAt: optionIndex)
        return delta / currentMonthlyPI * 100
    }

    /// Total interest the borrower would pay over the full term of the
    /// given option. `{{option_X_interest_remaining_formatted}}`.
    func interestOverTerm(forOptionAt optionIndex: Int) -> Decimal {
        guard optionIndex >= 0, optionIndex < inputs.options.count else { return 0 }
        let option = inputs.options[optionIndex]
        let principal = inputs.effectiveLoanAmount(for: option)
        guard principal > 0, option.termYears > 0 else { return 0 }
        return amortizedTotalInterest(
            principal: principal,
            annualRatePct: option.rate,
            termMonths: option.termYears * 12
        )
    }

    /// Derived discount-points dollar amount (1 point = 1% of loan
    /// amount). For the `{{option_X_discount_points_formatted}}` cell.
    /// Returns 0 when points == 0 — callers render em-dash "—" in that
    /// case per the template convention.
    func discountPointsAmount(forOptionAt optionIndex: Int) -> Decimal {
        guard optionIndex >= 0, optionIndex < inputs.options.count else { return 0 }
        let option = inputs.options[optionIndex]
        guard option.points > 0 else { return 0 }
        let principal = inputs.effectiveLoanAmount(for: option)
        return principal * Decimal(option.points) / 100
    }

    /// Lifetime savings vs the current loan over the longest horizon,
    /// for option at `optionIndex`. Positive = option saves money.
    /// `{{option_X_lifetime_savings_formatted}}`.
    func lifetimeSavings(forOptionAt optionIndex: Int) -> Decimal {
        guard let result,
              let lastH = result.horizons.last,
              let hIdx = result.horizons.firstIndex(of: lastH),
              optionIndex >= 0 else { return 0 }
        let scenarioIndex = optionIndex + 1
        guard scenarioIndex < result.scenarioTotalCosts.count else { return 0 }
        let currentCost = result.scenarioTotalCosts[0][hIdx]
        let optionCost = result.scenarioTotalCosts[scenarioIndex][hIdx]
        return currentCost - optionCost
    }

    /// Break-even month for the given option (or nil when not
    /// applicable — the option never pays back its closing cost delta
    /// vs current). `{{option_X_breakeven_label}}` — Swift formats
    /// "47 mo" or "n/a".
    func breakEvenMonth(forOptionAt optionIndex: Int) -> Int? {
        metrics(forOptionAt: optionIndex)?.breakEvenMonth
    }

    // MARK: - Recommended option derivations

    /// Years remaining on the recommended option's term — drives the
    /// page 1 hero "remaining N yrs · net of costs" via
    /// `{{recommended_remaining_years}}`.
    var recommendedRemainingYears: Int {
        guard let option = recommendedOption else { return inputs.currentRemainingYears }
        return option.termYears
    }

    /// The currently-selected option (selectedOptionIndex is 1-based
    /// against scenarioMetrics; maps back to `inputs.options[idx - 1]`).
    var recommendedOption: RefiOption? {
        let optionIdx = selectedOptionIndex - 1
        guard optionIdx >= 0, optionIdx < inputs.options.count else { return nil }
        return inputs.options[optionIdx]
    }

    // MARK: - Private helpers

    /// Total interest paid over a fully-amortizing loan's entire term:
    /// `payment × months − principal`. Simple and engine-free.
    private func amortizedTotalInterest(
        principal: Decimal,
        annualRatePct: Double,
        termMonths: Int
    ) -> Decimal {
        guard termMonths > 0 else { return 0 }
        let r = annualRatePct / 100 / 12
        let n = Double(termMonths)
        if r == 0 { return 0 }
        let factor = (r * pow(1 + r, n)) / (pow(1 + r, n) - 1)
        let payment = principal * Decimal(factor)
        return payment * Decimal(termMonths) - principal
    }
}
