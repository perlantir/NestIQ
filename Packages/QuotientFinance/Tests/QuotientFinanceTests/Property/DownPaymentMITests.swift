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
        ) { tuple in
            let (price, pct) = tuple
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

    // MARK: amortize(mi:) overload

    @Test("amortize(mi: nil) is byte-identical to amortize(loan:options:)")
    func amortizeMINilIsIdentity() throws {
        try forAll(
            "amortize(mi: nil) identity",
            generator: LoanGen.standardFixed,
            count: 200,
            shrink: LoanGen.shrink
        ) { loan in
            let direct = amortize(loan: loan, options: .none)
            let overload = amortize(
                loan: loan,
                options: .none,
                mi: nil,
                appraisedValue: loan.principal * Decimal(1.25)
            )
            try require(
                direct.payments == overload.payments,
                "payments differ between amortize and amortize(mi: nil)"
            )
            try require(
                direct.scheduledPeriodicPayment == overload.scheduledPeriodicPayment,
                "scheduled payment differs"
            )
        }
    }

    @Test("amortize(mi:) with nonnil MI carries premium through dropoff month")
    func amortizeMIPremiumIntegration() {
        let loan = Loan(
            principal: 475_000,
            annualRate: 0.065,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let appraised: Decimal = 500_000   // 95% LTV
        let mi = MIProfile(monthlyMI: 165, startLTV: 0.95)
        let schedule = amortize(
            loan: loan,
            options: .none,
            mi: mi,
            appraisedValue: appraised
        )
        // Engine should have attached PMI until the scheduled balance
        // crosses 78% × 500_000 = 390_000. Sanity: at least one row
        // carries the premium, and the last row carries 0.
        let withMI = schedule.payments.filter { $0.pmi > 0 }
        let withoutMI = schedule.payments.filter { $0.pmi == 0 }
        #expect(!withMI.isEmpty, "expected at least one PMI-carrying row")
        #expect(!withoutMI.isEmpty, "expected MI to drop by maturity")
        #expect(schedule.totalPMI > 0)
    }

    // MARK: ClosingCostBreakdown

    @Test("pointsAmount never exceeds totalClosingCosts")
    func closingCostInvariant() throws {
        try forAll(
            "closing cost invariant",
            generator: closingCostTriple,
            count: 500
        ) { triple in
            let b = ClosingCostBreakdown(
                totalClosingCosts: triple.total,
                pointsPercentage: triple.pct,
                loanAmount: triple.loan
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

struct ClosingTriple: CustomStringConvertible {
    let total: Decimal
    let pct: Double
    let loan: Decimal
    var description: String { "total=\(total) pct=\(pct) loan=\(loan)" }
}

private func closingCostTriple(_ rng: inout SeededPRNG) -> ClosingTriple {
    let loan = Decimal(rng.int(in: 50_000...2_000_000))
    let total = Decimal(rng.int(in: 1_000...50_000))
    let pct = rng.double(in: 0.0...3.0)
    return ClosingTriple(total: total, pct: pct, loan: loan)
}
