// Schedule.swift
// Amortization schedule value types. Pure data; no computation.

import Foundation

/// One row of an amortization schedule. `payment` is the scheduled P&I only —
/// `pmi` and `extraPrincipal` are reported alongside for completeness but are
/// excluded from `payment` so totals are unambiguous.
public struct AmortizationPayment: Sendable, Hashable, Codable {
    /// 1-indexed period number.
    public let number: Int
    /// Due date for this period.
    public let date: Date
    /// Scheduled principal + interest for the period (no PMI, taxes, HOA).
    public let payment: Decimal
    /// Portion of `payment` applied to principal.
    public let principal: Decimal
    /// Portion of `payment` applied to interest.
    public let interest: Decimal
    /// Additional principal paid this period beyond `principal`
    /// (periodic extra + any one-time extra scheduled here).
    public let extraPrincipal: Decimal
    /// PMI premium due this period, if any.
    public let pmi: Decimal
    /// Remaining balance after applying principal + extraPrincipal.
    public let balance: Decimal

    public init(
        number: Int,
        date: Date,
        payment: Decimal,
        principal: Decimal,
        interest: Decimal,
        extraPrincipal: Decimal,
        pmi: Decimal,
        balance: Decimal
    ) {
        self.number = number
        self.date = date
        self.payment = payment
        self.principal = principal
        self.interest = interest
        self.extraPrincipal = extraPrincipal
        self.pmi = pmi
        self.balance = balance
    }
}

/// Full schedule with convenience aggregates.
public struct AmortizationSchedule: Sendable, Hashable, Codable {
    public let payments: [AmortizationPayment]
    public let loan: Loan
    public let options: AmortizationOptions
    /// Scheduled periodic P&I at origination. This is the amount an LO would
    /// quote to the borrower; extras and recasts don't change this value.
    public let scheduledPeriodicPayment: Decimal

    public init(
        payments: [AmortizationPayment],
        loan: Loan,
        options: AmortizationOptions,
        scheduledPeriodicPayment: Decimal
    ) {
        self.payments = payments
        self.loan = loan
        self.options = options
        self.scheduledPeriodicPayment = scheduledPeriodicPayment
    }

    public var numberOfPayments: Int { payments.count }

    public var totalInterest: Decimal {
        payments.reduce(Decimal(0)) { $0 + $1.interest }
    }

    public var totalPrincipal: Decimal {
        payments.reduce(Decimal(0)) { $0 + $1.principal + $1.extraPrincipal }
    }

    /// Scheduled P&I + extras + PMI. Does not include taxes, insurance, HOA —
    /// those live in `calculatePITI`.
    public var totalPayments: Decimal {
        payments.reduce(Decimal(0)) { $0 + $1.payment + $1.extraPrincipal + $1.pmi }
    }

    public var totalPMI: Decimal {
        payments.reduce(Decimal(0)) { $0 + $1.pmi }
    }

    /// Cumulative interest paid through the end of month `M` (inclusive,
    /// 1-indexed). Clamped: month 0 → 0, month > payments.count → full
    /// total. Session 5M.5 primitive for TCA's horizon-year interest vs
    /// principal breakdown.
    public func cumulativeInterest(throughMonth month: Int) -> Decimal {
        guard month > 0 else { return 0 }
        let cap = Swift.min(month, payments.count)
        return payments.prefix(cap).reduce(Decimal(0)) { $0 + $1.interest }
    }

    /// Cumulative principal paid through the end of month `M` (inclusive,
    /// 1-indexed). Includes scheduled principal + any extra principal
    /// applied in that month. Clamped the same way as
    /// `cumulativeInterest(throughMonth:)`.
    public func cumulativePrincipal(throughMonth month: Int) -> Decimal {
        guard month > 0 else { return 0 }
        let cap = Swift.min(month, payments.count)
        return payments.prefix(cap).reduce(Decimal(0)) { $0 + $1.principal + $1.extraPrincipal }
    }

    /// Cumulative mortgage insurance (PMI/MIP) paid through the end of
    /// month `M`. Honors the PMI dropoff schedule baked into the
    /// amortization run — once PMI drops, later rows contribute 0.
    /// Session 5M.6 primitive for TCA's per-horizon unrecoverable-
    /// costs display.
    public func cumulativeMI(throughMonth month: Int) -> Decimal {
        guard month > 0 else { return 0 }
        let cap = Swift.min(month, payments.count)
        return payments.prefix(cap).reduce(Decimal(0)) { $0 + $1.pmi }
    }

    public var payoffDate: Date? { payments.last?.date }
}
