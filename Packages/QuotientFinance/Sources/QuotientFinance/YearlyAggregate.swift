// YearlyAggregate.swift
// Roll an amortization schedule into loan-year buckets for the
// "Yearly" view of the results screen. Bucket size is
// `loan.frequency.paymentsPerYear` — 12 for monthly, 26 for biweekly.

import Foundation

/// One loan-year bucket of an amortization schedule.
///
/// `totalPayment` is scheduled P&I + extra principal actually paid in the
/// year (no PMI, taxes, HOA — those live in PITI calls). `endingBalance`
/// is the balance after the last payment in the bucket.
public struct YearlyScheduleRow: Sendable, Hashable, Codable, Identifiable {
    public let year: Int
    public let firstPaymentDate: Date
    public let lastPaymentDate: Date
    public let totalPayment: Decimal
    public let totalPrincipal: Decimal
    public let totalInterest: Decimal
    public let endingBalance: Decimal

    public var id: Int { year }

    public init(
        year: Int,
        firstPaymentDate: Date,
        lastPaymentDate: Date,
        totalPayment: Decimal,
        totalPrincipal: Decimal,
        totalInterest: Decimal,
        endingBalance: Decimal
    ) {
        self.year = year
        self.firstPaymentDate = firstPaymentDate
        self.lastPaymentDate = lastPaymentDate
        self.totalPayment = totalPayment
        self.totalPrincipal = totalPrincipal
        self.totalInterest = totalInterest
        self.endingBalance = endingBalance
    }
}

/// Group a schedule's payments into 1-indexed loan-year buckets.
///
/// The last bucket may be short when the payoff lands mid-year (prepayments
/// or the scheduled final payment landing on period 355, say); its totals
/// still reflect only the payments it contains.
public func yearlyAggregate(schedule: AmortizationSchedule) -> [YearlyScheduleRow] {
    let payments = schedule.payments
    guard !payments.isEmpty else { return [] }
    let perYear = max(1, schedule.loan.frequency.paymentsPerYear)
    var out: [YearlyScheduleRow] = []
    var idx = 0
    var year = 1
    while idx < payments.count {
        let end = min(idx + perYear, payments.count)
        let bucket = payments[idx..<end]
        let totalPayment = bucket.reduce(Decimal(0)) { $0 + $1.payment + $1.extraPrincipal }
        let totalPrincipal = bucket.reduce(Decimal(0)) { $0 + $1.principal + $1.extraPrincipal }
        let totalInterest = bucket.reduce(Decimal(0)) { $0 + $1.interest }
        let endingBalance = bucket.last?.balance ?? 0
        let first = bucket.first?.date ?? Date()
        let last = bucket.last?.date ?? first
        out.append(YearlyScheduleRow(
            year: year,
            firstPaymentDate: first,
            lastPaymentDate: last,
            totalPayment: totalPayment,
            totalPrincipal: totalPrincipal,
            totalInterest: totalInterest,
            endingBalance: endingBalance
        ))
        idx = end
        year += 1
    }
    return out
}
