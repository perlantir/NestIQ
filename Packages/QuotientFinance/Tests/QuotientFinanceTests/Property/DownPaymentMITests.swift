// DownPaymentMITests.swift
// Property invariants for the Session 5B.5 primitives:
//   - DownPayment.% ↔ .$ equivalence at a given price
//   - isMIRequired(ltv:) gates strictly above 80%
//   - miDropoffMonth monotonicity in DP size + 80-vs-78 policy
//   - ClosingCostBreakdown invariants

import Testing
import Foundation
@testable import QuotientFinance

@Suite("Down payment + MI — property invariants")
struct DownPaymentMITests {

    // MARK: DownPayment equivalence

    @Test("% and $ forms with equivalent values yield identical LTV")
    func downPaymentEquivalence() throws {
        try forAll(
            "DP equivalence",
            generator: priceAndPercent,
            count: 500
        ) { (price, pct) in
            let byPct = DownPayment.percentage(pct)
            let dollars = byPct.amount(purchasePrice: price)
            let byDollars = DownPayment.dollars(dollars)

            let loanPct = byPct.loanAmount(purchasePrice: price)
            let loanDollars = byDollars.loanAmount(purchasePrice: price)
            let diff = abs(loanPct - loanDollars)
            try require(
                diff <= Decimal(1),
                "loan diff \(diff) > $1 between percent=\(pct) and dollars=\(dollars) on \(price)"
            )

            let ltvPct = calculateLTV(loanAmount: loanPct, propertyValue: price)
            let ltvDollars = calculateLTV(loanAmount: loanDollars, propertyValue: price)
            try require(
                abs(ltvPct - ltvDollars) < 1e-5,
                "LTV diff \(ltvPct - ltvDollars) at price \(price) pct \(pct)"
            )
        }
    }

    // MARK: isMIRequired gate

    @Test("isMIRequired returns true iff ltv > 0.80")
    func miGate() {
        #expect(isMIRequired(ltv: 0.0) == false)
        #expect(isMIRequired(ltv: 0.7999) == false)
        #expect(isMIRequired(ltv: 0.80) == false)   // strictly greater
        #expect(isMIRequired(ltv: 0.8001) == true)
        #expect(isMIRequired(ltv: 0.95) == true)
        #expect(isMIRequired(ltv: 1.2) == true)
    }

    // MARK: miDropoffMonth monotonicity

    @Test("Dropoff month is monotonically non-increasing as DP rises")
    func dropoffMonotoneInDownPayment() {
        let price: Decimal = 600_000
        let rate = 0.065
        let term = 360
        var prior: Int = .max
        for pct in stride(from: 0.05, through: 0.19, by: 0.01) {
            let loan = DownPayment.percentage(pct).loanAmount(purchasePrice: price)
            let month = miDropoffMonth(
                loanAmount: loan,
                appraisedValue: price,
                rate: rate,
                termMonths: term
            )
            guard let m = month else { continue }
            #expect(m <= prior, "dropoff month \(m) should be ≤ \(prior) at dp=\(pct)")
            prior = m
        }
    }

    @Test("80%-requested dropoff lands no later than 78%-default")
    func dropoffAt80VsDefault() {
        let price: Decimal = 550_000
        let loan: Decimal = 522_500   // 95% LTV → definitely needs MI
        let rate = 0.07
        let term = 360
        let at78 = miDropoffMonth(
            loanAmount: loan,
            appraisedValue: price,
            rate: rate,
            termMonths: term,
            requestRemovalAt80: false
        )
        let at80 = miDropoffMonth(
            loanAmount: loan,
            appraisedValue: price,
            rate: rate,
            termMonths: term,
            requestRemovalAt80: true
        )
        #expect(at78 != nil)
        #expect(at80 != nil)
        if let m78 = at78, let m80 = at80 {
            #expect(m80 <= m78,
                    "80%-requested dropoff (\(m80)) should be ≤ 78%-default (\(m78))")
        }
    }

    @Test("Loan already below 78% threshold returns nil dropoff")
    func dropoffNilWhenAlreadyBelowThreshold() {
        // 50% LTV — MI wasn't needed at origination.
        let m = miDropoffMonth(
            loanAmount: 250_000,
            appraisedValue: 500_000,
            rate: 0.06,
            termMonths: 360
        )
        #expect(m == nil)
    }

    // MARK: ClosingCostBreakdown

    @Test("pointsAmount never exceeds totalClosingCosts")
    func closingCostInvariant() throws {
        try forAll(
            "closing cost invariant",
            generator: closingCostTriple,
            count: 500
        ) { (total, pct, loan) in
            let b = ClosingCostBreakdown(
                totalClosingCosts: total,
                pointsPercentage: pct,
                loanAmount: loan
            )
            try require(
                b.pointsAmount <= b.totalClosingCosts,
                "pointsAmount \(b.pointsAmount) > total \(b.totalClosingCosts)"
            )
            try require(
                b.feesAmount >= 0,
                "feesAmount \(b.feesAmount) < 0"
            )
            try require(
                b.pointsAmount + b.feesAmount == b.totalClosingCosts,
                "sum \(b.pointsAmount + b.feesAmount) != total \(b.totalClosingCosts)"
            )
        }
    }

}

// MARK: Generators — file scope so `forAll` generators resolve cleanly

private func priceAndPercent(_ rng: inout SeededPRNG) -> (Decimal, Double) {
    let price = Decimal(rng.int(in: 150_000...2_000_000))
    let pct = rng.double(in: 0.00...0.50)
    return (price, pct)
}

private func closingCostTriple(_ rng: inout SeededPRNG) -> (Decimal, Double, Decimal) {
    let loan = Decimal(rng.int(in: 50_000...2_000_000))
    let total = Decimal(rng.int(in: 1_000...50_000))
    let pct = rng.double(in: 0.0...3.0)
    return (total, pct, loan)
}
