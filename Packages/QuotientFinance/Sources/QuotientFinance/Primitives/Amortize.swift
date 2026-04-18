// Amortize.swift
// Amortization schedule generation with support for extras, recast, PMI,
// and non-monthly cadences.
//
// Day-count convention: 30/360 for conventional/FHA/VA/USDA fixed;
// actual/365 for HELOCs; actual/360 for SOFR ARMs; actual/actual for
// Treasury ARMs. Derived from `loan.dayCount`.
//
// Precision: interest each period is computed in `Double` from the current
// balance, then rounded to 2 decimal places (banker's) to avoid sub-cent
// drift. Principal = payment − interest, with the final period capping at
// the remaining balance so the schedule zeroes out exactly.

import Foundation

/// Build an amortization schedule for the given loan + options.
///
/// Behavior:
/// - Periodic extra principal (`options.extraPeriodicPrincipal`) is applied
///   every scheduled payment.
/// - One-time extras apply at their declared periods.
/// - Recast re-amortizes the remaining balance over the remaining term at
///   the original period rate; the new scheduled payment takes effect in
///   the **next** period. Recasts are processed after applying any
///   scheduled and one-time extras on the recast period.
/// - PMI, when attached, uses the **scheduled** balance trajectory (no
///   extras) to decide automatic termination at `options.dropAtLTV` —
///   matching HPA §1321 for conventional PMI. Permanent MIP (e.g. FHA with
///   original LTV > 90%) runs for the full schedule.
///
/// - Parameters:
///   - loan: The loan to amortize.
///   - options: Optional extras and PMI policy.
/// - Returns: Full schedule with periodic rows, the original scheduled
///   payment, and aggregate totals reachable via `AmortizationSchedule`'s
///   computed properties.
public func amortize(loan: Loan, options: AmortizationOptions = .none) -> AmortizationSchedule {
    guard loan.principal >= 0, loan.termMonths > 0 else {
        return AmortizationSchedule(payments: [], loan: loan, options: options, scheduledPeriodicPayment: 0)
    }

    let pRate = periodRate(
        annualRate: loan.annualRate,
        frequency: loan.frequency,
        dayCount: loan.dayCount
    )
    let totalPds = totalPeriods(loan: loan)
    let originalScheduledPayment = paymentFor(
        principal: loan.principal,
        periodRate: pRate,
        periods: totalPds
    )

    if loan.principal == 0 {
        return AmortizationSchedule(
            payments: [],
            loan: loan,
            options: options,
            scheduledPeriodicPayment: originalScheduledPayment
        )
    }

    let scheduledBalances = scheduledBalanceTrajectory(
        principal: loan.principal,
        periodRate: pRate,
        periods: totalPds,
        scheduledPayment: originalScheduledPayment
    )

    var balance = loan.principal
    var currentPayment = originalScheduledPayment
    var payments: [AmortizationPayment] = []
    payments.reserveCapacity(totalPds)

    var paymentDate = loan.startDate
    let calendar = gregorianUTC

    let lumpsumsByPeriod = Dictionary(grouping: options.oneTimeExtra, by: \.period)
        .mapValues { $0.reduce(Decimal(0)) { $0 + $1.amount } }

    for period in 1...totalPds {
        // 1. Interest on current balance, rounded to cents.
        let interest = computePeriodInterest(balance: balance, periodRate: pRate)

        // 2. Determine scheduled principal portion of this payment.
        var scheduledPrincipal = (currentPayment - interest).clampedNonNegative

        // 3. Extras this period.
        let lumpsum = lumpsumsByPeriod[period] ?? 0
        let periodic = options.extraPeriodicPrincipal
        var extra = (periodic + lumpsum).clampedNonNegative

        // 4. Cap total principal at remaining balance. On the final scheduled
        //    period, absorb the rounding residual that accumulates from cents
        //    rounding of the scheduled payment — otherwise the schedule ends
        //    with a small non-zero balance.
        if scheduledPrincipal + extra > balance {
            if scheduledPrincipal > balance {
                scheduledPrincipal = balance
                extra = 0
            } else {
                extra = balance - scheduledPrincipal
            }
        } else if period == totalPds {
            scheduledPrincipal = balance - extra
        }

        let newBalance = (balance - scheduledPrincipal - extra).clampedNonNegative

        // 5. PMI determination: scheduled balance (no extras) vs dropAtLTV.
        let pmi = pmiForPeriod(
            policy: options.pmiSchedule,
            period: period,
            scheduledBalance: scheduledBalances[period]
        )

        let row = AmortizationPayment(
            number: period,
            date: paymentDate,
            payment: (scheduledPrincipal + interest).money(),
            principal: scheduledPrincipal,
            interest: interest,
            extraPrincipal: extra,
            pmi: pmi,
            balance: newBalance
        )
        payments.append(row)

        balance = newBalance

        // 6. Recast — applied after the period's row is appended. The new
        //    scheduled payment lands in the next period.
        if options.recastPeriods.contains(period), balance > 0, period < totalPds {
            let remaining = totalPds - period
            currentPayment = paymentFor(
                principal: balance,
                periodRate: pRate,
                periods: remaining
            )
        }

        if balance == 0 { break }

        paymentDate = advance(date: paymentDate, by: loan.frequency, calendar: calendar)
    }

    return AmortizationSchedule(
        payments: payments,
        loan: loan,
        options: options,
        scheduledPeriodicPayment: originalScheduledPayment
    )
}

