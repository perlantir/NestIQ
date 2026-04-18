// NPVTests.swift

import Testing
import Foundation
@testable import QuotientFinance

@Suite("NPV / IRR / XNPV / XIRR")
struct NPVTests {

    @Test("NPV at zero rate equals sum of cash flows")
    func npvZeroRate() {
        let flows: [Decimal] = [-1000, 300, 400, 500]
        #expect(npv(rate: 0, cashFlows: flows) == 200)
    }

    @Test("NPV of known simple series matches closed-form")
    func npvKnownSeries() {
        // -1000 at t=0, +1100 at t=1, r=10% → NPV = -1000 + 1100/1.10 = 0
        let flows: [Decimal] = [-1000, 1100]
        #expect(npv(rate: 0.10, cashFlows: flows).isApproximatelyEqual(to: 0, tolerance: 0.01))
    }

    @Test("IRR: two-period investment yields 10%")
    func irrSimple() throws {
        let flows: [Decimal] = [-1000, 1100]
        let r = try irr(cashFlows: flows)
        #expect(r.isApproximatelyEqual(to: 0.10, tolerance: 1e-6))
    }

    @Test("IRR: standard 4-year project")
    func irrFourYearProject() throws {
        // Invest 1000, receive 300/yr for 4 years → IRR ≈ 7.71%
        let flows: [Decimal] = [-1000, 300, 300, 300, 300]
        let r = try irr(cashFlows: flows)
        #expect(r.isApproximatelyEqual(to: 0.07714, tolerance: 1e-4))
    }

    @Test("IRR throws when all flows have the same sign")
    func irrNoSignChange() {
        let flows: [Decimal] = [100, 200, 300]
        #expect(throws: FinanceError.self) {
            _ = try irr(cashFlows: flows)
        }
    }

    @Test("XNPV with evenly-spaced annual dates matches NPV")
    func xnpvMatchesNPV() {
        let d0 = date(2026, 1, 1)
        let cal = Calendar(identifier: .gregorian)
        let dated: [(Date, Decimal)] = [
            (d0, -1000),
            (cal.date(byAdding: .year, value: 1, to: d0) ?? d0, 300),
            (cal.date(byAdding: .year, value: 2, to: d0) ?? d0, 400),
            (cal.date(byAdding: .year, value: 3, to: d0) ?? d0, 500)
        ]
        let plain: [Decimal] = [-1000, 300, 400, 500]
        let xn = xnpv(rate: 0.08, cashFlows: dated.map { (date: $0.0, amount: $0.1) })
        let n = npv(rate: 0.08, cashFlows: plain)
        // Close (small difference from 365 vs 365.25 leap handling)
        #expect(xn.isApproximatelyEqual(to: n, tolerance: 5))
    }

    @Test("XIRR: a 1-year 10% return on dated cash flows")
    func xirrOneYearTenPercent() throws {
        let d0 = date(2026, 1, 1)
        let d1 = date(2027, 1, 1)
        let flows: [(date: Date, amount: Decimal)] = [
            (d0, -1000),
            (d1, 1100)
        ]
        let r = try xirr(cashFlows: flows)
        #expect(r.isApproximatelyEqual(to: 0.10, tolerance: 1e-3))
    }
}

@Suite("Break-even month")
struct BreakEvenTests {

    @Test("Refi with lower payment breaks even when cum savings ≥ costs")
    func breakEvenBasic() {
        let current = Loan(
            principal: 300_000,
            annualRate: 0.075,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let refi = RefiScenario(
            newLoan: Loan(
                principal: 300_000,
                annualRate: 0.055,
                termMonths: 360,
                startDate: date(2026, 1, 1)
            ),
            closingCosts: 6000
        )
        // Current PI ~ 2,097.64; new PI ~ 1,703.37; savings ~ 394.27/mo
        // Months to break even: ceil(6000 / 394.27) = 16
        let months = breakEvenMonth(refiScenario: refi, currentLoan: current)
        #expect(months != nil)
        #expect(months == 16)
    }

    @Test("Refi with higher payment has no break-even")
    func breakEvenNone() {
        let current = Loan(
            principal: 300_000,
            annualRate: 0.055,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let refi = RefiScenario(
            newLoan: Loan(
                principal: 300_000,
                annualRate: 0.075,
                termMonths: 360,
                startDate: date(2026, 1, 1)
            ),
            closingCosts: 4000
        )
        let months = breakEvenMonth(refiScenario: refi, currentLoan: current)
        #expect(months == nil)
    }
}
