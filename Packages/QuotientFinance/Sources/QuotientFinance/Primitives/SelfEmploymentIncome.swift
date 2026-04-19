// SelfEmploymentIncome.swift
// Self-employment income cash-flow analysis per Fannie Mae Form 1084
// (subset). Supports three business types common in DTC mortgage:
//
//   * Schedule C (sole proprietor, 1040 Schedule C)
//   * Form 1120S (S-corporation via K-1)
//   * Form 1065 (partnership via K-1)
//
// Out of scope for v1 (Session 7+):
//   * Schedule F (farm)
//   * Schedule E rental (Form 1037 / 1038)
//   * Form 1120 (C-corp)
//   * Business liquidity / quick-ratio analysis
//   * COVID-era Lender Letter guidance
//
// Methodology references: Fannie Mae Selling Guide B3-3.6-03 (Schedule C
// cash flow) and B3-3.6-07 (K-1 income eligibility + distribution
// history rules for partners / S-corp shareholders).

import Foundation

/// Category of self-employment income the borrower reports.
public enum BusinessType: String, Codable, Sendable, Hashable, CaseIterable {
    /// 1040 Schedule C (sole proprietor).
    case scheduleC
    /// Form 1120S S-corp K-1.
    case form1120S
    /// Form 1065 partnership K-1.
    case form1065

    public var display: String {
        switch self {
        case .scheduleC: return "Schedule C"
        case .form1120S: return "S-corp (1120S)"
        case .form1065: return "Partnership (1065)"
        }
    }
}

// MARK: - Schedule C

/// One tax-year of Schedule C line items used for 1084 cash-flow analysis.
/// Each amount is a dollar Decimal; sign convention matches the
/// IRS form line (income/profit positive, expenses positive — subtractions
/// handled by the cash-flow fn).
public struct ScheduleCYear: Codable, Sendable, Hashable {
    public var year: Int
    /// Line 31 — net profit or loss.
    public var netProfit: Decimal
    /// Line 6 — other nonrecurring income or loss, user-entered signed.
    public var nonRecurringOtherIncomeOrLoss: Decimal
    /// Line 12 — depletion (added back).
    public var depletion: Decimal
    /// Line 13 — depreciation (added back).
    public var depreciation: Decimal
    /// Line 24b — non-deductible meals & entertainment (subtracted).
    public var nonDeductibleMealsAndEntertainment: Decimal
    /// Line 30 — business use of home (added back; non-cash).
    public var businessUseOfHome: Decimal
    /// Amortization or casualty loss (added back).
    public var amortizationOrCasualtyLoss: Decimal
    /// Optional: business miles × standard mileage depreciation rate for
    /// the year (added back). Leave 0 when the borrower doesn't use
    /// standard mileage.
    public var mileageDepreciation: Decimal

    public init(
        year: Int,
        netProfit: Decimal,
        nonRecurringOtherIncomeOrLoss: Decimal = 0,
        depletion: Decimal = 0,
        depreciation: Decimal = 0,
        nonDeductibleMealsAndEntertainment: Decimal = 0,
        businessUseOfHome: Decimal = 0,
        amortizationOrCasualtyLoss: Decimal = 0,
        mileageDepreciation: Decimal = 0
    ) {
        self.year = year
        self.netProfit = netProfit
        self.nonRecurringOtherIncomeOrLoss = nonRecurringOtherIncomeOrLoss
        self.depletion = depletion
        self.depreciation = depreciation
        self.nonDeductibleMealsAndEntertainment = nonDeductibleMealsAndEntertainment
        self.businessUseOfHome = businessUseOfHome
        self.amortizationOrCasualtyLoss = amortizationOrCasualtyLoss
        self.mileageDepreciation = mileageDepreciation
    }
}

