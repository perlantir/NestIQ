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
    /// User-entered monthly PMI amount. Consulted when `includePMI` is
    /// true; zeroed out for the PITI calculation when the toggle is off.
    /// Manual-entry only in Session 5B.3 — Session 5B.5 wires the
    /// auto-calc + dropoff path.
    var manualMonthlyPMI: Decimal
    var extraPrincipalMonthly: Decimal
    var biweekly: Bool
    var propertyDP: PropertyDownPaymentConfig

    // Legacy decodes won't carry newer keys. Defaults below.
    enum CodingKeys: String, CodingKey {
        case loanAmount, annualRate, termYears, startDate
        case annualTaxes, annualInsurance, monthlyHOA
        case includePMI, manualMonthlyPMI
        case extraPrincipalMonthly, biweekly, propertyDP
    }

    init(
        loanAmount: Decimal,
        annualRate: Double,
        termYears: Int,
        startDate: Date,
        annualTaxes: Decimal,
        annualInsurance: Decimal,
        monthlyHOA: Decimal,
        includePMI: Bool,
        manualMonthlyPMI: Decimal = 0,
        extraPrincipalMonthly: Decimal,
        biweekly: Bool,
        propertyDP: PropertyDownPaymentConfig = .empty
    ) {
        self.loanAmount = loanAmount
        self.annualRate = annualRate
        self.termYears = termYears
        self.startDate = startDate
        self.annualTaxes = annualTaxes
        self.annualInsurance = annualInsurance
        self.monthlyHOA = monthlyHOA
        self.includePMI = includePMI
        self.manualMonthlyPMI = manualMonthlyPMI
        self.extraPrincipalMonthly = extraPrincipalMonthly
        self.biweekly = biweekly
        self.propertyDP = propertyDP
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.loanAmount = try c.decode(Decimal.self, forKey: .loanAmount)
        self.annualRate = try c.decode(Double.self, forKey: .annualRate)
        self.termYears = try c.decode(Int.self, forKey: .termYears)
        self.startDate = try c.decode(Date.self, forKey: .startDate)
        self.annualTaxes = try c.decode(Decimal.self, forKey: .annualTaxes)
        self.annualInsurance = try c.decode(Decimal.self, forKey: .annualInsurance)
        self.monthlyHOA = try c.decode(Decimal.self, forKey: .monthlyHOA)
        self.includePMI = try c.decode(Bool.self, forKey: .includePMI)
        self.manualMonthlyPMI = try c.decodeIfPresent(Decimal.self, forKey: .manualMonthlyPMI) ?? 0
        self.extraPrincipalMonthly = try c.decode(Decimal.self, forKey: .extraPrincipalMonthly)
        self.biweekly = try c.decode(Bool.self, forKey: .biweekly)
        self.propertyDP = try c.decodeIfPresent(
            PropertyDownPaymentConfig.self, forKey: .propertyDP
        ) ?? .empty
    }

    static let sampleDefault = AmortizationFormInputs(
        loanAmount: 548_000,
        annualRate: 6.750,
        termYears: 30,
        startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 1)) ?? Date(),
        annualTaxes: 6_500,
        annualInsurance: 1_620,
        monthlyHOA: 0,
        includePMI: false,
        manualMonthlyPMI: 0,
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
        // Session 5B.3: honor the LO's manual entry. Session 5B.5 will
        // plumb auto-calc via `calculatePMI(...)` + dropoff schedule
        // here; the existing grid-based helper stays available for that.
        return manualMonthlyPMI
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
