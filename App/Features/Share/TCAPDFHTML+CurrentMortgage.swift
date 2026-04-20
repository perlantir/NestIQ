// TCAPDFHTML+CurrentMortgage.swift
// Session 5P.11 — the PDF mirror of the on-screen Current mortgage
// anchor card (5P.10 / TCAScreen+CurrentMortgage). Kept in its own
// file so TCAPDFHTML stays under SwiftLint's type_body_length cap.

import Foundation
import QuotientFinance

extension TCAPDFHTML {

    /// Refi-mode status-quo anchor card. No-op when refi mode is off
    /// or the inputs carry no currentMortgage snapshot.
    static func currentMortgageSection(viewModel: TCAViewModel) -> String {
        guard viewModel.inputs.mode == .refinance,
              let mortgage = viewModel.inputs.currentMortgage else {
            return ""
        }
        let balance = MoneyFormat.shared.currency(mortgage.currentBalance)
        let piti = MoneyFormat.shared.currency(mortgage.currentMonthlyPaymentPI)
        let rate = String(format: "%.3f%%", mortgage.currentRatePercent.asDouble)
        let remaining = CurrentMortgageCalculations.monthsRemaining(
            originalTermYears: mortgage.originalTermYears,
            loanStartDate: mortgage.loanStartDate
        )
        let equity = MoneyFormat.shared.currency(
            CurrentMortgageCalculations.equityToday(
                currentBalance: mortgage.currentBalance,
                propertyValue: mortgage.propertyValueToday
            )
        )
        let ltv = CurrentMortgageCalculations.ltvToday(
            currentBalance: mortgage.currentBalance,
            propertyValue: mortgage.propertyValueToday
        )
        let ltvStr = String(format: "%.1f%%", ltv.asDouble * 100)
        return """
        <section>
          <p class="eyebrow">Status quo · current mortgage</p>
          <div class="content-card">
            <div class="row">
              <div><div class="label">Current balance</div><div class="value">\(balance)</div></div>
              <div><div class="label">Current P&amp;I</div><div class="value">\(piti)/mo</div></div>
              <div><div class="label">Current rate</div><div class="value">\(rate)</div></div>
            </div>
            <div class="row">
              <div><div class="label">Months remaining</div><div class="value">\(remaining)</div></div>
              <div><div class="label">Equity today</div><div class="value">\(equity)</div></div>
              <div><div class="label">LTV today</div><div class="value">\(ltvStr)</div></div>
            </div>
          </div>
        </section>
        """
    }
}
