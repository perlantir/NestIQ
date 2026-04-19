// Biweekly.swift
// Two distinct biweekly primitives on top of the monthly amortization engine:
//
// 1. `convertToBiweekly(schedule:)` — re-slices a monthly schedule into a
//    26-period-per-year cadence that amortizes over the *same calendar term*.
//    Payment is solved by the engine as monthlyPMT-equivalent-at-biweekly-
//    rate; total interest and payoff date land within ~1 month / ~$500 of
//    the monthly source. This is the neutral "biweekly cadence" primitive —
//    useful when the loan product itself schedules biweekly, not when a
//    borrower wants to accelerate payoff. **Does not shorten term.**
//
// 2. `biweeklyAccelerated(schedule:)` — the what-Americans-mean biweekly
//    program. Pay monthlyPMT / 2 every 14 days; 26 half-payments per year
//    equals 13 monthly-equivalents per year; extra principal retires a
//    typical 30-yr note in ~22-26 years with materially lower interest.
//    **Shortens term and reduces interest.**
//
// Day-count convention:
// - `convertToBiweekly` delegates to `amortize(loan:)`, so interest accrues
//   under whatever the loan's dayCount resolves to (thirty360 for
//   conventional fixed, actual365 for HELOCs, etc.).
// - `biweeklyAccelerated` uses a fixed actual/365 14-day accrual:
//   `interest = balance × (annualRate × 14 / 365)`. This matches how US
//   lenders operate accelerated biweekly programs regardless of the loan's
//   underlying monthly convention — the program is a payment-cadence
//   overlay, not a product change.

import Foundation

/// Rebuild `schedule` as a biweekly-cadence amortization of the same loan
/// over the same calendar term (no acceleration).
///
/// The returned schedule uses the same principal, rate, term, startDate,
/// and loan/rate type, with `frequency = .biweekly`. Payment is solved by
/// the underlying engine so that 780 biweekly periods (for a 30-yr) fully
/// amortize the principal — total interest and payoff date come within
/// ~1 month and ~$500 of the monthly source schedule for typical loans.
/// Call `biweeklyAccelerated(schedule:)` instead if the goal is the
/// 13-monthly-equivalent-per-year acceleration that retires the note
/// several years early.
///
/// Extras, PMI, and recast periods from the source are intentionally
/// **dropped** — their period-number semantics don't translate 1:1 across
/// cadences (a "month-24 recast" has no biweekly equivalent), and
/// preserving them would produce wrong-but-plausible output. Callers that
/// want biweekly + extras should compose:
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

