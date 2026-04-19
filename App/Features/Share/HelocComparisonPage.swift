// HelocComparisonPage.swift
// Landscape (11×8.5 → 792×612) PDF page wedged between the HELOC
// cover and disclaimers. Two columns — Cash-Out Refinance vs.
// HELOC — with rows covering rate structure, payments, blended
// rate, closing costs, flexibility, etc.

import SwiftUI
import QuotientCompliance

struct HelocComparisonPage: View {
    struct Row {
        let label: String
        let refi: String
        let heloc: String
    }

    let borrowerName: String
    let generatedDate: String
    let loFullName: String
    let loNMLSLine: String
    let rows: [Row]
    let disclaimer: String
    let ehoStatement: String
    let accentHex: String
    /// Effective blended rate (1st lien + HELOC) at the 10-year horizon.
    /// Surfaced as the hero callout above the comparison table in 5F.5.
    let blendedRate10yr: Double
    /// Equivalent cash-out refinance rate, shown beside the hero for
    /// at-a-glance comparison.
    let refiRate: Double
    /// "keep 1st" when blended < refi, "refi wins" otherwise. Drives the
    /// verdict chip on the hero so the LO doesn't have to do the compare
    /// in their head.
    let verdict: String

    private let inkPrimary = Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x0F / 255)
    private let inkSecondary = Color(red: 0x4A / 255, green: 0x48 / 255, blue: 0x40 / 255)
    private let inkTertiary = Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255)
    private let border = Color(red: 0xE5 / 255, green: 0xE1 / 255, blue: 0xD5 / 255)

    private var accent: Color { Color(brandHex: accentHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            blendedRateHero
                .padding(.top, 16)
            comparisonTable
                .padding(.top, 14)
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 28)
        .frame(width: 792, height: 612)
        .background(Color.white)
    }

    // MARK: Blended-rate hero callout

    private var blendedRateHero: some View {
        let blendedStr = String(format: "%.2f%%", blendedRate10yr)
        let refiStr = String(format: "%.3f%%", refiRate)
        let helocWins = blendedRate10yr < refiRate
        let verdictColor: Color = helocWins ? accent : inkSecondary
        return HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("BLENDED RATE · 10-YEAR HORIZON")
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(inkTertiary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(blendedStr)
                        .font(.system(size: 40, weight: .medium, design: .monospaced))
                        .foregroundStyle(helocWins ? accent : inkPrimary)
                }
                Text("1st lien + HELOC weighted, simulated over 120 months")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(inkTertiary)
            }
            Rectangle().fill(border).frame(width: 1, height: 68)
            VStack(alignment: .leading, spacing: 4) {
                Text("VS CASH-OUT REFI")
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(inkTertiary)
                Text(refiStr)
                    .font(.system(size: 26, weight: .regular, design: .monospaced))
                    .foregroundStyle(inkPrimary)
                Text("fixed, over 30 yr")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(inkTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("VERDICT")
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(inkTertiary)
                Text(verdict.uppercased())
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(verdictColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(verdictColor, lineWidth: 1.2)
                    )
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color(red: 0xFB / 255, green: 0xF9 / 255, blue: 0xF3 / 255))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cash-Out Refinance vs. HELOC".uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(accent)
            HStack(alignment: .firstTextBaseline) {
                Text("For ")
                    .font(.custom("SourceSerif4", size: 26))
                    .foregroundStyle(inkPrimary)
                    +
                    Text(borrowerName)
                    .font(.custom("SourceSerif4-It", size: 26))
                    .foregroundStyle(inkPrimary)
                Spacer()
                Text(generatedDate)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(inkTertiary)
            }
            Rectangle().fill(inkPrimary).frame(height: 1.5)
        }
    }

    // MARK: Table

    private var comparisonTable: some View {
        VStack(spacing: 0) {
            columnHeader
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                rowView(row: row, zebra: idx.isMultiple(of: 2))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var columnHeader: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: 220, alignment: .leading)
            Text("CASH-OUT REFI")
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(inkTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("HELOC")
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(accent)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(border).frame(height: 1)
        }
    }

    private func rowView(row: Row, zebra: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(row.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(inkSecondary)
                .frame(width: 220, alignment: .leading)
            Text(row.refi)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(inkPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(row.heloc)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(inkPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(zebra ? Color(red: 0xF8 / 255, green: 0xF6 / 255, blue: 0xEF / 255) : Color.white)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle().fill(border).frame(height: 1)
                .padding(.bottom, 6)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(disclaimer)
                        .font(.system(size: 8.5))
                        .foregroundStyle(inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(ehoStatement)
                        .font(.system(size: 8.5))
                        .foregroundStyle(inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 16)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(loFullName)
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(inkSecondary)
                    Text(loNMLSLine)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(inkTertiary)
                }
            }
        }
    }
}

