// TCAInputs+CurrentMortgage.swift
// Session 5Q.4 — status-quo horizon helpers. The refi-mode TCA
// Results screen (+ PDF) renders a "Current" column alongside the
// proposed scenarios so LOs can narrate "stay put vs refinance"
// across horizons. Each helper answers one cell of that column.
//
// Extracted from TCAInputs.swift to keep that file under SwiftLint's
// file_length cap. All helpers operate on `self.currentMortgage`
// (Session 5P.8) and fall back to zero / empty displays when the
// mortgage is absent or has passed its original term.

import Foundation
import QuotientFinance

extension TCAFormInputs {

    /// Amortize the borrower's status-quo loan forward from today
    /// through its remaining term. Returns nil in purchase mode,
    /// when no `currentMortgage` is set, or when the loan has run
    /// past its original term (no months remaining to amortize).
    func buildCurrentMortgageSchedule() -> AmortizationSchedule? {
        guard mode == .refinance, let cm = currentMortgage else { return nil }
        let remaining = CurrentMortgageCalculations.monthsRemaining(
            originalTermYears: cm.originalTermYears,
            loanStartDate: cm.loanStartDate
        )
        guard remaining > 0, cm.currentBalance > 0 else { return nil }
        let loan = Loan(
            principal: cm.currentBalance,
            annualRate: cm.currentRatePercent.asDouble / 100,
            termMonths: remaining,
            startDate: Date()
        )
        return amortize(loan: loan)
    }

    /// Cumulative P&I paid on the status-quo loan over `years`.
    /// Uses the borrower's stated monthly P&I so the display matches
    /// what the borrower actually sends the lender. Capped at the
    /// loan's remaining months — no cost accrues past payoff.
    func currentHorizonCost(years: Int) -> Decimal {
        guard mode == .refinance, let cm = currentMortgage else { return 0 }
        let horizonMonths = Swift.max(0, years * 12)
        let remaining = CurrentMortgageCalculations.monthsRemaining(
            originalTermYears: cm.originalTermYears,
            loanStartDate: cm.loanStartDate
        )
        let months = Swift.min(horizonMonths, remaining)
        return cm.currentMonthlyPaymentPI * Decimal(months)
    }

    /// Unrecoverable portion of staying on the current mortgage
    /// through `years` = cumulative interest paid. No closing costs
    /// (those were paid years ago at origination); no MI (not
    /// captured on the `CurrentMortgage` model).
    func currentHorizonUnrecoverable(
        schedule: AmortizationSchedule?, years: Int
    ) -> Decimal {
        guard let schedule else { return 0 }
        return schedule.cumulativeInterest(throughMonth: Swift.max(0, years * 12))
    }

    /// Equity at horizon on the status-quo loan: propertyValueToday
    /// minus remaining balance at that month. Flat home value, same
    /// convention as `equityAtHorizon`. Clamped non-negative.
    func currentHorizonEquity(
        schedule: AmortizationSchedule?, years: Int
    ) -> Decimal {
        guard mode == .refinance, let cm = currentMortgage else { return 0 }
        let propertyValue = cm.propertyValueToday
        guard propertyValue > 0 else { return 0 }
        let month = Swift.max(0, years * 12)
        let remaining: Decimal
        if let schedule {
            if month == 0 {
                remaining = cm.currentBalance
            } else if month >= schedule.payments.count {
                remaining = 0
            } else {
                remaining = schedule.payments[month - 1].balance
            }
        } else {
            // No schedule: the original term has elapsed — balance 0.
            remaining = 0
        }
        return (propertyValue - remaining).clampedNonNegative
    }
}
