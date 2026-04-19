// HandlersTests.swift
// Unit tests for the three schedule-mutation handlers:
// applyExtraPrincipal, applyRecast, convertToBiweekly.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("applyExtraPrincipal")
struct ApplyExtraPrincipalTests {

    private static let standardLoan = Loan(
        principal: 300_000,
        annualRate: 0.06,
        termMonths: 360,
        startDate: date(2026, 1, 1)
    )

    @Test(".none is a structural pass-through")
    func noneIsPassthrough() {
        let base = amortize(loan: Self.standardLoan)
        let out = applyExtraPrincipal(schedule: base, extra: .none)
        #expect(out.payments.count == base.payments.count)
        #expect(out.scheduledPeriodicPayment == base.scheduledPeriodicPayment)
        #expect(out.totalInterest == base.totalInterest)
    }

    @Test("Recurring extra shortens term and reduces total interest")
    func recurringShortensTerm() {
        let base = amortize(loan: Self.standardLoan)
        let out = applyExtraPrincipal(
            schedule: base,
            extra: ExtraPrincipalPlan(recurring: 200)
        )
        #expect(out.payments.count < base.payments.count)
        #expect(out.totalInterest < base.totalInterest)
        #expect(out.payments.last?.balance == 0)
    }

    @Test("Recurring stacks additively with any existing periodic extra")
    func recurringStacksAdditive() {
        let loan = Self.standardLoan
        let withExisting = amortize(
            loan: loan,
            options: AmortizationOptions(extraPeriodicPrincipal: 100)
        )
        let out = applyExtraPrincipal(
            schedule: withExisting,
            extra: ExtraPrincipalPlan(recurring: 150)
        )
        // 100 + 150 = 250 — equivalent to starting from scratch with 250.
        let direct = amortize(
            loan: loan,
            options: AmortizationOptions(extraPeriodicPrincipal: 250)
        )
        #expect(out.payments.count == direct.payments.count)
        #expect(out.totalInterest.isApproximatelyEqual(to: direct.totalInterest, tolerance: 0.02))
    }

    @Test("Lump-sum extras appear at the declared period")
    func lumpsumsApplyAtPeriod() {
        let base = amortize(loan: Self.standardLoan)
        let out = applyExtraPrincipal(
            schedule: base,
            extra: ExtraPrincipalPlan(
                lumpSums: [ExtraPayment(period: 12, amount: 25_000)]
            )
        )
        #expect(out.payments[11].extraPrincipal >= 25_000)
        // Balance drops by at least the lump at month 12 (allowing for
        // some additional scheduled principal being absorbed).
        let balanceDropFromLump = base.payments[11].balance - out.payments[11].balance
        #expect(balanceDropFromLump >= 25_000)
    }

    @Test("Recurring + lumpsum combined still fully amortizes")
    func recurringPlusLumpsumAmortizes() {
        let base = amortize(loan: Self.standardLoan)
        let out = applyExtraPrincipal(
            schedule: base,
            extra: ExtraPrincipalPlan(
                recurring: 100,
                lumpSums: [
                    ExtraPayment(period: 24, amount: 10_000),
                    ExtraPayment(period: 60, amount: 20_000)
                ]
            )
        )
        #expect(out.payments.last?.balance == 0)
        #expect(out.payments.count < base.payments.count)
    }
}

@Suite("applyRecast")
struct ApplyRecastTests {

    private static let loan = Loan(
        principal: 400_000,
        annualRate: 0.065,
        termMonths: 360,
        startDate: date(2026, 1, 1)
    )

    @Test("Recast reduces scheduled payment post-recast")
    func reducesPostRecastPayment() throws {
        let base = amortize(loan: Self.loan)
        let recasted = try applyRecast(schedule: base, recastMonth: 36, lumpSum: 50_000)
        let postRecastPayment = recasted.payments[36].payment
        #expect(postRecastPayment < base.scheduledPeriodicPayment)
    }

    @Test("Recast reduces total interest")
    func reducesTotalInterest() throws {
        let base = amortize(loan: Self.loan)
        let recasted = try applyRecast(schedule: base, recastMonth: 24, lumpSum: 40_000)
        #expect(recasted.totalInterest < base.totalInterest)
    }

    @Test("Maturity is preserved (no early payoff at the same scheduled payment)")
    func preservesMaturity() throws {
        let base = amortize(loan: Self.loan)
        let recasted = try applyRecast(schedule: base, recastMonth: 60, lumpSum: 30_000)
        // Recast changes the payment but not the end date; schedule runs to
        // the original term.
        #expect(recasted.payments.count == base.payments.count)
    }