// MARK: - Row builder

extension HelocComparisonPage {
    /// Build the canonical row list from a HelocViewModel + computed
    /// simulation outputs. Keeping this here (rather than in the
    /// view model) so the view can be previewed / tested with
    /// arbitrary rows without dragging the whole HELOC domain along.
    static func rows(for viewModel: HelocViewModel) -> [Row] {
        let inputs = viewModel.inputs
        let refiMonthly = MoneyFormat.shared.currency(viewModel.refiMonthlyPayment())
        let helocMonth1 = MoneyFormat.shared.currency(
            viewModel.helocMonthlyPayment(shockBps: 0)
        )
        let postIntro = MoneyFormat.shared.currency(
            viewModel.helocMonthlyPayment(shockBps: 0)
        )
        let blended10y = String(format: "%.2f%%", viewModel.blendedRateAtTenYears)
        let cashOut = MoneyFormat.shared.currency(
            inputs.firstLienBalance + inputs.helocAmount
        )
        let helocAmt = MoneyFormat.shared.currency(inputs.helocAmount)
        let refiRate = String(format: "%.3f%%", inputs.refiRate)
        let introRate = String(format: "%.3f%%", inputs.helocIntroRate)
        let fullIdx = String(format: "%.3f%%", inputs.helocFullyIndexedRate)
        let primeMargin = max(0, inputs.helocFullyIndexedRate - 7.50)
        let marginDisplay = String(format: "Prime + %.2f%%", primeMargin)
        var rows: [Row] = [
            Row(label: "Loan amount / Credit limit",
                refi: cashOut,
                heloc: helocAmt),
            Row(label: "Rate structure",
                refi: "Fixed",
                heloc: "Variable (intro → fully indexed)"),
            Row(label: "Intro rate",
                refi: refiRate,
                heloc: introRate),
            Row(label: "Intro period",
                refi: "—",
                heloc: "\(inputs.helocIntroMonths) mo"),
            Row(label: "Margin over Prime",
                refi: "—",
                heloc: marginDisplay),
            Row(label: "Post-intro rate",
                refi: refiRate,
                heloc: fullIdx),
            Row(label: "Monthly payment · month 1",
                refi: refiMonthly,
                heloc: helocMonth1),
            Row(label: "Monthly payment · post-intro",
                refi: refiMonthly,
                heloc: postIntro),
            Row(label: "Blended rate · 10 years",
                refi: refiRate,
                heloc: blended10y),
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
        let refiMI = inputs.refiMonthlyMI > 0
            ? MoneyFormat.shared.currency(inputs.refiMonthlyMI)
            : "—"
        rows.append(Row(
            label: "Monthly MI",
            refi: refiMI,
            heloc: "N/A"
        ))
        rows.append(Row(
            label: "Closing costs",
            refi: "Typical $5k – $15k",
            heloc: "Typically lower"
        ))
        rows.append(Row(
            label: "Points",
            refi: "0.00",
            heloc: "—"
        ))
        rows.append(Row(
            label: "Flexibility",
            refi: "Fixed commitment",
            heloc: "Flexible draw / repay"
        ))
        return rows
    }
}
