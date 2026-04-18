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
        payload: Payload
    ) throws -> URL {
        let url = temporaryURL(for: payload.calculatorSlug)
        let cover = AnyView(coverPage(profile: profile, borrower: borrower, payload: payload))
        let disclaimers = AnyView(
            disclaimersPage(
                profile: profile,
                borrower: borrower,
                scenarioType: payload.complianceScenarioType
            )
        )
        try PDFRenderer.renderPDF(pages: [cover, disclaimers], to: url)
        return url
    }

    // MARK: Per-calculator convenience builders

    static func buildAmortizationPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: AmortizationViewModel,
        narrative: String
    ) throws -> URL {
        let interest = MoneyFormat.shared.dollarsShort(viewModel.totalInterest)
        let totalPaid = MoneyFormat.shared.dollarsShort(viewModel.totalPaid)
        let rate = String(format: "%.3f", viewModel.inputs.annualRate)
        let loanMoney = MoneyFormat.shared.decimalString(viewModel.inputs.loanAmount)
        let piti = MoneyFormat.shared.decimalString(viewModel.monthlyPITI)
        let payoff = viewModel.payoffDate.map { d -> String in
            let f = DateFormatter(); f.dateFormat = "MMM yyyy"; return f.string(from: d)
        } ?? "—"
        let fallbackNarrative = "At today's \(rate)% rate, the monthly PITI is $\(piti). "
            + "Over the life of the loan, interest totals about $\(interest)."
        let payload = Payload(
            calculatorSlug: "amortization",
            calculatorTitle: "Amortization analysis",
            complianceScenarioType: .amortization,
            loanSummary: "$\(loanMoney) · \(viewModel.inputs.termYears)-yr fixed · \(rate)%",
            heroLabel: "Monthly payment · PITI",
            heroValue: piti,
            heroKPIs: [
                ("Total interest", "$\(interest)"),
                ("Payoff", payoff),
                ("Total paid", "$\(totalPaid)"),
            ],
            narrative: narrative.isEmpty ? fallbackNarrative : narrative
        )
        return try buildPDF(profile: profile, borrower: borrower, payload: payload)
    }

    static func buildIncomeQualPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: IncomeQualViewModel,
        narrative: String
    ) throws -> URL {
        let maxLoan = MoneyFormat.shared.decimalString(viewModel.maxLoan)
        let piti = MoneyFormat.shared.decimalString(viewModel.maxPITI)
        let purchase = MoneyFormat.shared.decimalString(viewModel.maxPurchase)
        let backDTI = String(format: "%.1f%%", viewModel.backEndDTIIncludingDebts * 100)
        let rate = String(format: "%.3f", viewModel.inputs.annualRate)
        let fallback = "Qualifies up to $\(maxLoan) at a \(rate)% \(viewModel.inputs.termYears)-yr loan. "
            + "Back-end DTI lands at \(backDTI)."
        let payload = Payload(
            calculatorSlug: "income-qualification",
            calculatorTitle: "Income qualification",
            complianceScenarioType: .incomeQualification,
            loanSummary: "at \(rate)% · \(viewModel.inputs.termYears)-yr · DTI \(backDTI)",
            heroLabel: "Max loan · qualifying",
            heroValue: maxLoan,
            heroKPIs: [
                ("Max PITI", "$\(piti)"),
                ("Max purchase", "$\(purchase)"),
                ("Back-end DTI", backDTI),
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
        let savings = MoneyFormat.shared.decimalString(viewModel.monthlySavings)
        let be = viewModel.breakEvenMonth.map { "\($0) mo" } ?? "—"
        let lifetime = MoneyFormat.shared.dollarsShort(abs(viewModel.lifetimeDelta))
        let npv = MoneyFormat.shared.dollarsShort(abs(viewModel.npvDelta))
        let currentRate = String(format: "%.3f", viewModel.inputs.currentRate)
        let fallback = "Selected refi saves $\(savings)/mo versus the current \(currentRate)% loan. "
            + "Break-even: \(be)."
        let payload = Payload(
            calculatorSlug: "refinance",
            calculatorTitle: "Refinance comparison",
            complianceScenarioType: .refinance,
            loanSummary: "Current $\(MoneyFormat.shared.decimalString(viewModel.inputs.currentBalance)) @ \(currentRate)%",
            heroLabel: "Monthly savings · selected option",
            heroValue: savings,
            heroKPIs: [
                ("Break-even", be),
                ("Lifetime Δ", "$\(lifetime)"),
                ("NPV @ 5%", "$\(npv)"),
            ],
            narrative: narrative.isEmpty ? fallback : narrative
        )
        return try buildPDF(profile: profile, borrower: borrower, payload: payload)
    }

    static func buildTCAPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: TCAViewModel,
        narrative: String
    ) throws -> URL {
        let loan = MoneyFormat.shared.decimalString(viewModel.inputs.loanAmount)
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
            loanSummary: "$\(loan) · \(count) scenarios · \(horizons)",
            heroLabel: "Scenarios compared",
            heroValue: "\(count)",
            heroKPIs: [
                ("Horizons", "\(viewModel.inputs.horizonsYears.count)"),
                ("Life winner", winnerName),
                ("Loan", "$\(MoneyFormat.shared.dollarsShort(viewModel.inputs.loanAmount))"),
            ],
            narrative: narrative.isEmpty ? fallback : narrative
        )
        return try buildPDF(profile: profile, borrower: borrower, payload: payload)
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
            loanSummary: "1st $\(firstLien) + HELOC $\(helocAmt)",
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
        return try buildPDF(profile: profile, borrower: borrower, payload: payload)
    }

    // MARK: Page composition

    private static func coverPage(
        profile: LenderProfile,
        borrower: Borrower?,
        payload: Payload
    ) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let generated = formatter.string(from: Date())
        return PDFCoverPage(
            borrowerName: borrower?.fullName ?? "Client",
            loFullName: profile.fullName.isEmpty ? "Loan Officer" : profile.fullName,
            loNMLS: profile.nmlsId.isEmpty ? "—" : profile.nmlsId,
            loCompany: profile.companyName.isEmpty ? "—" : profile.companyName,
            loEmail: profile.email,
            loPhone: profile.phone,
            calculatorTitle: payload.calculatorTitle,
            generatedDate: generated,
            loanSummary: payload.loanSummary,
            heroPITI: payload.heroValue,
            heroKPIs: payload.heroKPIs,
            narrative: payload.narrative,
            accentHex: profile.brandColorHex,
            logoData: profile.companyLogoData,
            signatureLine: profile.tagline,
            loPhotoData: profile.showPhotoOnPDF ? profile.photoData : nil,
            heroLabel: payload.heroLabel,
            heroValuePrefix: payload.heroValuePrefix,
            heroValueSuffix: payload.heroValueSuffix
        )
    }

    private static func disclaimersPage(
        profile: LenderProfile,
        borrower: Borrower?,
        scenarioType: ScenarioType
    ) -> some View {
        let state = resolveState(borrower: borrower)
        let disclosures = requiredDisclosures(
            for: scenarioType,
            propertyState: state ?? .CA
        )
        let body = disclosures.map(\.textEN).joined(separator: "\n\n")
        let dateString: String = {
            let f = DateFormatter()
            f.dateFormat = "MMM d, yyyy · HH:mm"
            return f.string(from: Date())
        }()
        return PDFDisclaimersPage(
            disclosureText: body.isEmpty ? defaultDisclaimer() : body,
            loFullName: profile.fullName.isEmpty ? "Loan Officer" : profile.fullName,
            loNMLS: profile.nmlsId.isEmpty ? "—" : profile.nmlsId,
            loCompany: profile.companyName.isEmpty ? "—" : profile.companyName,
            licensedStates: profile.licensedStates,
            generatedAt: dateString
        )
    }

    private static func defaultDisclaimer() -> String {
        "This illustration is not a commitment to lend. Rates reflect pricing "
            + "available at the time of generation for qualifying borrowers and may "
            + "change without notice. Actual APR will vary by program, property, "
            + "borrower qualifications, and closing date. See your Loan Estimate "
            + "for final terms."
    }

    private static func resolveState(borrower: Borrower?) -> USState? {
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
