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

enum AmortScheduleGranularity: String, Hashable, CaseIterable {
    case yearly, monthly
    var label: String {
        switch self {
        case .yearly:  return "Yearly"
        case .monthly: return "Monthly"
        }
    }

    /// Sensible default for a given term: short terms (≤ 15 yrs) default
    /// to monthly so the ~180 rows are browsable; longer terms default
    /// to yearly so the LO isn't buried in 360 rows.
    static func `default`(termYears: Int) -> AmortScheduleGranularity {
        termYears <= 15 ? .monthly : .yearly
    }
}

struct AmortizationScheduleView: View {
    let viewModel: AmortizationViewModel

    @Binding var granularity: AmortScheduleGranularity

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    init(viewModel: AmortizationViewModel,
         granularity: Binding<AmortScheduleGranularity>) {
        self.viewModel = viewModel
        self._granularity = granularity
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Schedule")
                    .textStyle(Typography.section)
                    .foregroundStyle(Palette.ink)
                Spacer()
            }
            SegmentedControl(
                options: AmortScheduleGranularity.allCases,
                selection: $granularity,
                label: { $0.label }
            )
            .frame(maxWidth: 220)

            Group {
                switch granularity {
                case .yearly:  yearlyTable
                case .monthly: monthlyTable
                }
            }
            .transaction(value: granularity) { t in
                t.animation = reduceMotion ? nil : Motion.numberTweenEaseInOut
            }

            footerLabel
        }
    }

    private var footerLabel: some View {
        let count = viewModel.schedule?.numberOfPayments ?? 0
        let years = yearlyRows.count
        let text: String = granularity == .monthly
            ? "Showing all \(count) payments."
            : "Showing \(years) loan years · \(count) payments."
        return Text(text)
            .textStyle(Typography.body.withSize(11))
            .foregroundStyle(Palette.inkTertiary)
            .italic()
            .padding(.top, Spacing.s4)
    }

    // MARK: Shared header

    private var scheduleHeader: some View {
        let leading = granularity == .yearly ? "YR" : "#"
        let dateCol = granularity == .yearly ? "Year" : "Date"
        return HStack(spacing: 0) {
            Text(leading)
                .textStyle(Typography.micro.withSize(10))
                .foregroundStyle(Palette.inkTertiary)
                .frame(width: 36, alignment: .leading)
            Text(dateCol.uppercased())
                .textStyle(Typography.micro.withSize(10))
                .foregroundStyle(Palette.inkTertiary)
                .frame(width: 58, alignment: .leading)
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

    // MARK: Monthly table (virtualized)

    private var monthlyTable: some View {
        VStack(spacing: 0) {
            scheduleHeader
            LazyVStack(spacing: 0) {
                ForEach(viewModel.schedule?.payments ?? [], id: \.number) { p in
                    monthlyRow(p)
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                }
            }
        }
    }

    private func monthlyRow(_ p: AmortizationPayment) -> some View {
        // Engine reports `payment` = scheduled P&I and `extraPrincipal`
        // separately. The schedule row should reconcile: "what was paid"
        // (scheduled + extra) and "what went to principal" (scheduled +
        // extra) both include the periodic extra, otherwise the balance
        // column drops faster than the payment column explains.
        let actualPayment = p.payment + p.extraPrincipal
        let actualPrincipal = p.principal + p.extraPrincipal
        return HStack(spacing: 0) {
            Text(String(format: "%03d", p.number))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.inkTertiary)
                .frame(width: 36, alignment: .leading)
            Text(monthLabel(p.date))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
                .frame(width: 58, alignment: .leading)
            Text(MoneyFormat.shared.decimalString(actualPayment))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(MoneyFormat.shared.decimalString(actualPrincipal))
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

    // MARK: Yearly table

    private var yearlyRows: [YearlyScheduleRow] {
        guard let schedule = viewModel.schedule else { return [] }
        return yearlyAggregate(schedule: schedule)
    }

    private var yearlyTable: some View {
        VStack(spacing: 0) {
            scheduleHeader
            ForEach(yearlyRows) { row in
                yearlyRow(row)
                Rectangle().fill(Palette.borderSubtle).frame(height: 1)
            }
        }
    }

    private func yearlyRow(_ row: YearlyScheduleRow) -> some View {
        HStack(spacing: 0) {
            Text("\(row.year)")
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.inkTertiary)
                .frame(width: 36, alignment: .leading)
            Text(yearLabel(row.firstPaymentDate))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
                .frame(width: 58, alignment: .leading)
            Text(MoneyFormat.shared.decimalString(row.totalPayment))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(MoneyFormat.shared.decimalString(row.totalPrincipal))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(MoneyFormat.shared.decimalString(row.totalInterest))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(MoneyFormat.shared.decimalString(row.endingBalance))
                .textStyle(Typography.num.withSize(12))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, Spacing.s8)
    }

    // MARK: Date formatting

    private func monthLabel(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM ''yy"
        return f.string(from: d)
    }

    private func yearLabel(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f.string(from: d)
    }
}
