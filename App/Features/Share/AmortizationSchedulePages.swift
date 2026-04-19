// AmortizationSchedulePages.swift
// Full-schedule PDF pages for the Amortization calculator — landscape
// (792×612). Yearly mode ships one dense page with every loan year;
// monthly mode paginates the 360-row schedule across multiple pages
// with running headers, MI-dropoff marker, and page numbers.

import SwiftUI
import QuotientFinance

// MARK: - Shared styling

private let inkPrimary = Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x0F / 255)
private let inkSecondary = Color(red: 0x4A / 255, green: 0x48 / 255, blue: 0x40 / 255)
private let inkTertiary = Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255)
private let amortBorder = Color(red: 0xE5 / 255, green: 0xE1 / 255, blue: 0xD5 / 255)
private let miHighlight = Color(red: 0xE8 / 255, green: 0xF5 / 255, blue: 0xEC / 255)

/// Rows per page in monthly mode. 30 rows at ~15pt row height fits the
/// landscape body comfortably below the 40pt header and above the 22pt
/// footer.
private let monthlyRowsPerPage = 30

struct AmortSchedulePageHeader: View {
    let borrowerName: String
    let loanSummary: String
    let generatedDate: String
    let pageTitle: String
    let accentHex: String

    private var accent: Color { Color(brandHex: accentHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(pageTitle.uppercased())
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(1.1)
                    .foregroundStyle(accent)
                Spacer()
                Text(generatedDate)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(inkTertiary)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("For ")
                    .font(.custom("SourceSerif4", size: 20))
                    .foregroundStyle(inkPrimary)
                    +
                    Text(borrowerName)
                    .font(.custom("SourceSerif4-It", size: 20))
                    .foregroundStyle(inkPrimary)
                Spacer()
                Text(loanSummary)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(inkSecondary)
            }
            Rectangle().fill(inkPrimary).frame(height: 1)
        }
    }
}

struct AmortSchedulePageFooter: View {
    let pageIndex: Int
    let pageCount: Int
    let loFullName: String
    let loNMLSLine: String

    var body: some View {
        VStack(spacing: 6) {
            Rectangle().fill(amortBorder).frame(height: 1)
            HStack {
                Text("\(loFullName) · \(loNMLSLine)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(inkTertiary)
                Spacer()
                Text("Schedule · page \(pageIndex) of \(pageCount)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(inkTertiary)
            }
        }
    }
}

// MARK: - Yearly page

/// One page, every year. Columns: Year | Payment range |
/// Total principal | Total interest | Year-end balance.
struct AmortizationYearlyPage: View {
    let borrowerName: String
    let loanSummary: String
    let generatedDate: String
    let loFullName: String
    let loNMLSLine: String
    let rows: [YearlyScheduleRow]
    let startDate: Date
    let accentHex: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AmortSchedulePageHeader(
                borrowerName: borrowerName,
                loanSummary: loanSummary,
                generatedDate: generatedDate,
                pageTitle: "Amortization schedule · yearly",
                accentHex: accentHex
            )
            table
                .padding(.top, 16)
            Spacer(minLength: 0)
            AmortSchedulePageFooter(
                pageIndex: 1,
                pageCount: 1,
                loFullName: loFullName,
                loNMLSLine: loNMLSLine
            )
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 24)
        .frame(width: 792, height: 612)
        .background(Color.white)
    }

