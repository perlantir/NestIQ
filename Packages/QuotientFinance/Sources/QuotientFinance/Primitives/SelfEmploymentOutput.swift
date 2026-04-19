// SelfEmploymentOutput.swift
// Rolled-up result of a self-employment cash-flow analysis — two years
// of line-item breakdowns plus the averaged qualifying income. The UI
// and PDF consume this directly; the primitives in
// SelfEmploymentIncome.swift feed it.

import Foundation

/// One line-item addback with its source label (for PDF line-item display).
public struct Addback: Codable, Sendable, Hashable {
    public let label: String
    public let amount: Decimal

    public init(label: String, amount: Decimal) {
        self.label = label
        self.amount = amount
    }
}

/// One line-item deduction with its source label.
public struct Deduction: Codable, Sendable, Hashable {
    public let label: String
    public let amount: Decimal

    public init(label: String, amount: Decimal) {
        self.label = label
        self.amount = amount
    }
}

/// Per-year breakdown: the summed cash flow plus the line items that
/// produced it, so the PDF can reproduce the LO's math row by row.
public struct SelfEmploymentYearResult: Codable, Sendable, Hashable {
    public let year: Int
    public let cashFlow: Decimal
    public let addbacks: [Addback]
    public let deductions: [Deduction]

    public init(
        year: Int,
        cashFlow: Decimal,
        addbacks: [Addback],
        deductions: [Deduction]
    ) {
        self.year = year
        self.cashFlow = cashFlow
        self.addbacks = addbacks
        self.deductions = deductions
    }
}

/// Discriminated union of per-business-type inputs for the compute helper.
public enum SelfEmploymentInput: Codable, Sendable, Hashable {
    case scheduleC(y1: ScheduleCYear, y2: ScheduleCYear)
    case form1120S(y1: Form1120SYear, y2: Form1120SYear)
    case form1065(y1: Form1065Year, y2: Form1065Year)

    public var businessType: BusinessType {
        switch self {
        case .scheduleC: return .scheduleC
        case .form1120S: return .form1120S
        case .form1065: return .form1065
        }
    }
}

/// Full analysis output. `qualifyingMonthlyIncome` is the headline number
/// shown on the Results view; `trendNotes` is an auto-generated string
/// describing the two-year trend when it's anything other than stable.
public struct SelfEmploymentOutput: Codable, Sendable, Hashable {
    public let businessType: BusinessType
    public let year1: SelfEmploymentYearResult
    public let year2: SelfEmploymentYearResult
    public let twoYearAverage: TwoYearAverage
    public let trendNotes: String?
    public let qualifyingMonthlyIncome: Decimal

    public init(
        businessType: BusinessType,
        year1: SelfEmploymentYearResult,
        year2: SelfEmploymentYearResult,
        twoYearAverage: TwoYearAverage,
        trendNotes: String?,
        qualifyingMonthlyIncome: Decimal
    ) {
        self.businessType = businessType
        self.year1 = year1
        self.year2 = year2
        self.twoYearAverage = twoYearAverage
        self.trendNotes = trendNotes
        self.qualifyingMonthlyIncome = qualifyingMonthlyIncome
    }
}

/// Compute a full two-year self-employment analysis for the given input.
/// Line-item addbacks/deductions are surfaced so the PDF can show the
/// LO's math without re-deriving it.
public func compute(input: SelfEmploymentInput) -> SelfEmploymentOutput {
    switch input {
    case let .scheduleC(y1, y2):
        return computeScheduleC(y1: y1, y2: y2)
    case let .form1120S(y1, y2):
        return compute1120S(y1: y1, y2: y2)
    case let .form1065(y1, y2):
        return compute1065(y1: y1, y2: y2)
    }
}

// MARK: - Helpers

private func computeScheduleC(y1: ScheduleCYear, y2: ScheduleCYear) -> SelfEmploymentOutput {
    let r1 = scheduleCYearResult(y: y1)
    let r2 = scheduleCYearResult(y: y2)
    let avg = twoYearAverage(r1.cashFlow, r2.cashFlow)
    return SelfEmploymentOutput(
        businessType: .scheduleC,
        year1: r1,
        year2: r2,
        twoYearAverage: avg,
        trendNotes: trendNote(for: avg),
        qualifyingMonthlyIncome: avg.qualifyingMonthlyIncome
    )
}

