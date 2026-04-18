// ExtraPrincipal.swift
// Ergonomic wrapper for re-amortizing an existing schedule with additional
// principal payments merged into its options.
//
// Every mechanism ultimately composes into `AmortizationOptions` and routes
// through the single `amortize(loan:options:)` path — keeping one source of
// truth for payment-boundary rounding, PMI drop, and final-period residual
// absorption.

import Foundation

/// Extra principal plan applied to an existing schedule.
///
/// - `recurring`: flat amount added to every scheduled payment's principal
///   (e.g., "+$200/mo for the life of the loan"). Stacks additively with the
///   source schedule's existing `extraPeriodicPrincipal`.
/// - `lumpSums`: period-specific extra principal. Callers expressing a
///   "per-payment fixed increase" pattern that varies across periods supply
///   one `ExtraPayment` per affected period; they stack additively with
///   `recurring` in the period they apply.
public struct ExtraPrincipalPlan: Sendable, Hashable, Codable {
    public let recurring: Decimal
    public let lumpSums: [ExtraPayment]

    public init(recurring: Decimal = 0, lumpSums: [ExtraPayment] = []) {
        self.recurring = recurring
        self.lumpSums = lumpSums
    }

    public static let none = ExtraPrincipalPlan()
}

/// Re-amortize `schedule`'s underlying loan with `extra` merged into the
/// existing options.
///
/// Merging is additive: `extra.recurring` is added to
/// `schedule.options.extraPeriodicPrincipal`, and `extra.lumpSums` is
/// appended to `schedule.options.oneTimeExtra`. PMI, recast periods, and the
/// underlying loan are preserved.
///
/// No-op passthrough when `extra == .none`: the returned schedule is
/// structurally identical to the input (same loan, same options).
///
/// - Parameters:
///   - schedule: Source schedule; its `loan` and `options` are the baseline.
///   - extra: Additional extras to merge.
/// - Returns: A freshly amortized schedule reflecting the merged options.
public func applyExtraPrincipal(
    schedule: AmortizationSchedule,
    extra: ExtraPrincipalPlan
) -> AmortizationSchedule {
    if extra.recurring == 0 && extra.lumpSums.isEmpty {
        return schedule
    }

    let base = schedule.options
    let mergedOptions = AmortizationOptions(
        extraPeriodicPrincipal: base.extraPeriodicPrincipal + extra.recurring,
        oneTimeExtra: base.oneTimeExtra + extra.lumpSums,
        recastPeriods: base.recastPeriods,
        pmiSchedule: base.pmiSchedule
    )
    return amortize(loan: schedule.loan, options: mergedOptions)
}