    @Test("Throws invalidRecast for non-positive lump sum")
    func rejectsNonPositiveLump() {
        let base = amortize(loan: Self.loan)
        #expect(throws: FinanceError.self) {
            _ = try applyRecast(schedule: base, recastMonth: 24, lumpSum: 0)
        }
        #expect(throws: FinanceError.self) {
            _ = try applyRecast(schedule: base, recastMonth: 24, lumpSum: -100)
        }
    }

    @Test("Throws invalidRecast for recast month at or beyond schedule length")
    func rejectsRecastAtOrBeyondPayoff() {
        let base = amortize(loan: Self.loan)
        let lastPeriod = base.payments.count
        #expect(throws: FinanceError.self) {
            _ = try applyRecast(schedule: base, recastMonth: lastPeriod, lumpSum: 10_000)
        }
        #expect(throws: FinanceError.self) {
            _ = try applyRecast(schedule: base, recastMonth: lastPeriod + 10, lumpSum: 10_000)
        }
    }

    @Test("Throws invalidRecast for recast month less than 1")
    func rejectsRecastMonthZero() {
        let base = amortize(loan: Self.loan)
        #expect(throws: FinanceError.self) {
            _ = try applyRecast(schedule: base, recastMonth: 0, lumpSum: 10_000)
        }
    }

    @Test("Error description carries descriptive message")
    func errorMessageIsDescriptive() {
        let base = amortize(loan: Self.loan)
        do {
            _ = try applyRecast(schedule: base, recastMonth: 10, lumpSum: -1)
            Issue.record("expected throw")
        } catch let error as FinanceError {
            #expect(error.description.contains("Invalid recast"))
        } catch {
            Issue.record("unexpected error type: \(error)")
        }
    }
}

@Suite("convertToBiweekly")
struct ConvertToBiweeklyTests {