/// Annualized cash flow for a Schedule C borrower under Fannie 1084.
/// Formula: netProfit + nonRecurring + depletion + depreciation
///          - nonDeductibleMealsAndEntertainment + businessUseOfHome
///          + amortizationOrCasualtyLoss + mileageDepreciation.
/// Signs: all source fields are positive dollar amounts (the caller
/// adjusts `nonRecurringOtherIncomeOrLoss` for sign). Result can be
/// negative when a loss year outweighs the addbacks.
public func cashFlowScheduleC(_ y: ScheduleCYear) -> Decimal {
    y.netProfit
        + y.nonRecurringOtherIncomeOrLoss
        + y.depletion
        + y.depreciation
        - y.nonDeductibleMealsAndEntertainment
        + y.businessUseOfHome
        + y.amortizationOrCasualtyLoss
        + y.mileageDepreciation
}

// MARK: - Form 1120S (S-corp K-1)

/// One tax-year of 1120S K-1 + business return line items.
public struct Form1120SYear: Codable, Sendable, Hashable {
    public var year: Int
    /// 0.0 - 1.0 — borrower's ownership share from K-1.
    public var ownershipPercent: Double
    /// W-2 wages the borrower draws from the S-corp.
    public var w2WagesFromBusiness: Decimal
    /// K-1 Box 1 — ordinary income / loss.
    public var ordinaryIncomeLoss: Decimal
    /// K-1 Box 2 — net rental real estate income.
    public var netRentalRealEstate: Decimal
    /// K-1 Box 3 — other net rental income.
    public var otherNetRentalIncome: Decimal
    /// Business-return addback.
    public var depreciation: Decimal
    public var depletion: Decimal
    public var amortizationOrCasualtyLoss: Decimal
    /// Schedule L mortgages/notes < 1 year end-of-year (subtracted).
    public var mortgageOrNotesLessThan1Yr: Decimal
    /// Non-deductible travel & meals (subtracted).
    public var nonDeductibleTravelMeals: Decimal
    /// Fannie B3-3.6-07 gate: pass-through income is only usable when
    /// the borrower has a consistent distribution history OR ≥ 25%
    /// ownership. When both conditions fail, cash flow from the
    /// pass-through portion = 0 (W-2 wages still count).
    public var hasConsistentDistributionHistory: Bool

    public init(
        year: Int,
        ownershipPercent: Double,
        w2WagesFromBusiness: Decimal = 0,
        ordinaryIncomeLoss: Decimal = 0,
        netRentalRealEstate: Decimal = 0,
        otherNetRentalIncome: Decimal = 0,
        depreciation: Decimal = 0,
        depletion: Decimal = 0,
        amortizationOrCasualtyLoss: Decimal = 0,
        mortgageOrNotesLessThan1Yr: Decimal = 0,
        nonDeductibleTravelMeals: Decimal = 0,
        hasConsistentDistributionHistory: Bool = true
    ) {
        self.year = year
        self.ownershipPercent = ownershipPercent
        self.w2WagesFromBusiness = w2WagesFromBusiness
        self.ordinaryIncomeLoss = ordinaryIncomeLoss
        self.netRentalRealEstate = netRentalRealEstate
        self.otherNetRentalIncome = otherNetRentalIncome
        self.depreciation = depreciation
        self.depletion = depletion
        self.amortizationOrCasualtyLoss = amortizationOrCasualtyLoss
        self.mortgageOrNotesLessThan1Yr = mortgageOrNotesLessThan1Yr
        self.nonDeductibleTravelMeals = nonDeductibleTravelMeals
        self.hasConsistentDistributionHistory = hasConsistentDistributionHistory
    }
}

