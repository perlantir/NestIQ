// PDFBuilder.swift
// Assembles a PDF for any calculator: cover page (hero KPIs + narrative)
// + state-specific disclaimers appendix from QuotientCompliance.
// Per-calculator body pages (schedule, comparison tables, stress paths)
// are deferred to Session 5's polish pass where the on-screen views are
// re-used at print dimensions.

import SwiftUI
import Foundation
import QuotientPDF
import QuotientCompliance
import QuotientFinance

@MainActor
enum PDFBuilder {

    /// Calculator-agnostic composition payload.
    struct Payload {
        let calculatorSlug: String            // used for temp filename
        let calculatorTitle: String           // printed on the cover eyebrow
        let complianceScenarioType: ScenarioType
        let loanSummary: String               // mono-line under the "For *Name*"
        let heroLabel: String                 // "Monthly payment · PITI" etc
        let heroValue: String                 // e.g. "4,207"
        let heroValuePrefix: String           // "$" for money, "" for rate
        let heroValueSuffix: String           // "%" for rate, "" for money
        let heroKPIs: [(label: String, value: String)]
        let narrative: String

        init(
            calculatorSlug: String,
            calculatorTitle: String,
            complianceScenarioType: ScenarioType,
            loanSummary: String,
            heroLabel: String,
            heroValue: String,
            heroValuePrefix: String = "$",
            heroValueSuffix: String = "",
            heroKPIs: [(label: String, value: String)],
            narrative: String
        ) {
            self.calculatorSlug = calculatorSlug
            self.calculatorTitle = calculatorTitle
            self.complianceScenarioType = complianceScenarioType
            self.loanSummary = loanSummary
            self.heroLabel = heroLabel
            self.heroValue = heroValue
            self.heroValuePrefix = heroValuePrefix
            self.heroValueSuffix = heroValueSuffix
            self.heroKPIs = heroKPIs
            self.narrative = narrative
        }
    }

