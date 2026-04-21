// HelocInputs.swift
// Compare keeping the 1st + adding a HELOC vs a cash-out refi.

import Foundation
import QuotientFinance

/// Index source used to quote a HELOC's fully-indexed rate. Session 7.3b
/// added this as an input-form field so the PDF can display
/// "Prime + 0.50" / "WSJ Prime + …" / "SOFR + …" style text.
///
/// TODO: v0.1.2 wire FRED lookup so the LO can see today's index value
/// when choosing (FRED series: DPRIME for Prime / Daily Bank Prime Loan
/// Rate; WSJ Prime is identical in practice; SOFR has its own series).
enum HelocIndexType: String, Codable, Hashable, Sendable, CaseIterable {
    case prime
    case wsjPrime
    case sofr

    var displayName: String {
        switch self {
        case .prime:    return "Prime"
        case .wsjPrime: return "WSJ Prime"
        case .sofr:     return "SOFR"
        }
    }
}

/// One row in the HELOC rate stress-test table (v2.1.1 template:
/// 5 rows — today, flat, +100 bps, +200 bps, +300 bps/at cap).
struct StressRow: Sendable, Hashable {
    /// "Today", "Flat", "+100 bps", "+200 bps", "+300 bps / at cap"
    let scenarioLabel: String
    /// HELOC fully-indexed rate at this scenario, percent.
    let rate: Decimal
    /// Blended (first-lien + HELOC) monthly payment at this rate.
    let payment: Decimal
    /// Dollar delta vs the "Today" payment. Zero for Today/Flat.
    let delta: Decimal
    /// Peak monthly payment during the repayment period at this rate.
    let peak: Decimal
    /// Blended 10-year effective rate for the +200 bps row only
    /// (populates `stress_plus2_blended` in the v2.1.1 refi-vs-HELOC
    /// guardrail call-out). Nil on other rows.
    let blendedRate: Decimal?
}

struct HelocFormInputs: Codable, Hashable, Sendable {
    var firstLienBalance: Decimal
    var firstLienRate: Double           // % — untouched
    var firstLienRemainingYears: Int
    var helocAmount: Decimal
    var helocIntroRate: Double          // %
    var helocIntroMonths: Int
    var helocFullyIndexedRate: Double   // %
    var refiRate: Double                // % — alternative cash-out refi
    var refiTermYears: Int
    /// Monthly MI on the cash-out refi option. HELOCs are second-lien
    /// and don't carry PMI, so there is no HELOC-side MI field.
    var refiMonthlyMI: Decimal
    /// Appraised value. LTV (1st lien only) and CLTV (1st + HELOC)
    /// render against this.
    var homeValue: Decimal
    var stressShockBps: Int             // e.g. 200 for +2pt
    /// Session 5M.1: optional APR on the existing first lien.
    /// Display-only (D1); `nil` collapses display to rate alone (D2).
    var firstLienAPR: Decimal?
    /// Session 5M.1: optional APR on the HELOC. One APR reflects the
    /// fully-indexed cost over time; not paired to intro vs indexed.
    var helocAPR: Decimal?
    /// Session 5M.1: optional APR on the cash-out refi alternative.
    var refiAPR: Decimal?

    // MARK: - Session 7.3b additions (v0.1.1 PDF editorial parity)
    //
    // 11 new fields backing the v2.1.1 HELOC PDF template. All default
    // to sensible values so existing Saved Scenarios JSON decodes with
    // no migration (decodeIfPresent below). Power users override via
    // the HelocInputsScreen "Advanced" DisclosureGroup.

    /// Month the borrower's current first mortgage originated. Displayed
    /// in the v2.1.1 PDF assumptions box as "Originated Mar 2024".
    var firstMortgageOriginationDate: Date
    /// Dollar amount the borrower originally financed on the current
    /// first mortgage. Used in the assumptions box as context for the
    /// current balance.
    var firstMortgageOriginalAmount: Decimal
    /// Lender fees + third-party + title + appraisal + prepaids on the
    /// HELOC product, total.
    var helocClosingCosts: Decimal
    /// Lifetime cap on the HELOC's fully-indexed rate. Default 18.00%
    /// matches typical national HELOC product ceiling.
    var helocLifetimeCapPct: Decimal
    /// Which index drives the HELOC's fully-indexed rate. Defaults to
    /// Prime. Hardcoded assumption Prime = 8.50% as of Apr 2026 until
    /// FRED wiring lands in v0.1.2.
    var helocIndexType: HelocIndexType
    /// HELOC margin over the index (percent). Default 0.50.
    var helocMarginPct: Decimal
    /// Draw-period duration in years. Default 10.
    var helocDrawPeriodYears: Int
    /// Repayment-period duration in years. Default 20.
    var helocRepaymentPeriodYears: Int
    /// Cash-out refi total closing costs. Used alongside helocClosingCosts
    /// in the v2.1.1 HELOC-vs-refi comparison.
    var cashoutRefiClosingCosts: Decimal
    /// Cash-out refi rate (percent). Often equals `refiRate` above —
    /// kept as a separate field because the LO may want to quote an
    /// apples-to-apples cash-out rate distinct from a rate-&-term
    /// refi rate captured in Refinance Comparison.
    var cashoutRefiRate: Decimal
    /// Cash-out refi term (years). Default 30.
    var cashoutRefiTerm: Int