private func compute1120S(y1: Form1120SYear, y2: Form1120SYear) -> SelfEmploymentOutput {
    let r1 = form1120SYearResult(y: y1)
    let r2 = form1120SYearResult(y: y2)
    let avg = twoYearAverage(r1.cashFlow, r2.cashFlow)
    return SelfEmploymentOutput(
        businessType: .form1120S,
        year1: r1,
        year2: r2,
        twoYearAverage: avg,
        trendNotes: trendNote(for: avg),
        qualifyingMonthlyIncome: avg.qualifyingMonthlyIncome
    )
}

private func compute1065(y1: Form1065Year, y2: Form1065Year) -> SelfEmploymentOutput {
    let r1 = form1065YearResult(y: y1)
    let r2 = form1065YearResult(y: y2)
    let avg = twoYearAverage(r1.cashFlow, r2.cashFlow)
    return SelfEmploymentOutput(
        businessType: .form1065,
        year1: r1,
        year2: r2,
        twoYearAverage: avg,
        trendNotes: trendNote(for: avg),
        qualifyingMonthlyIncome: avg.qualifyingMonthlyIncome
    )
}

private func scheduleCYearResult(y: ScheduleCYear) -> SelfEmploymentYearResult {
    var addbacks: [Addback] = []
    if y.depletion > 0 {
        addbacks.append(Addback(label: "Depletion (Line 12)", amount: y.depletion))
    }
    if y.depreciation > 0 {
        addbacks.append(Addback(label: "Depreciation (Line 13)", amount: y.depreciation))
    }
    if y.businessUseOfHome > 0 {
        addbacks.append(Addback(label: "Business use of home (Line 30)",
                                amount: y.businessUseOfHome))
    }
    if y.amortizationOrCasualtyLoss > 0 {
        addbacks.append(Addback(label: "Amortization / casualty loss",
                                amount: y.amortizationOrCasualtyLoss))
    }
    if y.mileageDepreciation > 0 {
        addbacks.append(Addback(label: "Mileage depreciation",
                                amount: y.mileageDepreciation))
    }
    var deductions: [Deduction] = []
    if y.nonDeductibleMealsAndEntertainment > 0 {
        deductions.append(Deduction(label: "Non-deductible meals (Line 24b)",
                                    amount: y.nonDeductibleMealsAndEntertainment))
    }
    return SelfEmploymentYearResult(
        year: y.year,
        cashFlow: cashFlowScheduleC(y),
        addbacks: addbacks,
        deductions: deductions
    )
}

private func form1120SYearResult(y: Form1120SYear) -> SelfEmploymentYearResult {
    var addbacks: [Addback] = []
    if y.w2WagesFromBusiness > 0 {
        addbacks.append(Addback(label: "W-2 wages from business",
                                amount: y.w2WagesFromBusiness))
    }
    if y.ordinaryIncomeLoss != 0 {
        addbacks.append(Addback(
            label: "Ordinary income (K-1 Box 1) · share",
            amount: y.ordinaryIncomeLoss * Decimal(y.ownershipPercent)
        ))
    }
    if y.netRentalRealEstate != 0 {
        addbacks.append(Addback(
            label: "Net rental RE (K-1 Box 2) · share",
            amount: y.netRentalRealEstate * Decimal(y.ownershipPercent)
        ))
    }
    if y.otherNetRentalIncome != 0 {
        addbacks.append(Addback(
            label: "Other rental (K-1 Box 3) · share",
            amount: y.otherNetRentalIncome * Decimal(y.ownershipPercent)
        ))
    }
    if y.depreciation > 0 {
        addbacks.append(Addback(
            label: "Depreciation · share",
            amount: y.depreciation * Decimal(y.ownershipPercent)
        ))
    }
    if y.depletion > 0 {
        addbacks.append(Addback(
            label: "Depletion · share",
            amount: y.depletion * Decimal(y.ownershipPercent)
        ))
    }
    if y.amortizationOrCasualtyLoss > 0 {
        addbacks.append(Addback(
            label: "Amortization / casualty · share",
            amount: y.amortizationOrCasualtyLoss * Decimal(y.ownershipPercent)
        ))
    }
    var deductions: [Deduction] = []
    if y.mortgageOrNotesLessThan1Yr > 0 {
        deductions.append(Deduction(
            label: "Mortgage / notes < 1 yr (Sched L) · share",
            amount: y.mortgageOrNotesLessThan1Yr * Decimal(y.ownershipPercent)
        ))
    }
    if y.nonDeductibleTravelMeals > 0 {
        deductions.append(Deduction(
            label: "Non-deductible travel / meals · share",
            amount: y.nonDeductibleTravelMeals * Decimal(y.ownershipPercent)
        ))
    }
    return SelfEmploymentYearResult(
        year: y.year,
        cashFlow: cashFlowForm1120S(y),
        addbacks: addbacks,
        deductions: deductions
    )
}

