// TCAComparisonPage.swift
// Landscape (792×612) PDF page for Total Cost Analysis. Two stacked
// blocks — scenario spec grid (rate, pts, term, monthly P&I, closing
// costs) + horizons × total cost matrix with per-row winner highlight.

import SwiftUI
import QuotientFinance

struct TCAComparisonPage: View {
    let borrowerName: String
    let generatedDate: String
    let loFullName: String
    let loNMLSLine: String
    let viewModel: TCAViewModel
    let disclaimer: String
    let ehoStatement: String
    let accentHex: String
    let scenarioColors: [Color]

    private let inkPrimary = Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x0F / 255)
    private let inkSecondary = Color(red: 0x4A / 255, green: 0x48 / 255, blue: 0x40 / 255)
    private let inkTertiary = Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255)
    private let border = Color(red: 0xE5 / 255, green: 0xE1 / 255, blue: 0xD5 / 255)
    private var accent: Color { Color(brandHex: accentHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            scenarioSpecGrid
                .padding(.top, 18)
            matrix
                .padding(.top, 14)
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 28)
        .frame(width: 792, height: 612)
        .background(Color.white)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total cost analysis".uppercased())
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

    private var scenarioSpecGrid: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 92)
            ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.element.id) { idx, s in
                let metrics = viewModel.result?.scenarioMetrics
                let pmt = metrics.flatMap {
                    idx < $0.count ? "$\(MoneyFormat.shared.decimalString($0[idx].payment))" : "—"
                } ?? "—"
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.label.uppercased() + " · " + s.name)
                        .font(.system(size: 10.5, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(scenarioColors[min(idx, scenarioColors.count - 1)])
                    Text(String(format: "%.3f%% · %d yr", s.rate, s.termYears))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(inkPrimary)
                    Text(String(format: "pts %.2f · close $%@",
                                s.points,
                                MoneyFormat.shared.decimalString(s.closingCosts)))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(inkSecondary)
                    Text("Mo " + pmt)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .overlay(alignment: .trailing) {
                    if idx < viewModel.inputs.scenarios.count - 1 {
                        Rectangle().fill(border).frame(width: 1)
                    }
                }
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var matrix: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("Horizon")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(inkTertiary)
                    .frame(width: 92, alignment: .leading)
                    .padding(.leading, 16)
                ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.element.id) { idx, s in
                    Text(s.label.uppercased())
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(scenarioColors[min(idx, scenarioColors.count - 1)])
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 16)
                }
            }
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) {
                Rectangle().fill(border).frame(height: 1)
            }

            ForEach(Array(viewModel.inputs.horizonsYears.enumerated()), id: \.offset) { hIdx, years in
                matrixRow(hIdx: hIdx, years: years)
                Rectangle().fill(border).frame(height: 1)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func matrixRow(hIdx: Int, years: Int) -> some View {
        guard let result = viewModel.result,
              hIdx < (result.scenarioTotalCosts.first?.count ?? 0) else {
            return AnyView(EmptyView())
        }
        let costs = result.scenarioTotalCosts.map { $0[hIdx] }
        let winner = costs.indices.reduce(0) { costs[$1] < costs[$0] ? $1 : $0 }
        return AnyView(
            HStack(spacing: 0) {
                Text("\(years)-yr")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(inkSecondary)
                    .frame(width: 92, alignment: .leading)
                    .padding(.leading, 16)
                ForEach(costs.indices, id: \.self) { i in
                    let value = costs[i]
                    let isW = i == winner
                    HStack(spacing: 3) {
                        if isW {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(accent)
                        }
                        Text(dollarsShort(value))
                            .font(.system(size: 12, weight: isW ? .semibold : .regular, design: .monospaced))
                            .foregroundStyle(isW ? accent : inkPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 16)
                }
            }
            .padding(.vertical, 9)
        )
    }

    private func dollarsShort(_ value: Decimal) -> String {
        let d = Double(truncating: value as NSNumber)
        if d >= 1_000_000 { return String(format: "$%.2fM", d / 1_000_000) }
        return String(format: "$%.0fk", d / 1_000)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle().fill(border).frame(height: 1).padding(.bottom, 6)
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
