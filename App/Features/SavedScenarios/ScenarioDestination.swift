// ScenarioDestination.swift
// Shared scenario → calculator-screen dispatcher. Extracted from
// SavedScenariosScreen in Session 5K.4 so the Home tab's "Recent
// scenarios" list can deep-link into the same calculator screens
// with the same loaded inputs + existingScenario handle.

import SwiftUI

/// Dispatches a persisted `Scenario` to its matching calculator
/// screen, decoding the inputs JSON and forwarding `existingScenario`
/// so Save + Share routes behave identically to opening the scenario
/// from the Saved tab.
struct ScenarioDestinationView: View {
    let scenario: Scenario

    var body: some View {
        switch scenario.calculatorType {
        case .amortization:
            AmortizationInputsScreen(
                borrower: scenario.borrower,
                initialInputs: decode(AmortizationFormInputs.self),
                existingScenario: scenario
            )
        case .incomeQualification:
            IncomeQualScreen(
                initialInputs: decode(IncomeQualFormInputs.self),
                existingScenario: scenario
            )
        case .refinance:
            RefinanceScreen(
                initialInputs: decode(RefinanceFormInputs.self),
                existingScenario: scenario
            )
        case .totalCostAnalysis:
            TCAScreen(
                initialInputs: decode(TCAFormInputs.self),
                existingScenario: scenario
            )
        case .helocVsRefinance:
            HelocScreen(
                initialInputs: decode(HelocFormInputs.self),
                existingScenario: scenario
            )
        case .selfEmployment:
            SelfEmploymentInputsScreen(
                borrower: scenario.borrower,
                initialInputs: decode(SelfEmploymentFormInputs.self),
                existingScenario: scenario
            )
        }
    }

    private func decode<T: Decodable>(_ type: T.Type) -> T? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: scenario.inputsJSON)
    }
}