private func form1065YearResult(y: Form1065Year) -> SelfEmploymentYearResult {
    var addbacks: [Addback] = []
    if y.guaranteedPayments > 0 {
        addbacks.append(Addback(label: "Guaranteed payments (K-1 Box 4c)",
                                amount: y.guaranteedPayments))
    }
    if y.ordinaryIncomeLoss != 0 {
        addbacks.append(Addback(
            label: "Ordinary income (K-1 Box 1) · share",
            amount: y.ordinaryIncomeLoss * Decimal(y.ownershipPercent)
        ))
    }
    if y.netRentalRealEstate != 0 {
        addbacks.append(Addback(
            label: "Net rental RE (K-1 Box 2) · share",
            amount: y.netRentalRealEstate * Decimal(y.ownershipPercent)
        ))
    }
    if y.otherNetRentalIncome != 0 {
        addbacks.append(Addback(
            label: "Other rental (K-1 Box 3) · share",
            amount: y.otherNetRentalIncome * Decimal(y.ownershipPercent)
        ))
    }
    if y.depreciation > 0 {
        addbacks.append(Addback(
            label: "Depreciation · share",
            amount: y.depreciation * Decimal(y.ownershipPercent)
        ))
    }
    if y.depletion > 0 {
        addbacks.append(Addback(
            label: "Depletion · share",
            amount: y.depletion * Decimal(y.ownershipPercent)
        ))
    }
    if y.amortizationOrCasualtyLoss > 0 {
        addbacks.append(Addback(
            label: "Amortization / casualty · share",
            amount: y.amortizationOrCasualtyLoss * Decimal(y.ownershipPercent)
        ))
    }
    var deductions: [Deduction] = []
    if y.mortgageOrNotesLessThan1Yr > 0 {
        deductions.append(Deduction(
            label: "Mortgage / notes < 1 yr · share",
            amount: y.mortgageOrNotesLessThan1Yr * Decimal(y.ownershipPercent)
        ))
    }
    if y.nonDeductibleTravelMeals > 0 {
        deductions.append(Deduction(
            label: "Non-deductible travel / meals · share",
            amount: y.nonDeductibleTravelMeals * Decimal(y.ownershipPercent)
        ))
    }
    return SelfEmploymentYearResult(
        year: y.year,
        cashFlow: cashFlowForm1065(y),
        addbacks: addbacks,
        deductions: deductions
    )
}

private func trendNote(for avg: TwoYearAverage) -> String? {
    let delta = avg.year2CashFlow - avg.year1CashFlow
    let deltaInt = (delta as NSDecimalNumber).intValue
    switch avg.trend {
    case .stable:
        return nil
    case .increasing:
        return "Year-over-year increase of $\(abs(deltaInt).formatted()) — qualifying at two-year average (conservative)."
    case .declining:
        let pct = avg.year1CashFlow > 0
            ? Int((avg.year2CashFlow.asDouble / avg.year1CashFlow.asDouble - 1.0) * -100)
            : 0
        return "Income declining ~\(pct)% year over year — using the lower year per Fannie guideline."
    case .significantDecline:
        let pct = avg.year1CashFlow > 0
            ? Int((avg.year2CashFlow.asDouble / avg.year1CashFlow.asDouble - 1.0) * -100)
            : 0
        return "Significant decline (~\(pct)%) — using lower year; written explanation from borrower required per Fannie B3-3.6-03."
    }
}
