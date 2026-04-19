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
    /// New loan amount for this option. When 0, engine falls back to
    /// the form-level currentBalance (backward-compat for scenarios
    /// saved before per-option loan amounts were supported).
    var newLoanAmount: Decimal
    /// User-entered monthly MI for this option. MI here is per-option
    /// because different lenders quote different MI for the same
    /// borrower/property even at the same loan amount.
    var monthlyMI: Decimal

    enum CodingKeys: String, CodingKey {
        case id, label, rate, termYears, points, closingCosts
        case newLoanAmount, monthlyMI
    }

    init(
        id: UUID = UUID(),
        label: String,
        rate: Double,
        termYears: Int,
        points: Double = 0,
        closingCosts: Decimal = 0,
        newLoanAmount: Decimal = 0,
        monthlyMI: Decimal = 0
    ) {
        self.id = id
        self.label = label
        self.rate = rate
        self.termYears = termYears
        self.points = points
        self.closingCosts = closingCosts
        self.newLoanAmount = newLoanAmount
        self.monthlyMI = monthlyMI
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.label = try c.decode(String.self, forKey: .label)
        self.rate = try c.decode(Double.self, forKey: .rate)
        self.termYears = try c.decode(Int.self, forKey: .termYears)
        self.points = try c.decode(Double.self, forKey: .points)
        self.closingCosts = try c.decode(Decimal.self, forKey: .closingCosts)
        self.newLoanAmount = try c.decodeIfPresent(Decimal.self, forKey: .newLoanAmount) ?? 0
        self.monthlyMI = try c.decodeIfPresent(Decimal.self, forKey: .monthlyMI) ?? 0
    }
}

struct RefinanceFormInputs: Codable, Hashable, Sendable {
    var currentBalance: Decimal
    var currentRate: Double
    var currentRemainingYears: Int
    /// Monthly MI on the current loan (if any).
    var currentMonthlyMI: Decimal
    /// Current appraised value. Shared across all options — LTV per
    /// option uses this as the denominator.
    var homeValue: Decimal
    var monthlyTaxes: Decimal
    var monthlyInsurance: Decimal
    var monthlyHOA: Decimal
    var options: [RefiOption]
    var horizonsYears: [Int]
    var stressTestHorizonYears: Int  // 3, 5, 10

    enum CodingKeys: String, CodingKey {
        case currentBalance, currentRate, currentRemainingYears
        case currentMonthlyMI, homeValue
        case monthlyTaxes, monthlyInsurance, monthlyHOA
        case options, horizonsYears, stressTestHorizonYears
    }

    init(
        currentBalance: Decimal,
        currentRate: Double,
        currentRemainingYears: Int,
        currentMonthlyMI: Decimal = 0,
        homeValue: Decimal = 0,
        monthlyTaxes: Decimal,
        monthlyInsurance: Decimal,
        monthlyHOA: Decimal,
        options: [RefiOption],
        horizonsYears: [Int],
        stressTestHorizonYears: Int
    ) {
        self.currentBalance = currentBalance
        self.currentRate = currentRate
        self.currentRemainingYears = currentRemainingYears
        self.currentMonthlyMI = currentMonthlyMI
        self.homeValue = homeValue
        self.monthlyTaxes = monthlyTaxes
        self.monthlyInsurance = monthlyInsurance
        self.monthlyHOA = monthlyHOA
        self.options = options
        self.horizonsYears = horizonsYears
        self.stressTestHorizonYears = stressTestHorizonYears
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.currentBalance = try c.decode(Decimal.self, forKey: .currentBalance)
        self.currentRate = try c.decode(Double.self, forKey: .currentRate)
        self.currentRemainingYears = try c.decode(Int.self, forKey: .currentRemainingYears)
        self.currentMonthlyMI = try c.decodeIfPresent(Decimal.self, forKey: .currentMonthlyMI) ?? 0
        self.homeValue = try c.decodeIfPresent(Decimal.self, forKey: .homeValue) ?? 0
        self.monthlyTaxes = try c.decode(Decimal.self, forKey: .monthlyTaxes)
        self.monthlyInsurance = try c.decode(Decimal.self, forKey: .monthlyInsurance)
        self.monthlyHOA = try c.decode(Decimal.self, forKey: .monthlyHOA)
        self.options = try c.decode([RefiOption].self, forKey: .options)
        self.horizonsYears = try c.decode([Int].self, forKey: .horizonsYears)
        self.stressTestHorizonYears = try c.decode(Int.self, forKey: .stressTestHorizonYears)
    }

    /// Effective new loan amount for an option. Falls back to
    /// currentBalance when the option doesn't carry its own.
    func effectiveLoanAmount(for option: RefiOption) -> Decimal {
        option.newLoanAmount > 0 ? option.newLoanAmount : currentBalance
    }

    /// LTV for an option against homeValue. 0 when homeValue is unset.
    func ltv(for option: RefiOption) -> Double {
        guard homeValue > 0 else { return 0 }
        return Double(truncating:
            (effectiveLoanAmount(for: option) / homeValue) as NSNumber)
    }

    /// LTV on the current loan, same denominator.
    var currentLTV: Double {
        guard homeValue > 0 else { return 0 }
        return Double(truncating: (currentBalance / homeValue) as NSNumber)
    }

    static let sampleDefault = RefinanceFormInputs(
        currentBalance: 412_300,
        currentRate: 7.375,
        currentRemainingYears: 28,
        currentMonthlyMI: 0,
        homeValue: 575_000,
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
                    principal: effectiveLoanAmount(for: opt),
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
