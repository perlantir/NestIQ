// TCAInputs.swift
// 2-4 scenarios × 5 horizons (5/7/10/15/30 yr). Stored as inputsJSON.

import Foundation
import QuotientFinance

/// Purchase comparison (15yr vs 30yr on the same house) vs. refinance
/// comparison (option A vs B on the same existing home). Drives per-
/// scenario field visibility.
enum TCAMode: String, Codable, Hashable, Sendable {
    case purchase
    case refinance
}

struct TCAScenario: Codable, Hashable, Sendable, Identifiable {
    var id: UUID
    var label: String       // "A", "B", …
    var name: String        // "Conv 30", "Conv 15"
    var rate: Double
    var termYears: Int
    var points: Double
    var closingCosts: Decimal
    /// Refinance-mode loan amount. When 0, engine falls back to the
    /// form-level loanAmount (backward-compat for scenarios saved
    /// before per-scenario loan amounts were supported).
    var loanAmount: Decimal
    /// User-entered monthly MI — both modes consume this.
    var monthlyMI: Decimal
    /// Purchase-mode Property & DP (purchase price, DP %, DP $, LTV).
    /// Left at .empty in refinance mode.
    var propertyDP: PropertyDownPaymentConfig
    /// Refinance-mode only: remaining other-debts balance + monthly
    /// payment after this scenario's cash-out consolidates some/all
    /// of the borrower's current other debts. nil in purchase mode.
    var otherDebts: OtherDebts?
    /// Session 5M.1: optional per-scenario APR. Display-only.
    var aprRate: Decimal?
    /// Session 5M.3 input: prepaids (taxes + insurance escrow at close).
    /// Feeds cash-to-close computation; defaults to 0 for scenarios
    /// saved before the field existed.
    var prepaids: Decimal
    /// Session 5M.3 input: seller / lender credits applied at close.
    /// Reduces cash-to-close.
    var credits: Decimal

    enum CodingKeys: String, CodingKey {
        case id, label, name, rate, termYears, points, closingCosts
        case loanAmount, monthlyMI, propertyDP, otherDebts
        case aprRate, prepaids, credits
    }

    init(
        id: UUID = UUID(),
        label: String,
        name: String,
        rate: Double,
        termYears: Int,
        points: Double = 0,
        closingCosts: Decimal = 0,
        loanAmount: Decimal = 0,
        monthlyMI: Decimal = 0,
        propertyDP: PropertyDownPaymentConfig = .empty,
        otherDebts: OtherDebts? = nil,
        aprRate: Decimal? = nil,
        prepaids: Decimal = 0,
        credits: Decimal = 0
    ) {
        self.id = id
        self.label = label
        self.name = name
        self.rate = rate
        self.termYears = termYears
        self.points = points
        self.closingCosts = closingCosts
        self.loanAmount = loanAmount
        self.monthlyMI = monthlyMI
        self.propertyDP = propertyDP
        self.otherDebts = otherDebts
        self.aprRate = aprRate
        self.prepaids = prepaids
        self.credits = credits
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.label = try c.decode(String.self, forKey: .label)
        self.name = try c.decode(String.self, forKey: .name)
        self.rate = try c.decode(Double.self, forKey: .rate)
        self.termYears = try c.decode(Int.self, forKey: .termYears)
        self.points = try c.decode(Double.self, forKey: .points)
        self.closingCosts = try c.decode(Decimal.self, forKey: .closingCosts)
        self.loanAmount = try c.decodeIfPresent(Decimal.self, forKey: .loanAmount) ?? 0
        self.monthlyMI = try c.decodeIfPresent(Decimal.self, forKey: .monthlyMI) ?? 0
        self.propertyDP = try c.decodeIfPresent(
            PropertyDownPaymentConfig.self, forKey: .propertyDP
        ) ?? .empty
        self.otherDebts = try c.decodeIfPresent(OtherDebts.self, forKey: .otherDebts)
        self.aprRate = try c.decodeIfPresent(Decimal.self, forKey: .aprRate)
        self.prepaids = try c.decodeIfPresent(Decimal.self, forKey: .prepaids) ?? 0
        self.credits = try c.decodeIfPresent(Decimal.self, forKey: .credits) ?? 0
    }
}

