// Types.swift
// Core value types for the calculation engine.
//
// All monetary amounts are `Foundation.Decimal` for exact base-10 storage.
// All interest rates are `Double` expressed as decimal fractions
// (6.75% = 0.0675), with `Double` exponentiation used for period-factor
// math and results rounded back to `Decimal` cents at payment boundaries.

import Foundation

// MARK: - Loan

/// Category of mortgage product. Determines default day-count, PMI rules,
/// QM treatment, and APOR table selection.
public enum LoanType: String, Sendable, Codable, Hashable, CaseIterable {
    case conventional
    case fha
    case va
    case usda
    case jumbo
    case heloc
}

/// How interest accrues from one period to the next.
public enum RateType: String, Sendable, Codable, Hashable, CaseIterable {
    case fixed
    case armSOFR       // Secured Overnight Financing Rate index
    case armTreasury   // Constant-maturity Treasury index
}

/// Payment cadence. `biweekly` is 26 payments/year — standard U.S. biweekly
/// mortgage programs schedule (monthly P&I / 2) every 14 days, yielding an
/// extra monthly payment per year of principal reduction.
public enum PaymentFrequency: String, Sendable, Codable, Hashable, CaseIterable {
    case monthly
    case biweekly
    case semiMonthly
    case weekly

    public var paymentsPerYear: Int {
        switch self {
        case .monthly:     return 12
        case .biweekly:    return 26
        case .semiMonthly: return 24
        case .weekly:      return 52
        }
    }

    /// Average days between payments; used when converting an annual rate to
    /// a per-period rate under an actual/365 convention.
    public var averageDaysPerPeriod: Double {
        365.0 / Double(paymentsPerYear)
    }
}

/// Day-count convention used for period-interest accrual. The choice is
/// driven by the product — never by the calculator.
///
/// - `.thirty360`: 30 day months, 360 day year. Conventional / FHA / VA / USDA.
/// - `.actual365`: actual calendar days over a 365 day year. HELOCs.
/// - `.actual360`: actual days over 360 days. SOFR-indexed ARMs.
/// - `.actualActual`: actual days over actual year length. Treasury-indexed ARMs.
public enum DayCountConvention: String, Sendable, Codable, Hashable, CaseIterable {
    case thirty360
    case actual365
    case actual360
    case actualActual

    public var daysPerYear: Double {
        switch self {
        case .thirty360:    return 360
        case .actual365:    return 365
        case .actual360:    return 360
        case .actualActual: return 365.25
        }
    }
}

/// A loan as an input to the calculation engine.
///
/// Day-count and APR treatment are derived from `loanType` + `rateType` rather
/// than being duplicated on the struct — single source of truth keeps invalid
/// combinations unrepresentable.
public struct Loan: Sendable, Hashable, Codable {
    public var principal: Decimal
    public var annualRate: Double
    public var termMonths: Int
    public var loanType: LoanType
    public var rateType: RateType
    public var startDate: Date
    public var frequency: PaymentFrequency

    public init(
        principal: Decimal,
        annualRate: Double,
        termMonths: Int,
        loanType: LoanType = .conventional,
        rateType: RateType = .fixed,
        startDate: Date,
        frequency: PaymentFrequency = .monthly
    ) {
        self.principal = principal
        self.annualRate = annualRate
        self.termMonths = termMonths
        self.loanType = loanType
        self.rateType = rateType
        self.startDate = startDate
        self.frequency = frequency
    }

    /// Day-count convention implied by `loanType` and `rateType`.
    public var dayCount: DayCountConvention {
        switch (loanType, rateType) {
        case (.heloc, _):               return .actual365
        case (_, .armSOFR):             return .actual360
        case (_, .armTreasury):         return .actualActual
        case (_, .fixed):               return .thirty360
        }
    }
}

// MARK: - Amortization inputs

/// Extra principal applied at a specific payment period.
public struct ExtraPayment: Sendable, Hashable, Codable {
    /// 1-indexed payment number; `1` is the first payment.
    public var period: Int
    public var amount: Decimal