/// Annualized cash flow for an S-corp K-1 borrower under Fannie 1084 +
/// B3-3.6-07.
///
/// Returns w2Wages when ownership < 25% AND no distribution history
/// (pass-through income not usable). Otherwise returns
/// w2Wages + ownership × (Box1 + Box2 + Box3 + depreciation + depletion
///                        + amortization - mortgageNotes - nonDeductibleTM).
public func cashFlowForm1120S(_ y: Form1120SYear) -> Decimal {
    if !y.hasConsistentDistributionHistory, y.ownershipPercent < 0.25 {
        return y.w2WagesFromBusiness
    }
    let passThrough = y.ordinaryIncomeLoss
        + y.netRentalRealEstate
        + y.otherNetRentalIncome
        + y.depreciation
        + y.depletion
        + y.amortizationOrCasualtyLoss
        - y.mortgageOrNotesLessThan1Yr
        - y.nonDeductibleTravelMeals
    let share = passThrough * Decimal(y.ownershipPercent)
    return y.w2WagesFromBusiness + share
}

// MARK: - Form 1065 (partnership K-1)

/// One tax-year of Form 1065 K-1 + business return line items for a
/// partner. Partnerships don't have W-2 wages to partners (the
/// distinguishing feature vs 1120S) — guaranteed payments take that role.
public struct Form1065Year: Codable, Sendable, Hashable {
    public var year: Int
    public var ownershipPercent: Double
    /// K-1 Box 1 — ordinary income / loss.
    public var ordinaryIncomeLoss: Decimal
    /// K-1 Box 2 — net rental real estate income.
    public var netRentalRealEstate: Decimal
    /// K-1 Box 3 — other net rental income.
    public var otherNetRentalIncome: Decimal
    /// K-1 Box 4c — guaranteed payments to the partner (counted directly,
    /// not scaled by ownership).
    public var guaranteedPayments: Decimal
    public var depreciation: Decimal
    public var depletion: Decimal
    public var amortizationOrCasualtyLoss: Decimal
    public var mortgageOrNotesLessThan1Yr: Decimal
    public var nonDeductibleTravelMeals: Decimal
    public var hasConsistentDistributionHistory: Bool

    public init(
        year: Int,
        ownershipPercent: Double,
        ordinaryIncomeLoss: Decimal = 0,
        netRentalRealEstate: Decimal = 0,
        otherNetRentalIncome: Decimal = 0,
        guaranteedPayments: Decimal = 0,
        depreciation: Decimal = 0,
        depletion: Decimal = 0,
        amortizationOrCasualtyLoss: Decimal = 0,
        mortgageOrNotesLessThan1Yr: Decimal = 0,
        nonDeductibleTravelMeals: Decimal = 0,
        hasConsistentDistributionHistory: Bool = true
    ) {
        self.year = year
        self.ownershipPercent = ownershipPercent
        self.ordinaryIncomeLoss = ordinaryIncomeLoss
        self.netRentalRealEstate = netRentalRealEstate
        self.otherNetRentalIncome = otherNetRentalIncome
        self.guaranteedPayments = guaranteedPayments
        self.depreciation = depreciation
        self.depletion = depletion
        self.amortizationOrCasualtyLoss = amortizationOrCasualtyLoss
        self.mortgageOrNotesLessThan1Yr = mortgageOrNotesLessThan1Yr
        self.nonDeductibleTravelMeals = nonDeductibleTravelMeals
        self.hasConsistentDistributionHistory = hasConsistentDistributionHistory
    }
}

/// Annualized cash flow for a partnership K-1 borrower under Fannie 1084 +
/// B3-3.6-07.
///
/// Returns guaranteed payments only when ownership < 25% AND no
/// distribution history (pass-through not usable; guaranteed payments
/// are contractual and remain countable).
public func cashFlowForm1065(_ y: Form1065Year) -> Decimal {
    if !y.hasConsistentDistributionHistory, y.ownershipPercent < 0.25 {
        return y.guaranteedPayments
    }
    let passThrough = y.ordinaryIncomeLoss
        + y.netRentalRealEstate
        + y.otherNetRentalIncome
        + y.depreciation
        + y.depletion
        + y.amortizationOrCasualtyLoss
        - y.mortgageOrNotesLessThan1Yr
        - y.nonDeductibleTravelMeals
    let share = passThrough * Decimal(y.ownershipPercent)
    return y.guaranteedPayments + share
}