struct TCAFormInputs: Codable, Hashable, Sendable {
    /// 7% annualized. String-initialized so the stored Decimal is
    /// exactly `0.07` (the Decimal literal `0.07` routes through
    /// Double and stores `0.07000000000000001024`).
    static let defaultReinvestmentRate: Decimal = Decimal(string: "0.07") ?? 0

    var mode: TCAMode
    /// Refinance-mode fallback loan amount. Scenarios that set their
    /// own `loanAmount` override this; scenarios at 0 use it.
    var loanAmount: Decimal
    /// Refinance-mode home value — shared LTV denominator across
    /// scenarios. Purchase mode ignores this (LTV comes from each
    /// scenario's propertyDP.purchasePrice).
    var homeValue: Decimal
    var monthlyTaxes: Decimal
    var monthlyInsurance: Decimal
    var monthlyHOA: Decimal
    var scenarios: [TCAScenario]
    var horizonsYears: [Int]
    /// Refinance-mode only: aggregate of every non-mortgage debt the
    /// borrower carries today (credit cards, auto, student, etc.). Per
    /// scenario, `TCAScenario.otherDebts` is what remains after the
    /// scenario's cash-out consolidates some/all of this.
    var currentOtherDebts: OtherDebts?
    /// Refinance-mode only: when true, debts factor into winner
    /// determination (monthly total = PITI + scenario debt monthly,
    /// total cost += remaining debt monthly × horizon months). When
    /// false, winner is PITI-only and all debt rows are hidden. Purchase
    /// mode ignores this. Default: true (matches 5E.5 behavior so saved
    /// scenarios don't regress).
    var includeDebts: Bool
    /// Number of scenarios the LO wants to compare (2, 3, or 4).
    /// Default is 2. Kept in sync with `scenarios.count` when the user
    /// changes the selector on the Inputs screen. Mirrors Refi 5F.3.
    var scenarioCount: Int
    /// Session 5M.1 (5M.8 consumer): annualized reinvestment rate used
    /// by the reinvestment-strategy section on Results. 0.07 (7%) is a
    /// conservative S&P long-run default; LO-editable per analysis.
    var reinvestmentRate: Decimal

    enum CodingKeys: String, CodingKey {
        case mode, loanAmount, homeValue
        case monthlyTaxes, monthlyInsurance, monthlyHOA
        case scenarios, horizonsYears, currentOtherDebts, includeDebts
        case scenarioCount, reinvestmentRate
    }

    init(
        mode: TCAMode = .refinance,
        loanAmount: Decimal,
        homeValue: Decimal = 0,
        monthlyTaxes: Decimal,
        monthlyInsurance: Decimal,
        monthlyHOA: Decimal,
        scenarios: [TCAScenario],
        horizonsYears: [Int],
        currentOtherDebts: OtherDebts? = nil,
        includeDebts: Bool = true,
        scenarioCount: Int? = nil,
        reinvestmentRate: Decimal = TCAFormInputs.defaultReinvestmentRate
    ) {
        self.mode = mode
        self.loanAmount = loanAmount
        self.homeValue = homeValue
        self.monthlyTaxes = monthlyTaxes
        self.monthlyInsurance = monthlyInsurance
        self.monthlyHOA = monthlyHOA
        self.scenarios = scenarios
        self.horizonsYears = horizonsYears
        self.currentOtherDebts = currentOtherDebts
        self.includeDebts = includeDebts
        self.scenarioCount = scenarioCount ?? scenarios.count
        self.reinvestmentRate = reinvestmentRate
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.mode = try c.decodeIfPresent(TCAMode.self, forKey: .mode) ?? .refinance
        self.loanAmount = try c.decode(Decimal.self, forKey: .loanAmount)
        self.homeValue = try c.decodeIfPresent(Decimal.self, forKey: .homeValue) ?? 0
        self.monthlyTaxes = try c.decode(Decimal.self, forKey: .monthlyTaxes)
        self.monthlyInsurance = try c.decode(Decimal.self, forKey: .monthlyInsurance)
        self.monthlyHOA = try c.decode(Decimal.self, forKey: .monthlyHOA)
        self.scenarios = try c.decode([TCAScenario].self, forKey: .scenarios)
        self.horizonsYears = try c.decode([Int].self, forKey: .horizonsYears)
        self.currentOtherDebts = try c.decodeIfPresent(OtherDebts.self, forKey: .currentOtherDebts)
        self.includeDebts = try c.decodeIfPresent(Bool.self, forKey: .includeDebts) ?? true
        self.scenarioCount = try c.decodeIfPresent(Int.self, forKey: .scenarioCount)
            ?? self.scenarios.count
        self.reinvestmentRate = try c.decodeIfPresent(Decimal.self, forKey: .reinvestmentRate)
            ?? Self.defaultReinvestmentRate
    }