// MARK: - Internals

/// Interest for one period at a given per-period rate, rounded to cents.
@inline(__always)
func computePeriodInterest(balance: Decimal, periodRate: Double) -> Decimal {
    if periodRate == 0 || balance == 0 { return 0 }
    let interestDbl = balance.asDouble * periodRate
    return interestDbl.asDecimal.money()
}

/// Scheduled balance after each period assuming no extras or recast.
/// Used for HPA §1321 PMI drop determination.
func scheduledBalanceTrajectory(
    principal: Decimal,
    periodRate: Double,
    periods: Int,
    scheduledPayment: Decimal
) -> [Decimal] {
    var balances: [Decimal] = []
    balances.reserveCapacity(periods + 1)
    balances.append(principal)

    var balance = principal
    for _ in 1...periods {
        let interest = computePeriodInterest(balance: balance, periodRate: periodRate)
        var principalPortion = (scheduledPayment - interest).clampedNonNegative
        if principalPortion > balance { principalPortion = balance }
        balance = (balance - principalPortion).clampedNonNegative
        balances.append(balance)
    }
    return balances
}

func pmiForPeriod(
    policy: PMISchedule?,
    period: Int,
    scheduledBalance: Decimal
) -> Decimal {
    guard let policy else { return 0 }
    if policy.isPermanent { return policy.monthlyAmount }
    if period <= policy.minimumPeriods { return policy.monthlyAmount }
    guard policy.originalValue > 0 else { return 0 }
    let scheduledLTV = scheduledBalance.asDouble / policy.originalValue.asDouble
    return scheduledLTV > policy.dropAtLTV ? policy.monthlyAmount : 0
}

/// A deterministic Gregorian calendar fixed to UTC. Used for payment-date
/// advancement so schedules don't depend on the test machine's locale or DST.
let gregorianUTC: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    return c
}()

/// Advance a payment date by the given frequency.
func advance(date: Date, by frequency: PaymentFrequency, calendar: Calendar) -> Date {
    switch frequency {
    case .monthly:
        return calendar.date(byAdding: .month, value: 1, to: date) ?? date
    case .biweekly:
        return calendar.date(byAdding: .day, value: 14, to: date) ?? date
    case .semiMonthly:
        return calendar.date(byAdding: .day, value: 15, to: date) ?? date
    case .weekly:
        return calendar.date(byAdding: .day, value: 7, to: date) ?? date
    }
}
