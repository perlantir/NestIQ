// IncomeQualViewModel.swift
// Wraps the inputs + derived qualifying-loan / DTI state.

import Foundation
import Observation
import QuotientFinance

@MainActor
@Observable
final class IncomeQualViewModel {
    var inputs: IncomeQualFormInputs
    var borrower: Borrower?

    init(inputs: IncomeQualFormInputs = .sampleDefault, borrower: Borrower? = nil) {
        self.inputs = inputs
        self.borrower = borrower
    }

    var maxLoan: Decimal { inputs.maxQualifyingLoan }
    var maxPurchase: Decimal { inputs.maxPurchasePrice }
    var maxPITI: Decimal { inputs.maxPITI }
    var qualifyingIncome: Decimal { inputs.qualifyingIncome }
    var totalDebt: Decimal { inputs.totalMonthlyDebt }

    /// Approximate reserve months = (qualifying income - current debt
    /// service) / max PITI. Displayed on the hero card as an at-a-glance
    /// cushion measure.
    var reserveMonths: Double {
        let piti = maxPITI
        guard piti > 0 else { return 0 }
        let cushion = qualifyingIncome - totalDebt
        return Double(truncating: (cushion / piti) as NSNumber)
    }

    var frontEndDTI: Double {
        guard qualifyingIncome > 0 else { return 0 }
        let piti = maxPITI
        let housing = piti
        return Double(truncating: (housing / qualifyingIncome) as NSNumber)
    }

    var backEndDTI: Double {
        guard qualifyingIncome > 0 else { return 0 }
        let total = maxPITI + 0 // maxPITI already nets debts
        return Double(truncating: (total / qualifyingIncome) as NSNumber)
    }

    var backEndDTIIncludingDebts: Double {
        guard qualifyingIncome > 0 else { return 0 }
        let total = maxPITI + totalDebt
        return Double(truncating: (total / qualifyingIncome) as NSNumber)
    }

    func prefilledAmortizationInputs() -> AmortizationFormInputs {
        AmortizationFormInputs(
            loanAmount: maxLoan,
            annualRate: inputs.annualRate,
            termYears: inputs.termYears,
            startDate: Date(),
            annualTaxes: inputs.annualTaxes,
            annualInsurance: inputs.annualInsurance,
            monthlyHOA: inputs.monthlyHOA,
            includePMI: false,
            extraPrincipalMonthly: 0,
            biweekly: false
        )
    }

    func buildScenario() -> AmortizationViewModel.ScenarioSnapshot {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let inputsJSON = (try? encoder.encode(inputs)) ?? Data()
        let key = "Max $\(MoneyFormat.shared.decimalString(maxLoan)) · "
            + "DTI \(String(format: "%.1f", backEndDTIIncludingDebts * 100))"
        return AmortizationViewModel.ScenarioSnapshot(
            inputsJSON: inputsJSON,
            outputsJSON: nil,
            keyStat: key
        )
    }
}
