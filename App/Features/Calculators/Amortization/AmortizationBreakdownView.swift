// AmortizationBreakdownView.swift
// PITI breakdown stacked bar + 2-column legend, and the schedule table
// from the results screen. Extracted as separate views to keep
// AmortizationResultsScreen under SwiftLint's type-body-length limit.

import SwiftUI
import QuotientFinance

struct AmortizationBreakdownView: View {
    let viewModel: AmortizationViewModel

    private struct Slice: Identifiable {
        let id = UUID()
        let name: String
        let value: Decimal
        let color: Color
    }

    private var slices: [Slice] {
        let pi = viewModel.monthlyPI
        let principal = pi * Decimal(0.12)
        let interest = pi - principal
        return [
            Slice(name: "Interest", value: max(interest, 0), color: Palette.accent),
            Slice(name: "Principal", value: max(principal, 0), color: Palette.scenario2),
            Slice(name: "Taxes", value: viewModel.monthlyTax, color: Palette.scenario4),
            Slice(name: "Insurance", value: viewModel.monthlyInsurance, color: Palette.scenario3),
            Slice(name: "PMI", value: viewModel.monthlyPMI, color: Palette.warn),
            Slice(name: "HOA", value: viewModel.monthlyHOA, color: Palette.inkTertiary),
        ].filter { ($0.value as NSDecimalNumber).doubleValue > 0 }
    }

    private var total: Decimal { slices.reduce(0) { $0 + $1.value } }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Text("Where the payment goes")
                .textStyle(Typography.section)
                .foregroundStyle(Palette.ink)

            stackedBar
            legend
        }
    }

    private var stackedBar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(slices) { s in
                    let ratio: CGFloat = total > 0
                        ? CGFloat(truncating: (s.value / total) as NSNumber)
                        : 0
                    Rectangle().fill(s.color).frame(width: geo.size.width * ratio)
                }
            }
        }
        .frame(height: 10)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.chartBar)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.chartBar))
    }

    private var legend: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: Spacing.s8) {
            ForEach(slices) { s in
                HStack(spacing: Spacing.s8) {
                    Rectangle().fill(s.color).frame(width: 8, height: 8).cornerRadius(1)
                    Text(s.name)
                        .textStyle(Typography.body.withSize(12))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text("$\(MoneyFormat.shared.decimalString(s.value))")
                        .textStyle(Typography.num.withSize(12))
                        .foregroundStyle(Palette.ink)
                    Text(ratioPct(s.value))
                        .textStyle(Typography.num.withSize(10.5))
                        .foregroundStyle(Palette.inkTertiary)
                        .frame(width: 34, alignment: .trailing)
                }
            }
        }
    }

    private func ratioPct(_ v: Decimal) -> String {
        guard total > 0 else { return "" }
        let d = Double(truncating: (v / total) as NSNumber)
        return String(format: "%.0f%%", d * 100)
    }
}

// MARK: - Schedule table

struct AmortizationScheduleView: View {
    let viewModel: AmortizationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Text("Schedule")
                .textStyle(Typography.section)
                .foregroundStyle(Palette.ink)
            scheduleHeader
            ForEach(sampledRows(), id: \.number) { row in
                scheduleRow(row)
                Rectangle().fill(Palette.borderSubtle).frame(height: 1)
            }
            Text("Showing \(min(8, viewModel.schedule?.numberOfPayments ?? 0)) of \(viewModel.schedule?.numberOfPayments ?? 0) payments.")
                .textStyle(Typography.body.withSize(11))
                .foregroundStyle(Palette.inkTertiary)
                .italic()
                .padding(.top, Spacing.s4)
        }
    }

    private var scheduleHeader: some View {
        HStack(spacing: 0) {
            Text("#")
                .textStyle(Typography.micro.withSize(10))
                .foregroundStyle(Palette.inkTertiary)
                .frame(width: 44, alignment: .leading)
            ForEach(["Pmt", "Prin", "Int", "Balance"], id: \.self) { h in
                Text(h.uppercased())
                    .textStyle(Typography.micro.withSize(10))
                    .foregroundStyle(Palette.inkTertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, Spacing.s8)
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.borderSubtle).frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.borderSubtle).frame(height: 1)
        }
    }

    private func scheduleRow(_ p: AmortizationPayment) -> some View {
        HStack(spacing: 0) {
            Text(String(format: "%03d", p.number))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.inkTertiary)
                .frame(width: 44, alignment: .leading)
            Text(MoneyFormat.shared.decimalString(p.payment))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(MoneyFormat.shared.decimalString(p.principal))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(MoneyFormat.shared.decimalString(p.interest))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(MoneyFormat.shared.decimalString(p.balance))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, Spacing.s8)
    }

    private func sampledRows() -> [AmortizationPayment] {
        guard let payments = viewModel.schedule?.payments, !payments.isEmpty else { return [] }
        let count = payments.count
        let indices: [Int] = [0, 11, 59, 119, 179, 239, 299, count - 1]
            .map { min(max(0, $0), count - 1) }
        var seen: Set<Int> = []
        var out: [AmortizationPayment] = []
        for i in indices where !seen.contains(i) {
            seen.insert(i)
            out.append(payments[i])
        }
        return out
    }
}
