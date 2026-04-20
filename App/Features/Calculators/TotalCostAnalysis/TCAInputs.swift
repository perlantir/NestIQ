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
    /// Session 5P.8 (D9): refinance-mode snapshot of the borrower's
    /// current mortgage — stored with the scenario so loading a saved
    /// scenario restores the status-quo baseline regardless of any
    /// later edits to the borrower's live currentMortgage. nil for
    /// purchase-mode scenarios and for refi scenarios saved before
    /// this field existed (backward-compat).
    var currentMortgage: CurrentMortgage?

    enum CodingKeys: String, CodingKey {
        case mode, loanAmount, homeValue
        case monthlyTaxes, monthlyInsurance, monthlyHOA
        case scenarios, horizonsYears, currentOtherDebts, includeDebts
        case scenarioCount, reinvestmentRate
        case currentMortgage
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
        reinvestmentRate: Decimal = TCAFormInputs.defaultReinvestmentRate,
        currentMortgage: CurrentMortgage? = nil
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
        self.currentMortgage = currentMortgage
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
        self.currentMortgage = try c.decodeIfPresent(CurrentMortgage.self, forKey: .currentMortgage)
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
    /// Refinance: scenario.loanAmount if > 0 (cash-out / cash-in
    /// override); otherwise `currentMortgage.currentBalance` — the
    /// authoritative amount being refinanced. form.loanAmount stays
    /// as a final fallback for saved scenarios predating the 5P
    /// currentMortgage snapshot and for the (unusual) refi where the
    /// LO hasn't attached a currentMortgage.
    func effectiveLoanAmount(for scenario: TCAScenario) -> Decimal {
        switch mode {
        case .purchase:
            let derived = scenario.propertyDP.derivedLoanAmount
            return derived > 0 ? derived : loanAmount
        case .refinance:
            if scenario.loanAmount > 0 { return scenario.loanAmount }
            if let bal = currentMortgage?.currentBalance, bal > 0 { return bal }
            return loanAmount
        }
    }

    // MARK: - Session 5M.9 — equity buildup

    /// Home equity at horizon month = home value − remaining loan
    /// balance. Flat home value (no appreciation modeled — label
    /// clearly reflects this). Purchase mode uses the scenario's own
    /// purchasePrice; refinance mode uses the form-level homeValue.
    /// Returns 0 when neither is set.
    func equityAtHorizon(
        scenarioIndex: Int,
        schedule: AmortizationSchedule,
        years: Int
    ) -> Decimal {
        guard scenarioIndex < scenarios.count else { return 0 }
        let scenario = scenarios[scenarioIndex]
        let homeValueForScenario: Decimal
        switch mode {
        case .purchase:
            homeValueForScenario = scenario.propertyDP.purchasePrice
        case .refinance:
            homeValueForScenario = homeValue
        }
        guard homeValueForScenario > 0 else { return 0 }
        let month = Swift.max(0, years * 12)
        let remaining: Decimal
        if month == 0 {
            remaining = schedule.loan.principal
        } else if month >= schedule.payments.count {
            remaining = 0
        } else {
            remaining = schedule.payments[month - 1].balance
        }
        return (homeValueForScenario - remaining).clampedNonNegative
    }

    // MARK: - Session 5M.8 — reinvestment strategy

    /// "Invest the savings" — future value of baseline-minus-scenario
    /// monthly savings invested at `reinvestmentRate` for `months`.
    /// Returns 0 when baseline or scenario payment isn't set, when the
    /// scenario is the baseline (pre-5P.9: index 0 with no
    /// currentMortgage), or when monthly savings are non-positive.
    ///
    /// Session 5Q.6: when `currentMortgage` is set, scenario A is a
    /// proposed refinance, not the baseline — its savings are measured
    /// against the status-quo monthly P&I just like B/C/D. The legacy
    /// "scenario 0 is baseline" exclusion only fires when no
    /// currentMortgage snapshot is attached.
    func pathAInvestmentBalance(
        scenarioIndex: Int,
        months: Int,
        monthlyPayments: [Decimal]
    ) -> Decimal {
        guard mode == .refinance,
              scenarioIndex >= 0,
              scenarioIndex < monthlyPayments.count
        else { return 0 }
        if currentMortgage == nil, scenarioIndex == 0 { return 0 }
        let baseline = breakEvenBaselinePayment(monthlyPayments: monthlyPayments)
        let savings = baseline - monthlyPayments[scenarioIndex]
        guard savings > 0 else { return 0 }
        return futureValueOfMonthlyDeposits(
            deposit: savings,
            annualRate: reinvestmentRate.asDouble,
            months: months
        )
    }

    /// "Apply savings as extra principal" — accelerates payoff and
    /// reduces lifetime interest. Returns nil when the scenario is
    /// baseline (index 0), refinance savings are nonpositive, or
    /// inputs don't line up with the provided schedule.
    struct PathBResult: Hashable {
        public let newPayoffMonth: Int
        public let originalPayoffMonth: Int
        public let interestSaved: Decimal
        /// Interest saved + monthly payment × months-avoided. The
        /// second term represents cash the borrower keeps after the
        /// accelerated payoff — dollars they no longer have to send
        /// the lender each month.
        public let wealthBuilt: Decimal
    }

    func pathBExtraPrincipal(
        scenarioIndex: Int,
        schedule: AmortizationSchedule,
        monthlyPayments: [Decimal]
    ) -> PathBResult? {
        guard mode == .refinance,
              scenarioIndex >= 0,
              scenarioIndex < monthlyPayments.count,
              scenarioIndex < scenarios.count
        else { return nil }
        // 5Q.6: scenario A is a baseline only when there's no
        // currentMortgage to anchor against. With currentMortgage set,
        // A is a proposed refinance like B/C/D and measured against
        // status quo.
        if currentMortgage == nil, scenarioIndex == 0 { return nil }
        let baseline = breakEvenBaselinePayment(monthlyPayments: monthlyPayments)
        let savings = baseline - monthlyPayments[scenarioIndex]
        guard savings > 0 else { return nil }
        let accelerated = applyExtraPrincipal(
            schedule: schedule,
            extra: ExtraPrincipalPlan(recurring: savings, lumpSums: [])
        )
        let interestSaved = schedule.totalInterest - accelerated.totalInterest
        let original = schedule.payments.count
        let newPayoff = accelerated.payments.count
        let monthsSaved = Swift.max(original - newPayoff, 0)
        let avoidedCashflow = monthlyPayments[scenarioIndex] * Decimal(monthsSaved)
        return PathBResult(
            newPayoffMonth: newPayoff,
            originalPayoffMonth: original,
            interestSaved: interestSaved,
            wealthBuilt: interestSaved + avoidedCashflow
        )
    }

    /// Session 5M.7: estimated break-even month for a non-baseline
    /// refinance scenario against the baseline (scenario index 0).
    /// Returns `nil` when break-even is never reached within the
    /// scenario's term (baseline is cheaper monthly, or savings don't
    /// offset closing costs before payoff).
    ///
    /// `monthlyPayments` expects `viewModel.result.scenarioMetrics.map
    /// { $0.payment }` so callers reuse the already-computed P&I from
    /// the main ComparisonResult. Refinance-mode only — purchase mode
    /// doesn't have a "baseline" in the TCA sense.
    /// Baseline monthly P&I used for break-even: the borrower's current
    /// mortgage P&I when available (5P.9 — the status-quo comparison),
    /// otherwise `monthlyPayments[0]` (scenario A's payment — legacy
    /// scenario-vs-scenario baseline preserved for saved scenarios
    /// without a currentMortgage snapshot and for modes without a
    /// current-mortgage concept).
    func breakEvenBaselinePayment(monthlyPayments: [Decimal]) -> Decimal {
        if mode == .refinance, let currentMortgage {
            return currentMortgage.currentMonthlyPaymentPI
        }
        return monthlyPayments.first ?? 0
    }

    /// Horizon ceiling (in months) for break-even determination. When
    /// a currentMortgage is available and has months remaining on its
    /// original term, the proposed scenario only has until the existing
    /// loan would have been paid off anyway to recoup closing costs —
    /// that's the correct "within remaining term" horizon Nick called
    /// out in 5P.9. Without a currentMortgage we fall back to the
    /// scenario's own term (legacy behavior).
    func breakEvenTermMonths(scenarioIndex: Int) -> Int {
        let scenarioTerm = scenarios[scenarioIndex].termYears * 12
        guard mode == .refinance, let currentMortgage else { return scenarioTerm }
        let remaining = CurrentMortgageCalculations.monthsRemaining(
            originalTermYears: currentMortgage.originalTermYears,
            loanStartDate: currentMortgage.loanStartDate
        )
        guard remaining > 0 else { return scenarioTerm }
        return min(scenarioTerm, remaining)
    }

    func breakEvenMonth(
        scenarioIndex: Int,
        monthlyPayments: [Decimal]
    ) -> Int? {
        guard mode == .refinance,
              scenarioIndex >= 0,
              scenarioIndex < scenarios.count,
              scenarioIndex < monthlyPayments.count,
              !monthlyPayments.isEmpty
        else { return nil }
        // Legacy (no currentMortgage): scenario A IS the baseline, can't
        // break even against itself. 5P.9 (currentMortgage set): A is a
        // proposed refinance like B/C/D, compared against status quo.
        if currentMortgage == nil, scenarioIndex == 0 { return nil }
        let baseline = breakEvenBaselinePayment(monthlyPayments: monthlyPayments)
        let scenarioPmt = monthlyPayments[scenarioIndex]
        let monthlySavings = baseline - scenarioPmt
        guard monthlySavings > 0 else { return nil }
        let closing = scenarios[scenarioIndex].closingCosts
        guard closing > 0 else { return 0 }
        // Integer ceiling division: smallest M where M × savings >= closing.
        let monthsDouble = (closing.asDouble / monthlySavings.asDouble).rounded(.up)
        let months = Int(monthsDouble)
        let maxTerm = breakEvenTermMonths(scenarioIndex: scenarioIndex)
        guard months <= maxTerm else { return nil }
        return months
    }

    /// Session 5M.7: sampled points for the break-even Swift Chart.
    /// Returns (month, cumulativeSavings) pairs at each integer month
    /// from 0 through `maxMonths`. Cumulative savings is a flat linear
    /// growth (monthlySavings × M) because the math assumes constant
    /// P&I differential month-to-month. Callers chart this against a
    /// horizontal reference line at `scenario.closingCosts`.
    func breakEvenGraphData(
        scenarioIndex: Int,
        monthlyPayments: [Decimal],
        maxMonths: Int
    ) -> [(month: Int, cumulative: Decimal)] {
        guard scenarioIndex >= 0,
              scenarioIndex < scenarios.count,
              scenarioIndex < monthlyPayments.count
        else { return [] }
        if currentMortgage == nil, scenarioIndex == 0 { return [] }
        let baseline = breakEvenBaselinePayment(monthlyPayments: monthlyPayments)
        let scenarioPmt = monthlyPayments[scenarioIndex]
        let monthlySavings = baseline - scenarioPmt
        return (0...maxMonths).map { m in
            (month: m, cumulative: monthlySavings * Decimal(m))
        }
    }

    /// Session 5M.6: cumulative unrecoverable cost at horizon — the
    /// portion of total mortgage payments that doesn't build equity or
    /// transfer to the borrower. Definition per D4 (5M): interest paid
    /// through horizon M + MI paid through M + closing costs (paid
    /// once at origination).
    ///
    /// Tax/insurance/HOA are deliberately excluded — those go to the
    /// government / carrier / HOA regardless of ownership vs. rent and
    /// render on a separate "Ongoing housing costs" line.
    func unrecoverableCost(
        scenario: TCAScenario,
        schedule: AmortizationSchedule,
        years: Int
    ) -> Decimal {
        let month = years * 12
        return scenario.closingCosts
            + schedule.cumulativeInterest(throughMonth: month)
            + schedule.cumulativeMI(throughMonth: month)
    }

    /// Session 5M.6: taxes + insurance + HOA × horizon months. "Ongoing"
    /// because the borrower pays this whether they own or rent at this
    /// property — so it's not an ownership-specific cost to compare
    /// against the rental alternative.
    func ongoingHousingCost(years: Int) -> Decimal {
        let monthly = monthlyTaxes + monthlyInsurance + monthlyHOA
        return monthly * Decimal(years * 12)
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

    // `scenarioInputs()` + MI plumbing moved to TCAInputs+Engine.swift
    // in 5R.2 so this file stays under SwiftLint's 600-line cap.
}
