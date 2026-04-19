// SelfEmploymentPDFPages.swift
// Cash-flow analysis + summary pages for the Self-Employment calculator.
// Portrait letter (612×792). Cover + disclaimers are composed by the
// shared PDFBuilder; this file provides the middle content pages.

import SwiftUI
import QuotientFinance

private let sePaperInk = Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x0F / 255)
private let sePaperInkSecondary = Color(red: 0x4A / 255, green: 0x48 / 255, blue: 0x40 / 255)
private let sePaperInkTertiary = Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255)
private let sePaperBorder = Color(red: 0xE5 / 255, green: 0xE1 / 255, blue: 0xD5 / 255)

/// Portrait page listing line items for each year side-by-side.
struct SelfEmploymentCashFlowPage: View {
    let borrowerName: String
    let loFullName: String
    let loNMLSLine: String
    let businessType: BusinessType
    let year1: SelfEmploymentYearResult
    let year2: SelfEmploymentYearResult
    let accentHex: String
    let generatedDate: String

    private var accent: Color { Color(brandHex: accentHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            twoColumnTable
                .padding(.top, 18)
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 28)
        .frame(width: 612, height: 792)
        .background(Color.white)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Self-employment cash flow".uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(accent)
            HStack(alignment: .firstTextBaseline) {
                Text("For ")
                    .font(.custom("SourceSerif4", size: 22))
                    .foregroundStyle(sePaperInk)
                    +
                    Text(borrowerName)
                    .font(.custom("SourceSerif4-It", size: 22))
                    .foregroundStyle(sePaperInk)
                Spacer()
                Text(generatedDate)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(sePaperInkTertiary)
            }
            Text("\(businessType.display) · 2-year line-item breakdown")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(sePaperInkSecondary)
            Rectangle().fill(sePaperInk).frame(height: 1)
        }
    }

    private var twoColumnTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 220, alignment: .leading)
                yearCol(title: "Year \(year1.year)")
                yearCol(title: "Year \(year2.year)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) {
                Rectangle().fill(sePaperBorder).frame(height: 1)
            }

            ForEach(Array(rows().enumerated()), id: \.offset) { idx, row in
                tableRow(row: row, zebra: idx.isMultiple(of: 2))
            }

            Rectangle().fill(sePaperBorder).frame(height: 1)
            HStack(spacing: 0) {
                Text("Annual cash flow")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(sePaperInk)
                    .frame(width: 220, alignment: .leading)
                moneyCell(year1.cashFlow, bold: true)
                moneyCell(year2.cashFlow, bold: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 0xFB / 255, green: 0xF9 / 255, blue: 0xF3 / 255))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(sePaperBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func yearCol(title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10.5, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(sePaperInkTertiary)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private struct TableRow {
        let label: String
        let y1: Decimal
        let y2: Decimal
        let isDeduction: Bool
    }

    /// Merge year1 + year2 into a stable union of labels so the two
    /// columns line up row-by-row.
    private func rows() -> [TableRow] {
        var result: [TableRow] = []
        let addLabels = Set(year1.addbacks.map(\.label))
            .union(year2.addbacks.map(\.label))
        let dedLabels = Set(year1.deductions.map(\.label))
            .union(year2.deductions.map(\.label))
        for lbl in addLabels.sorted() {
            let a = year1.addbacks.first(where: { $0.label == lbl })?.amount ?? 0
            let b = year2.addbacks.first(where: { $0.label == lbl })?.amount ?? 0
            result.append(TableRow(label: lbl, y1: a, y2: b, isDeduction: false))
        }
        for lbl in dedLabels.sorted() {
            let a = year1.deductions.first(where: { $0.label == lbl })?.amount ?? 0
            let b = year2.deductions.first(where: { $0.label == lbl })?.amount ?? 0
            result.append(TableRow(label: lbl, y1: a, y2: b, isDeduction: true))
        }
        return result
    }

    private func tableRow(row: TableRow, zebra: Bool) -> some View {
        HStack(spacing: 0) {
            Text(row.label)
                .font(.system(size: 10.5))
                .foregroundStyle(sePaperInkSecondary)
                .frame(width: 220, alignment: .leading)
            moneyCell(row.y1, isDeduction: row.isDeduction)
            moneyCell(row.y2, isDeduction: row.isDeduction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(zebra ? Color(red: 0xFA / 255, green: 0xF8 / 255, blue: 0xF2 / 255) : Color.white)
    }

    private func moneyCell(
        _ amount: Decimal,
        bold: Bool = false,
        isDeduction: Bool = false
    ) -> some View {
        let prefix = isDeduction ? "−$" : "$"
        let text = amount == 0
            ? "—"
            : prefix + MoneyFormat.shared.decimalString(amount)
        return Text(text)
            .font(.system(size: 11, weight: bold ? .semibold : .regular, design: .monospaced))
            .foregroundStyle(sePaperInk)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle().fill(sePaperBorder).frame(height: 1)
            HStack {
                Text(loFullName)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(sePaperInkSecondary)
                Spacer()
                Text(loNMLSLine)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(sePaperInkTertiary)
            }
        }
    }
}
