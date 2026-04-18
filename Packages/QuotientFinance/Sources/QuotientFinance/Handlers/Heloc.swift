// Heloc.swift
// HELOC simulation: draw period (interest-only or minimum payment) followed
// by repay period (fully amortized over the remaining term), with a
// configurable rate path to stress-test the variable-rate portion.
//
// Day-count convention: actual/365, matching `Loan.dayCount` for `.heloc`.
// The monthly rate used each period is `effectiveAnnualRate / 12`.
//
// Rate assembly (per period):
//   - During the intro period (months 1..introPeriodMonths): `product.introRate`.
//   - Afterward: `indexAtMonth + product.margin`, where `indexAtMonth` is the
//     forward-fill lookup from `ratePath.apply(...)` seeded with
//     `product.currentFullyIndexedRate - product.margin` (the implied index
//     today). This lets callers express "flat", "+100bps", "+200bps", or an
//     explicit schedule without the simulator caring how the stress was built.

import Foundation

// MARK: - Product & environment

public enum HelocIndexType: String, Sendable, Codable, Hashable, CaseIterable {
    /// Secured Overnight Financing Rate — replaced LIBOR for most new HELOCs
    /// post-2022.
    case sofr
    /// Wall Street Journal Prime Rate — historic standard, still prevalent.
    case prime
}

/// How the minimum periodic payment during the draw period is computed.
///
/// - `.interestOnly`: pay accrued interest only; principal unchanged.
/// - `.percentOfBalance(pct)`: pay `max(pct × balance, accrued interest)`,
///   with `pct` as a decimal fraction (e.g., `0.01` = 1%). Principal portion
///   is whatever exceeds interest.
/// - `.amortizingOverRepay`: during the draw period, pay what a full
///   amortization over the repay period would require — usually the
///   conservative choice for borrower education.
public enum HelocMinimumPaymentType: Sendable, Hashable, Codable {
    case interestOnly
    case percentOfBalance(Double)
    case amortizingOverRepay
}

/// Product spec for a HELOC quote. See `RatePath` for how stress scenarios
/// interact with `currentFullyIndexedRate`.
public struct HelocProduct: Sendable, Hashable, Codable {
    public let creditLimit: Decimal
    public let introRate: Double
    public let introPeriodMonths: Int
    public let indexType: HelocIndexType
    public let margin: Double
    /// Baseline post-intro rate: `index + margin` at origination. Used as
    /// `baseRate` when materializing the `RatePath`. E.g., if SOFR is 4.5%
    /// today and margin is 2.5%, `currentFullyIndexedRate = 0.07`.
    public let currentFullyIndexedRate: Double
    public let drawPeriodMonths: Int
    public let repayPeriodMonths: Int
    public let minimumPaymentType: HelocMinimumPaymentType

    public init(
        creditLimit: Decimal,
        introRate: Double,
        introPeriodMonths: Int,
        indexType: HelocIndexType,
        margin: Double,
        currentFullyIndexedRate: Double,
        drawPeriodMonths: Int,
        repayPeriodMonths: Int,
        minimumPaymentType: HelocMinimumPaymentType
    ) {
        self.creditLimit = creditLimit
        self.introRate = introRate
        self.introPeriodMonths = introPeriodMonths
        self.indexType = indexType
        self.margin = margin
        self.currentFullyIndexedRate = currentFullyIndexedRate
        self.drawPeriodMonths = drawPeriodMonths
        self.repayPeriodMonths = repayPeriodMonths
        self.minimumPaymentType = minimumPaymentType
    }
}

// MARK: - Draw schedule

/// Future-dated additional draw above `initialDraw`.
public struct ScheduledDraw: Sendable, Hashable, Codable {
    public let date: Date
    public let amount: Decimal

    public init(date: Date, amount: Decimal) {
        self.date = date
        self.amount = amount
    }
}

/// Borrower's draw plan. `initialDraw` is taken at origination; each
/// `scheduledDraws` entry is taken on the first simulation period whose
/// period date is on or after the entry's date.
public struct HelocDrawSchedule: Sendable, Hashable, Codable {
    public let initialDraw: Decimal
    public let scheduledDraws: [ScheduledDraw]

