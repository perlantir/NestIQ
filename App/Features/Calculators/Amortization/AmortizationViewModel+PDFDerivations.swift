// AmortizationViewModel+PDFDerivations.swift
// Session 7.3d — derivations backing the v2.1.1 amortization PDF
// template tokens. Mirrors the HELOC + Refi +PDFDerivations pattern:
// pure Swift, no QuotientFinance additions.

import Foundation
import QuotientFinance

extension AmortizationViewModel {

    // MARK: - Cover-hero derivations

    /// Integer portion of monthlyPITI for the PDF's big-number display
    /// (`{{piti_dollars}}`). E.g., 4207 out of $4,207.14.
    var pitiDollarsPart: String {
        let whole = (monthlyPITI as NSDecimalNumber).intValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: whole)) ?? "\(whole)"
    }

    /// Two-digit cents portion for `{{piti_cents}}` (e.g., "14" in $4,207.14).
    var pitiCentsPart: String {
        let whole = Decimal((monthlyPITI as NSDecimalNumber).intValue)
        let fractional = (monthlyPITI - whole) * 100
        let cents = (fractional as NSDecimalNumber).intValue
        return String(format: "%02d", abs(cents))
    }

    /// First scheduled payment date — startDate + one month cadence.
    /// Used by `{{first_payment_date}}`.
    var firstPaymentDate: Date {
        schedule?.payments.first?.date
            ?? Calendar.current.date(byAdding: .month, value: 1, to: inputs.startDate)
            ?? inputs.startDate
    }

    /// Product badge like "GEN-QM · 30yr" for `{{product_badge}}`.
    /// Term derived; loan-type always "GEN-QM" for v0.1.1 (the only
    /// type the engine exposes via AmortizationFormInputs).
    var productBadge: String {
        "GEN-QM · \(inputs.termYears)yr"
    }

    /// Human-readable PMI note for `{{pmi_note}}`. Three shapes:
    /// - "no PMI required" when toggle off or LTV ≤ 80%
    /// - "PMI drops {{miDropoffDate}}" when dropoff known
    /// - "$N/mo until LTV 78%" generic fallback when LTV > 80%
    var pmiNote: String {
        guard inputs.includePMI, inputs.manualMonthlyPMI > 0 else {
            return "no PMI required"
        }
        if let d = miDropoffDate {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM yyyy"
            return "PMI drops \(fmt.string(from: d))"
        }
        let dollars = (inputs.manualMonthlyPMI as NSDecimalNumber).intValue
        return "$\(dollars)/mo until LTV 78%"
    }

    // MARK: - 10-year point + extra-principal scenarios

    /// Outstanding balance after 120 monthly payments.
    /// `{{yr10_balance_formatted}}`.
    var year10Balance: Decimal {
        guard let payments = schedule?.payments, payments.count >= 120 else {
            return schedule?.payments.last?.balance ?? inputs.loanAmount
        }
        return payments[119].balance
    }

    /// Months shaved off the payoff by the LO's monthly extra principal
    /// vs a counterfactual schedule with `extraPrincipalMonthly = 0`.
    /// Returns 0 when no extra is set. Used for
    /// `{{extra_paydown_shortened}}` ("4 yrs 3 mos" composition happens
    /// Swift-side in the builder).
    var extraPaydownMonthsSaved: Int {
        guard inputs.extraPrincipalMonthly > 0 else { return 0 }
        let baseline = scheduleWithoutExtraPrincipal()
        let withExtra = schedule
        guard let baseCount = baseline?.payments.count,
              let withCount = withExtra?.payments.count else { return 0 }
        return max(baseCount - withCount, 0)
    }

    /// Lifetime interest saved by the monthly extra-principal payments.
    /// `{{extra_paydown_interest_saved}}`.
    var extraPaydownInterestSaved: Decimal {
        guard inputs.extraPrincipalMonthly > 0 else { return 0 }
        let baseline = scheduleWithoutExtraPrincipal()
        let savings = (baseline?.totalInterest ?? 0) - totalInterest
        return max(savings, 0)
    }

    /// Monthly P&I savings if the LO could lock the rate 0.25 pts lower.
    /// `{{quarterpt_savings_monthly}}`.
    var quarterPointSavingsMonthly: Decimal {
        let cheaperLoan = Loan(
            principal: inputs.loanAmount,
            annualRate: max(inputs.annualRate - 0.25, 0) / 100,
            termMonths: inputs.termYears * 12,
            startDate: inputs.startDate
        )
        let cheaperPayment = paymentFor(loan: cheaperLoan)
        return max(monthlyPI - cheaperPayment, 0)
    }

    /// Lifetime interest savings at the same 0.25-pt lower rate.
    /// `{{quarterpt_savings_lifetime}}`.
    var quarterPointSavingsLifetime: Decimal {
        let cheaperLoan = Loan(
            principal: inputs.loanAmount,
            annualRate: max(inputs.annualRate - 0.25, 0) / 100,
            termMonths: inputs.termYears * 12,
            startDate: inputs.startDate
        )
        let cheaperSchedule = amortize(loan: cheaperLoan, options: AmortizationOptions())
        return max(totalInterest - cheaperSchedule.totalInterest, 0)
    }

    // MARK: - Private helpers

    /// Fresh schedule with the LO's extra principal removed — used to
    /// compute the "without extra principal" baseline.
    private func scheduleWithoutExtraPrincipal() -> AmortizationSchedule? {
        let loan = inputs.toLoan()
        let options = AmortizationOptions(
            extraPeriodicPrincipal: 0,
            oneTimeExtra: [],
            recastPeriods: [],
            pmiSchedule: inputs.includePMI ? PMISchedule(
                monthlyAmount: inputs.manualMonthlyPMI,
                originalValue: inputs.propertyDP.purchasePrice > 0
                    ? inputs.propertyDP.purchasePrice
                    : inputs.propertyValueGuess
            ) : nil
        )
        return amortize(loan: loan, options: options)
    }
}
