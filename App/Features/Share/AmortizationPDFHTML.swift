// AmortizationPDFHTML.swift
// Session 5O.2 — Amortization calculator PDF body composition.
// Returns a full HTML document (base.html + content body) which
// HTMLPDFRenderer paginates into a multi-page PDF with per-page header
// + footer drawn by NestIQPrintRenderer.

import Foundation
import QuotientFinance

@MainActor
enum AmortizationPDFHTML {

    static func buildHTML(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: AmortizationViewModel,
        narrative: String,
        scheduleGranularity: AmortScheduleGranularity
    ) -> String {
        let body = coverSection(
            profile: profile,
            borrower: borrower,
            viewModel: viewModel,
            narrative: narrative
        )
            + scheduleSection(
                viewModel: viewModel,
                granularity: scheduleGranularity
            )
            + PDFHTMLComposition.disclaimersHTML(
                profile: profile,
                borrower: borrower,
                scenarioType: .amortization
            )
        return PDFHTMLComposition.wrap(body: body)
    }

    // MARK: - Cover

    private static func coverSection(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: AmortizationViewModel,
        narrative: String
    ) -> String {
        let borrowerName = borrower?.fullName ?? "Client"
        let rateDisplay = displayRateAndAPR(
            rate: viewModel.inputs.annualRate,
            decimalAPR: viewModel.inputs.aprRate
        )
        let loanMoney = MoneyFormat.shared.currency(viewModel.inputs.loanAmount)
        let loanSummary = "\(loanMoney) · \(viewModel.inputs.termYears)-yr fixed · \(rateDisplay)"

        let piti = MoneyFormat.shared.currency(viewModel.monthlyPITI)
        let interest = MoneyFormat.shared.dollarsShort(viewModel.totalInterest)
        let totalPaid = MoneyFormat.shared.dollarsShort(viewModel.totalPaid)
        let payoff = viewModel.payoffDate.map {
            PDFHTMLComposition.formatDate($0, style: .monthYear)
        } ?? "—"
        let rateStr = String(format: "%.3f", viewModel.inputs.annualRate)
        let narrativeCopy: String = {
            if !narrative.isEmpty { return narrative }
            return "At today's \(rateStr)% rate, the monthly PITI is \(piti). "
                + "Over the life of the loan, interest totals about \(interest)."
        }()

        let eyebrow = "AMORTIZATION · \(PDFHTMLComposition.formatDate(Date()))"
        let hero = PDFHTMLComposition.heroCardHTML(
            label: "Monthly payment · PITI",
            value: piti,
            prefix: "",
            suffix: ""
        )
        let kpis = PDFHTMLComposition.kpiGridHTML([
            ("Total interest", interest),
            ("Payoff", payoff),
            ("Total paid", totalPaid)
        ])
        let signature = PDFHTMLComposition.signatureHTML(profile: profile)
        let title = PDFHTMLComposition.titleBlockHTML(
            eyebrow: eyebrow,
            borrowerName: borrowerName,
            loanSummary: loanSummary
        )

        return """
        <section>
          \(signature)
          \(title)
          \(hero)
          \(kpis)
          <h2>Summary</h2>
          <p class="summary-text">\(PDFHTMLComposition.escape(narrativeCopy))</p>
          \(paymentBreakdownHTML(viewModel: viewModel))
        </section>
        """
    }

    private static func paymentBreakdownHTML(viewModel: AmortizationViewModel) -> String {
        let rows: [(label: String, value: Decimal)] = [
            ("Principal & interest", viewModel.monthlyPI),
            ("Property tax", viewModel.monthlyTax),
            ("Insurance", viewModel.monthlyInsurance),
            ("HOA", viewModel.monthlyHOA),
            ("Mortgage insurance", viewModel.monthlyPMI)
        ]
        let bodyRows = rows
            .filter { $0.value > 0 || $0.label == "Principal & interest" }
            .map { row in
                let amount = MoneyFormat.shared.currency(row.value)
                return "<tr><td>\(PDFHTMLComposition.escape(row.label))</td><td class=\"num\">\(amount)</td></tr>"
            }
            .joined()
        return """
        <h2>Payment breakdown</h2>
        <table class="data">
          <thead><tr><th>Component</th><th class="num">Monthly</th></tr></thead>
          <tbody>\(bodyRows)</tbody>
        </table>
        """
    }

