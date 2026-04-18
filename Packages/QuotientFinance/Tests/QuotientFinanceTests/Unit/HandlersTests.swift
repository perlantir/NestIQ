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

    @Test("Biweekly retires loan earlier than monthly")
    func retiresEarlier() {
        let monthly = Loan(
            principal: 250_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let source = amortize(loan: monthly)
        let biweekly = convertToBiweekly(schedule: source)

        // In calendar time, biweekly payoff arrives before the monthly
        // payoff — each payment is half of monthly, at 26/yr vs 12/yr pace,
        // producing one extra monthly-equivalent per year of principal.
        guard
            let monthlyEnd = source.payments.last?.date,
            let biweeklyEnd = biweekly.payments.last?.date
        else {
            Issue.record("schedule empty")
            return
        }
        #expect(biweeklyEnd < monthlyEnd)
    }

    @Test("Biweekly totals to ≤ monthly total interest")
    func reducesInterest() {
        let monthly = Loan(
            principal: 250_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let monthlySched = amortize(loan: monthly)
        let biweekly = convertToBiweekly(schedule: monthlySched)
        #expect(biweekly.totalInterest < monthlySched.totalInterest)
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
