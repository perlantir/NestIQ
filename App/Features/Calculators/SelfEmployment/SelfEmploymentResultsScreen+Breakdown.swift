// SelfEmploymentResultsScreen+Breakdown.swift
// Signed line-item breakdown of the Fannie 1084 cash-flow math for
// each business type. The user expands a year card to see every
// addback / subtraction with explicit sign, then the ownership × share
// step (for K-1 types), then the final cash flow total.

import SwiftUI
import QuotientFinance

extension SelfEmploymentResultsScreen {

    // MARK: Dispatcher

    @ViewBuilder
    func signedBreakdown(
        result: SelfEmploymentYearResult,
        isY1: Bool
    ) -> some View {
        switch viewModel.inputs.businessType {
        case .scheduleC:
            scheduleCBreakdown(
                y: isY1 ? viewModel.inputs.scheduleCY1 : viewModel.inputs.scheduleCY2,
                cashFlow: result.cashFlow
            )
        case .form1120S:
            form1120SBreakdown(
                y: isY1 ? viewModel.inputs.form1120SY1 : viewModel.inputs.form1120SY2,
                cashFlow: result.cashFlow
            )
        case .form1065:
            form1065Breakdown(
                y: isY1 ? viewModel.inputs.form1065Y1 : viewModel.inputs.form1065Y2,
                cashFlow: result.cashFlow
            )
        }
    }

    // MARK: Schedule C

