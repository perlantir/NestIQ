// SelfEmploymentViewModel.swift
// Owns Self-Employment form state + computed SelfEmploymentOutput.

import Foundation
import Observation
import QuotientFinance

@MainActor
@Observable
final class SelfEmploymentViewModel {
    var inputs: SelfEmploymentFormInputs
    var borrower: Borrower?
    var output: SelfEmploymentOutput?

    init(
        inputs: SelfEmploymentFormInputs = .sampleDefault,
        borrower: Borrower? = nil
    ) {
        self.inputs = inputs
        self.borrower = borrower
    }

    func compute() {
        output = QuotientFinance.compute(input: inputs.currentInput)
    }

    var qualifyingMonthly: Decimal {
        output?.qualifyingMonthlyIncome ?? 0
    }

    var qualifyingAnnual: Decimal {
        output?.twoYearAverage.qualifyingAnnualIncome ?? 0
    }

    struct ScenarioSnapshot {
        let inputsJSON: Data
        let keyStat: String
    }

    func buildScenario() -> ScenarioSnapshot {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = (try? encoder.encode(inputs)) ?? Data()
        let monthly = MoneyFormat.shared.decimalString(qualifyingMonthly)
        let key = "\(inputs.businessType.display) · $\(monthly)/mo qualifying"
        return ScenarioSnapshot(inputsJSON: data, keyStat: key)
    }
}