    enum CodingKeys: String, CodingKey {
        case firstLienBalance, firstLienRate, firstLienRemainingYears
        case helocAmount, helocIntroRate, helocIntroMonths, helocFullyIndexedRate
        case refiRate, refiTermYears, refiMonthlyMI, homeValue, stressShockBps
        case firstLienAPR, helocAPR, refiAPR
        // 7.3b additions
        case firstMortgageOriginationDate, firstMortgageOriginalAmount
        case helocClosingCosts, helocLifetimeCapPct, helocIndexType, helocMarginPct
        case helocDrawPeriodYears, helocRepaymentPeriodYears
        case cashoutRefiClosingCosts, cashoutRefiRate, cashoutRefiTerm
    }

    init(
        firstLienBalance: Decimal,
        firstLienRate: Double,
        firstLienRemainingYears: Int,
        helocAmount: Decimal,
        helocIntroRate: Double,
        helocIntroMonths: Int,
        helocFullyIndexedRate: Double,
        refiRate: Double,
        refiTermYears: Int,
        refiMonthlyMI: Decimal = 0,
        homeValue: Decimal = 0,
        stressShockBps: Int,
        firstLienAPR: Decimal? = nil,
        helocAPR: Decimal? = nil,
        refiAPR: Decimal? = nil,
        firstMortgageOriginationDate: Date = HelocFormInputs.defaultFirstMortgageOriginationDate,
        firstMortgageOriginalAmount: Decimal = 0,
        helocClosingCosts: Decimal = 500,
        helocLifetimeCapPct: Decimal = 18.00,
        helocIndexType: HelocIndexType = .prime,
        helocMarginPct: Decimal = 0.50,
        helocDrawPeriodYears: Int = 10,
        helocRepaymentPeriodYears: Int = 20,
        cashoutRefiClosingCosts: Decimal = 11_000,
        cashoutRefiRate: Decimal = 6.875,
        cashoutRefiTerm: Int = 30
    ) {
        self.firstLienBalance = firstLienBalance
        self.firstLienRate = firstLienRate
        self.firstLienRemainingYears = firstLienRemainingYears
        self.helocAmount = helocAmount
        self.helocIntroRate = helocIntroRate
        self.helocIntroMonths = helocIntroMonths
        self.helocFullyIndexedRate = helocFullyIndexedRate
        self.refiRate = refiRate
        self.refiTermYears = refiTermYears
        self.refiMonthlyMI = refiMonthlyMI
        self.homeValue = homeValue
        self.stressShockBps = stressShockBps
        self.firstLienAPR = firstLienAPR
        self.helocAPR = helocAPR
        self.refiAPR = refiAPR
        self.firstMortgageOriginationDate = firstMortgageOriginationDate
        self.firstMortgageOriginalAmount = firstMortgageOriginalAmount
        self.helocClosingCosts = helocClosingCosts
        self.helocLifetimeCapPct = helocLifetimeCapPct
        self.helocIndexType = helocIndexType
        self.helocMarginPct = helocMarginPct
        self.helocDrawPeriodYears = helocDrawPeriodYears
        self.helocRepaymentPeriodYears = helocRepaymentPeriodYears
        self.cashoutRefiClosingCosts = cashoutRefiClosingCosts
        self.cashoutRefiRate = cashoutRefiRate
        self.cashoutRefiTerm = cashoutRefiTerm
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.firstLienBalance = try c.decode(Decimal.self, forKey: .firstLienBalance)
        self.firstLienRate = try c.decode(Double.self, forKey: .firstLienRate)
        self.firstLienRemainingYears = try c.decode(Int.self, forKey: .firstLienRemainingYears)
        self.helocAmount = try c.decode(Decimal.self, forKey: .helocAmount)
        self.helocIntroRate = try c.decode(Double.self, forKey: .helocIntroRate)
        self.helocIntroMonths = try c.decode(Int.self, forKey: .helocIntroMonths)
        self.helocFullyIndexedRate = try c.decode(Double.self, forKey: .helocFullyIndexedRate)
        self.refiRate = try c.decode(Double.self, forKey: .refiRate)
        self.refiTermYears = try c.decode(Int.self, forKey: .refiTermYears)
        self.refiMonthlyMI = try c.decodeIfPresent(Decimal.self, forKey: .refiMonthlyMI) ?? 0
        self.homeValue = try c.decodeIfPresent(Decimal.self, forKey: .homeValue) ?? 0
        self.stressShockBps = try c.decode(Int.self, forKey: .stressShockBps)
        self.firstLienAPR = try c.decodeIfPresent(Decimal.self, forKey: .firstLienAPR)
        self.helocAPR = try c.decodeIfPresent(Decimal.self, forKey: .helocAPR)
        self.refiAPR = try c.decodeIfPresent(Decimal.self, forKey: .refiAPR)
        // 7.3b additions — all decodeIfPresent with defaults so pre-7.3b
        // Saved Scenarios JSON continues to decode unchanged.
        self.firstMortgageOriginationDate = try c.decodeIfPresent(Date.self, forKey: .firstMortgageOriginationDate)
            ?? HelocFormInputs.defaultFirstMortgageOriginationDate
        self.firstMortgageOriginalAmount = try c.decodeIfPresent(Decimal.self, forKey: .firstMortgageOriginalAmount) ?? 0
        self.helocClosingCosts = try c.decodeIfPresent(Decimal.self, forKey: .helocClosingCosts) ?? 500
        self.helocLifetimeCapPct = try c.decodeIfPresent(Decimal.self, forKey: .helocLifetimeCapPct) ?? 18.00
        self.helocIndexType = try c.decodeIfPresent(HelocIndexType.self, forKey: .helocIndexType) ?? .prime
        self.helocMarginPct = try c.decodeIfPresent(Decimal.self, forKey: .helocMarginPct) ?? 0.50
        self.helocDrawPeriodYears = try c.decodeIfPresent(Int.self, forKey: .helocDrawPeriodYears) ?? 10
        self.helocRepaymentPeriodYears = try c.decodeIfPresent(Int.self, forKey: .helocRepaymentPeriodYears) ?? 20
        self.cashoutRefiClosingCosts = try c.decodeIfPresent(Decimal.self, forKey: .cashoutRefiClosingCosts) ?? 11_000
        self.cashoutRefiRate = try c.decodeIfPresent(Decimal.self, forKey: .cashoutRefiRate) ?? 6.875
        self.cashoutRefiTerm = try c.decodeIfPresent(Int.self, forKey: .cashoutRefiTerm) ?? 30
    }