    private func scheduleCBreakdown(
        y: ScheduleCYear,
        cashFlow: Decimal
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            breakdownLine("Net profit (Line 31)", amount: y.netProfit, kind: .base)
            breakdownLine("Nonrecurring (Line 6)", amount: y.nonRecurringOtherIncomeOrLoss, kind: .signed)
            breakdownLine("Depletion (Line 12)", amount: y.depletion, kind: .addback)
            breakdownLine("Depreciation (Line 13)", amount: y.depreciation, kind: .addback)
            breakdownLine("Non-deductible meals (24b)", amount: y.nonDeductibleMealsAndEntertainment, kind: .subtraction)
            breakdownLine("Business use of home (L30)", amount: y.businessUseOfHome, kind: .addback)
            breakdownLine("Amortization / casualty", amount: y.amortizationOrCasualtyLoss, kind: .addback)
            breakdownLine("Mileage depreciation", amount: y.mileageDepreciation, kind: .addback)
            totalRule
            breakdownTotal("Cash flow", amount: cashFlow)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    // MARK: 1120S

    private func form1120SBreakdown(
        y: Form1120SYear,
        cashFlow: Decimal
    ) -> some View {
        let kickout = !y.hasConsistentDistributionHistory && y.ownershipPercent < 0.25
        let pt = y.ordinaryIncomeLoss
            + y.netRentalRealEstate
            + y.otherNetRentalIncome
            + y.depreciation
            + y.depletion
            + y.amortizationOrCasualtyLoss
            - y.mortgageOrNotesLessThan1Yr
            - y.nonDeductibleTravelMeals
        let share = pt * Decimal(y.ownershipPercent)
        return VStack(alignment: .leading, spacing: 0) {
            if kickout {
                kickoutNote
            } else {
                breakdownLine("Ordinary income (K-1 Box 1)", amount: y.ordinaryIncomeLoss, kind: .signed)
                breakdownLine("Net rental RE (Box 2)", amount: y.netRentalRealEstate, kind: .signed)
                breakdownLine("Other rental (Box 3)", amount: y.otherNetRentalIncome, kind: .signed)
                breakdownLine("Depreciation", amount: y.depreciation, kind: .addback)
                breakdownLine("Depletion", amount: y.depletion, kind: .addback)
                breakdownLine("Amortization / casualty", amount: y.amortizationOrCasualtyLoss, kind: .addback)
                breakdownLine("Mortgage / notes < 1 yr (Sched L)", amount: y.mortgageOrNotesLessThan1Yr, kind: .subtraction)
                breakdownLine("Non-deductible travel / meals", amount: y.nonDeductibleTravelMeals, kind: .subtraction)
                totalRule
                breakdownSubtotal("Business cash flow", amount: pt)
                ownershipRow(percent: y.ownershipPercent)
                totalRule
                breakdownSubtotal("Borrower share", amount: share)
            }
            breakdownLine("W-2 wages from business", amount: y.w2WagesFromBusiness, kind: .base)
            totalRule
            breakdownTotal("Cash flow", amount: cashFlow)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    // MARK: 1065

    private func form1065Breakdown(
        y: Form1065Year,
        cashFlow: Decimal
    ) -> some View {
        let kickout = !y.hasConsistentDistributionHistory && y.ownershipPercent < 0.25
        let pt = y.ordinaryIncomeLoss
            + y.netRentalRealEstate
            + y.otherNetRentalIncome
            + y.depreciation
            + y.depletion
            + y.amortizationOrCasualtyLoss
            - y.mortgageOrNotesLessThan1Yr
            - y.nonDeductibleTravelMeals
        let share = pt * Decimal(y.ownershipPercent)
        return VStack(alignment: .leading, spacing: 0) {
            if kickout {
                kickoutNote
            } else {
                breakdownLine("Ordinary income (K-1 Box 1)", amount: y.ordinaryIncomeLoss, kind: .signed)
                breakdownLine("Net rental RE (Box 2)", amount: y.netRentalRealEstate, kind: .signed)
                breakdownLine("Other rental (Box 3)", amount: y.otherNetRentalIncome, kind: .signed)
                breakdownLine("Depreciation", amount: y.depreciation, kind: .addback)
                breakdownLine("Depletion", amount: y.depletion, kind: .addback)
                breakdownLine("Amortization / casualty", amount: y.amortizationOrCasualtyLoss, kind: .addback)
                breakdownLine("Mortgage / notes < 1 yr", amount: y.mortgageOrNotesLessThan1Yr, kind: .subtraction)
                breakdownLine("Non-deductible travel / meals", amount: y.nonDeductibleTravelMeals, kind: .subtraction)
                totalRule
                breakdownSubtotal("Business cash flow", amount: pt)
                ownershipRow(percent: y.ownershipPercent)
                totalRule
                breakdownSubtotal("Borrower share", amount: share)
            }
            breakdownLine("Guaranteed payments (Box 4c)", amount: y.guaranteedPayments, kind: .base)
            totalRule
            breakdownTotal("Cash flow", amount: cashFlow)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    // MARK: Row kinds + helpers

    enum BreakdownKind {
        case base           // no sign prefix, shown as "$X"
        case signed         // sign follows the amount's sign (nonRecurring, K-1 income)
        case addback        // "+ $X" with green "addback" tag
        case subtraction    // "− $X" in red
    }

    @ViewBuilder
    private func breakdownLine(
        _ label: String,
        amount: Decimal,
        kind: BreakdownKind
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s8) {
            Text(signChar(kind: kind, amount: amount))
                .textStyle(Typography.num.withSize(12, weight: .medium, design: .monospaced))
                .foregroundStyle(signColor(kind: kind, amount: amount))
                .frame(width: 12, alignment: .center)
            Text(label)
                .textStyle(Typography.body.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
            Spacer()
            if kind == .addback {
                Text("addback")
                    .textStyle(Typography.num.withSize(10))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Text(formatAmount(amount: amount, kind: kind))
                .textStyle(Typography.num.withSize(12, weight: .medium, design: .monospaced))
                .foregroundStyle(signColor(kind: kind, amount: amount))
                .frame(minWidth: 84, alignment: .trailing)
        }
        .padding(.vertical, 3)
    }

    private func signChar(kind: BreakdownKind, amount: Decimal) -> String {
        switch kind {
        case .base: return " "
        case .signed: return amount < 0 ? "−" : "+"
        case .addback: return "+"
        case .subtraction: return "−"
        }
    }

    private func signColor(kind: BreakdownKind, amount: Decimal) -> Color {
        switch kind {
        case .base: return Palette.ink
        case .signed: return amount < 0 ? Palette.loss : Palette.ink
        case .addback: return Palette.gain
        case .subtraction: return Palette.loss
        }
    }

    private func formatAmount(amount: Decimal, kind: BreakdownKind) -> String {
        let abs = amount < 0 ? -amount : amount
        return "$" + MoneyFormat.shared.decimalString(abs)
    }

    private var totalRule: some View {
        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
            .padding(.vertical, Spacing.s8)
    }

    private func breakdownSubtotal(_ label: String, amount: Decimal) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .textStyle(Typography.body.withSize(12, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text((amount < 0 ? "−$" : "$") + MoneyFormat.shared.decimalString(amount < 0 ? -amount : amount))
                .textStyle(Typography.num.withSize(13, weight: .semibold, design: .monospaced))
                .foregroundStyle(amount < 0 ? Palette.loss : Palette.ink)
        }
        .padding(.vertical, 4)
    }

    private func breakdownTotal(_ label: String, amount: Decimal) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .textStyle(Typography.body.withSize(13, weight: .bold))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text((amount < 0 ? "−$" : "$") + MoneyFormat.shared.decimalString(amount < 0 ? -amount : amount))
                .textStyle(Typography.num.withSize(14, weight: .bold, design: .monospaced))
                .foregroundStyle(amount < 0 ? Palette.loss : Palette.accent)
        }
        .padding(.vertical, 4)
    }

    private func ownershipRow(percent: Double) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s8) {
            Text("×")
                .textStyle(Typography.num.withSize(12, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.inkSecondary)
                .frame(width: 12, alignment: .center)
            Text("Ownership")
                .textStyle(Typography.body.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
            Spacer()
            Text(String(format: "%.0f%%", percent * 100))
                .textStyle(Typography.num.withSize(12, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 84, alignment: .trailing)
        }
        .padding(.vertical, 3)
    }

    private var kickoutNote: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("Pass-through income zeroed")
                .textStyle(Typography.body.withSize(12, weight: .semibold))
                .foregroundStyle(Palette.warn)
            Text("Ownership < 25% and no consistent distribution history — Fannie B3-3.6-07 disallows the pass-through contribution.")
                .textStyle(Typography.body.withSize(11))
                .foregroundStyle(Palette.inkSecondary)
        }
        .padding(Spacing.s8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Palette.warn.opacity(0.3), lineWidth: 1)
        )
        .padding(.bottom, Spacing.s4)
    }
}
