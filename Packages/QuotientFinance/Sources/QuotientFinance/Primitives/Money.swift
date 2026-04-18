// Money.swift
// Core time-value-of-money primitives.
//
// These operate on an already-computed per-period rate. Callers using an
// annual rate should compute the period rate via `periodRate(annualRate:…)`
// — or use the `Loan`-based convenience overload which derives it from the
// loan's declared frequency + day-count convention.

import Foundation

// MARK: - Period-rate conversion

/// Convert an annual nominal rate to a per-period rate under the given
/// day-count convention.
///
/// Day-count convention:
/// - `.thirty360`: `annualRate / paymentsPerYear` (standard for conventional,
///   FHA, VA, USDA fixed loans — 30-day months, 360-day year).
/// - `.actual365`: `annualRate / 365 × avgDaysPerPeriod` (HELOC).
/// - `.actual360`: `annualRate / 360 × avgDaysPerPeriod` (SOFR-indexed ARMs).
/// - `.actualActual`: `annualRate / 365.25 × avgDaysPerPeriod` (Treasury ARMs).
public func periodRate(
    annualRate: Double,
    frequency: PaymentFrequency,
    dayCount: DayCountConvention
) -> Double {
    switch dayCount {
    case .thirty360:
        return annualRate / Double(frequency.paymentsPerYear)
    case .actual365, .actual360, .actualActual:
        return (annualRate / dayCount.daysPerYear) * frequency.averageDaysPerPeriod
    }
}

/// Number of payment periods implied by a loan's term and frequency.
///
/// A 360-month loan paid biweekly has `30 × 26 = 780` biweekly periods at
/// the scheduled amount, though the actual payoff arrives earlier because
/// each biweekly payment is half a monthly PMT — yielding one extra monthly
/// payment of principal reduction per year.
public func totalPeriods(loan: Loan) -> Int {
    let years = Double(loan.termMonths) / 12.0
    return Int((years * Double(loan.frequency.paymentsPerYear)).rounded())
}

// MARK: - Payment

/// Scheduled periodic payment for a fully-amortizing loan (ordinary annuity,
/// payment at period end).
///
/// Formula: `PMT = PV × r / (1 − (1 + r)^−n)`
/// When `r == 0`: `PMT = PV / n`.
///
/// Day-count convention: caller-provided — `periodRate` must already reflect
/// the product's convention.
///
/// Returns the payment rounded to 2 decimal places with banker's rounding.
public func paymentFor(principal: Decimal, periodRate: Double, periods: Int) -> Decimal {
    guard periods > 0, principal >= 0 else { return 0 }
    if principal == 0 { return 0 }

    if periodRate == 0 {
        return (principal / Decimal(periods)).money()
    }

    let pv = principal.asDouble
    let factor = pow(1.0 + periodRate, Double(periods))
    let pmt = pv * periodRate * factor / (factor - 1.0)
    return pmt.asDecimal.money()
}

/// Convenience overload: payment for a `Loan`, deriving the period rate from
/// the loan's declared frequency and implied day-count convention.
public func paymentFor(loan: Loan) -> Decimal {
    let r = periodRate(
        annualRate: loan.annualRate,
        frequency: loan.frequency,
        dayCount: loan.dayCount
    )
    return paymentFor(
        principal: loan.principal,
        periodRate: r,
        periods: totalPeriods(loan: loan)
    )
}

// MARK: - Present value

/// Present value of a lump sum received `periods` periods from now.
///
/// Formula: `PV = FV / (1 + r)^n`
///
/// Day-count convention: caller-provided.
public func presentValue(futureValue: Decimal, periodRate: Double, periods: Int) -> Decimal {
    guard periods >= 0 else { return futureValue }
    if periodRate == 0 || periods == 0 { return futureValue }
    let pv = futureValue.asDouble / pow(1.0 + periodRate, Double(periods))
    return pv.asDecimal.money()
}

/// Present value of an ordinary annuity (level payments, end of period).
///
/// Formula: `PV = PMT × (1 − (1 + r)^−n) / r`
/// When `r == 0`: `PV = PMT × n`.
///
/// Day-count convention: caller-provided.
public func presentValue(payment: Decimal, periodRate: Double, periods: Int) -> Decimal {
    guard periods > 0 else { return 0 }
    if periodRate == 0 { return (payment * Decimal(periods)).money() }
    let pmt = payment.asDouble
    let pv = pmt * (1.0 - pow(1.0 + periodRate, -Double(periods))) / periodRate
    return pv.asDecimal.money()
}

// MARK: - Future value

/// Future value of a lump sum invested now.
///
/// Formula: `FV = PV × (1 + r)^n`
///
/// Day-count convention: caller-provided.
public func futureValue(presentValue: Decimal, periodRate: Double, periods: Int) -> Decimal {
    guard periods >= 0 else { return presentValue }
    if periodRate == 0 || periods == 0 { return presentValue }
    let fv = presentValue.asDouble * pow(1.0 + periodRate, Double(periods))
    return fv.asDecimal.money()
}

/// Future value of an ordinary annuity of `payment` for `periods` periods.
///
/// Formula: `FV = PMT × ((1 + r)^n − 1) / r`
/// When `r == 0`: `FV = PMT × n`.
///
/// Day-count convention: caller-provided.
public func futureValue(payment: Decimal, periodRate: Double, periods: Int) -> Decimal {
    guard periods > 0 else { return 0 }
    if periodRate == 0 { return (payment * Decimal(periods)).money() }
    let pmt = payment.asDouble
    let fv = pmt * (pow(1.0 + periodRate, Double(periods)) - 1.0) / periodRate
    return fv.asDecimal.money()
}

// MARK: - Compound growth

/// Future value under compound growth, with explicit compounding frequency.
///
/// Formula: `FV = PV × (1 + r / m)^(n × m)` where `n` is years in the horizon
/// and `m = compoundingsPerYear`.
///
/// Day-count convention: assumes `annualRate` is already nominal for the
/// chosen compounding frequency.
public func compoundGrowth(
    presentValue: Decimal,
    annualRate: Double,
    years: Double,
    compoundingsPerYear: Int
) -> Decimal {
    guard compoundingsPerYear > 0, years >= 0 else { return presentValue }
    if annualRate == 0 || years == 0 { return presentValue }
    let m = Double(compoundingsPerYear)
    let fv = presentValue.asDouble * pow(1.0 + annualRate / m, years * m)
    return fv.asDecimal.money()
}
