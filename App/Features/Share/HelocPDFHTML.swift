// HelocPDFHTML.swift
// Session 5O.5 — HELOC vs Refinance PDF body composition.

import Foundation
import QuotientFinance

@MainActor
enum HelocPDFHTML {

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
        let rows = HelocComparisonPage.rows(for: viewModel)
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