    public init(period: Int, amount: Decimal) {
        self.period = period
        self.amount = amount
    }
}

/// Private Mortgage Insurance schedule attached to a loan.
///
/// Automatic termination under the Homeowners Protection Act (§1321) occurs
/// at the scheduled 78% LTV point — that is, based on the original
/// amortization schedule, **not** the actual balance (extra principal doesn't
/// accelerate termination for conventional PMI). FHA MIP is typically
/// permanent when the original LTV > 90% and therefore has `isPermanent = true`.
public struct PMISchedule: Sendable, Hashable, Codable {
    public var monthlyAmount: Decimal
    /// Appraised value at origination. PMI drop compares scheduled balance
    /// against this, not current market value.
    public var originalValue: Decimal
    /// LTV threshold at which PMI terminates automatically. `0.78` per HPA.
    public var dropAtLTV: Double
    /// Earliest period PMI may terminate. Some servicers require a minimum
    /// seasoning (commonly 24 months) regardless of LTV.
    public var minimumPeriods: Int
    /// `true` for FHA MIP on loans with original LTV > 90% — runs for the life
    /// of the loan and cannot be cancelled via LTV crossover.
    public var isPermanent: Bool

    public init(
        monthlyAmount: Decimal,
        originalValue: Decimal,
        dropAtLTV: Double = 0.78,
        minimumPeriods: Int = 0,
        isPermanent: Bool = false
    ) {
        self.monthlyAmount = monthlyAmount
        self.originalValue = originalValue
        self.dropAtLTV = dropAtLTV
        self.minimumPeriods = minimumPeriods
        self.isPermanent = isPermanent
    }
}

/// Optional extras that modify a plain-vanilla amortization.
///
/// - `extraPeriodicPrincipal`: added to every scheduled payment.
/// - `oneTimeExtra`: specific periods with a lump-sum extra principal.
/// - `recastPeriods`: periods after which to re-amortize the remaining
///   balance over the remaining term. Recast reduces the subsequent scheduled
///   payment without changing the maturity date.
/// - `pmiSchedule`: PMI policy, if any.
public struct AmortizationOptions: Sendable, Hashable, Codable {
    public var extraPeriodicPrincipal: Decimal
    public var oneTimeExtra: [ExtraPayment]
    public var recastPeriods: [Int]
    public var pmiSchedule: PMISchedule?

    public init(
        extraPeriodicPrincipal: Decimal = 0,
        oneTimeExtra: [ExtraPayment] = [],
        recastPeriods: [Int] = [],
        pmiSchedule: PMISchedule? = nil
    ) {
        self.extraPeriodicPrincipal = extraPeriodicPrincipal
        self.oneTimeExtra = oneTimeExtra
        self.recastPeriods = recastPeriods
        self.pmiSchedule = pmiSchedule
    }

    public static let none = AmortizationOptions()
}

// MARK: - PMI inputs

/// How PMI is paid. Affects the monthly premium formula and the
/// APR-inclusion treatment under Reg Z.
public enum PMIPaymentType: String, Sendable, Codable, Hashable, CaseIterable {
    case monthly        // BPMI paid monthly — drops at 78% LTV
    case singlePremium  // BPMI paid upfront — no monthly component
    case lenderPaid     // LPMI — higher note rate, no cancellation
    case splitPremium   // upfront + reduced monthly
}

// MARK: - Comparison

/// One scenario feeding `compareScenarios` — a loan plus the non-P&I carrying
/// costs needed for a true total-cost comparison at each horizon.
///
/// Index 0 of the `scenarios` array is treated as the **baseline** by
/// `compareScenarios` — deltas (`monthlyPIDelta`, `lifetimeCostDelta`) are
/// relative to it, and `breakEvenMonth` is computed vs. it.
public struct ScenarioInput: Sendable, Hashable, Codable {
    public let name: String
    public let loan: Loan
    public let closingCosts: Decimal
    public let monthlyTaxes: Decimal
    public let monthlyInsurance: Decimal
    public let monthlyHOA: Decimal
    public let options: AmortizationOptions

