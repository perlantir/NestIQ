// Generators.swift
// Input generators for property tests.

import Foundation
@testable import QuotientFinance

enum LoanGen {

    /// A standard amortizing conventional fixed-rate loan.
    /// Principal ∈ [$50k, $1.5M], rate ∈ [2%, 12%], term ∈ {120, 180, 240, 300, 360}.
    static func standardFixed(_ rng: inout SeededPRNG) -> Loan {
        let principalDollars = rng.int(in: 50_000...1_500_000)
        let rate = rng.double(in: 0.02...0.12)
        let terms = [120, 180, 240, 300, 360]
        let term = terms[rng.int(in: 0...(terms.count - 1))]
        return Loan(
            principal: Decimal(principalDollars),
            annualRate: rate,
            termMonths: term,
            startDate: date(2026, 1, 1)
        )
    }

    /// A biweekly conventional loan for the biweekly-cadence invariant.
    static func biweeklyFixed(_ rng: inout SeededPRNG) -> Loan {
        let principalDollars = rng.int(in: 50_000...1_000_000)
        let rate = rng.double(in: 0.03...0.10)
        let term = [180, 240, 300, 360][rng.int(in: 0...3)]
        return Loan(
            principal: Decimal(principalDollars),
            annualRate: rate,
            termMonths: term,
            startDate: date(2026, 1, 1),
            frequency: .biweekly
        )
    }

    /// Shrink a loan toward a simpler example: half principal, half rate,
    /// shorter term, zero-rate. Helps pinpoint minimal failures.
    static func shrink(_ loan: Loan) -> [Loan] {
        var candidates: [Loan] = []
        let halvedPrincipal = (loan.principal / 2).money()
        if halvedPrincipal >= 10_000 {
            var next = loan
            next.principal = halvedPrincipal
            candidates.append(next)
        }
        if loan.annualRate > 0.04 {
            var next = loan
            next.annualRate = loan.annualRate / 2
            candidates.append(next)
        }
        if loan.termMonths > 120 {
            var next = loan
            next.termMonths = loan.termMonths - 60
            candidates.append(next)
        }
        return candidates
    }
}

/// Inputs for the APR invariant: loan + prepaid finance charges.
struct LoanWithFees: CustomStringConvertible {
    var loan: Loan
    var prepaidFinanceCharges: Decimal
    var description: String {
        "LoanWithFees(principal: \(loan.principal), rate: \(loan.annualRate), term: \(loan.termMonths), fees: \(prepaidFinanceCharges))"
    }
}

enum LoanWithFeesGen {
    static func standard(_ rng: inout SeededPRNG) -> LoanWithFees {
        let loan = LoanGen.standardFixed(&rng)
        // Fees between 0.25% and 4% of principal.
        let feeFraction = rng.double(in: 0.0025...0.04)
        let fees = (loan.principal * Decimal(feeFraction)).money()
        return LoanWithFees(loan: loan, prepaidFinanceCharges: fees)
    }

    static func shrink(_ lf: LoanWithFees) -> [LoanWithFees] {
        let loanShrinks = LoanGen.shrink(lf.loan)
        return loanShrinks.map { LoanWithFees(loan: $0, prepaidFinanceCharges: lf.prepaidFinanceCharges) }
    }
}

/// Inputs for the PMI-drop invariant: loan + PMI policy at known origination LTV.
struct LoanWithPMI: CustomStringConvertible {
    var loan: Loan
    var originalValue: Decimal
    var description: String {
        "LoanWithPMI(principal: \(loan.principal), rate: \(loan.annualRate), origValue: \(originalValue))"
    }
}

enum LoanWithPMIGen {
    static func highLTVConventional(_ rng: inout SeededPRNG) -> LoanWithPMI {
        // Target origination LTV in [85%, 97%]
        let principalDollars = rng.int(in: 150_000...800_000)
        let origLTV = rng.double(in: 0.85...0.97)
        let origValue = Decimal(Double(principalDollars) / origLTV)
        let rate = rng.double(in: 0.04...0.09)
        let loan = Loan(
            principal: Decimal(principalDollars),
            annualRate: rate,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        return LoanWithPMI(loan: loan, originalValue: origValue.money())
    }
}

/// Inputs for the recast-reduces-payment invariant: loan + lump-sum month + amount.
struct LoanWithRecast: CustomStringConvertible {
    var loan: Loan
    var recastPeriod: Int
    var lumpSum: Decimal
    var description: String {
        "LoanWithRecast(principal: \(loan.principal), recastAt: \(recastPeriod), lumpSum: \(lumpSum))"
    }
}

enum LoanWithRecastGen {
    /// Generate a recast scenario where the loan has meaningful life after
    /// the recast period. Term ≥ 240 months and recast in [24, 120] keeps
    /// the lump-sum well clear of the payoff edge, so the "recast reduces
    /// payment" invariant is exercising the intended mechanism rather than
    /// degenerate near-payoff cases.
    static func standard(_ rng: inout SeededPRNG) -> LoanWithRecast {
        let principalDollars = rng.int(in: 150_000...1_500_000)
        let rate = rng.double(in: 0.03...0.10)
        let term = [240, 300, 360][rng.int(in: 0...2)]
        let loan = Loan(
            principal: Decimal(principalDollars),
            annualRate: rate,
            termMonths: term,
            startDate: date(2026, 1, 1)
        )
        let recastPeriod = rng.int(in: 24...120)
        // Lump-sum between 2% and 10% of principal.
        let fraction = rng.double(in: 0.02...0.10)
        let lumpSum = (loan.principal * Decimal(fraction)).money()
        return LoanWithRecast(loan: loan, recastPeriod: recastPeriod, lumpSum: lumpSum)
    }
}
