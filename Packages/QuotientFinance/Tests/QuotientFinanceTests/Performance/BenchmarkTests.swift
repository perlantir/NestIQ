// BenchmarkTests.swift
//
// XCTest `measure` blocks for the performance budgets in DEVELOPMENT.md:
//   - amortize(360 months)         < 5 ms
//   - compareScenarios(4 × 30yr)   < 50 ms
//
// Swift Testing doesn't expose `measure`; we use XCTest for these. Both
// frameworks coexist in a single SPM test target.

import XCTest
@testable import QuotientFinance

final class BenchmarkTests: XCTestCase {

    /// A standard 30-year fixed used by every benchmark below.
    private let loan = Loan(
        principal: 400_000,
        annualRate: 0.065,
        termMonths: 360,
        startDate: Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 UTC
    )

    /// Budget: amortize(360 months) under 5 ms. We measure the average over
    /// 10 inner iterations to reduce per-call overhead variance.
    func testAmortize360MonthsPerformance() {
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        measure(options: options) {
            for _ in 0..<10 {
                _ = amortize(loan: loan)
            }
        }
    }

    /// Budget: compare four 30-year scenarios under 50 ms. Session 2 adds
    /// `compareScenarios(_:horizons:)` — for Session 1 we exercise the
    /// underlying cost: amortize four loans back to back, reducing to
    /// totals per horizon, which is what the eventual API will do.
    func testCompareFourScenariosPerformance() {
        let variants: [Loan] = (0..<4).map { i in
            Loan(
                principal: loan.principal,
                annualRate: loan.annualRate + Double(i) * 0.0025,
                termMonths: 360,
                startDate: loan.startDate
            )
        }
        let horizons = [5, 7, 10, 15, 30]

        measure {
            var results: [[Decimal]] = []
            for v in variants {
                let schedule = amortize(loan: v)
                let horizonTotals: [Decimal] = horizons.map { years in
                    let cutoff = min(years * 12, schedule.payments.count)
                    return schedule.payments.prefix(cutoff).reduce(Decimal(0)) {
                        $0 + $1.payment + $1.extraPrincipal + $1.pmi
                    }
                }
                results.append(horizonTotals)
            }
            _ = results
        }
    }

    /// APR solver is in the hot path for every scenario edit — worth a
    /// standalone watcher. Budget target: < 2 ms per call.
    func testAPRIterationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = calculateAPR(loan: loan, prepaidFinanceCharges: 4_500)
            }
        }
    }
}
