// AmortizationScheduleTable.swift
// Virtualized 5-column table (period, payment, principal, interest,
// balance) used on the Amortization Results screen. `List` with a custom
// row view gives virtualization for free on a 360-row schedule.
//
// Tokens consumed: Typography.num / micro, Palette.ink / inkSecondary /
// borderSubtle / surfaceRaised, Spacing.s8 / s12 / s16.

import SwiftUI

public struct AmortizationScheduleRow: Identifiable, Sendable {
    public let id: Int
    public let period: Int
    public let dateLabel: String
    public let payment: String
    public let principal: String
    public let interest: String
    public let balance: String

    public init(
        period: Int,
        dateLabel: String,
        payment: String,
        principal: String,
        interest: String,
        balance: String
    ) {
        self.id = period
        self.period = period
        self.dateLabel = dateLabel
        self.payment = payment
        self.principal = principal
        self.interest = interest
        self.balance = balance
    }
}

public struct AmortizationScheduleTable: View {
    let rows: [AmortizationScheduleRow]

    public init(rows: [AmortizationScheduleRow]) {
        self.rows = rows
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            HairlineDivider()
            List {
                ForEach(rows) { row in
                    tableRow(row)
                        .listRowInsets(EdgeInsets(
                            top: Spacing.s8,
                            leading: Spacing.s16,
                            bottom: Spacing.s8,
                            trailing: Spacing.s16
                        ))
                        .listRowBackground(Palette.surfaceRaised)
                        .listRowSeparatorTint(Palette.borderSubtle)
                }
            }
            .listStyle(.plain)
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.s16) {
            col("#", .leading, width: 40)
            col("Date", .leading, flexible: true)
            col("Payment", .trailing, width: 84)
            col("Principal", .trailing, width: 84)
            col("Interest", .trailing, width: 84)
            col("Balance", .trailing, width: 96)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s8)
        .background(Palette.surface)
    }

    private func col(
        _ text: String,
        _ alignment: HorizontalAlignment,
        width: CGFloat? = nil,
        flexible: Bool = false
    ) -> some View {
        Text(text.uppercased())
            .textStyle(Typography.micro)
            .foregroundStyle(Palette.inkTertiary)
            .frame(
                maxWidth: flexible ? .infinity : width,
                alignment: alignment == .leading ? .leading : .trailing
            )
    }

    private func tableRow(_ row: AmortizationScheduleRow) -> some View {
        HStack(spacing: Spacing.s16) {
            Text("\(row.period)")
                .textStyle(Typography.num)
                .foregroundStyle(Palette.inkTertiary)
                .frame(width: 40, alignment: .leading)
            Text(row.dateLabel)
                .textStyle(Typography.num)
                .foregroundStyle(Palette.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            MonoNumber(row.payment)
                .frame(width: 84, alignment: .trailing)
            MonoNumber(row.principal)
                .frame(width: 84, alignment: .trailing)
            MonoNumber(row.interest)
                .frame(width: 84, alignment: .trailing)
            MonoNumber(row.balance)
                .frame(width: 96, alignment: .trailing)
        }
    }
}

#Preview {
    AmortizationScheduleTable(rows: (1...24).map {
        AmortizationScheduleRow(
            period: $0,
            dateLabel: "Feb \(2026 + ($0 / 12))",
            payment: "$2,528.27",
            principal: "$428.\($0 % 100)",
            interest: "$2,100.\(99 - ($0 % 100))",
            balance: "$399,\(1000 - $0)"
        )
    })
    .frame(height: 400)
    .background(Palette.surfaceRaised)
}