    public init(initialDraw: Decimal, scheduledDraws: [ScheduledDraw] = []) {
        self.initialDraw = initialDraw
        self.scheduledDraws = scheduledDraws
    }
}

// MARK: - Rate path

/// Rate-change event: at `effectiveDate`, the fully-indexed HELOC rate
/// steps to `fullyIndexedRate` (i.e., index + margin).
public struct SteppedRateChange: Sendable, Hashable, Codable {
    public let effectiveDate: Date
    public let fullyIndexedRate: Double

    public init(effectiveDate: Date, fullyIndexedRate: Double) {
        self.effectiveDate = effectiveDate
        self.fullyIndexedRate = fullyIndexedRate
    }
}

/// (date, rate) pair used for custom rate paths.
public struct DatedRate: Sendable, Hashable, Codable {
    public let date: Date
    public let rate: Double

    public init(date: Date, rate: Double) {
        self.date = date
        self.rate = rate
    }
}

/// How the variable-rate portion evolves over time.
///
/// `.flat`: the current fully-indexed rate stays constant.
/// `.shiftBps(bps)`: a one-time parallel shift applied at `startDate`.
/// `.stepped(changes)`: pre-scheduled index changes (explicit step path).
/// `.custom(pairs)`: full arbitrary curve supplied as `(date, rate)` pairs.
///
/// The fully-indexed rate at any period is the forward-filled value from the
/// materialized path — the simulator looks up the most-recent entry whose
/// key is ≤ the period's date. Callers use `apply(startDate:baseRate:)` to
/// materialize the curve once; the simulator does the lookup.
public enum RatePath: Sendable, Hashable, Codable {
    case flat
    case shiftBps(Int)
    case stepped([SteppedRateChange])
    case custom([DatedRate])

    /// Materialize the rate schedule as a date→rate map of change points.
    /// `baseRate` is the starting fully-indexed rate at `startDate`.
    /// Callers forward-fill: for any date `d`, the effective rate is the
    /// latest entry whose key is ≤ `d`.
    public func apply(startDate: Date, baseRate: Double) -> [Date: Double] {
        switch self {
        case .flat:
            return [startDate: baseRate]
        case let .shiftBps(bps):
            return [startDate: baseRate + Double(bps) / 10_000]
        case let .stepped(changes):
            var result: [Date: Double] = [startDate: baseRate]
            for c in changes {
                result[c.effectiveDate] = c.fullyIndexedRate
            }
            return result
        case let .custom(pairs):
            var result: [Date: Double] = [startDate: baseRate]
            for p in pairs {
                result[p.date] = p.rate
            }
            return result
        }
    }
}

// MARK: - Simulation output

public struct HelocMonth: Sendable, Hashable, Codable {
    public let number: Int
    public let date: Date
    public let annualRate: Double
    public let interestAccrued: Decimal
    public let principalPaid: Decimal
    public let drawnThisPeriod: Decimal
    public let payment: Decimal
    public let balance: Decimal
    public let available: Decimal
    public let cumulativeTotalCost: Decimal

    public init(
        number: Int,
        date: Date,
        annualRate: Double,
        interestAccrued: Decimal,
        principalPaid: Decimal,
        drawnThisPeriod: Decimal,
        payment: Decimal,
        balance: Decimal,
        available: Decimal,
        cumulativeTotalCost: Decimal
    ) {
        self.number = number
        self.date = date
        self.annualRate = annualRate
        self.interestAccrued = interestAccrued
        self.principalPaid = principalPaid
        self.drawnThisPeriod = drawnThisPeriod
        self.payment = payment
        self.balance = balance
        self.available = available
        self.cumulativeTotalCost = cumulativeTotalCost
    }
}

public struct HelocSimulation: Sendable, Hashable, Codable {
    public let months: [HelocMonth]
    /// Cumulative borrower cost (first lien + HELOC payments) at month 120.
    /// `nil` if the simulation is shorter than 10 years.
    public let tenYearTotalCost: Decimal?
    /// Effective blended rate at month 120: (annualized interest portion on
    /// both liens at that month) / (combined balance at that month).
    /// `nil` if simulation is shorter than 10 years or combined balance is
    /// zero at that point.
    public let blendedRateAtHorizon: Double?
    /// Jump from the last draw-period minimum payment to the first
    /// repay-period fully-amortizing payment. `nil` when there is no repay
    /// period (draw-only or zero outstanding at reset).
    public let paymentShockAtResetMonth: Decimal?
}

