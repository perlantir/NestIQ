// IncomeQualListViews.swift
// Income + debts list subviews extracted so IncomeQualScreen stays
// under SwiftLint's 400-line type-body cap after the Session 4.5 dock
// wiring grew the screen.

import SwiftUI

struct IncomeListView: View {
    let incomes: [IncomeSource]
    let total: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Qualifying income · monthly")
                .padding(.horizontal, Spacing.s20)
                .padding(.bottom, Spacing.s8)
            VStack(spacing: 0) {
                ForEach(incomes) { item in
                    IncomeRow(item: item)
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                }
                IncomeTotalRow(label: "Total qualifying", value: total)
            }
            .background(Palette.surfaceRaised)
            .overlay(
                VStack(spacing: 0) {
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                    Spacer()
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                }
            )
        }
    }
}

struct DebtsListView: View {
    let debts: [MonthlyDebt]
    let total: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Monthly debts")
                .padding(.horizontal, Spacing.s20)
                .padding(.bottom, Spacing.s8)
            VStack(spacing: 0) {
                ForEach(debts) { debt in
                    DebtRow(debt: debt)
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                }
                IncomeTotalRow(label: "Total", value: total)
            }
            .background(Palette.surfaceRaised)
            .overlay(
                VStack(spacing: 0) {
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                    Spacer()
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                }
            )
        }
    }
}

// MARK: - Rows

struct IncomeRow: View {
    let item: IncomeSource

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(item.label) · \(item.kind.display)")
                    .textStyle(Typography.bodyLg.withSize(13.5, weight: .medium))
                    .foregroundStyle(Palette.ink)
                if item.weightPercent < 1 {
                    let weightPct = item.weightPercent * 100
                    let amt = MoneyFormat.shared.decimalString(item.monthlyAmount)
                    Text(String(format: "%.0f%% of $%@", weightPct, amt))
                        .textStyle(Typography.num.withSize(10.5))
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            Spacer()
            Text("$\(MoneyFormat.shared.decimalString(item.qualifyingMonthly))")
                .textStyle(Typography.num.withSize(14, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }
}

struct DebtRow: View {
    let debt: MonthlyDebt

    var body: some View {
        HStack {
            Text(debt.label)
                .textStyle(Typography.bodyLg.withSize(13.5, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text("$\(MoneyFormat.shared.decimalString(debt.monthlyAmount))")
                .textStyle(Typography.num.withSize(14, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }
}

struct IncomeTotalRow: View {
    let label: String
    let value: Decimal

    var body: some View {
        HStack {
            Text(label)
                .textStyle(Typography.bodyLg.withSize(13.5, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text("$\(MoneyFormat.shared.decimalString(value))")
                .textStyle(Typography.num.withSize(14, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }
}