    // MARK: - Schedule

    private static func scheduleSection(
        viewModel: AmortizationViewModel,
        granularity: AmortScheduleGranularity
    ) -> String {
        guard let schedule = viewModel.schedule else { return "" }
        switch granularity {
        case .yearly:
            return yearlyScheduleHTML(schedule: schedule)
        case .monthly:
            return monthlyScheduleHTML(schedule: schedule, viewModel: viewModel)
        }
    }

    private static func yearlyScheduleHTML(schedule: AmortizationSchedule) -> String {
        let rows = yearlyAggregate(schedule: schedule)
        let yearFmt = DateFormatter()
        yearFmt.dateFormat = "MMM yyyy"
        let bodyRows = rows.map { row in
            let first = yearFmt.string(from: row.firstPaymentDate)
            let last = yearFmt.string(from: row.lastPaymentDate)
            let range = first == last ? first : "\(first) – \(last)"
            return """
            <tr>
              <td class="num">\(row.year)</td>
              <td>\(PDFHTMLComposition.escape(range))</td>
              <td class="num">\(MoneyFormat.shared.currency(row.totalPayment))</td>
              <td class="num">\(MoneyFormat.shared.currency(row.totalPrincipal))</td>
              <td class="num">\(MoneyFormat.shared.currency(row.totalInterest))</td>
              <td class="num">\(MoneyFormat.shared.currency(row.endingBalance))</td>
            </tr>
            """
        }.joined()
        return """
        <section class="break-before">
          <p class="eyebrow">Amortization schedule · yearly</p>
          <h2>Year-by-year breakdown</h2>
          <table class="data">
            <thead>
              <tr>
                <th class="num">Year</th>
                <th>Calendar</th>
                <th class="num">Total paid</th>
                <th class="num">Principal</th>
                <th class="num">Interest</th>
                <th class="num">Year-end balance</th>
              </tr>
            </thead>
            <tbody>\(bodyRows)</tbody>
          </table>
        </section>
        """
    }

    private static func monthlyScheduleHTML(
        schedule: AmortizationSchedule,
        viewModel: AmortizationViewModel
    ) -> String {
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "MMM d, yyyy"
        let miDropoff = viewModel.miDropoffPeriod
        let bodyRows = schedule.payments.map { p in
            let isDropoff = miDropoff.map { p.number == $0 } ?? false
            let rowClass = isDropoff ? " class=\"winner\"" : ""
            let actualPayment = p.payment + p.extraPrincipal
            let actualPrincipal = p.principal + p.extraPrincipal
            return """
            <tr\(rowClass)>
              <td class="num">\(p.number)</td>
              <td>\(PDFHTMLComposition.escape(dateFmt.string(from: p.date)))</td>
              <td class="num">\(MoneyFormat.shared.currency(actualPayment))</td>
              <td class="num">\(MoneyFormat.shared.currency(actualPrincipal))</td>
              <td class="num">\(MoneyFormat.shared.currency(p.interest))</td>
              <td class="num">\(MoneyFormat.shared.currency(p.balance))</td>
            </tr>
            """
        }.joined()
        return """
        <section class="break-before">
          <p class="eyebrow">Amortization schedule · monthly</p>
          <h2>Payment-by-payment breakdown</h2>
          <table class="data">
            <thead>
              <tr>
                <th class="num">#</th>
                <th>Date</th>
                <th class="num">Payment</th>
                <th class="num">Principal</th>
                <th class="num">Interest</th>
                <th class="num">Balance</th>
              </tr>
            </thead>
            <tbody>\(bodyRows)</tbody>
          </table>
        </section>
        """
    }
}
