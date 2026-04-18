// AmortizationInputs.swift
// Codable payload persisted into Scenario.inputsJSON. Keeps the UI form
// state isolated from the finance engine's Loan struct so the form can
// evolve (future fields) without breaking the decoded history of saved
// scenarios.

import Foundation
import QuotientFinance

struct AmortizationFormInputs: Codable, Hashable, Sendable {
    var loanAmount: Decimal
    var annualRate: Double
    var termYears: Int
    var startDate: Date
    var annualTaxes: Decimal
    var annualInsurance: Decimal
    var monthlyHOA: Decimal
    var includePMI: Bool
    var extraPrincipalMonthly: Decimal
    var biweekly: Bool

    static let sampleDefault = AmortizationFormInputs(
        loanAmount: 548_000,
        annualRate: 6.750,
        termYears: 30,
        startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 1)) ?? Date(),
        annualTaxes: 6_500,
        annualInsurance: 1_620,
        monthlyHOA: 0,
        includePMI: false,
        extraPrincipalMonthly: 0,
        biweekly: false
    )

    var monthlyPITI: Decimal {
        let loan = toLoan()
        let (scheduledMonthly, _) = monthlyPI(loan: loan)
        let tax = annualTaxes / 12
        let ins = annualInsurance / 12
        let pmi = monthlyPMI(loan: loan)
        return scheduledMonthly + tax + ins + monthlyHOA + pmi
    }

    private func monthlyPI(loan: Loan) -> (Decimal, Int) {
        let pmt = paymentFor(loan: loan)
        return (pmt, totalPeriods(loan: loan))
    }

    var propertyValueGuess: Decimal {
        // Treat LTV as 80% default so PMI / value-derived displays have
        // something reasonable to lean on until the user edits.
        loanAmount * Decimal(1.25)
    }

    private func monthlyPMI(loan: Loan) -> Decimal {
        guard includePMI else { return 0 }
        let ltv = Double(truncating: (loanAmount / propertyValueGuess) as NSNumber)
        return calculatePMI(
            ltv: ltv,
            creditScore: 740,
            loanAmount: loanAmount,
            loanType: .conventional,
            termMonths: termYears * 12,
            paymentType: .monthly
        )
    }

    func toLoan() -> Loan {
        Loan(
            principal: loanAmount,
            annualRate: annualRate / 100,
            termMonths: termYears * 12,
            loanType: .conventional,
            rateType: .fixed,
            startDate: startDate,
            frequency: biweekly ? .biweekly : .monthly
        )
    }

    func toOptions() -> AmortizationOptions {
        AmortizationOptions(
            extraPeriodicPrincipal: extraPrincipalMonthly,
            oneTimeExtra: [],
            recastPeriods: [],
            pmiSchedule: includePMI ? PMISchedule(
                monthlyAmount: monthlyPMI(loan: toLoan()),
                originalValue: propertyValueGuess
            ) : nil
        )
    }
}
