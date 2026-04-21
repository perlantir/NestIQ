// HelocViewModel+PDFDerivations.swift
// Session 7.3b — derivations backing the v2.1.1 HELOC PDF template tokens.
//
// These compute 10-year cumulative cost metrics for the HELOC path vs a
// cash-out refi alternative plus the 5-row rate stress-test matrix.
// Kept in its own file so the HELOC screen (containing the base
// HelocViewModel) stays tight.

import Foundation
import QuotientFinance

extension HelocViewModel {

    // MARK: - 10-year cumulative HELOC vs refi

    /// HELOC path 10-year cumulative interest paid: first-lien
    /// amortization interest portion + interest-only HELOC accruals.
    var tenYearCumulativeInterestHELOC: Decimal {
        let firstLien = amortizeFirstLien(months: 120)
        let helocInterest = helocInterestOnlyInterest(months: 120)
        return firstLien.totalInterest + helocInterest
    }

    /// Cash-out refi 10-year cumulative interest paid.
    var tenYearCumulativeInterestRefi: Decimal {
        let totalPrincipal = inputs.firstLienBalance + inputs.helocAmount
        let result = amortize(
            principal: totalPrincipal,
            annualRatePct: Double(truncating: inputs.cashoutRefiRate as NSNumber),
            termMonths: inputs.cashoutRefiTerm * 12,
            months: 120
        )
        return result.totalInterest
    }

    /// HELOC path 10-year principal paydown: first-lien principal only
    /// (HELOC interest-only during draw means zero principal paydown
    /// unless the LO sets aside extra — not modelled here).
    var tenYearPrincipalPaydownHELOC: Decimal {
        amortizeFirstLien(months: 120).totalPrincipal
    }

    /// Cash-out refi 10-year principal paydown.
    var tenYearPrincipalPaydownRefi: Decimal {
        let totalPrincipal = inputs.firstLienBalance + inputs.helocAmount
        return amortize(
            principal: totalPrincipal,
            annualRatePct: Double(truncating: inputs.cashoutRefiRate as NSNumber),
            termMonths: inputs.cashoutRefiTerm * 12,
            months: 120
        ).totalPrincipal
    }

    /// Signed 10-year net cost delta: HELOC total cost minus refi total
    /// cost, including closing. Positive means HELOC costs more (refi
    /// wins); negative means HELOC saves. Callers format as display
    /// text like "$29K saved" / "$72K extra".
    var tenYearNetCostDelta: Decimal {
        let helocTotal = tenYearCumulativeInterestHELOC + inputs.helocClosingCosts
        let refiTotal = tenYearCumulativeInterestRefi + inputs.cashoutRefiClosingCosts
        return helocTotal - refiTotal
    }

    /// Month at which cumulative refi cost catches up to cumulative
    /// HELOC cost (including closing). Returns nil when HELOC is
    /// cheaper throughout the simulation horizon — UI renders that as
    /// "immediate" (HELOC breaks even against refi immediately) or
    /// equivalent text.
    var breakEvenMonthsHELOCvsRefi: Int? {
        let helocMonthly = helocMonthlyPayment(shockBps: 0)
        let refiMonthly = refiMonthlyPayment()
        var cumHeloc = inputs.helocClosingCosts
        var cumRefi = inputs.cashoutRefiClosingCosts
        for month in 1...360 {
            cumHeloc += helocMonthly
            cumRefi += refiMonthly
            if cumHeloc <= cumRefi {
                return month
            }
        }
        return nil
    }

    // MARK: - Stress-path matrix (5 rows)

    /// 5-row stress table matching the v2.1.1 HELOC template layout:
    /// today · flat · +100 bps · +200 bps · +300 bps (capped at
    /// `inputs.helocLifetimeCapPct`).
    var stressPathMatrix: [StressRow] {
        let fullyIndexed = Decimal(inputs.helocFullyIndexedRate)
        let cap = inputs.helocLifetimeCapPct
        // Actual rate at each scenario, clamped at the lifetime cap.
        let today = fullyIndexed
        let flat = fullyIndexed
        let plus1 = min(fullyIndexed + 1.00, cap)
        let plus2 = min(fullyIndexed + 2.00, cap)
        let plus3 = min(fullyIndexed + 3.00, cap)

        let todayPayment = blendedMonthlyPayment(helocRatePct: today)
        let flatPayment = blendedMonthlyPayment(helocRatePct: flat)
        let plus1Payment = blendedMonthlyPayment(helocRatePct: plus1)
        let plus2Payment = blendedMonthlyPayment(helocRatePct: plus2)
        let plus3Payment = blendedMonthlyPayment(helocRatePct: plus3)

        let todayPeak = repaymentPeakPayment(helocRatePct: today)
        let flatPeak = repaymentPeakPayment(helocRatePct: flat)
        let plus1Peak = repaymentPeakPayment(helocRatePct: plus1)
        let plus2Peak = repaymentPeakPayment(helocRatePct: plus2)
        let plus3Peak = repaymentPeakPayment(helocRatePct: plus3)

        let plus2Blended = blendedEffectiveRate(helocRatePct: plus2)

        return [
            StressRow(
                scenarioLabel: "Today",
                rate: today,
                payment: todayPayment,
                delta: 0,
                peak: todayPeak,
                blendedRate: nil
            ),
            StressRow(
                scenarioLabel: "Flat",
                rate: flat,
                payment: flatPayment,
                delta: 0,
                peak: flatPeak,
                blendedRate: nil
            ),
            StressRow(
                scenarioLabel: "+100 bps",
                rate: plus1,
                payment: plus1Payment,
                delta: plus1Payment - todayPayment,
                peak: plus1Peak,
                blendedRate: nil
            ),
            StressRow(
                scenarioLabel: "+200 bps",
                rate: plus2,
                payment: plus2Payment,
                delta: plus2Payment - todayPayment,
                peak: plus2Peak,
                blendedRate: plus2Blended
            ),
            StressRow(
                scenarioLabel: "+300 bps / at cap",
                rate: plus3,
                payment: plus3Payment,
                delta: plus3Payment - todayPayment,
                peak: plus3Peak,
                blendedRate: nil
            )
        ]
    }

