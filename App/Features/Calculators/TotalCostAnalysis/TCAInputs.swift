// TCAInputs.swift
// 2-4 scenarios × 5 horizons (5/7/10/15/30 yr). Stored as inputsJSON.

import Foundation
import QuotientFinance

struct TCAScenario: Codable, Hashable, Sendable, Identifiable {
    var id: UUID
    var label: String       // "A", "B", …
    var name: String        // "Conv 30", "Conv 15"
    var rate: Double
    var termYears: Int
    var points: Double
    var closingCosts: Decimal

    init(
        id: UUID = UUID(),
        label: String,
        name: String,
        rate: Double,
        termYears: Int,
        points: Double = 0,
        closingCosts: Decimal = 0
    ) {
        self.id = id
        self.label = label
        self.name = name
        self.rate = rate
        self.termYears = termYears
        self.points = points
        self.closingCosts = closingCosts
    }
}

struct TCAFormInputs: Codable, Hashable, Sendable {
    var loanAmount: Decimal
    var monthlyTaxes: Decimal
    var monthlyInsurance: Decimal
    var monthlyHOA: Decimal
    var scenarios: [TCAScenario]
    var horizonsYears: [Int]

    static let sampleDefault = TCAFormInputs(
        loanAmount: 548_000,
        monthlyTaxes: 542,
        monthlyInsurance: 135,
        monthlyHOA: 0,
        scenarios: [
            TCAScenario(
                label: "A",
                name: "Conv 30",
                rate: 6.750,
                termYears: 30
            ),
            TCAScenario(
                label: "B",
                name: "Conv 15",
                rate: 5.875,
                termYears: 15
            ),
            TCAScenario(
                label: "C",
                name: "FHA 30",
                rate: 6.375,
                termYears: 30,
                points: 0.5
            ),
            TCAScenario(
                label: "D",
                name: "Buydown",
                rate: 4.750,
                termYears: 30,
                points: 2.75,
                closingCosts: 15_100
            ),
        ],
        horizonsYears: [5, 7, 10, 15, 30]
    )

    func scenarioInputs() -> [ScenarioInput] {
        scenarios.map { s in
            let pointsCost = loanAmount * Decimal(s.points) / 100
            return ScenarioInput(
                name: s.label,
                loan: Loan(
                    principal: loanAmount,
                    annualRate: s.rate / 100,
                    termMonths: s.termYears * 12,
                    startDate: Date()
                ),
                closingCosts: s.closingCosts + pointsCost,
                monthlyTaxes: monthlyTaxes,
                monthlyInsurance: monthlyInsurance,
                monthlyHOA: monthlyHOA
            )
        }
    }
}