    private var table: some View {
        VStack(spacing: 0) {
            header
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                tableRow(row, zebra: idx.isMultiple(of: 2))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(amortBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var header: some View {
        HStack(spacing: 0) {
            cell("Year", width: 54, align: .leading, weight: .semibold)
            cell("Calendar", width: 110, align: .leading, weight: .semibold)
            cell("Total paid", align: .trailing, weight: .semibold)
            cell("Principal", align: .trailing, weight: .semibold)
            cell("Interest", align: .trailing, weight: .semibold)
            cell("Year-end balance", align: .trailing, weight: .semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(amortBorder).frame(height: 1)
        }
    }

    @ViewBuilder
    private func cell(
        _ text: String,
        width: CGFloat? = nil,
        align: HorizontalAlignment = .trailing,
        weight: Font.Weight = .regular
    ) -> some View {
        let frameAlignment: Alignment = align == .leading ? .leading : .trailing
        let t = Text(text)
            .font(.system(size: 10.5, weight: weight, design: .monospaced))
            .foregroundStyle(inkSecondary)
        if let width {
            t.frame(width: width, alignment: frameAlignment)
        } else {
            t.frame(maxWidth: .infinity, alignment: frameAlignment)
        }
    }

    private func tableRow(_ row: YearlyScheduleRow, zebra: Bool) -> some View {
        let first = Self.yearFormatter.string(from: row.firstPaymentDate)
        let last = Self.yearFormatter.string(from: row.lastPaymentDate)
        let range = first == last ? first : "\(first) – \(last)"
        return HStack(spacing: 0) {
            cell("\(row.year)", width: 54, align: .leading)
            cell(range, width: 110, align: .leading)
            cell(MoneyFormat.shared.currency(row.totalPayment))
            cell(MoneyFormat.shared.currency(row.totalPrincipal))
            cell(MoneyFormat.shared.currency(row.totalInterest))
            cell(MoneyFormat.shared.currency(row.endingBalance))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(zebra ? Color(red: 0xFA / 255, green: 0xF8 / 255, blue: 0xF2 / 255) : Color.white)
    }

    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f
    }()
}

// MARK: - Monthly page (paginated)

/// One page of the monthly amortization table. A PDF typically ships
/// multiple of these, one per 30-row slice.
struct AmortizationMonthlyPage: View {
    let borrowerName: String
    let loanSummary: String
    let generatedDate: String
    let loFullName: String
    let loNMLSLine: String
    let payments: [AmortizationPayment]
    /// 1-indexed page number within the monthly schedule pages only.
    let pageIndex: Int
    /// Total number of monthly schedule pages in the document.
    let pageCount: Int
    /// Payment number where MI drops off; rows < this period show the
    /// highlight tint. nil when MI isn't active.
    let miDropoffPeriod: Int?
    let accentHex: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AmortSchedulePageHeader(
                borrowerName: borrowerName,
                loanSummary: loanSummary,
                generatedDate: generatedDate,
                pageTitle: "Amortization schedule · monthly",
                accentHex: accentHex
            )
            table
                .padding(.top, 14)
            Spacer(minLength: 0)
            AmortSchedulePageFooter(
                pageIndex: pageIndex,
                pageCount: pageCount,
                loFullName: loFullName,
                loNMLSLine: loNMLSLine
            )
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 24)
        .frame(width: 792, height: 612)
        .background(Color.white)
    }

    private var table: some View {
        VStack(spacing: 0) {
            header
            ForEach(Array(payments.enumerated()), id: \.offset) { idx, p in
                row(p, zebra: idx.isMultiple(of: 2))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(amortBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var header: some View {
        HStack(spacing: 0) {
            headerCell("#", width: 40, align: .leading)
            headerCell("Date", width: 90, align: .leading)
            headerCell("Payment")
            headerCell("Principal")
            headerCell("Interest")
            headerCell("Balance")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            Rectangle().fill(amortBorder).frame(height: 1)
        }
    }

    @ViewBuilder
    private func headerCell(
        _ text: String,
        width: CGFloat? = nil,
        align: HorizontalAlignment = .trailing
    ) -> some View {
        let frameAlignment: Alignment = align == .leading ? .leading : .trailing
        let t = Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(inkSecondary)
        if let width {
            t.frame(width: width, alignment: frameAlignment)
        } else {
            t.frame(maxWidth: .infinity, alignment: frameAlignment)
        }
    }

    private func row(_ p: AmortizationPayment, zebra: Bool) -> some View {
        let isDropoff = miDropoffPeriod.map { p.number == $0 } ?? false
        let tint: Color = {
            if isDropoff { return miHighlight }
            return zebra ? Color(red: 0xFA / 255, green: 0xF8 / 255, blue: 0xF2 / 255) : Color.white
        }()
        return HStack(spacing: 0) {
            cell("\(p.number)", width: 40, align: .leading)
            cell(Self.monthFormatter.string(from: p.date), width: 90, align: .leading)
            cell(MoneyFormat.shared.currency(p.payment))
            cell(MoneyFormat.shared.currency(p.principal))
            cell(MoneyFormat.shared.currency(p.interest))
            cell(MoneyFormat.shared.currency(p.balance))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(tint)
        .overlay(alignment: .leading) {
            if isDropoff {
                Rectangle().fill(Color(brandHex: accentHex)).frame(width: 3)
            }
        }
    }

    @ViewBuilder
    private func cell(
        _ text: String,
        width: CGFloat? = nil,
        align: HorizontalAlignment = .trailing
    ) -> some View {
        let frameAlignment: Alignment = align == .leading ? .leading : .trailing
        let t = Text(text)
            .font(.system(size: 9.5, design: .monospaced))
            .foregroundStyle(inkPrimary)
        if let width {
            t.frame(width: width, alignment: frameAlignment)
        } else {
            t.frame(maxWidth: .infinity, alignment: frameAlignment)
        }
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()
}

// MARK: - Page slicing helper

enum AmortizationSchedulePages {
    /// Slice a flat payments array into `monthlyRowsPerPage` chunks.
    static func monthlyChunks(_ payments: [AmortizationPayment]) -> [[AmortizationPayment]] {
        guard !payments.isEmpty else { return [] }
        var chunks: [[AmortizationPayment]] = []
        var idx = 0
        while idx < payments.count {
            let end = min(idx + monthlyRowsPerPage, payments.count)
            chunks.append(Array(payments[idx..<end]))
            idx = end
        }
        return chunks
    }
}