    // MARK: - Private helpers

    /// Blended (first-lien P&I + HELOC interest-only) monthly payment
    /// at a given HELOC fully-indexed rate (percent).
    private func blendedMonthlyPayment(helocRatePct: Decimal) -> Decimal {
        let firstLien = Loan(
            principal: inputs.firstLienBalance,
            annualRate: inputs.firstLienRate / 100,
            termMonths: inputs.firstLienRemainingYears * 12,
            startDate: Date()
        )
        let firstPI = paymentFor(loan: firstLien)
        let helocRate = Double(truncating: helocRatePct as NSNumber) / 100
        let helocMonthly = inputs.helocAmount * Decimal(helocRate / 12)
        return firstPI + helocMonthly
    }

    /// Peak monthly payment during the HELOC repayment period at a
    /// given rate — first-lien P&I (possibly paid off by then) plus
    /// HELOC fully-amortizing P&I over the repayment term.
    private func repaymentPeakPayment(helocRatePct: Decimal) -> Decimal {
        let helocRate = Double(truncating: helocRatePct as NSNumber) / 100
        let helocRepayTermMonths = inputs.helocRepaymentPeriodYears * 12
        let helocAmortized = amortizedMonthlyPayment(
            principal: inputs.helocAmount,
            annualRate: helocRate,
            termMonths: helocRepayTermMonths
        )
        // First lien may have paid off by the time repayment starts;
        // peak is conservative — assume still in repayment.
        let firstLien = Loan(
            principal: inputs.firstLienBalance,
            annualRate: inputs.firstLienRate / 100,
            termMonths: inputs.firstLienRemainingYears * 12,
            startDate: Date()
        )
        let firstPI = paymentFor(loan: firstLien)
        return firstPI + helocAmortized
    }

    /// 10-year blended effective rate when HELOC is at `helocRatePct`
    /// for the full horizon.
    private func blendedEffectiveRate(helocRatePct: Decimal) -> Decimal {
        let totalCapital = inputs.firstLienBalance + inputs.helocAmount
        guard totalCapital > 0 else { return 0 }
        let firstWeight = inputs.firstLienBalance / totalCapital
        let helocWeight = inputs.helocAmount / totalCapital
        let firstRateDecimal = Decimal(inputs.firstLienRate)
        return firstWeight * firstRateDecimal + helocWeight * helocRatePct
    }

    /// Amortize the first lien for `months` payments, returning
    /// cumulative interest + principal.
    private func amortizeFirstLien(months: Int) -> (totalInterest: Decimal, totalPrincipal: Decimal) {
        amortize(
            principal: inputs.firstLienBalance,
            annualRatePct: inputs.firstLienRate,
            termMonths: inputs.firstLienRemainingYears * 12,
            months: months
        )
    }

    /// Interest-only HELOC interest accrued over `months` (draw period
    /// assumption: balance held at `helocAmount`, no principal paydown).
    private func helocInterestOnlyInterest(months: Int) -> Decimal {
        let monthlyRate = inputs.helocFullyIndexedRate / 100 / 12
        return inputs.helocAmount * Decimal(monthlyRate) * Decimal(months)
    }

    /// Standard monthly payment on a fixed-rate fully amortizing loan.
    private func amortizedMonthlyPayment(
        principal: Decimal,
        annualRate: Double,
        termMonths: Int
    ) -> Decimal {
        guard termMonths > 0 else { return principal }
        let r = annualRate / 12
        if r == 0 { return principal / Decimal(termMonths) }
        let n = Double(termMonths)
        let factor = (r * pow(1 + r, n)) / (pow(1 + r, n) - 1)
        return principal * Decimal(factor)
    }

    /// Amortize a loan and return cumulative interest + principal paid
    /// over the first `months` payments. Not full schedule — just
    /// running sums for PDF summary numbers.
    private func amortize(
        principal: Decimal,
        annualRatePct: Double,
        termMonths: Int,
        months: Int
    ) -> (totalInterest: Decimal, totalPrincipal: Decimal) {
        guard termMonths > 0, principal > 0 else { return (0, 0) }
        let r = annualRatePct / 100 / 12
        let payment = amortizedMonthlyPayment(
            principal: principal,
            annualRate: annualRatePct / 100,
            termMonths: termMonths
        )
        var balance = principal
        var totalInterest: Decimal = 0
        var totalPrincipal: Decimal = 0
        let cap = min(months, termMonths)
        for _ in 0..<cap {
            let interest = balance * Decimal(r)
            let principalPortion = payment - interest
            totalInterest += interest
            totalPrincipal += principalPortion
            balance -= principalPortion
            if balance < 0 { balance = 0 }
        }
        return (totalInterest, totalPrincipal)
    }
}
