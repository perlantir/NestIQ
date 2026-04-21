// HelocPDFHTML.swift
// Session 7.3f — Template-driven HELOC vs Refinance PDF builder.
//
// Loads pdf-heloc-with-masthead.html via PDFTemplateLoader, fills the
// token dictionary from HelocViewModel + +PDFDerivations, and appends
// the compliance trailer (per D12) before handing HTML to the renderer.
// Template owns all chrome, layout, and typography.

import Foundation
import QuotientFinance

@MainActor
enum HelocPDFHTML {

    /// Row shape used by the on-screen side-by-side comparison table in
    /// HelocScreen (not the PDF; the PDF has its own tokenized layout
    /// now, but the view still renders rows from this list).
    struct Row {
        let label: String
        let refi: String
        let heloc: String
    }

    /// Canonical row list for the side-by-side view. PDF no longer uses
    /// this — templates emit token-by-token — but the Results screen
    /// comparison table still does.
    static func rows(for viewModel: HelocViewModel) -> [Row] {
        let inputs = viewModel.inputs
        let money = MoneyFormat.shared
        let refiMonthly = money.currency(viewModel.refiMonthlyPayment())
        let helocMonth1 = money.currency(viewModel.helocMonthlyPayment(shockBps: 0))
        let blended10y = String(format: "%.2f%%", viewModel.blendedRateAtTenYears)
        let cashOut = money.currency(inputs.firstLienBalance + inputs.helocAmount)
        let helocAmt = money.currency(inputs.helocAmount)
        let refiRate = displayRateAndAPR(rate: inputs.refiRate, decimalAPR: inputs.refiAPR)
        let introRate = displayRateAndAPR(rate: inputs.helocIntroRate, decimalAPR: inputs.helocAPR)
        let fullIdx = displayRateAndAPR(rate: inputs.helocFullyIndexedRate, decimalAPR: inputs.helocAPR)
        let primeMargin = max(0, inputs.helocFullyIndexedRate - 7.50)
        let marginDisplay = String(format: "Prime + %.2f%%", primeMargin)
        var rows: [Row] = [
            Row(label: "Loan amount / Credit limit", refi: cashOut, heloc: helocAmt),
            Row(label: "Rate structure", refi: "Fixed", heloc: "Variable (intro → fully indexed)"),
            Row(label: "Intro rate", refi: refiRate, heloc: introRate),
            Row(label: "Intro period", refi: "—", heloc: "\(inputs.helocIntroMonths) mo"),
            Row(label: "Margin over Prime", refi: "—", heloc: marginDisplay),
            Row(label: "Post-intro rate", refi: refiRate, heloc: fullIdx),
            Row(label: "Monthly payment · month 1", refi: refiMonthly, heloc: helocMonth1),
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
        let refiMI = inputs.refiMonthlyMI > 0 ? money.currency(inputs.refiMonthlyMI) : "—"
        rows.append(Row(label: "Monthly MI", refi: refiMI, heloc: "N/A"))
        rows.append(Row(label: "Flexibility", refi: "Fixed commitment", heloc: "Flexible draw / repay"))
        return rows
    }

    // MARK: - Template-driven PDF

    static func buildHTML(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: HelocViewModel
    ) throws -> String {
        let template = try PDFTemplateLoader.load("pdf-heloc-with-masthead")
        let values = tokens(profile: profile, borrower: borrower, viewModel: viewModel)
        let html = HTMLPDFRenderer.shared.interpolate(
            template: template,
            values: values
        )
        let trailer = PDFTemplateLoader.complianceTrailerPage(
            profile: profile,
            borrower: borrower,
            scenarioType: .helocVsRefinance
        )
        return html.replacingOccurrences(
            of: "</body>",
            with: "\(trailer)\n</body>"
        )
    }

    // MARK: - Token filling

    private static func tokens(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: HelocViewModel
    ) -> [String: String] {
        let inputs = viewModel.inputs
        let money = MoneyFormat.shared
        let borrowerFirst = borrower?.firstName ?? "Client"
        let borrowerLast = borrower?.lastName ?? ""
        let propertyAddress = borrower?.propertyAddress ?? ""
        let preparedDate = PDFHTMLComposition.formatDate(Date(), style: .short)

        // Lien stack bar widths (as % of home value)
        let home = inputs.homeValue
        let firstLienBalance = inputs.firstLienBalance
        let helocAmount = inputs.helocAmount
        let remainingEquity = max(home - firstLienBalance - helocAmount, 0)
        let cltvPct: String = {
            guard home > 0 else { return "—" }
            let pct = Double(truncating: ((firstLienBalance + helocAmount) / home) as NSNumber) * 100
            return String(format: "%.0f%%", pct)
        }()

        // First mortgage P&I
        let firstLien = Loan(
            principal: firstLienBalance,
            annualRate: inputs.firstLienRate / 100,
            termMonths: inputs.firstLienRemainingYears * 12,
            startDate: Date()
        )
        let firstPI = paymentFor(loan: firstLien)

        // HELOC draw-period IO payment and repayment-period amortized P&I
        let helocIO = helocAmount * Decimal(inputs.helocFullyIndexedRate / 100 / 12)
        let helocRepayPmt = amortizedPayment(
            principal: helocAmount,
            annualRatePct: inputs.helocFullyIndexedRate,
            termMonths: inputs.helocRepaymentPeriodYears * 12
        )

        // 10-year cumulative cost metrics (signed delta: negative = HELOC cheaper)
        let netDelta = viewModel.tenYearNetCostDelta
        let helocTenYrInterest = viewModel.tenYearCumulativeInterestHELOC
        let refiTenYrInterest = viewModel.tenYearCumulativeInterestRefi
        let savingsVsRefi = refiTenYrInterest - helocTenYrInterest
        let helocWins = netDelta <= 0

        // Refi monthly (for year-n payment matrix)
        let refiMonthly = viewModel.refiMonthlyPayment()
        let helocDrawMonthly = firstPI + helocIO
        let helocYear11Monthly = firstPI + helocRepayPmt

        // Break-even month label
        let breakevenLabel: String = {
            guard let months = viewModel.breakEvenMonthsHELOCvsRefi else {
                return "never"
            }
            if months <= 1 { return "immediate" }
            return "\(months) mo"
        }()

        // First-mortgage origination: "Aug 2021"
        let origFmt = DateFormatter()
        origFmt.dateFormat = "MMM yyyy"
        let origDate = origFmt.string(from: inputs.firstMortgageOriginationDate)

        // Rate premium (refi − first-lien) in bps
        let ratePremiumBps = Int(round(
            (inputs.cashoutRefiRate.asDouble - inputs.firstLienRate) * 100
        ))

        // Index+margin display: "Prime + 0.50"
        let indexPlusMargin = "\(inputs.helocIndexType.displayName) + "
            + String(format: "%.2f", inputs.helocMarginPct.asDouble)

        // Recommendation copy
        let recommendedProduct = "\(money.dollarsShort(helocAmount)) HELOC · "
            + "\(inputs.helocDrawPeriodYears) / \(inputs.helocRepaymentPeriodYears) draw-repay"

        var out: [String: String] = [
            "borrower_first": PDFHTMLComposition.escape(borrowerFirst),
            "borrower_last": PDFHTMLComposition.escape(borrowerLast.isEmpty ? borrowerFirst : borrowerLast),
            "property_address": PDFHTMLComposition.escape(propertyAddress),
            "doc_num": Self.generateDocNum(prefix: "HL"),
            "prepared_by_name": PDFHTMLComposition.escape(profile.fullName),
            "prepared_by_nmls": PDFHTMLComposition.escape(profile.nmlsId),
            "prepared_date": preparedDate,
            "loan_amount_formatted": money.currency(firstLienBalance + helocAmount),

            "cash_need_formatted": money.currency(helocAmount),
            "home_value_formatted": money.currency(home),
            "post_cltv_pct": cltvPct,
            "remaining_equity_formatted": money.currency(remainingEquity),
            "first_mortgage_balance_formatted": money.currency(firstLienBalance),
            "first_mortgage_payment": money.decimalString(firstPI),
            "first_mortgage_originated": origDate,
            "current_rate_pct": String(format: "%.3f%%", inputs.firstLienRate),

            "first_lien_bar_pct": percentOf(firstLienBalance, home: home),
            "heloc_bar_pct": percentOf(helocAmount, home: home),
            "remaining_equity_bar_pct": percentOf(remainingEquity, home: home),

            "recommended_product": recommendedProduct,
            "recommended_savings_vs_refi": helocWins ? money.dollarsShort(abs(netDelta)) : "—",
            "ten_yr_savings_vs_refi": money.decimalString(abs(savingsVsRefi)),
            "blended_effective_rate_pct": String(format: "%.2f%%", viewModel.blendedRateAtTenYears),

            "heloc_draw_rate_pct": String(format: "%.3f%%", inputs.helocFullyIndexedRate),
            "heloc_index_plus_margin_pct": indexPlusMargin,
            "heloc_draw_period_yrs": String(inputs.helocDrawPeriodYears),
            "heloc_repay_period_yrs": String(inputs.helocRepaymentPeriodYears),
            "heloc_lifetime_cap_pct": String(format: "%.2f%%", inputs.helocLifetimeCapPct.asDouble),
            "heloc_line_formatted": money.currency(helocAmount),
            "heloc_interest_only_payment": money.decimalString(helocIO),
            "heloc_repay_payment_start": money.decimalString(helocRepayPmt),

            "cashout_refi_rate_pct": String(format: "%.3f%%", inputs.cashoutRefiRate.asDouble),
            "rate_premium_bps": String(max(ratePremiumBps, 0)),

            "heloc_year1_payment": money.decimalString(helocDrawMonthly),
            "heloc_year5_payment": money.decimalString(helocDrawMonthly),
            "heloc_year11_payment": money.decimalString(helocYear11Monthly),
            "refi_year1_payment": money.decimalString(refiMonthly),
            "refi_year5_payment": money.decimalString(refiMonthly),
            "refi_year11_payment": money.decimalString(refiMonthly),

            "heloc_closing_costs_formatted": money.currency(inputs.helocClosingCosts),
            "refi_closing_costs_formatted": money.currency(inputs.cashoutRefiClosingCosts),
            "heloc_breakeven_months": breakevenLabel,
            "heloc_10yr_interest_formatted": money.dollarsShort(helocTenYrInterest),
            "refi_10yr_interest_formatted": money.dollarsShort(refiTenYrInterest),
            "heloc_10yr_principal_paydown": money.dollarsShort(viewModel.tenYearPrincipalPaydownHELOC),
            "refi_10yr_principal_paydown": money.dollarsShort(viewModel.tenYearPrincipalPaydownRefi),
            "heloc_10yr_net_cost": netCostLabel(delta: netDelta),
            "refi_10yr_net_cost": netCostLabel(delta: -netDelta)
        ]
        out.merge(stressTokens(viewModel: viewModel)) { _, new in new }
        return out
    }

    /// 5-row stress matrix tokens: today / flat / +100 / +200 / +300.
    private static func stressTokens(viewModel: HelocViewModel) -> [String: String] {
        let stress = viewModel.stressPathMatrix
        let money = MoneyFormat.shared
        let crossoverBps = estimateCrossoverBps(
            stress: stress,
            cashoutRate: viewModel.inputs.cashoutRefiRate.asDouble
        )
        return [
            "stress_today_rate": String(format: "%.3f%%", stress[0].rate.asDouble),
            "stress_today_payment": money.decimalString(stress[0].payment),
            "stress_today_peak": money.decimalString(stress[0].peak),
            "stress_flat_rate": String(format: "%.3f%%", stress[1].rate.asDouble),
            "stress_flat_payment": money.decimalString(stress[1].payment),
            "stress_flat_peak": money.decimalString(stress[1].peak),
            "stress_plus1_rate": String(format: "%.3f%%", stress[2].rate.asDouble),
            "stress_plus1_payment": money.decimalString(stress[2].payment),
            "stress_plus1_delta": money.decimalString(stress[2].delta),
            "stress_plus1_peak": money.decimalString(stress[2].peak),
            "stress_plus2_rate": String(format: "%.3f%%", stress[3].rate.asDouble),
            "stress_plus2_payment": money.decimalString(stress[3].payment),
            "stress_plus2_delta": money.decimalString(stress[3].delta),
            "stress_plus2_peak": money.decimalString(stress[3].peak),
            "stress_plus2_blended": stress[3].blendedRate
                .map { String(format: "%.2f%%", $0.asDouble) } ?? "—",
            "stress_plus3_rate": String(format: "%.3f%%", stress[4].rate.asDouble),
            "stress_plus3_payment": money.decimalString(stress[4].payment),
            "stress_plus3_delta": money.decimalString(stress[4].delta),
            "stress_plus3_peak": money.decimalString(stress[4].peak),
            "stress_crossover_bps": String(crossoverBps)
        ]
    }

    // MARK: - Helpers

    private static func percentOf(_ value: Decimal, home: Decimal) -> String {
        guard home > 0 else { return "0%" }
        let pct = Double(truncating: (value / home) as NSNumber) * 100
        return String(format: "%.0f%%", pct)
    }

    /// "$29K saved" when HELOC beats refi; "$72K extra" when refi wins.
    private static func netCostLabel(delta: Decimal) -> String {
        let amount = MoneyFormat.shared.dollarsShort(abs(delta))
        return delta <= 0 ? "\(amount) saved" : "\(amount) extra"
    }

    /// Closed-form monthly payment on a fixed-rate fully amortizing loan.
    private static func amortizedPayment(
        principal: Decimal,
        annualRatePct: Double,
        termMonths: Int
    ) -> Decimal {
        guard termMonths > 0 else { return principal }
        let r = annualRatePct / 100 / 12
        if r == 0 { return principal / Decimal(termMonths) }
        let n = Double(termMonths)
        let factor = (r * pow(1 + r, n)) / (pow(1 + r, n) - 1)
        return principal * Decimal(factor)
    }

    /// The bps shock at which the HELOC's blended rate exceeds the
    /// cash-out refi rate — i.e. the point where HELOC stops winning.
    /// Returns the first matrix row's shock magnitude that crosses.
    private static func estimateCrossoverBps(
        stress: [StressRow],
        cashoutRate: Double
    ) -> Int {
        // Stress matrix is in order: today, flat, +100, +200, +300.
        // Only +200 carries a blendedRate; if it's already above cashout,
        // crossover is between +100 and +200 — approximate at 200.
        if let plus2Blended = stress.dropFirst(3).first?.blendedRate {
            if plus2Blended.asDouble >= cashoutRate {
                return 200
            }
        }
        return 300
    }

    private static func generateDocNum(prefix: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let stamp = df.string(from: Date())
        let seq = String(format: "%04d", Int.random(in: 0..<10_000))
        return "NIQ-\(prefix)-\(stamp)-\(seq)"
    }
}