    /// Blank scenario with the term defaulted to 30 yr and every other
    /// numeric field at 0. Mirrors the Refi 5F.3 blank-slate pattern —
    /// LOs fill in just the fields that matter per scenario.
    static func blankScenario(label: String, name: String? = nil) -> TCAScenario {
        TCAScenario(
            label: label,
            name: name ?? "Scenario \(label)",
            rate: 0,
            termYears: 30,
            points: 0,
            closingCosts: 0,
            loanAmount: 0,
            monthlyMI: 0
        )
    }

    /// Grow or shrink `scenarios` to match `newCount`. Preserves any
    /// existing entries (by position) when shrinking; appends blanks
    /// labeled A/B/C/D when growing. Normalizes labels so they always
    /// read A..{count} top-to-bottom.
    mutating func resizeScenarios(to newCount: Int) {
        let clamped = max(2, min(newCount, 4))
        let labels = ["A", "B", "C", "D"]
        if scenarios.count < clamped {
            for i in scenarios.count..<clamped {
                scenarios.append(Self.blankScenario(label: labels[i]))
            }
        } else if scenarios.count > clamped {
            scenarios = Array(scenarios.prefix(clamped))
        }
        for (idx, lbl) in labels.prefix(scenarios.count).enumerated() {
            scenarios[idx].label = lbl
        }
        scenarioCount = clamped
    }

    /// Effective principal for the given scenario under the active
    /// mode. Purchase: price − DP (derivedLoanAmount), falling back
    /// to form.loanAmount when the scenario's DP isn't set up.
    /// Refinance: scenario.loanAmount if > 0, else form.loanAmount.
    func effectiveLoanAmount(for scenario: TCAScenario) -> Decimal {
        switch mode {
        case .purchase:
            let derived = scenario.propertyDP.derivedLoanAmount
            return derived > 0 ? derived : loanAmount
        case .refinance:
            return scenario.loanAmount > 0 ? scenario.loanAmount : loanAmount
        }
    }

    /// Session 5M.3: approximate cash-to-close per scenario. Display-
    /// only; labeled "Approximate" on surfaces so LOs don't confuse it
    /// with a regulated Loan Estimate. Earnest money is deliberately
    /// out of scope (Session 5M decision).
    ///
    /// Purchase mode: Price + Closing Costs + Prepaids − Down Payment − Credits
    /// Refinance mode: Closing Costs + Prepaids − Credits
    ///
    /// Clamped to `>= 0` so a credit-heavy scenario doesn't render as
    /// a negative dollar amount (which isn't semantically "cash to
    /// close" — it's credit to the borrower; separate line item).
    func approximateCashToClose(for scenario: TCAScenario) -> Decimal {
        let base: Decimal
        switch mode {
        case .purchase:
            let price = scenario.propertyDP.purchasePrice
            let downPayment = scenario.propertyDP.downPaymentAmount
            base = price + scenario.closingCosts + scenario.prepaids - downPayment - scenario.credits
        case .refinance:
            base = scenario.closingCosts + scenario.prepaids - scenario.credits
        }
        return base.clampedNonNegative
    }

    /// LTV per scenario against the active mode's denominator.
    func ltv(for scenario: TCAScenario) -> Double {
        switch mode {
        case .purchase:
            return scenario.propertyDP.ltv(loanAmount: effectiveLoanAmount(for: scenario))
        case .refinance:
            guard homeValue > 0 else { return 0 }
            return Double(truncating:
                (effectiveLoanAmount(for: scenario) / homeValue) as NSNumber)
        }
    }

    static let sampleDefault = TCAFormInputs(
        mode: .refinance,
        loanAmount: 548_000,
        homeValue: 710_000,
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
            let principal = effectiveLoanAmount(for: s)
            let pointsCost = principal * Decimal(s.points) / 100
            return ScenarioInput(
                name: s.label,
                loan: Loan(
                    principal: principal,
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