// MARK: - Entry point

/// Simulate a HELOC behind the borrower's first lien over the full
/// draw + repay life of the HELOC, given a draw plan and a rate path.
///
/// The returned `HelocSimulation` has one row per HELOC month; `months[i]`
/// covers the interval ending at `months[i].date`. First-lien payments are
/// folded into `cumulativeTotalCost` using the standard `amortize` schedule
/// (monthly P&I only; taxes/insurance/HOA are out of scope here).
public func simulateHelocPath(
    firstLien: Loan,
    product: HelocProduct,
    drawSchedule: HelocDrawSchedule,
    ratePath: RatePath
) -> HelocSimulation {
    let totalMonths = product.drawPeriodMonths + product.repayPeriodMonths
    let calendar = gregorianUTC
    let startDate = firstLien.startDate

    let firstLienSchedule = amortize(loan: firstLien, options: .none)
    let pathBase = product.currentFullyIndexedRate
    let pathMap = ratePath.apply(startDate: startDate, baseRate: pathBase)
    let sortedPathDates = pathMap.keys.sorted()

    var balance: Decimal = 0
    var cumulativeCost: Decimal = 0
    var months: [HelocMonth] = []
    months.reserveCapacity(totalMonths)

    // Pre-sort scheduled draws by date for linear walk.
    let sortedDraws = drawSchedule.scheduledDraws.sorted { $0.date < $1.date }
    var drawIdx = 0

    // Repay-period scheduled payment is recomputed when the repay period
    // starts, against the balance rolling into month `drawPeriodMonths + 1`.
    // Captured as `nil` up front; set on first repay-period iteration.
    var repayScheduledPayment: Decimal?
    var paymentShock: Decimal?
    var drawPeriodFinalPayment: Decimal?

    for m in 1...totalMonths {
        let monthDate: Date = {
            if m == 1 {
                return startDate
            }
            return calendar.date(byAdding: .month, value: m - 1, to: startDate) ?? startDate
        }()

        // 1. Apply draws: initialDraw at period 1, scheduledDraws whose date
        //    is on or before this period's date.
        var drawnThisPeriod: Decimal = 0
        if m == 1 {
            let initial = min(drawSchedule.initialDraw, product.creditLimit)
            balance += initial
            drawnThisPeriod += initial
        }
        while drawIdx < sortedDraws.count, sortedDraws[drawIdx].date <= monthDate {
            let available = product.creditLimit - balance
            let take = min(sortedDraws[drawIdx].amount, available).clampedNonNegative
            balance += take
            drawnThisPeriod += take
            drawIdx += 1
        }

        // 2. Determine effective annual rate for this period.
        let inIntro = m <= product.introPeriodMonths
        let annualRate: Double = inIntro
            ? product.introRate
            : effectiveRateFromPath(
                pathMap: pathMap,
                sortedDates: sortedPathDates,
                asOf: monthDate
            )

        // 3. Interest accrued this period.
        let monthlyRate = annualRate / 12.0
        let interest = computePeriodInterest(balance: balance, periodRate: monthlyRate)

        // 4. Minimum payment for this period.
        let isDrawPeriod = m <= product.drawPeriodMonths
        let scheduledPayment: Decimal
        if isDrawPeriod {
            scheduledPayment = drawPeriodMinimum(
                balance: balance,
                interest: interest,
                type: product.minimumPaymentType,
                repayMonths: product.repayPeriodMonths,
                monthlyRate: monthlyRate
            )
        } else {
            if repayScheduledPayment == nil {
                repayScheduledPayment = paymentFor(
                    principal: balance,
                    periodRate: monthlyRate,
                    periods: product.repayPeriodMonths
                )
                if let last = drawPeriodFinalPayment, let newPay = repayScheduledPayment {
                    paymentShock = (newPay - last).money()
                }
            }
            scheduledPayment = repayScheduledPayment ?? 0
        }

        // 5. Allocate payment: interest first, remainder to principal; cap
        //    principal at balance to zero out on final period.
        var principalPaid: Decimal = 0
        var paymentActual = scheduledPayment
        if paymentActual <= interest {
            // Minimum payment didn't cover interest — principal unchanged,
            // interest deferred onto balance (negative amortization).
            balance += (interest - paymentActual)
            paymentActual = interest.money()
        } else {
            principalPaid = (paymentActual - interest).clampedNonNegative
            if principalPaid > balance { principalPaid = balance }
            balance = (balance - principalPaid).clampedNonNegative
        }

        if isDrawPeriod, m == product.drawPeriodMonths {
            drawPeriodFinalPayment = paymentActual
        }

        cumulativeCost += paymentActual

        // 6. First-lien contribution this month.
        if m <= firstLienSchedule.payments.count {
            let flRow = firstLienSchedule.payments[m - 1]
            cumulativeCost += flRow.payment + flRow.pmi
        }

        let available = (product.creditLimit - balance).clampedNonNegative
        months.append(HelocMonth(
            number: m,
            date: monthDate,
            annualRate: annualRate,
            interestAccrued: interest,
            principalPaid: principalPaid,
            drawnThisPeriod: drawnThisPeriod,
            payment: paymentActual.money(),
            balance: balance,
            available: available,
            cumulativeTotalCost: cumulativeCost.money()
        ))
    }

    let tenYear: Decimal? = months.count >= 120 ? months[119].cumulativeTotalCost : nil
    let blended: Double? = {
        guard months.count >= 120 else { return nil }
        let helocMonth = months[119]
        let flBalance = m120FirstLienBalance(firstLienSchedule: firstLienSchedule)
        let flInterestAnnualized = m120FirstLienInterestAnnualized(firstLienSchedule: firstLienSchedule)
        let helocInterestAnnualized = helocMonth.interestAccrued.asDouble * 12
        let combinedBalance = helocMonth.balance.asDouble + flBalance.asDouble
        guard combinedBalance > 0 else { return nil }
        return (helocInterestAnnualized + flInterestAnnualized) / combinedBalance
    }()

    return HelocSimulation(
        months: months,
        tenYearTotalCost: tenYear,
        blendedRateAtHorizon: blended,
        paymentShockAtResetMonth: paymentShock
    )
}