    /// Default origination date for new scenarios and for pre-7.3b JSON
    /// that lacks the field. Two years before today — roughly the
    /// median age of a current-homeowner borrower considering a HELOC.
    static var defaultFirstMortgageOriginationDate: Date {
        Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
    }

    static let sampleDefault = HelocFormInputs(
        firstLienBalance: 318_000,
        firstLienRate: 3.125,
        firstLienRemainingYears: 22,
        helocAmount: 80_000,
        helocIntroRate: 6.990,
        helocIntroMonths: 12,
        helocFullyIndexedRate: 8.750,
        refiRate: 6.125,
        refiTermYears: 30,
        refiMonthlyMI: 0,
        homeValue: 560_000,
        stressShockBps: 200,
        firstMortgageOriginationDate: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 1)) ?? Date(),
        firstMortgageOriginalAmount: 340_000,
        helocClosingCosts: 450,
        helocLifetimeCapPct: 18.00,
        helocIndexType: .prime,
        helocMarginPct: 0.50,
        helocDrawPeriodYears: 10,
        helocRepaymentPeriodYears: 20,
        cashoutRefiClosingCosts: 11_200,
        cashoutRefiRate: 6.875,
        cashoutRefiTerm: 30
    )

    /// LTV of the first lien alone against homeValue. 0 when homeValue
    /// isn't set.
    var firstLienLTV: Double {
        guard homeValue > 0 else { return 0 }
        return Double(truncating: (firstLienBalance / homeValue) as NSNumber)
    }

    /// Combined LTV — (first lien + HELOC draw) / homeValue.
    var cltv: Double {
        guard homeValue > 0 else { return 0 }
        return Double(truncating: (totalCapital / homeValue) as NSNumber)
    }

    /// Cash-out refi LTV = (first lien + HELOC draw) / homeValue.
    /// Same numerator as CLTV since the refi rolls both into one loan.
    var refiLTV: Double { cltv }

    var blendedRate: Double {
        let tranches = [
            RateTranche(balance: firstLienBalance, annualRate: firstLienRate / 100),
            RateTranche(balance: helocAmount, annualRate: helocFullyIndexedRate / 100),
        ]
        return QuotientFinance.blendedRate(tranches: tranches) * 100
    }

    var totalCapital: Decimal { firstLienBalance + helocAmount }

    var firstLienWeight: Double {
        let total = totalCapital
        guard total > 0 else { return 0 }
        return Double(truncating: (firstLienBalance / total) as NSNumber)
    }

    var helocWeight: Double { 1 - firstLienWeight }
}
