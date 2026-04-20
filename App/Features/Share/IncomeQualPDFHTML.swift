// IncomeQualPDFHTML.swift
// Session 5O.6 — Income Qualification PDF body composition.

import Foundation
import QuotientFinance

@MainActor
enum IncomeQualPDFHTML {

    static func buildHTML(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: IncomeQualViewModel,
        narrative: String
    ) -> String {
        let body = coverSection(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            narrative: narrative
        )
            + breakdownSection(viewModel: viewModel)
            + PDFHTMLComposition.disclaimersHTML(
                profile: profile,
                borrower: borrower,
                scenarioType: .incomeQualification
            )
        return PDFHTMLComposition.wrap(body: body)
    }

    // MARK: - Cover

    private static func coverSection(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: IncomeQualViewModel,
        narrative: String
    ) -> String {
        let borrowerName = borrower?.fullName ?? "Client"
        let inputs = viewModel.inputs
        let maxLoan = MoneyFormat.shared.currency(viewModel.maxLoan)
        let piti = MoneyFormat.shared.currency(viewModel.maxPITI)
        let purchase = MoneyFormat.shared.currency(viewModel.maxPurchase)
        let backDTI = String(format: "%.1f%%", viewModel.backEndDTIIncludingDebts * 100)
        let rateDisplay = displayRateAndAPR(
            rate: inputs.annualRate,
            decimalAPR: inputs.aprRate
        )
        let isRefi = inputs.mode == .refinance

        let summary = isRefi
            ? "Refi · \(rateDisplay) · \(inputs.termYears)-yr · DTI \(backDTI)"
            : "at \(rateDisplay) · \(inputs.termYears)-yr · DTI \(backDTI)"

        let secondaryLabel = isRefi ? "Current LTV" : "Max purchase"
        let secondaryValue: String = {
            if isRefi {
                guard inputs.currentHomeValue > 0 else { return "—" }
                return String(format: "%.1f%%", inputs.currentRefiLTV * 100)
            }
            return purchase
        }()
        let reservesMonths = inputs.reservesMonths
        let reservesTotal = MoneyFormat.shared.currency(
            viewModel.maxPITI * Decimal(reservesMonths)
        )
        let reservesValue = reservesMonths > 0
            ? "\(reservesMonths) mo · \(reservesTotal)"
            : "—"
        let reservesSentence = reservesMonths > 0
            ? " Requires \(reservesMonths)-month reserves: \(reservesTotal) (\(reservesMonths) × PITI)."
            : ""

        let rateStr = String(format: "%.3f", inputs.annualRate)
        let currentBal = MoneyFormat.shared.currency(inputs.currentLoanBalance)
        let fallback: String = {
            if isRefi {
                return "Qualifies at \(rateStr)% \(inputs.termYears)-yr — max "
                    + "qualifying loan \(maxLoan) vs current balance \(currentBal). "
                    + "Back-end DTI lands at \(backDTI)." + reservesSentence
            }
            return "Qualifies up to \(maxLoan) at a \(rateStr)% "
                + "\(inputs.termYears)-yr loan. Back-end DTI lands at \(backDTI)."
                + reservesSentence
        }()

        let eyebrow = (isRefi ? "INCOME QUALIFICATION · REFINANCE · " : "INCOME QUALIFICATION · ")
            + PDFHTMLComposition.formatDate(Date())
        let hero = PDFHTMLComposition.heroCardHTML(
            label: "Max loan · qualifying",
            value: maxLoan,
            prefix: "",
            suffix: ""
        )
        let kpis = PDFHTMLComposition.kpiGridHTML([
            ("Max PITI", piti),
            (secondaryLabel, secondaryValue),
            ("Back-end DTI", backDTI),
            ("Reserves", reservesValue)
        ])
        let signature = PDFHTMLComposition.signatureHTML(profile: profile)
        let title = PDFHTMLComposition.titleBlockHTML(
            eyebrow: eyebrow,
            borrowerName: borrowerName,
            loanSummary: summary
        )
        let narrativeCopy = narrative.isEmpty ? fallback : narrative
        return """
        <section>
          \(signature)
          \(title)
          \(hero)
          \(kpis)
          <h2>Summary</h2>
          <p class="summary-text">\(PDFHTMLComposition.escape(narrativeCopy))</p>
        </section>
        """
    }

    // MARK: - Breakdown table

    private static func breakdownSection(viewModel: IncomeQualViewModel) -> String {
        let inputs = viewModel.inputs
        let qualifyingIncome = MoneyFormat.shared.currency(viewModel.qualifyingIncome)
        let totalDebt = MoneyFormat.shared.currency(viewModel.totalDebt)
        let frontDTI = String(format: "%.1f%%", viewModel.frontEndDTI * 100)
        let backDTI = String(format: "%.1f%%", viewModel.backEndDTIIncludingDebts * 100)
        let maxPITI = MoneyFormat.shared.currency(viewModel.maxPITI)
        let maxLoan = MoneyFormat.shared.currency(viewModel.maxLoan)

        var rows: [(String, String)] = [
            ("Qualifying income (monthly)", qualifyingIncome),
            ("Total monthly debts", totalDebt),
            ("Front-end DTI (housing only)", frontDTI),
            ("Back-end DTI (housing + debts)", backDTI),
            ("Max qualifying PITI", maxPITI),
            ("Max qualifying loan", maxLoan)
        ]
        if inputs.mode == .refinance {
            rows.append(("Current loan balance",
                         MoneyFormat.shared.currency(inputs.currentLoanBalance)))
            if inputs.currentHomeValue > 0 {
                rows.append(("Current home value",
                             MoneyFormat.shared.currency(inputs.currentHomeValue)))
                rows.append(("Current LTV",
                             String(format: "%.1f%%", inputs.currentRefiLTV * 100)))
            }
        } else {
            rows.append(("Max purchase price",
                         MoneyFormat.shared.currency(viewModel.maxPurchase)))
        }

        let body = rows.map { row in
            "<tr><td>\(PDFHTMLComposition.escape(row.0))</td><td class=\"num\">"
                + "\(PDFHTMLComposition.escape(row.1))</td></tr>"
        }.joined()
        return """
        <section>
          <h2>Qualification breakdown</h2>
          <table class="data">
            <thead><tr><th>Metric</th><th class="num">Value</th></tr></thead>
            <tbody>\(body)</tbody>
          </table>
        </section>
        """
    }
}