// MARK: - Internals

func effectiveRateFromPath(
    pathMap: [Date: Double],
    sortedDates: [Date],
    asOf: Date
) -> Double {
    var lo = 0
    var hi = sortedDates.count - 1
    var candidate = sortedDates.first
    while lo <= hi {
        let mid = (lo + hi) / 2
        if sortedDates[mid] <= asOf {
            candidate = sortedDates[mid]
            lo = mid + 1
        } else {
            hi = mid - 1
        }
    }
    if let c = candidate { return pathMap[c] ?? 0 }
    return 0
}

func drawPeriodMinimum(
    balance: Decimal,
    interest: Decimal,
    type: HelocMinimumPaymentType,
    repayMonths: Int,
    monthlyRate: Double
) -> Decimal {
    switch type {
    case .interestOnly:
        return interest
    case let .percentOfBalance(pct):
        let pctPayment = (balance * Decimal(pct)).money()
        return max(pctPayment, interest)
    case .amortizingOverRepay:
        return paymentFor(principal: balance, periodRate: monthlyRate, periods: repayMonths)
    }
}

func m120FirstLienBalance(firstLienSchedule: AmortizationSchedule) -> Decimal {
    guard firstLienSchedule.payments.count >= 120 else {
        return firstLienSchedule.payments.last?.balance ?? 0
    }
    return firstLienSchedule.payments[119].balance
}

func m120FirstLienInterestAnnualized(firstLienSchedule: AmortizationSchedule) -> Double {
    guard firstLienSchedule.payments.count >= 120 else { return 0 }
    let window = firstLienSchedule.payments.prefix(120).suffix(12)
    let annual = window.reduce(Decimal(0)) { $0 + $1.interest }
    return annual.asDouble
}
