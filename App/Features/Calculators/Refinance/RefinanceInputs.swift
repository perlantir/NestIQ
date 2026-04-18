// RefinanceInputs.swift
// Codable payload for a refi comparison: current loan + up to 3 option
// loans. Horizons default to [5, 7, 10, 15, 30] per spec.

import Foundation
import QuotientFinance

struct RefiOption: Codable, Hashable, Sendable, Identifiable {
    var id: UUID
    var label: String   // "A", "B", "C"
    var rate: Double    // %
    var termYears: Int
    var points: Double
    var closingCosts: Decimal

    init(
        id: UUID = UUID(),
        label: String,
        rate: Double,
        termYears: Int,
        points: Double = 0,
        closingCosts: Decimal = 0
    ) {
        self.id = id
        self.label = label
        self.rate = rate
        self.termYears = termYears
        self.points = points
        self.closingCosts = closingCosts
    }
}

struct RefinanceFormInputs: Codable, Hashable, Sendable {
    var currentBalance: Decimal
    var currentRate: Double
    var currentRemainingYears: Int
    var monthlyTaxes: Decimal
    var monthlyInsurance: Decimal
    var monthlyHOA: Decimal
    var options: [RefiOption]
    var horizonsYears: [Int]
    var stressTestHorizonYears: Int  // 3, 5, 10
    var propertyDP: PropertyDownPaymentConfig

    enum CodingKeys: String, CodingKey {
        case currentBalance, currentRate, currentRemainingYears
        case monthlyTaxes, monthlyInsurance, monthlyHOA
        case options, horizonsYears, stressTestHorizonYears, propertyDP
    }

    init(
        currentBalance: Decimal,
        currentRate: Double,
        currentRemainingYears: Int,
        monthlyTaxes: Decimal,
        monthlyInsurance: Decimal,
        monthlyHOA: Decimal,
        options: [RefiOption],
        horizonsYears: [Int],
        stressTestHorizonYears: Int,
        propertyDP: PropertyDownPaymentConfig = .empty
    ) {
        self.currentBalance = currentBalance
        self.currentRate = currentRate
        self.currentRemainingYears = currentRemainingYears
        self.monthlyTaxes = monthlyTaxes
        self.monthlyInsurance = monthlyInsurance
        self.monthlyHOA = monthlyHOA
        self.options = options
        self.horizonsYears = horizonsYears
        self.stressTestHorizonYears = stressTestHorizonYears
        self.propertyDP = propertyDP
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.currentBalance = try c.decode(Decimal.self, forKey: .currentBalance)
        self.currentRate = try c.decode(Double.self, forKey: .currentRate)
        self.currentRemainingYears = try c.decode(Int.self, forKey: .currentRemainingYears)
        self.monthlyTaxes = try c.decode(Decimal.self, forKey: .monthlyTaxes)
        self.monthlyInsurance = try c.decode(Decimal.self, forKey: .monthlyInsurance)
        self.monthlyHOA = try c.decode(Decimal.self, forKey: .monthlyHOA)
        self.options = try c.decode([RefiOption].self, forKey: .options)
        self.horizonsYears = try c.decode([Int].self, forKey: .horizonsYears)
        self.stressTestHorizonYears = try c.decode(Int.self, forKey: .stressTestHorizonYears)
        self.propertyDP = try c.decodeIfPresent(
            PropertyDownPaymentConfig.self, forKey: .propertyDP
        ) ?? .empty
    }

    static let sampleDefault = RefinanceFormInputs(
        currentBalance: 412_300,
        currentRate: 7.375,
        currentRemainingYears: 28,
        monthlyTaxes: 542,
        monthlyInsurance: 135,
        monthlyHOA: 0,
        options: [
            RefiOption(label: "A", rate: 6.125, termYears: 30, points: 0.5, closingCosts: 9_800),
            RefiOption(label: "B", rate: 6.500, termYears: 25, points: 0, closingCosts: 5_200),
            RefiOption(label: "C", rate: 5.875, termYears: 30, points: 1.5, closingCosts: 14_800),
        ],
        horizonsYears: [5, 7, 10, 15, 30],
        stressTestHorizonYears: 5
    )

    func scenarioInputs() -> [ScenarioInput] {
        let current = ScenarioInput(
            name: "Current",
            loan: Loan(
                principal: currentBalance,
                annualRate: currentRate / 100,
                termMonths: currentRemainingYears * 12,
                startDate: Date()
            ),
            closingCosts: 0,
            monthlyTaxes: monthlyTaxes,
            monthlyInsurance: monthlyInsurance,
            monthlyHOA: monthlyHOA
        )
        let opts = options.map { opt in
            ScenarioInput(
                name: opt.label,
                loan: Loan(
                    principal: currentBalance,
                    annualRate: opt.rate / 100,
                    termMonths: opt.termYears * 12,
                    startDate: Date()
                ),
                closingCosts: opt.closingCosts,
                monthlyTaxes: monthlyTaxes,
                monthlyInsurance: monthlyInsurance,
                monthlyHOA: monthlyHOA
            )
        }
        return [current] + opts
    }
}
