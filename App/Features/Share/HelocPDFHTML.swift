// HelocPDFHTML.swift
// Session 5O.5 — HELOC vs Refinance PDF body composition.

import Foundation
import QuotientFinance

@MainActor
enum HelocPDFHTML {

    /// One comparison row: refi column + HELOC column. Moved here in
    /// 5O.8 from the deleted HelocComparisonPage SwiftUI view.
    struct Row {
        let label: String
        let refi: String
        let heloc: String
    }

    /// Build the canonical row list from a HelocViewModel.
    static func rows(for viewModel: HelocViewModel) -> [Row] {
        let inputs = viewModel.inputs
        let refiMonthly = MoneyFormat.shared.currency(viewModel.refiMonthlyPayment())
        let helocMonth1 = MoneyFormat.shared.currency(
            viewModel.helocMonthlyPayment(shockBps: 0)
        )
        let postIntro = MoneyFormat.shared.currency(
            viewModel.helocMonthlyPayment(shockBps: 0)
        )
        let blended10y = String(format: "%.2f%%", viewModel.blendedRateAtTenYears)
        let cashOut = MoneyFormat.shared.currency(
            inputs.firstLienBalance + inputs.helocAmount
        )
        let helocAmt = MoneyFormat.shared.currency(inputs.helocAmount)
        let refiRate = displayRateAndAPR(rate: inputs.refiRate, decimalAPR: inputs.refiAPR)
        let introRate = displayRateAndAPR(rate: inputs.helocIntroRate, decimalAPR: inputs.helocAPR)
        let fullIdx = displayRateAndAPR(rate: inputs.helocFullyIndexedRate, decimalAPR: inputs.helocAPR)
        let primeMargin = max(0, inputs.helocFullyIndexedRate - 7.50)
        let marginDisplay = String(format: "Prime + %.2f%%", primeMargin)
        let rateStructureHeloc = "Variable (intro → fully indexed)"
        let introPeriod = "\(inputs.helocIntroMonths) mo"
        var rows: [Row] = [
            Row(label: "Loan amount / Credit limit", refi: cashOut, heloc: helocAmt),
            Row(label: "Rate structure", refi: "Fixed", heloc: rateStructureHeloc),
            Row(label: "Intro rate", refi: refiRate, heloc: introRate),
            Row(label: "Intro period", refi: "—", heloc: introPeriod),
            Row(label: "Margin over Prime", refi: "—", heloc: marginDisplay),
            Row(label: "Post-intro rate", refi: refiRate, heloc: fullIdx),
            Row(label: "Monthly payment · month 1", refi: refiMonthly, heloc: helocMonth1),
            Row(label: "Monthly payment · post-intro", refi: refiMonthly, heloc: postIntro),
            Row(label: "Blended rate · 10 years", refi: refiRate, heloc: blended10y)
        ]
        if inputs.homeValue > 0 {
            rows.append(Row(
                label: "LTV · new loan",
                refi: String(format: "%.1f%%", inputs.refiLTV * 100),
                heloc: String(format: "%.1f%%", inputs.firstLienLTV * 100)
            ))
            rows.append(Row(
                label: "CLTV · total",
                refi: String(format: "%.1f%%", inputs.refiLTV * 100),
                heloc: String(format: "%.1f%%", inputs.cltv * 100)
            ))
        }
        let refiMI = inputs.refiMonthlyMI > 0
            ? MoneyFormat.shared.currency(inputs.refiMonthlyMI)
            : "—"
        rows.append(Row(label: "Monthly MI", refi: refiMI, heloc: "N/A"))
        rows.append(Row(label: "Closing costs", refi: "Typical $5k – $15k", heloc: "Typically lower"))
        rows.append(Row(label: "Points", refi: "0.00", heloc: "—"))
        rows.append(Row(label: "Flexibility", refi: "Fixed commitment", heloc: "Flexible draw / repay"))
        return rows
    }

    static func buildHTML(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: HelocViewModel,
        narrative: String
    ) -> String {
        let body = coverSection(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            narrative: narrative
        )
            + blendedHeroSection(viewModel: viewModel)
            + comparisonSection(viewModel: viewModel)
            + PDFHTMLComposition.disclaimersHTML(
                profile: profile,
                borrower: borrower,
                scenarioType: .helocVsRefinance
            )
        return PDFHTMLComposition.wrap(body: body)
    }

