// IncomeQualInputs.swift
// Codable payload for Income Qualification scenarios. Stored as
// Scenario.inputsJSON.

import Foundation
import QuotientFinance

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
