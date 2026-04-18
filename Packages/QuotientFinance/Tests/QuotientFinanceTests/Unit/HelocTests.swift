// HelocTests.swift
// Unit tests for `simulateHelocPath`, `RatePath.apply`, and supporting types.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("RatePath.apply")
struct RatePathApplyTests {

    private static let start = date(2026, 1, 1)

    @Test("flat returns a single entry at startDate at baseRate")
    func flatIsSingleEntry() {
        let map = RatePath.flat.apply(startDate: Self.start, baseRate: 0.07)
        #expect(map.count == 1)
        #expect(map[Self.start]?.isApproximatelyEqual(to: 0.07) == true)
    }

    @Test("shiftBps adds bps/10_000 to baseRate")
    func shiftBpsAddsShift() {
        let map = RatePath.shiftBps(200).apply(startDate: Self.start, baseRate: 0.07)
        #expect(map[Self.start]?.isApproximatelyEqual(to: 0.09) == true)
    }

    @Test("stepped includes startDate at base + each change date at its fully-indexed rate")
    func steppedIncludesAllChangePoints() {
        let change1 = date(2028, 1, 1)
        let change2 = date(2030, 1, 1)
        let path = RatePath.stepped([
            SteppedRateChange(effectiveDate: change1, fullyIndexedRate: 0.08),
            SteppedRateChange(effectiveDate: change2, fullyIndexedRate: 0.09)
        ])
        let map = path.apply(startDate: Self.start, baseRate: 0.07)
        #expect(map[Self.start]?.isApproximatelyEqual(to: 0.07) == true)
        #expect(map[change1]?.isApproximatelyEqual(to: 0.08) == true)
        #expect(map[change2]?.isApproximatelyEqual(to: 0.09) == true)
    }

    @Test("custom preserves all supplied dated rates")
    func customPreservesAllEntries() {
        let d1 = date(2027, 6, 15)
        let d2 = date(2029, 3, 1)
        let path = RatePath.custom([
            DatedRate(date: d1, rate: 0.075),
            DatedRate(date: d2, rate: 0.085)
        ])
        let map = path.apply(startDate: Self.start, baseRate: 0.07)
        #expect(map[Self.start]?.isApproximatelyEqual(to: 0.07) == true)
        #expect(map[d1]?.isApproximatelyEqual(to: 0.075) == true)
        #expect(map[d2]?.isApproximatelyEqual(to: 0.085) == true)
    }
}

@Suite("simulateHelocPath")
struct HelocSimulationTests {

    private static let start = date(2026, 1, 1)

    private static func standardFirstLien() -> Loan {
        Loan(
            principal: 300_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: start
        )
    }

    private static func standardProduct(
        minimumPaymentType: HelocMinimumPaymentType = .interestOnly
    ) -> HelocProduct {
        HelocProduct(
            creditLimit: 100_000,
            introRate: 0.0299,
            introPeriodMonths: 6,
            indexType: .sofr,
            margin: 0.025,
            currentFullyIndexedRate: 0.07,
            drawPeriodMonths: 120,
            repayPeriodMonths: 240,
            minimumPaymentType: minimumPaymentType
        )
    }