    @Test("Monthly 30-year fixed converts to biweekly cadence")
    func producesBiweekly() {
        let monthly = Loan(
            principal: 250_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1),
            frequency: .monthly
        )
        let source = amortize(loan: monthly)
        let biweekly = convertToBiweekly(schedule: source)
        #expect(biweekly.loan.frequency == .biweekly)
        // 14-day spacing.
        let d0 = biweekly.payments[0].date
        let d1 = biweekly.payments[1].date
        let days = Calendar(identifier: .gregorian).dateComponents([.day], from: d0, to: d1).day ?? 0
        #expect(days == 14)
    }

    @Test("Payoff arrives within ~45 days of monthly — cadence re-slice, not acceleration")
    func nearEqualPayoff() {
        let monthly = Loan(
            principal: 250_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let source = amortize(loan: monthly)
        let biweekly = convertToBiweekly(schedule: source)

        // convertToBiweekly re-slices into 26/yr cadence over the same
        // calendar term; biweekly end lands within ~1 month of the monthly
        // source (780 × 14 days = 10,920 days vs ~10,957 days for 360
        // monthly). For real payoff acceleration use biweeklyAccelerated.
        guard
            let monthlyEnd = source.payments.last?.date,
            let biweeklyEnd = biweekly.payments.last?.date
        else {
            Issue.record("schedule empty")
            return
        }
        let days = Calendar(identifier: .gregorian)
            .dateComponents([.day], from: biweeklyEnd, to: monthlyEnd).day ?? 0
        #expect(abs(days) < 45, "payoff within ~45 days — got \(days)-day delta")
    }

    @Test("Total interest within ~$500 of monthly — cadence re-slice, not acceleration")
    func nearEqualInterest() {
        let monthly = Loan(
            principal: 250_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let monthlySched = amortize(loan: monthly)
        let biweekly = convertToBiweekly(schedule: monthlySched)
        let delta = abs((biweekly.totalInterest - monthlySched.totalInterest).asDouble)
        #expect(delta < 500, "interest within ~$500 — got $\(delta) delta")
    }

    @Test("Source extras are intentionally dropped")
    func dropsSourceExtras() {
        let monthly = Loan(
            principal: 250_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let source = amortize(
            loan: monthly,
            options: AmortizationOptions(extraPeriodicPrincipal: 500)
        )
        let biweekly = convertToBiweekly(schedule: source)
        #expect(biweekly.options.extraPeriodicPrincipal == 0)
        #expect(biweekly.options.oneTimeExtra.isEmpty)
        #expect(biweekly.options.pmiSchedule == nil)
    }

    @Test("Idempotent when source is already biweekly")
    func idempotentOnBiweeklyInput() {
        let biweeklyLoan = Loan(
            principal: 250_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1),
            frequency: .biweekly
        )
        let source = amortize(loan: biweeklyLoan)
        let out = convertToBiweekly(schedule: source)
        #expect(out.loan.frequency == .biweekly)
        #expect(out.payments.count == source.payments.count)
        #expect(out.scheduledPeriodicPayment == source.scheduledPeriodicPayment)
    }
}

@Suite("biweeklyAccelerated")
struct BiweeklyAcceleratedTests {

    private static let standard30yr = Loan(
        principal: 250_000,
        annualRate: 0.06,
        termMonths: 360,
        startDate: date(2026, 1, 1),
        frequency: .monthly
    )

    @Test("Retires 30-yr note at least 24 months earlier than monthly")
    func retiresEarly() {
        let source = amortize(loan: Self.standard30yr)
        let accel = biweeklyAccelerated(schedule: source)
        guard
            let monthlyEnd = source.payments.last?.date,
            let accelEnd = accel.payments.last?.date
        else {
            Issue.record("schedule empty")
            return
        }
        let months = Calendar(identifier: .gregorian)
            .dateComponents([.month], from: accelEnd, to: monthlyEnd).month ?? 0
        #expect(months >= 24, "expected ≥24 months of acceleration, got \(months)")
    }

    @Test("Reduces total interest vs monthly source")
    func reducesInterest() {
        let source = amortize(loan: Self.standard30yr)
        let accel = biweeklyAccelerated(schedule: source)
        #expect(accel.totalInterest < source.totalInterest)
        // At 6% / $250k / 30yr the saving is well north of $30k; guard
        // against a regression where the fn silently becomes a no-op.
        let saving = (source.totalInterest - accel.totalInterest).asDouble
        #expect(saving > 20_000, "expected material interest saving, got $\(saving)")
    }

    @Test("Biweekly payment equals half the monthly P&I")
    func halfMonthlyPayment() {
        let source = amortize(loan: Self.standard30yr)
        let accel = biweeklyAccelerated(schedule: source)
        let expectedHalf = (source.scheduledPeriodicPayment / 2).money()
        #expect(accel.scheduledPeriodicPayment == expectedHalf)
    }

    @Test("Schedule zeroes out within $1 floating-point tolerance")
    func zeroEnding() {
        let source = amortize(loan: Self.standard30yr)
        let accel = biweeklyAccelerated(schedule: source)
        guard let last = accel.payments.last else {
            Issue.record("schedule empty"); return
        }
        #expect(abs(last.balance.asDouble) < 1.0)
    }

    @Test("Sum of payments = principal + total interest")
    func sumsConserve() {
        let source = amortize(loan: Self.standard30yr)
        let accel = biweeklyAccelerated(schedule: source)
        let totalPaid = accel.payments.reduce(Decimal(0)) { $0 + $1.payment }
        let expected = Self.standard30yr.principal + accel.totalInterest
        let delta = abs((totalPaid - expected).asDouble)
        #expect(delta < 1.0, "payments sum off by \(delta)")
    }

    @Test("14-day cadence between payments")
    func fourteenDaySpacing() {
        let source = amortize(loan: Self.standard30yr)
        let accel = biweeklyAccelerated(schedule: source)
        guard accel.payments.count >= 2 else {
            Issue.record("schedule too short"); return
        }
        let d0 = accel.payments[0].date
        let d1 = accel.payments[1].date
        let days = Calendar(identifier: .gregorian)
            .dateComponents([.day], from: d0, to: d1).day ?? 0
        #expect(days == 14)
    }

    @Test("Drops source extras / PMI / recast")
    func dropsSourceExtras() {
        let source = amortize(
            loan: Self.standard30yr,
            options: AmortizationOptions(extraPeriodicPrincipal: 500)
        )
        let accel = biweeklyAccelerated(schedule: source)
        #expect(accel.options.extraPeriodicPrincipal == 0)
        #expect(accel.options.oneTimeExtra.isEmpty)
        #expect(accel.options.pmiSchedule == nil)
    }

    @Test("Zero principal produces an empty schedule")
    func zeroPrincipal() {
        let zeroLoan = Loan(
            principal: 0,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let source = amortize(loan: zeroLoan)
        let accel = biweeklyAccelerated(schedule: source)
        #expect(accel.payments.isEmpty)
    }

    @Test("Zero rate retires loan in fixed number of half-PMT periods")
    func zeroRateAmortizes() {
        let noRate = Loan(
            principal: 240_000,
            annualRate: 0,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let source = amortize(loan: noRate)
        let accel = biweeklyAccelerated(schedule: source)
        // monthly PMT = 240k / 360 = 666.67; biweekly = 333.33; principal
        // clears in ceil(240000 / 333.33) = 721 biweekly periods (~27.7yr).
        #expect(accel.payments.count > 600 && accel.payments.count < 800)
        #expect(accel.payments.last?.balance == 0)
        #expect(accel.totalInterest == 0)
    }
}