    static func buildPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        payload: Payload,
        extraPages: [(AnyView, PDFRenderer.Orientation)] = []
    ) throws -> URL {
        let url = temporaryURL(for: payload.calculatorSlug)
        // Total pages known up front: cover + extras + disclaimers.
        let total = 1 + extraPages.count + 1
        let cover = AnyView(coverPage(
            profile: profile,
            borrower: borrower,
            payload: payload,
            pageIndex: 1,
            pageCount: total
        ))
        let disclaimers = AnyView(disclaimersPage(
            profile: profile,
            borrower: borrower,
            scenarioType: payload.complianceScenarioType,
            pageIndex: total,
            pageCount: total
        ))
        var pages: [(AnyView, PDFRenderer.Orientation)] = [(cover, .portrait)]
        pages.append(contentsOf: extraPages)
        pages.append((disclaimers, .portrait))
        try PDFRenderer.renderMixed(pages: pages, to: url)
        return url
    }

    // MARK: Per-calculator convenience builders

    static func buildAmortizationPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: AmortizationViewModel,
        narrative: String,
        scheduleGranularity: AmortScheduleGranularity = .yearly
    ) throws -> URL {
        let interest = MoneyFormat.shared.dollarsShort(viewModel.totalInterest)
        let totalPaid = MoneyFormat.shared.dollarsShort(viewModel.totalPaid)
        let rate = String(format: "%.3f", viewModel.inputs.annualRate)
        let rateDisplay = displayRateAndAPR(rate: viewModel.inputs.annualRate, decimalAPR: viewModel.inputs.aprRate)
        let loanMoney = MoneyFormat.shared.currency(viewModel.inputs.loanAmount)
        let piti = MoneyFormat.shared.currency(viewModel.monthlyPITI)
        let payoff = viewModel.payoffDate.map { d -> String in
            let f = DateFormatter(); f.dateFormat = "MMM yyyy"; return f.string(from: d)
        } ?? "—"
        let fallbackNarrative = "At today's \(rate)% rate, the monthly PITI is \(piti). "
            + "Over the life of the loan, interest totals about \(interest)."
        let loanSummary = "\(loanMoney) · \(viewModel.inputs.termYears)-yr fixed · \(rateDisplay)"
        let payload = Payload(
            calculatorSlug: "amortization",
            calculatorTitle: "Amortization analysis",
            complianceScenarioType: .amortization,
            loanSummary: loanSummary,
            heroLabel: "Monthly payment · PITI",
            heroValue: piti,
            heroValuePrefix: "",
            heroKPIs: [
                ("Total interest", interest),
                ("Payoff", payoff),
                ("Total paid", totalPaid),
            ],
            narrative: narrative.isEmpty ? fallbackNarrative : narrative
        )
        let scheduleCount = AmortizationSchedulePages.pageCount(
            schedule: viewModel.schedule,
            granularity: scheduleGranularity
        )
        let globalTotal = 1 + scheduleCount + 1
        let schedulePages = amortizationSchedulePages(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            loanSummary: loanSummary,
            granularity: scheduleGranularity,
            globalPageStart: 2,
            globalPageCount: globalTotal
        )
        return try buildPDF(
            profile: profile,
            borrower: borrower,
            payload: payload,
            extraPages: schedulePages
        )
    }

    static func buildIncomeQualPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: IncomeQualViewModel,
        narrative: String
    ) throws -> URL {
        let maxLoan = MoneyFormat.shared.currency(viewModel.maxLoan)
        let piti = MoneyFormat.shared.currency(viewModel.maxPITI)
        let purchase = MoneyFormat.shared.currency(viewModel.maxPurchase)
        let backDTI = String(format: "%.1f%%", viewModel.backEndDTIIncludingDebts * 100)
        let rate = displayRateAndAPR(rate: viewModel.inputs.annualRate, decimalAPR: viewModel.inputs.aprRate)
        let isRefi = viewModel.inputs.mode == .refinance
        let summary = isRefi
            ? "Refi · \(rate) · \(viewModel.inputs.termYears)-yr · DTI \(backDTI)"
            : "at \(rate) · \(viewModel.inputs.termYears)-yr · DTI \(backDTI)"
        let secondaryLabel = isRefi ? "Current LTV" : "Max purchase"
        let secondaryValue: String = {
            if isRefi {
                let ltv = viewModel.inputs.currentRefiLTV
                guard viewModel.inputs.currentHomeValue > 0 else { return "—" }
                return String(format: "%.1f%%", ltv * 100)
            }
            return purchase
        }()
        let currentBal = MoneyFormat.shared.currency(viewModel.inputs.currentLoanBalance)
        let reservesMonths = viewModel.inputs.reservesMonths
        let reservesTotal = MoneyFormat.shared.currency(
            viewModel.maxPITI * Decimal(reservesMonths)
        )
        let reservesSentence = reservesMonths > 0
            ? " Requires \(reservesMonths)-month reserves: \(reservesTotal) (\(reservesMonths) × PITI)."
            : ""
        let refiNarrative = "Qualifies at \(rate)% \(viewModel.inputs.termYears)-yr — max "
            + "qualifying loan \(maxLoan) vs current balance \(currentBal). "
            + "Back-end DTI lands at \(backDTI)." + reservesSentence
        let purchaseNarrative = "Qualifies up to \(maxLoan) at a \(rate)% "
            + "\(viewModel.inputs.termYears)-yr loan. Back-end DTI lands at \(backDTI)."
            + reservesSentence
        let fallback = isRefi ? refiNarrative : purchaseNarrative
        let reservesValue = reservesMonths > 0
            ? "\(reservesMonths) mo · \(reservesTotal)"
            : "—"
        let payload = Payload(
            calculatorSlug: "income-qualification",
            calculatorTitle: isRefi ? "Income qualification · refinance" : "Income qualification",
            complianceScenarioType: .incomeQualification,
            loanSummary: summary,
            heroLabel: "Max loan · qualifying",
            heroValue: maxLoan,
            heroValuePrefix: "",
            heroKPIs: [
                ("Max PITI", piti),
                (secondaryLabel, secondaryValue),
                ("Back-end DTI", backDTI),
                ("Reserves", reservesValue),
            ],
            narrative: narrative.isEmpty ? fallback : narrative
        )
        return try buildPDF(profile: profile, borrower: borrower, payload: payload)
    }

    static func buildRefinancePDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: RefinanceViewModel,
        narrative: String
    ) throws -> URL {
        let savings = MoneyFormat.shared.currency(viewModel.monthlySavings)
        let be = viewModel.breakEvenMonth.map { "\($0) mo" } ?? "—"
        let lifetime = MoneyFormat.shared.dollarsShort(abs(viewModel.lifetimeDelta))
        let npv = MoneyFormat.shared.dollarsShort(abs(viewModel.npvDelta))
        let currentRate = String(format: "%.3f", viewModel.inputs.currentRate)
        let currentRateDisplay = displayRateAndAPR(rate: viewModel.inputs.currentRate, decimalAPR: viewModel.inputs.currentAPR)
        let fallback = "Selected refi saves \(savings)/mo versus the current \(currentRate)% loan. "
            + "Break-even: \(be)."
        let payload = Payload(
            calculatorSlug: "refinance",
            calculatorTitle: "Refinance comparison",
            complianceScenarioType: .refinance,
            loanSummary: "Current \(MoneyFormat.shared.currency(viewModel.inputs.currentBalance)) @ \(currentRateDisplay)",
            heroLabel: "Monthly savings · selected option",
            heroValue: savings,
            heroValuePrefix: "",
            heroKPIs: [
                ("Break-even", be),
                ("Lifetime Δ", lifetime),
                ("NPV @ 5%", npv),
            ],
            narrative: narrative.isEmpty ? fallback : narrative
        )
        // Refi ships cover + 1 comparison + disclaimers → 3 pages total.
        let comparison = AnyView(refinanceComparisonPage(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            pageIndex: 2,
            pageCount: 3
        ))
        return try buildPDF(
            profile: profile,
            borrower: borrower,
            payload: payload,
            extraPages: [(comparison, .landscape)]
        )
    }

    static func buildTCAPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: TCAViewModel,
        narrative: String
    ) throws -> URL {
        let loan = MoneyFormat.shared.currency(viewModel.inputs.loanAmount)
        let count = viewModel.inputs.scenarios.count
        let horizons = viewModel.inputs.horizonsYears.map { "\($0)yr" }.joined(separator: "/")
        let winnerIndex = viewModel.result?.winnerByHorizon.last ?? 0
        let winnerName = viewModel.inputs.scenarios.indices.contains(winnerIndex)
            ? viewModel.inputs.scenarios[winnerIndex].name : "—"
        let fallback = "Across \(count) scenarios over \(horizons) horizons, "
            + "\(winnerName) wins on total cost at the longest horizon."
        let payload = Payload(
            calculatorSlug: "total-cost",
            calculatorTitle: "Total cost analysis",
            complianceScenarioType: .totalCostAnalysis,
            loanSummary: "\(loan) · \(count) scenarios · \(horizons)",
            heroLabel: "Scenarios compared",
            heroValue: "\(count)",
            heroValuePrefix: "",
            heroKPIs: [
                ("Horizons", "\(viewModel.inputs.horizonsYears.count)"),
                ("Life winner", winnerName),
                ("Loan", MoneyFormat.shared.dollarsShort(viewModel.inputs.loanAmount)),
            ],
            narrative: narrative.isEmpty ? fallback : narrative
        )
        // TCA ships cover + 1 comparison + disclaimers → total 3 pages.
        let comparison = AnyView(tcaComparisonPage(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            pageIndex: 2,
            pageCount: 3
        ))
        return try buildPDF(
            profile: profile,
            borrower: borrower,
            payload: payload,
            extraPages: [(comparison, .landscape)]
        )
    }

    static func buildHelocPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: HelocViewModel,
        narrative: String
    ) throws -> URL {
        let blend = String(format: "%.2f", viewModel.blendedRate)
        let refi = String(format: "%.3f", viewModel.inputs.refiRate)
        let firstLien = MoneyFormat.shared.dollarsShort(viewModel.inputs.firstLienBalance)
        let helocAmt = MoneyFormat.shared.dollarsShort(viewModel.inputs.helocAmount)
        let verdict = viewModel.blendedRate < viewModel.inputs.refiRate ? "keep 1st" : "refi wins"
        let fallback = "Keeping the first mortgage and taking a HELOC blends to \(blend)% — "
            + "vs a cash-out refi at \(refi)%. Verdict: \(verdict)."
        let payload = Payload(
            calculatorSlug: "heloc",
            calculatorTitle: "HELOC vs refinance",
            complianceScenarioType: .helocVsRefinance,
            loanSummary: "1st \(firstLien) + HELOC \(helocAmt)",
            heroLabel: "Blended rate · HELOC path",
            heroValue: blend,
            heroValuePrefix: "",
            heroValueSuffix: "%",
            heroKPIs: [
                ("vs refi", "\(refi)%"),
                ("Verdict", verdict),
                ("1st rate", String(format: "%.3f%%", viewModel.inputs.firstLienRate)),
            ],
            narrative: narrative.isEmpty ? fallback : narrative
        )
        let comparison = AnyView(helocComparisonPage(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel
        ))
        return try buildPDF(
            profile: profile,
            borrower: borrower,
            payload: payload,
            extraPages: [(comparison, .landscape)]
        )
    }

    // `buildSelfEmploymentPDF` lives in PDFBuilder+SelfEmployment.swift
    // to keep this enum under SwiftLint's type_body_length cap.

    private static func helocComparisonPage(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: HelocViewModel
    ) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let generated = formatter.string(from: Date())
        let rows = HelocComparisonPage.rows(for: viewModel)
        let state = resolveState(borrower: borrower)
        let disclosures = requiredDisclosures(
            for: .helocVsRefinance,
            propertyState: state ?? .CA
        )
        let disclaimer = disclosures.first?.textEN ?? defaultDisclaimer()
        let ehoStatement = equalHousingOpportunityStatement(locale: Locale(identifier: "en_US"))
        let nmlsLine: String = {
            switch profile.nmlsDisplayFormat {
            case .idOnly: return "NMLS \(profile.nmlsId)"
            case .idAndURL: return "NMLS \(profile.nmlsId) · nmlsconsumeraccess.org"
            case .none: return ""
            }
        }()
        let blended10yr = viewModel.blendedRateAtTenYears
        let verdict = blended10yr < viewModel.inputs.refiRate ? "keep 1st" : "refi wins"
        return HelocComparisonPage(
            borrowerName: borrower?.fullName ?? "Client",
            generatedDate: generated,
            loFullName: profile.fullName.isEmpty ? "Loan Officer" : profile.fullName,
            loNMLSLine: nmlsLine,
            rows: rows,
            disclaimer: disclaimer,
            ehoStatement: ehoStatement,
            accentHex: profile.brandColorHex,
            blendedRate10yr: blended10yr,
            refiRate: viewModel.inputs.refiRate,
            verdict: verdict
        )
    }

    // Page composition helpers live in PDFBuilder+Pages.swift.

    static func defaultDisclaimer() -> String {
        "This illustration is not a commitment to lend. Rates reflect pricing "
            + "available at the time of generation for qualifying borrowers and may "
            + "change without notice. Actual APR will vary by program, property, "
            + "borrower qualifications, and closing date. See your Loan Estimate "
            + "for final terms."
    }

    static func resolveState(borrower: Borrower?) -> USState? {
        guard let code = borrower?.propertyState?.uppercased() else { return nil }
        return USState(rawValue: code)
    }

    private static func temporaryURL(for calc: String) -> URL {
        let dir = FileManager.default.temporaryDirectory
        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        return dir.appendingPathComponent("quotient-\(calc)-\(stamp).pdf")
    }
}
