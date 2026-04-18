// NPV.swift
// Net Present Value, Internal Rate of Return, and their date-aware
// counterparts XNPV / XIRR.
//
// Conventions:
// - `cashFlows[0]` is the time-0 value — undiscounted (spreadsheet `NPV`
//   functions vary on this; we follow the "Excel `XNPV`" convention of
//   including the first flow as-is, which maps cleanly to our date-aware
//   version too).
// - Sign convention: outflows (investment, refi closing costs) are negative;
//   inflows (refund, savings) are positive. IRR solves for r such that
//   NPV(r, cashFlows) = 0 under this sign convention.
// - XNPV / XIRR use an actual/365 day-count per Excel's convention, which
//   matches HELOC accrual. Regulatory APR (per Reg Z) uses the different
//   actuarial method — see `calculateAPR`.

import Foundation

/// Net Present Value at a per-period rate.
///
/// Formula: `NPV = Σ CFᵢ / (1 + r)ⁱ` for i = 0…n-1, with CF₀ undiscounted.
public func npv(rate: Double, cashFlows: [Decimal]) -> Decimal {
    guard !cashFlows.isEmpty else { return 0 }
    var acc = 0.0
    for (i, cf) in cashFlows.enumerated() {
        if i == 0 {
            acc += cf.asDouble
        } else {
            acc += cf.asDouble / pow(1.0 + rate, Double(i))
        }
    }
    return acc.asDecimal.money()
}

/// Internal Rate of Return — the per-period rate at which NPV = 0.
///
/// Solved via bisection over `[-99.99%, 10000%]`. Converges in ~60
/// iterations to float precision regardless of the cash-flow shape; for
/// the once-per-scenario use case the few microseconds vs. Newton-Raphson
/// is irrelevant, and bisection has zero "got stuck" cases to maintain.
///
/// - Parameters:
///   - cashFlows: At least one negative and one positive flow are required.
///   - tolerance: Absolute tolerance on NPV (default 1e-7).
///   - maxIterations: Safety bound (default 200; bisection convergence
///     reaches double-precision in ~60).
/// - Throws: `FinanceError.solverDidNotConverge` if the bracket can't be
///   established or convergence isn't reached within `maxIterations`.
///   `FinanceError.invalidInput` if the flows don't change sign.
public func irr(
    cashFlows: [Decimal],
    tolerance: Double = 1e-7,
    maxIterations: Int = 200
) throws -> Double {
    guard cashFlows.count >= 2 else {
        throw FinanceError.invalidInput("irr: need at least 2 cash flows")
    }
    let signs = Set(cashFlows.map { $0 == 0 ? 0 : ($0 > 0 ? 1 : -1) })
    guard signs.contains(1) && signs.contains(-1) else {
        throw FinanceError.invalidInput("irr requires at least one positive and one negative cash flow")
    }

    let flows = cashFlows.map(\.asDouble)

    func eval(_ r: Double) -> Double {
        var acc = 0.0
        for (i, cf) in flows.enumerated() {
            acc += i == 0 ? cf : cf / pow(1.0 + r, Double(i))
        }
        return acc
    }

    var low = -0.9999
    var high = 100.0
    let lowSign = eval(low).sign
    if lowSign == eval(high).sign {
        throw FinanceError.solverDidNotConverge(function: "irr", iterations: 0)
    }
    for _ in 0..<maxIterations {
        let mid = 0.5 * (low + high)
        let fm = eval(mid)
        if abs(fm) < tolerance { return mid }
        if fm.sign == lowSign { low = mid } else { high = mid }
    }
    throw FinanceError.solverDidNotConverge(function: "irr", iterations: maxIterations)
}

/// Date-aware NPV. Discounts each flow by `(dateᵢ − date₀) / 365` years.
///
/// Formula: `XNPV = Σ CFᵢ / (1 + r)^((dᵢ - d₀)/365)`
public func xnpv(rate: Double, cashFlows: [(date: Date, amount: Decimal)]) -> Decimal {
    guard !cashFlows.isEmpty else { return 0 }
    let base = cashFlows[0].date
    var acc = 0.0
    for (d, amt) in cashFlows {
        let years = d.timeIntervalSince(base) / (365.0 * 86_400.0)
        acc += amt.asDouble / pow(1.0 + rate, years)
    }
    return acc.asDecimal.money()
}

/// Date-aware IRR — the annualized rate at which XNPV = 0 under actual/365.
/// Bisection over `[-99.99%, 10000%]`, like `irr(cashFlows:)`.
public func xirr(
    cashFlows: [(date: Date, amount: Decimal)],
    tolerance: Double = 1e-7,
    maxIterations: Int = 200
) throws -> Double {
    guard cashFlows.count >= 2 else {
        throw FinanceError.invalidInput("xirr: need at least 2 cash flows")
    }
    let signs = Set(cashFlows.map { $0.amount == 0 ? 0 : ($0.amount > 0 ? 1 : -1) })
    guard signs.contains(1) && signs.contains(-1) else {
        throw FinanceError.invalidInput("xirr requires at least one positive and one negative cash flow")
    }

    let base = cashFlows[0].date
    let points: [(years: Double, amount: Double)] = cashFlows.map {
        ($0.date.timeIntervalSince(base) / (365.0 * 86_400.0), $0.amount.asDouble)
    }

    func eval(_ r: Double) -> Double {
        var acc = 0.0
        for p in points {
            acc += p.amount / pow(1.0 + r, p.years)
        }
        return acc
    }

    var low = -0.9999
    var high = 100.0
    let lowSign = eval(low).sign
    if lowSign == eval(high).sign {
        throw FinanceError.solverDidNotConverge(function: "xirr", iterations: 0)
    }
    for _ in 0..<maxIterations {
        let mid = 0.5 * (low + high)
        let fm = eval(mid)
        if abs(fm) < tolerance { return mid }
        if fm.sign == lowSign { low = mid } else { high = mid }
    }
    throw FinanceError.solverDidNotConverge(function: "xirr", iterations: maxIterations)
}