// MARK: - Two-year averaging & trend classification

/// Income trend classification on the two-year average. Thresholds:
///   * ≥ +5% → increasing
///   * within ±5% → stable
///   * -5% to -20% → declining (use lower year per Fannie)
///   * < -20% → significantDecline (lower year + written explanation required)
public enum IncomeTrend: String, Codable, Sendable, Hashable, CaseIterable {
    case increasing
    case stable
    case declining
    case significantDecline

    public var display: String {
        switch self {
        case .increasing: return "Increasing"
        case .stable: return "Stable"
        case .declining: return "Declining — using lower year"
        case .significantDecline: return "Significant decline — explanation required"
        }
    }

    public var usesLowerYear: Bool {
        switch self {
        case .increasing, .stable: return false
        case .declining, .significantDecline: return true
        }
    }
}

/// Result of two-year cash-flow averaging with trend classification.
public struct TwoYearAverage: Codable, Sendable, Hashable {
    /// Older year's cash flow.
    public let year1CashFlow: Decimal
    /// Newer year's cash flow.
    public let year2CashFlow: Decimal
    /// Arithmetic mean of y1 and y2.
    public let average: Decimal
    public let trend: IncomeTrend
    /// Qualifying annual income — the mean when trend is stable or
    /// increasing; the lower year (y2) when declining.
    public let qualifyingAnnualIncome: Decimal
    /// qualifyingAnnualIncome / 12, rounded to money cents.
    public let qualifyingMonthlyIncome: Decimal

    public init(
        year1CashFlow: Decimal,
        year2CashFlow: Decimal,
        average: Decimal,
        trend: IncomeTrend,
        qualifyingAnnualIncome: Decimal,
        qualifyingMonthlyIncome: Decimal
    ) {
        self.year1CashFlow = year1CashFlow
        self.year2CashFlow = year2CashFlow
        self.average = average
        self.trend = trend
        self.qualifyingAnnualIncome = qualifyingAnnualIncome
        self.qualifyingMonthlyIncome = qualifyingMonthlyIncome
    }
}

/// Classify the year-over-year delta and derive qualifying annual + monthly.
///
/// - `y1`: older year cash flow
/// - `y2`: newer year cash flow
///
/// Trend thresholds expressed as fractions of y1:
/// y2 < y1 × 0.80 → .significantDecline; y1 × 0.80 ≤ y2 < y1 × 0.95 →
/// .declining; y1 × 0.95 ≤ y2 ≤ y1 × 1.05 → .stable; y2 > y1 × 1.05 →
/// .increasing.
///
/// Qualifying annual = average when stable/increasing, y2 when declining
/// or significantly declining (Fannie uses the lower of the two years
/// to qualify a borrower whose income is trending down).
///
/// When y1 ≤ 0: any y2 ≥ y1 is treated as .stable (no meaningful %
/// delta to classify); qualifying = mean to avoid a divide-by-zero.
public func twoYearAverage(_ y1: Decimal, _ y2: Decimal) -> TwoYearAverage {
    let mean = (y1 + y2) / 2
    let trend: IncomeTrend
    if y1 <= 0 {
        trend = .stable
    } else {
        let ratio = (y2.asDouble / y1.asDouble) - 1.0
        switch ratio {
        case _ where ratio < -0.20:
            trend = .significantDecline
        case _ where ratio < -0.05:
            trend = .declining
        case _ where ratio > 0.05:
            trend = .increasing
        default:
            trend = .stable
        }
    }
    let qualifyingAnnual = trend.usesLowerYear ? y2 : mean
    let qualifyingMonthly = (qualifyingAnnual / 12).money()
    return TwoYearAverage(
        year1CashFlow: y1,
        year2CashFlow: y2,
        average: mean,
        trend: trend,
        qualifyingAnnualIncome: qualifyingAnnual,
        qualifyingMonthlyIncome: qualifyingMonthly
    )
}