    @Test("Row count equals drawPeriodMonths + repayPeriodMonths")
    func fullLifeRowCount() {
        let sim = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(),
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: .flat
        )
        #expect(sim.months.count == 360) // 120 + 240
    }

    @Test("Intro-period rate applies for the first introPeriodMonths periods")
    func introPeriodAppliesPromoRate() {
        let sim = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(),
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: .flat
        )
        for i in 0..<6 {
            #expect(sim.months[i].annualRate.isApproximatelyEqual(to: 0.0299, tolerance: 1e-9))
        }
        // Month 7 has switched to post-intro fully-indexed rate.
        #expect(sim.months[6].annualRate.isApproximatelyEqual(to: 0.07, tolerance: 1e-9))
    }

    @Test("Flat path keeps post-intro rate constant")
    func flatIsConstantPostIntro() {
        let sim = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(),
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: .flat
        )
        for i in 6..<sim.months.count {
            #expect(sim.months[i].annualRate.isApproximatelyEqual(to: 0.07, tolerance: 1e-9))
        }
    }

    @Test("+100bps shift raises post-intro rate by exactly 1pp")
    func shiftRaisesPostIntroRate() {
        let base = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(),
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: .flat
        )
        let stressed = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(),
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: .shiftBps(100)
        )
        // Post-intro rate differs by exactly 0.01.
        let baseRate = base.months[6].annualRate
        let stressRate = stressed.months[6].annualRate
        #expect((stressRate - baseRate).isApproximatelyEqual(to: 0.01, tolerance: 1e-9))
    }

    @Test("Interest-only draw period holds balance flat if no additional draws")
    func interestOnlyHoldsBalance() {
        let sim = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(minimumPaymentType: .interestOnly),
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: .flat
        )
        // Throughout the draw period, with interest-only payments and no
        // additional draws, the balance stays at the initial draw.
        for m in 0..<120 {
            #expect(sim.months[m].balance == 50_000)
        }
    }

    @Test("Repay period fully amortizes the balance to zero")
    func repayPeriodAmortizesToZero() {
        let sim = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(minimumPaymentType: .interestOnly),
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: .flat
        )
        let last = sim.months.last
        #expect(last?.balance == 0)
    }

    @Test("Payment shock at reset is positive for an interest-only draw period")
    func paymentShockIsPositiveForInterestOnly() {
        let sim = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(minimumPaymentType: .interestOnly),
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: .flat
        )
        #expect(sim.paymentShockAtResetMonth != nil)
        if let shock = sim.paymentShockAtResetMonth {
            #expect(shock > 0)
        }
    }

    @Test("Scheduled future draws are absorbed on or after their date")
    func scheduledDrawAbsorbed() {
        let futureDrawDate = date(2027, 1, 1)
        let schedule = HelocDrawSchedule(
            initialDraw: 20_000,
            scheduledDraws: [ScheduledDraw(date: futureDrawDate, amount: 30_000)]
        )
        let sim = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(minimumPaymentType: .interestOnly),
            drawSchedule: schedule,
            ratePath: .flat
        )
        // Before the scheduled draw the balance is 20k; at/after m=13 (2027-01-01)
        // the balance jumps to 50k.
        #expect(sim.months[11].balance == 20_000)
        #expect(sim.months[12].balance == 50_000)
    }

    @Test("Scheduled draws honor the credit limit")
    func scheduledDrawRespectsLimit() {
        let schedule = HelocDrawSchedule(
            initialDraw: 90_000,
            scheduledDraws: [
                ScheduledDraw(date: date(2026, 7, 1), amount: 50_000) // would exceed 100k limit
            ]
        )
        let sim = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(minimumPaymentType: .interestOnly),
            drawSchedule: schedule,
            ratePath: .flat
        )
        // Balance is capped at the credit limit.
        #expect(sim.months.allSatisfy { $0.balance <= 100_000 })
    }

    @Test("ten-year total cost and blended rate populated at month 120")
    func horizonAggregatesPopulated() {
        let sim = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(),
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: .flat
        )
        #expect(sim.tenYearTotalCost != nil)
        #expect(sim.blendedRateAtHorizon != nil)
        if let blended = sim.blendedRateAtHorizon {
            // Blended rate sits between 1st-lien rate (6%) and HELOC rate (7%).
            #expect(blended > 0.05 && blended < 0.08)
        }
    }

    @Test("Percent-of-balance payment respects minimum of interest")
    func percentOfBalanceFloorsAtInterest() {
        let productPct = Self.standardProduct(minimumPaymentType: .percentOfBalance(0.001))
        let sim = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: productPct,
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: .flat
        )
        // 0.1% of 50k = $50; post-intro interest at 7% on 50k/12 ≈ $291.67.
        // Payment should be the interest floor, not the tiny percent.
        let m7 = sim.months[6]
        #expect(m7.payment >= m7.interestAccrued)
    }

    @Test("amortizing-over-repay minimum payment exceeds interest-only")
    func amortizingOverRepayMinExceedsInterest() {
        let productAmort = Self.standardProduct(minimumPaymentType: .amortizingOverRepay)
        let productIO = Self.standardProduct(minimumPaymentType: .interestOnly)
        let sim1 = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: productAmort,
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: .flat
        )
        let sim2 = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: productIO,
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: .flat
        )
        // Amortizing-over-repay draws down principal during the draw period;
        // interest-only holds it flat.
        #expect(sim1.months[119].balance < sim2.months[119].balance)
    }

    @Test("First lien shorter than 120 months: blended aggregates degrade gracefully")
    func shortFirstLienBlendedNil() {
        let shortFL = Loan(
            principal: 100_000,
            annualRate: 0.05,
            termMonths: 60,         // 5 years
            startDate: Self.start
        )
        let sim = simulateHelocPath(
            firstLien: shortFL,
            product: Self.standardProduct(),
            drawSchedule: HelocDrawSchedule(initialDraw: 25_000),
            ratePath: .flat
        )
        // First lien is fully paid off by month 60; blended at month 120
        // still populates (HELOC-only), 10-year total cost still populated.
        #expect(sim.tenYearTotalCost != nil)
        #expect(sim.blendedRateAtHorizon != nil)
    }

    @Test("Custom rate path flows through simulation")
    func customPathFlowsThrough() {
        let d1 = date(2027, 1, 1)
        let d2 = date(2029, 1, 1)
        let custom = RatePath.custom([
            DatedRate(date: d1, rate: 0.08),
            DatedRate(date: d2, rate: 0.10)
        ])
        let sim = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(),
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: custom
        )
        // After intro ends (m=7): uses base 0.07 until d1, then 0.08, then 0.10.
        #expect(sim.months[6].annualRate.isApproximatelyEqual(to: 0.07, tolerance: 1e-9))
        #expect(sim.months[12].annualRate.isApproximatelyEqual(to: 0.08, tolerance: 1e-9))
        #expect(sim.months[36].annualRate.isApproximatelyEqual(to: 0.10, tolerance: 1e-9))
    }

    @Test("Stepped rate path applies change at the effective date")
    func steppedChangeApplies() {
        let changeDate = date(2027, 7, 1) // month 19 (0-indexed) — post-intro
        let path = RatePath.stepped([
            SteppedRateChange(effectiveDate: changeDate, fullyIndexedRate: 0.09)
        ])
        let sim = simulateHelocPath(
            firstLien: Self.standardFirstLien(),
            product: Self.standardProduct(),
            drawSchedule: HelocDrawSchedule(initialDraw: 50_000),
            ratePath: path
        )
        // Before change (still post-intro, using 0.07 base).
        #expect(sim.months[17].annualRate.isApproximatelyEqual(to: 0.07, tolerance: 1e-9))
        // On/after change — 0.09.
        let onOrAfter = sim.months[18].annualRate
        #expect(onOrAfter.isApproximatelyEqual(to: 0.09, tolerance: 1e-9))
    }
}