/// Rebuild `schedule` as an accelerated biweekly program: pay monthlyPMT / 2
/// every 14 days, with interest accruing on the current balance between
/// payments under an actual/365 14-day convention. 26 half-payments per
/// year = 13 monthly-equivalents per year = one extra month of principal
/// per year, which retires a conventional 30-yr note in roughly 22-26
/// years and materially reduces total interest vs the monthly source.
///
/// - `scheduledPeriodicPayment` is the biweekly payment (= monthlyPMT / 2
///   rounded to cents).
/// - `loan.frequency` on the returned schedule is `.biweekly`; `termMonths`
///   is preserved from the source for identity — the *actual* payoff falls
///   well short of that via early termination when `balance` reaches 0.
/// - Extras / PMI / recast from the source are dropped (same rationale as
///   `convertToBiweekly`).
///
/// Interest-accrual precision: `balance × (annualRate × 14 / 365)` each
/// period, rounded to cents via `computePeriodInterest`. Rounding residuals
/// are absorbed by the final period — principal caps at remaining balance
/// so the schedule ends exactly at 0.
///
/// If `schedule.loan.principal == 0` or the rate is 0, the behavior is
/// identical: compute the baseline monthly PMT, pay half of it every 14
/// days, amortize to 0. A zero-rate loan retires in `principal / (PMT/2)`
/// periods.
public func biweeklyAccelerated(schedule: AmortizationSchedule) -> AmortizationSchedule {
    let src = schedule.loan
    guard src.principal > 0 else {
        return emptyBiweeklyAccelerated(from: src, biweeklyPayment: 0)
    }

    // Baseline monthly PMT. This is the "what the borrower would pay per
    // month on the monthly schedule" — half of it paid every 14 days is
    // the scheduled biweekly payment.
    let monthlyLoan = Loan(
        principal: src.principal,
        annualRate: src.annualRate,
        termMonths: src.termMonths,
        loanType: src.loanType,
        rateType: src.rateType,
        startDate: src.startDate,
        frequency: .monthly
    )
    let monthlyPMT = paymentFor(loan: monthlyLoan)
    let biweeklyPayment = (monthlyPMT / 2).money()

    // 14-day actual/365 per-period rate.
    let perPeriodRate = src.annualRate * 14.0 / 365.0

    var balance = src.principal
    var payments: [AmortizationPayment] = []
    var paymentDate = src.startDate
    let calendar = gregorianUTC

    // Hard cap against runaway loops — well above any realistic biweekly
    // payoff. A 40-yr loan retires in at most ~900 biweekly periods; this
    // is 3× that.
    let maxPeriods = max(src.termMonths * 4, 4_000)
    var period = 1

    while balance > 0, period <= maxPeriods {
        let interest = computePeriodInterest(balance: balance, periodRate: perPeriodRate)
        var principal = (biweeklyPayment - interest).clampedNonNegative

        // Guard against a zero-principal payment when rate is so high that
        // interest alone exceeds the biweekly payment — refuse to loop
        // forever and mark the schedule as empty-ish.
        if principal == 0, balance > 0 {
            // Apply whatever the payment covers (possibly just interest)
            // and break to avoid infinite loop. In practice this only
            // fires at rates > ~13% on very short biweeklyPayments; the
            // UI clamps rate well below that.
            let row = AmortizationPayment(
                number: period,
                date: paymentDate,
                payment: biweeklyPayment,
                principal: 0,
                interest: biweeklyPayment,
                extraPrincipal: 0,
                pmi: 0,
                balance: balance
            )
            payments.append(row)
            break
        }

        // Final period: cap principal at remaining balance so the schedule
        // ends exactly at 0.
        if principal > balance {
            principal = balance
        }

        let payment = (principal + interest).money()
        let newBalance = (balance - principal).clampedNonNegative

        let row = AmortizationPayment(
            number: period,
            date: paymentDate,
            payment: payment,
            principal: principal,
            interest: interest,
            extraPrincipal: 0,
            pmi: 0,
            balance: newBalance
        )
        payments.append(row)
        balance = newBalance

        if balance == 0 { break }
        paymentDate = calendar.date(byAdding: .day, value: 14, to: paymentDate) ?? paymentDate
        period += 1
    }

    let biweeklyLoan = Loan(
        principal: src.principal,
        annualRate: src.annualRate,
        termMonths: src.termMonths,
        loanType: src.loanType,
        rateType: src.rateType,
        startDate: src.startDate,
        frequency: .biweekly
    )
    return AmortizationSchedule(
        payments: payments,
        loan: biweeklyLoan,
        options: .none,
        scheduledPeriodicPayment: biweeklyPayment
    )
}

private func emptyBiweeklyAccelerated(
    from src: Loan,
    biweeklyPayment: Decimal
) -> AmortizationSchedule {
    let biweeklyLoan = Loan(
        principal: src.principal,
        annualRate: src.annualRate,
        termMonths: src.termMonths,
        loanType: src.loanType,
        rateType: src.rateType,
        startDate: src.startDate,
        frequency: .biweekly
    )
    return AmortizationSchedule(
        payments: [],
        loan: biweeklyLoan,
        options: .none,
        scheduledPeriodicPayment: biweeklyPayment
    )
}
