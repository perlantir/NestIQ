// TCAScreen+CurrentMortgage.swift
// Session 5P.10 — surface the borrower's current mortgage as a
// status-quo anchor card on the TCA refinance Results screen. The
// proposed scenarios are compared against this baseline for
// break-even (5P.9) and monthly-savings downstream of it. Showing
// the same reference on-screen ("Current: $X balance, $Y P&I, Z mo
// remaining, equity W, LTV L%") lets the LO narrate the whole
// comparison without guessing at the baseline.

import SwiftUI
import QuotientFinance

extension TCAScreen {

    @ViewBuilder var currentMortgageCard: some View {
        if viewModel.inputs.mode == .refinance,
           let mortgage = viewModel.inputs.currentMortgage {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                Eyebrow("Status quo · current mortgage")
                card(for: mortgage)
            }
        }
    }

    private func card(for mortgage: CurrentMortgage) -> some View {
        let remainingMonths = CurrentMortgageCalculations.monthsRemaining(
            originalTermYears: mortgage.originalTermYears,
            loanStartDate: mortgage.loanStartDate
        )
        let equity = CurrentMortgageCalculations.equityToday(
            currentBalance: mortgage.currentBalance,
            propertyValue: mortgage.propertyValueToday
        )
        let ltv = CurrentMortgageCalculations.ltvToday(
            currentBalance: mortgage.currentBalance,
            propertyValue: mortgage.propertyValueToday
        )
        return VStack(alignment: .leading, spacing: Spacing.s12) {
            topRow(balance: mortgage.currentBalance,
                   piti: mortgage.currentMonthlyPaymentPI,
                   rate: mortgage.currentRatePercent)
            bottomRow(
                remainingMonths: remainingMonths,
                equity: equity,
                ltv: ltv
            )
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
    }

    private func topRow(
        balance: Decimal, piti: Decimal, rate: Decimal
    ) -> some View {
        HStack(spacing: 0) {
            valueCell(
                label: "Current balance",
                value: "$\(MoneyFormat.shared.decimalString(balance))"
            )
            valueCell(
                label: "Current P&I",
                value: "$\(MoneyFormat.shared.decimalString(piti))/mo",
                leadingDivider: true
            )
            valueCell(
                label: "Current rate",
                value: String(format: "%.3f%%", rate.asDouble),
                leadingDivider: true
            )
        }
    }

    private func bottomRow(
        remainingMonths: Int, equity: Decimal, ltv: Decimal
    ) -> some View {
        HStack(spacing: 0) {
            valueCell(
                label: "Months remaining",
                value: "\(remainingMonths)"
            )
            valueCell(
                label: "Equity today",
                value: "$\(MoneyFormat.shared.decimalString(equity))",
                leadingDivider: true
            )
            valueCell(
                label: "LTV today",
                value: String(format: "%.1f%%", ltv.asDouble * 100),
                leadingDivider: true
            )
        }
    }

    private func valueCell(
        label: String, value: String, leadingDivider: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .textStyle(Typography.micro.withSize(9.5))
                .foregroundStyle(Palette.inkTertiary)
            Text(value)
                .textStyle(Typography.num.withSize(13, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, leadingDivider ? 10 : 0)
        .padding(.trailing, 6)
        .overlay(alignment: .leading) {
            if leadingDivider {
                Rectangle().fill(Palette.borderSubtle).frame(width: 1)
            }
        }
    }
}
