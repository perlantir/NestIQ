// IncomeQualInputs.swift
// Codable payload for Income Qualification scenarios. Stored as
// Scenario.inputsJSON.

import Foundation
import QuotientFinance

/// Income qualification can support either a purchase (find the max
/// loan the borrower can afford) or a refinance (find whether the
/// current loan + property still qualify at today's terms).
enum IncomeQualMode: String, Codable, Hashable, Sendable {
    case purchase
    case refinance
}

struct IncomeSource: Codable, Hashable, Sendable, Identifiable {
    var id: UUID
    var label: String
    var monthlyAmount: Decimal
    var weightPercent: Double   // 1.0 = 100%
    var kind: Kind

    enum Kind: String, Codable, Hashable, Sendable, CaseIterable {
        case w2, selfEmployed, rental, other

        var display: String {
            switch self {
            case .w2: "W-2"
            case .selfEmployed: "Self-employed"
            case .rental: "Rental · Schedule E"
            case .other: "Other"
            }
        }
    }

    init(
        id: UUID = UUID(),
        label: String,
        monthlyAmount: Decimal,
        weightPercent: Double = 1.0,
        kind: Kind = .w2
    ) {
        self.id = id
        self.label = label
        self.monthlyAmount = monthlyAmount
        self.weightPercent = weightPercent
        self.kind = kind
    }

    var qualifyingMonthly: Decimal {
        monthlyAmount * Decimal(weightPercent)
    }
}

struct MonthlyDebt: Codable, Hashable, Sendable, Identifiable {
    var id: UUID
    var label: String
    var monthlyAmount: Decimal

    init(id: UUID = UUID(), label: String, monthlyAmount: Decimal) {
        self.id = id
        self.label = label
        self.monthlyAmount = monthlyAmount
    }
}

struct IncomeQualFormInputs: Codable, Hashable, Sendable {
    var mode: IncomeQualMode
    var loanType: String        // stored as String for Codable simplicity
    var creditScore: Int
    var frontEndLimit: Double   // e.g. 0.28
    var backEndLimit: Double    // e.g. 0.43
    var annualRate: Double
    var termYears: Int
    var annualTaxes: Decimal
    var annualInsurance: Decimal
    var monthlyHOA: Decimal
    var downPaymentPercent: Double   // 0.20 default
    var incomes: [IncomeSource]
    var debts: [MonthlyDebt]
    var propertyDP: PropertyDownPaymentConfig
    /// Refinance-mode current appraised value. Drives the live current
    /// LTV readout. 0 in purchase mode (or when the LO hasn't entered
    /// it yet).
    var currentHomeValue: Decimal
    /// Refinance-mode current first-lien balance. Becomes the implicit
    /// loan amount being qualified for. 0 in purchase mode.
    var currentLoanBalance: Decimal
    /// Refinance-mode optional monthly MI on the current loan.
    var refiMonthlyMI: Decimal
    /// Required months of cash reserves. LO-adjustable 0-36. Default is
    /// 2 months — reasonable starting point for conventional loans.
    /// Jumbo, investor property, and self-employed programs may require
    /// up to 24-36 months, so the stepper now spans the full range.
    /// Surfaced on the Results view as "Reserves: $X (N months × PITI)"
    /// using the max qualifying PITI as the month.
    var reservesMonths: Int

    enum CodingKeys: String, CodingKey {
        case mode
        case loanType, creditScore, frontEndLimit, backEndLimit
        case annualRate, termYears, annualTaxes, annualInsurance, monthlyHOA
        case downPaymentPercent, incomes, debts, propertyDP
        case currentHomeValue, currentLoanBalance, refiMonthlyMI
        case reservesMonths
    }

