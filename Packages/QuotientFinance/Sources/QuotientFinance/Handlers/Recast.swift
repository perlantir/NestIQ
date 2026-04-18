// Recast.swift
// Apply a lump-sum recast to an existing amortization schedule.
//
// Mechanism: the lump sum is added as a one-time extra on `recastMonth`, and
// `recastMonth` is appended to `options.recastPeriods`. The engine's existing
// recast path then re-amortizes the post-lump-sum balance over the remaining
// term at the original period rate — all recast arithmetic stays in
// `Amortize.swift`.

import Foundation

/// Apply a principal-reducing lump sum at `recastMonth` and re-amortize the
/// remaining balance over the remaining term at the original rate.
///
/// Throws `FinanceError.invalidRecast` when:
/// - `lumpSum <= 0` — a non-positive recast is a silent no-op that masks
///   caller bugs; reject.
/// - `recastMonth < 1` — periods are 1-indexed.
/// - `recastMonth >= schedule.payments.count` — can't recast at or beyond
///   payoff; the post-lump-sum schedule would have no remaining term.
///
/// - Parameters:
///   - schedule: Source schedule; its `loan` and `options` are preserved.
///   - recastMonth: 1-indexed period at which the lump sum is applied and the
///     recast takes effect. The new, lower scheduled payment applies from the
///     following period onward.
///   - lumpSum: Principal-reducing payment. Must be strictly positive.
/// - Returns: Re-amortized schedule with the lump sum applied and recast
///   period merged into the loan's existing options.
public func applyRecast(
    schedule: AmortizationSchedule,
    recastMonth: Int,
    lumpSum: Decimal
) throws -> AmortizationSchedule {
    guard lumpSum > 0 else {
        throw FinanceError.invalidRecast(
            "lumpSum must be strictly positive; got \(lumpSum)"
        )
    }
    guard recastMonth >= 1 else {
        throw FinanceError.invalidRecast(
            "recastMonth must be >= 1; got \(recastMonth)"
        )
    }
    guard recastMonth < schedule.payments.count else {
        throw FinanceError.invalidRecast(
            "recastMonth \(recastMonth) is at or beyond schedule length \(schedule.payments.count)"
        )
    }

    let base = schedule.options
    let mergedOptions = AmortizationOptions(
        extraPeriodicPrincipal: base.extraPeriodicPrincipal,
        oneTimeExtra: base.oneTimeExtra + [ExtraPayment(period: recastMonth, amount: lumpSum)],
        recastPeriods: base.recastPeriods + [recastMonth],
        pmiSchedule: base.pmiSchedule
    )
    return amortize(loan: schedule.loan, options: mergedOptions)
}