    // MARK: - Cover

    private static func coverSection(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: HelocViewModel,
        narrative: String
    ) -> String {
        let borrowerName = borrower?.fullName ?? "Client"
        let inputs = viewModel.inputs
        let blend = String(format: "%.2f", viewModel.blendedRate)
        let refi = String(format: "%.3f", inputs.refiRate)
        let firstLien = MoneyFormat.shared.currency(inputs.firstLienBalance)
        let helocAmt = MoneyFormat.shared.currency(inputs.helocAmount)
        let verdict = viewModel.blendedRate < inputs.refiRate ? "keep 1st" : "refi wins"
        let fallback = "Keeping the first mortgage and taking a HELOC blends to \(blend)% — "
            + "vs a cash-out refi at \(refi)%. Verdict: \(verdict)."
        let loanSummary = "1st \(firstLien) + HELOC \(helocAmt)"

        let eyebrow = "HELOC VS REFINANCE · \(PDFHTMLComposition.formatDate(Date()))"
        let hero = PDFHTMLComposition.heroCardHTML(
            label: "Blended rate · HELOC path",
            value: blend,
            prefix: "",
            suffix: "%"
        )
        let kpis = PDFHTMLComposition.kpiGridHTML([
            ("vs refi", "\(refi)%"),
            ("Verdict", verdict),
            ("1st rate", String(format: "%.3f%%", inputs.firstLienRate))
        ])
        let signature = PDFHTMLComposition.signatureHTML(profile: profile)
        let title = PDFHTMLComposition.titleBlockHTML(
            eyebrow: eyebrow,
            borrowerName: borrowerName,
            loanSummary: loanSummary
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

    // MARK: - 10-year blended-rate hero band

    private static func blendedHeroSection(viewModel: HelocViewModel) -> String {
        let blended = String(format: "%.2f%%", viewModel.blendedRateAtTenYears)
        let refi = String(format: "%.3f%%", viewModel.inputs.refiRate)
        let helocWins = viewModel.blendedRateAtTenYears < viewModel.inputs.refiRate
        let verdictText = helocWins ? "HELOC blended wins" : "Cash-out refi wins"
        let badgeClass = helocWins ? "badge" : "badge"
        return """
        <section>
          <div class="content-card">
            <div class="label">Blended rate · 10-year horizon</div>
            <div class="row">
              <div>
                <div class="label">HELOC blended</div>
                <div class="value" style="font-size: 22pt;">\(blended)</div>
              </div>
              <div>
                <div class="label">Cash-out refi</div>
                <div class="value" style="font-size: 22pt;">\(refi)</div>
              </div>
              <div>
                <div class="label">Verdict</div>
                <div><span class="\(badgeClass)">\(PDFHTMLComposition.escape(verdictText))</span></div>
              </div>
            </div>
          </div>
        </section>
        """
    }

    // MARK: - Comparison table

    private static func comparisonSection(viewModel: HelocViewModel) -> String {
        let rows = HelocPDFHTML.rows(for: viewModel)
        let bodyRows = rows.map { row in
            """
            <tr>
              <td>\(PDFHTMLComposition.escape(row.label))</td>
              <td class="num">\(PDFHTMLComposition.escape(row.refi))</td>
              <td class="num">\(PDFHTMLComposition.escape(row.heloc))</td>
            </tr>
            """
        }.joined()
        return """
        <section class="break-before">
          <p class="eyebrow">Side-by-side</p>
          <h2>Cash-out refinance vs HELOC</h2>
          <table class="data">
            <thead>
              <tr><th>Metric</th><th class="num">Cash-out refi</th><th class="num">HELOC</th></tr>
            </thead>
            <tbody>\(bodyRows)</tbody>
          </table>
          <p class="meta">Post-intro HELOC rate is variable and indexed to Prime + margin. Illustrated payments
             assume no draws beyond the opening balance and no intro-period shock. See disclosures.</p>
        </section>
        """
    }
}