    init(
        mode: IncomeQualMode = .purchase,
        loanType: String,
        creditScore: Int,
        frontEndLimit: Double,
        backEndLimit: Double,
        annualRate: Double,
        termYears: Int,
        annualTaxes: Decimal,
        annualInsurance: Decimal,
        monthlyHOA: Decimal,
        downPaymentPercent: Double,
        incomes: [IncomeSource],
        debts: [MonthlyDebt],
        propertyDP: PropertyDownPaymentConfig = .empty,
        currentHomeValue: Decimal = 0,
        currentLoanBalance: Decimal = 0,
        refiMonthlyMI: Decimal = 0,
        reservesMonths: Int = 2
    ) {
        self.mode = mode
        self.loanType = loanType
        self.creditScore = creditScore
        self.frontEndLimit = frontEndLimit
        self.backEndLimit = backEndLimit
        self.annualRate = annualRate
        self.termYears = termYears
        self.annualTaxes = annualTaxes
        self.annualInsurance = annualInsurance
        self.monthlyHOA = monthlyHOA
        self.downPaymentPercent = downPaymentPercent
        self.incomes = incomes
        self.debts = debts
        self.propertyDP = propertyDP
        self.currentHomeValue = currentHomeValue
        self.currentLoanBalance = currentLoanBalance
        self.refiMonthlyMI = refiMonthlyMI
        self.reservesMonths = reservesMonths
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.mode = try c.decodeIfPresent(IncomeQualMode.self, forKey: .mode) ?? .purchase
        self.loanType = try c.decode(String.self, forKey: .loanType)
        self.creditScore = try c.decode(Int.self, forKey: .creditScore)
        self.frontEndLimit = try c.decode(Double.self, forKey: .frontEndLimit)
        self.backEndLimit = try c.decode(Double.self, forKey: .backEndLimit)
        self.annualRate = try c.decode(Double.self, forKey: .annualRate)
        self.termYears = try c.decode(Int.self, forKey: .termYears)
        self.annualTaxes = try c.decode(Decimal.self, forKey: .annualTaxes)
        self.annualInsurance = try c.decode(Decimal.self, forKey: .annualInsurance)
        self.monthlyHOA = try c.decode(Decimal.self, forKey: .monthlyHOA)
        self.downPaymentPercent = try c.decode(Double.self, forKey: .downPaymentPercent)
        self.incomes = try c.decode([IncomeSource].self, forKey: .incomes)
        self.debts = try c.decode([MonthlyDebt].self, forKey: .debts)
        self.propertyDP = try c.decodeIfPresent(
            PropertyDownPaymentConfig.self, forKey: .propertyDP
        ) ?? .empty
        self.currentHomeValue = try c.decodeIfPresent(Decimal.self, forKey: .currentHomeValue) ?? 0
        self.currentLoanBalance = try c.decodeIfPresent(Decimal.self, forKey: .currentLoanBalance) ?? 0
        self.refiMonthlyMI = try c.decodeIfPresent(Decimal.self, forKey: .refiMonthlyMI) ?? 0
        if let asInt = try? c.decodeIfPresent(Int.self, forKey: .reservesMonths) {
            self.reservesMonths = max(0, min(36, asInt))
        } else if let asDouble = try? c.decodeIfPresent(Double.self, forKey: .reservesMonths) {
            // Legacy schema stored this as Double (2.5-allowing). Round
            // to the nearest integer to fit the stepper's 0-36 Int range.
            self.reservesMonths = max(0, min(36, Int(asDouble.rounded())))
        } else {
            self.reservesMonths = 2
        }
    }

    /// Live current LTV in refinance mode. 0 when home value unset.
    var currentRefiLTV: Double {
        guard currentHomeValue > 0 else { return 0 }
        return Double(truncating: (currentLoanBalance / currentHomeValue) as NSNumber)
    }

    static let sampleDefault = IncomeQualFormInputs(
        loanType: LoanType.conventional.rawValue,
        creditScore: 740,
        frontEndLimit: 0.28,
        backEndLimit: 0.43,
        annualRate: 6.750,
        termYears: 30,
        annualTaxes: 6_500,
        annualInsurance: 1_620,
        monthlyHOA: 0,
        downPaymentPercent: 0.20,
        incomes: [
            IncomeSource(
                label: "Borrower 1",
                monthlyAmount: 8_750,
                kind: .w2
            ),
            IncomeSource(
                label: "Borrower 2",
                monthlyAmount: 6_320,
                kind: .w2
            ),
            IncomeSource(
                label: "Rental",
                monthlyAmount: 1_307,
                weightPercent: 0.75,
                kind: .rental
            ),
        ],
        debts: [
            MonthlyDebt(label: "Auto · lease", monthlyAmount: 482),
            MonthlyDebt(label: "Student loans · IBR", monthlyAmount: 215),
            MonthlyDebt(label: "Minimum CC", monthlyAmount: 130),
        ]
    )

    var qualifyingIncome: Decimal {
        incomes.reduce(0) { $0 + $1.qualifyingMonthly }
    }

    var totalMonthlyDebt: Decimal {
        debts.reduce(0) { $0 + $1.monthlyAmount }
    }

    var monthlyTax: Decimal { annualTaxes / 12 }
    var monthlyInsurance: Decimal { annualInsurance / 12 }

    var loanTypeEnum: LoanType {
        LoanType(rawValue: loanType) ?? .conventional
    }

    var maxQualifyingLoan: Decimal {
        calculateMaxQualifyingLoan(
            grossMonthlyIncome: qualifyingIncome,
            monthlyDebts: totalMonthlyDebt,
            annualRate: annualRate / 100,
            termMonths: termYears * 12,
            monthlyTaxes: monthlyTax,
            monthlyInsurance: monthlyInsurance,
            monthlyHOA: monthlyHOA,
            dtiCap: backEndLimit,
            loanType: loanTypeEnum
        )
    }

    var maxPurchasePrice: Decimal {
        guard downPaymentPercent < 1 else { return maxQualifyingLoan }
        let ratio = Decimal(1 - downPaymentPercent)
        guard ratio > 0 else { return 0 }
        return maxQualifyingLoan / ratio
    }

    var maxPITI: Decimal {
        qualifyingIncome * Decimal(backEndLimit) - totalMonthlyDebt
    }

    var frontEndDTI: Double {
        guard qualifyingIncome > 0 else { return 0 }
        let piti = maxPITI > 0 ? (maxPITI - totalMonthlyDebt) : 0
        return Double(truncating: (piti / qualifyingIncome) as NSNumber)
    }

    var backEndDTI: Double {
        guard qualifyingIncome > 0 else { return 0 }
        let total = maxPITI
        return Double(truncating: (total / qualifyingIncome) as NSNumber)
    }
}
