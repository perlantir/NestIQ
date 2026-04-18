// APR.swift
// Annual Percentage Rate per Reg Z §1026.22 and Appendix J (actuarial method).
//
// The APR is the per-period rate that equates the present value of all
// scheduled payments to the "amount financed" (principal minus prepaid
// finance charges). Solved iteratively with bisection — guaranteed to
// converge for a well-formed amortizing loan.
//
// Day-count: the annual figure is `periodAPR × paymentsPerYear`, consistent
// with the loan's day-count convention (30/360 for conv/FHA/VA/USDA fixed
// gives `i × 12 = APR`).

import Foundation

/// Annual Percentage Rate for a fully-amortizing fixed loan with constant
/// scheduled payments.
///
/// - Parameters:
///   - loan: The loan whose note rate, term, and frequency drive the
///     scheduled payment.
///   - prepaidFinanceCharges: Closing costs that Reg Z counts as finance
///     charges — points, origination, MI premium if required, etc. Does
///     **not** include third-party fees excluded per §1026.4(c) (most
///     escrowed taxes, transfer taxes, appraisal, title insurance).
///   - tolerance: Relative tolerance for PV convergence (default 1e-10).
///   - maxIterations: Safety bound (default 200). Bisection converges
///     to float precision in ~60 iterations.
/// - Returns: APR expressed as an annual decimal fraction (0.0712 = 7.12%).
public func calculateAPR(
    loan: Loan,
    prepaidFinanceCharges: Decimal,
    tolerance: Double = 1e-10,
    maxIterations: Int = 200
) -> Double {
    guard loan.principal > 0, prepaidFinanceCharges >= 0 else { return loan.annualRate }

    // When there are no finance charges, APR equals the note rate exactly.
    if prepaidFinanceCharges == 0 { return loan.annualRate }

    let amountFinanced = (loan.principal - prepaidFinanceCharges).asDouble
    guard amountFinanced > 0 else { return loan.annualRate }

    let pmt = paymentFor(loan: loan).asDouble
    let n = Double(totalPeriods(loan: loan))
    let periodsPerYear = Double(loan.frequency.paymentsPerYear)
    let noteI = loan.annualRate / periodsPerYear

    func presentValue(atPeriodRate i: Double) -> Double {
        if i.magnitude < 1e-14 { return pmt * n }
        return pmt * (1.0 - pow(1.0 + i, -n)) / i
    }

    // At noteI the PV equals principal > amountFinanced. Expand upper bound
    // until PV < amountFinanced so we have a valid bracket.
    var low = noteI
    var high = noteI + 0.005
    for _ in 0..<80 {
        if presentValue(atPeriodRate: high) < amountFinanced { break }
        high *= 2
    }

    // Bisection. Monotone decreasing function, guaranteed convergence.
    var mid = 0.5 * (low + high)
    for _ in 0..<maxIterations {
        mid = 0.5 * (low + high)
        let pv = presentValue(atPeriodRate: mid)
        let residual = pv - amountFinanced
        if abs(residual) < tolerance * amountFinanced { break }
        if pv > amountFinanced { low = mid } else { high = mid }
    }

    return mid * periodsPerYear
}
