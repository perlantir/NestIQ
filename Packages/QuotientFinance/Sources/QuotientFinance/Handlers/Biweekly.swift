// Biweekly.swift
// Convert a schedule to a biweekly cadence.
//
// Biweekly schedules pay every 14 days — 26 payments per 364-day window —
// with each payment sized at half the equivalent monthly P&I. The practical
// effect is 13 monthly-equivalent payments per year, retiring a 30-year term
// several years early with no change to the note rate.
//
// Day-count convention: whatever the underlying loan declares. Conventional
// biweekly programs use 30/360 just like their monthly counterparts — the
// engine's `periodRate` helper derives the right per-period rate from
// `loan.dayCount` × `frequency.averageDaysPerPeriod`.

import Foundation

/// Rebuild `schedule` as a biweekly-cadence amortization of the same loan.
///
/// The returned schedule uses the same principal, rate, term, startDate, and
/// loan/rate type, with `frequency = .biweekly`. The underlying engine
/// constructs a fresh schedule; extras, PMI, and recast periods from the
/// source are intentionally **dropped** — their period-number semantics
/// don't translate 1:1 across cadences (a "month-24 recast" has no biweekly
/// equivalent), and preserving them would produce wrong-but-plausible
/// output. Callers that want biweekly + extras should compose:
/// `applyExtraPrincipal(schedule: convertToBiweekly(schedule: x), extra: ...)`.
///
/// If `schedule.loan.frequency` is already `.biweekly`, returns a fresh
/// amortization with empty options (same drop-the-extras behavior).
public func convertToBiweekly(schedule: AmortizationSchedule) -> AmortizationSchedule {
    let src = schedule.loan
    let biweeklyLoan = Loan(
        principal: src.principal,
        annualRate: src.annualRate,
        termMonths: src.termMonths,
        loanType: src.loanType,
        rateType: src.rateType,
        startDate: src.startDate,
        frequency: .biweekly
    )
    return amortize(loan: biweeklyLoan, options: .none)
}
