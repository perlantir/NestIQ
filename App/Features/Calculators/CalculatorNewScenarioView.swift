// CalculatorNewScenarioView.swift
// Router from Home's calculators list into the right inputs screen.
// Session 3.4 builds the real Amortization Inputs; Session 4 builds the
// other four. Until then each calculator routes to a stub placeholder
// that still exercises the navigation wiring.

import SwiftUI

struct CalculatorNewScenarioView: View {
    let calculator: CalculatorType

    var body: some View {
        switch calculator {
        case .amortization:
            AmortizationInputsScreen(borrower: nil)
        case .incomeQualification:
            ComingSoonStub(calculator: calculator)
        case .refinance:
            ComingSoonStub(calculator: calculator)
        case .totalCostAnalysis:
            ComingSoonStub(calculator: calculator)
        case .helocVsRefinance:
            ComingSoonStub(calculator: calculator)
        }
    }
}

struct ComingSoonStub: View {
    let calculator: CalculatorType

    var body: some View {
        VStack(spacing: Spacing.s16) {
            Eyebrow("\(calculator.number) · \(CalculatorCopy.longName(for: calculator))")
            Text("Ships in Session 4.")
                .textStyle(Typography.h2)
                .foregroundStyle(Palette.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
        .navigationBarTitleDisplayMode(.inline)
    }
}