    public init(
        name: String,
        loan: Loan,
        closingCosts: Decimal = 0,
        monthlyTaxes: Decimal = 0,
        monthlyInsurance: Decimal = 0,
        monthlyHOA: Decimal = 0,
        options: AmortizationOptions = .none
    ) {
        self.name = name
        self.loan = loan
        self.closingCosts = closingCosts
        self.monthlyTaxes = monthlyTaxes
        self.monthlyInsurance = monthlyInsurance
        self.monthlyHOA = monthlyHOA
        self.options = options
    }
}

/// Per-scenario metrics surfaced in the Refi Comparison + TCA UIs.
///
/// `npvAt5pct` is the present value of the scenario's all-in monthly cash
/// outflows (P&I + PMI + extras + T+I+HOA) plus upfront closing costs,
/// discounted at 5% annual with monthly compounding over the longest horizon
/// supplied to `compareScenarios`. Loans are cash outflows, so `npvAt5pct` is
/// negative; smaller magnitude is better. Callers who want a "refi NPV" —
/// the signed savings vs. the baseline — should subtract the baseline's
/// `npvAt5pct`.
///
/// `monthlyPIDelta` is the scheduled P&I minus the baseline's scheduled P&I —
/// positive means this scenario pays more each month.
///
/// `lifetimeCostDelta` is `scenarioTotalCosts[i][last horizon]` minus the
/// baseline's same cell; precomputed so callers don't re-derive it.
///
/// `breakEvenMonth` is `nil` for the baseline itself and for any scenario
/// whose P&I is not strictly lower than the baseline's (no monthly savings
/// to recoup the net upfront cost).
public struct ScenarioMetrics: Sendable, Hashable, Codable {
    public let payment: Decimal
    public let totalInterest: Decimal
    public let totalPaid: Decimal
    public let breakEvenMonth: Int?
    public let npvAt5pct: Decimal
    public let monthlyPIDelta: Decimal
    public let lifetimeCostDelta: Decimal

    public init(
        payment: Decimal,
        totalInterest: Decimal,
        totalPaid: Decimal,
        breakEvenMonth: Int?,
        npvAt5pct: Decimal,
        monthlyPIDelta: Decimal,
        lifetimeCostDelta: Decimal
    ) {
        self.payment = payment
        self.totalInterest = totalInterest
        self.totalPaid = totalPaid
        self.breakEvenMonth = breakEvenMonth
        self.npvAt5pct = npvAt5pct
        self.monthlyPIDelta = monthlyPIDelta
        self.lifetimeCostDelta = lifetimeCostDelta
    }
}

/// Result of comparing several scenarios over specified horizons.
///
/// `scenarioMetrics` is indexed parallel to `scenarioTotalCosts` — the entry
/// at index `i` describes the scenario that produced `scenarioTotalCosts[i]`.
/// Defaults to an empty array so Session 1 call sites that predate the
/// metrics addition keep compiling unchanged.
public struct ComparisonResult: Sendable, Hashable, Codable {
    public let scenarioTotalCosts: [[Decimal]]   // [scenarioIndex][horizonIndex]
    public let winnerByHorizon: [Int]            // scenario index winning each horizon
    public let horizons: [Int]                   // in years, e.g. [5, 7, 10, 15, 30]
    public let scenarioMetrics: [ScenarioMetrics]

    public init(
        scenarioTotalCosts: [[Decimal]],
        winnerByHorizon: [Int],
        horizons: [Int],
        scenarioMetrics: [ScenarioMetrics] = []
    ) {
        self.scenarioTotalCosts = scenarioTotalCosts
        self.winnerByHorizon = winnerByHorizon
        self.horizons = horizons
        self.scenarioMetrics = scenarioMetrics
    }
}
