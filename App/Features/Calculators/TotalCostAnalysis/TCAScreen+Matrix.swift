// TCAScreen+Matrix.swift
// Session 5Q.4 — the "Total cost by horizon" matrix, extracted from
// TCAScreen.swift to stay under SwiftLint's type_body_length cap
// after the Current column lands. The matrix renders one row per
// horizon × one column per scenario, plus a leading "Current" column
// in refi mode when `viewModel.showsCurrentColumn` is true (the
// borrower's status-quo mortgage cost over that horizon).
//
// Winner determination stays within the proposed scenarios — Current
// is a reference baseline, never flagged as a "winner."

import SwiftUI
import QuotientFinance

extension TCAScreen {

    var matrix: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("Total cost · by horizon")
                .textStyle(Typography.section)
                .foregroundStyle(Palette.ink)
            Text(matrixCaption)
                .textStyle(Typography.body.withSize(12))
                .foregroundStyle(Palette.inkSecondary)
                .padding(.bottom, Spacing.s12)

            matrixHeader
            ForEach(Array(viewModel.inputs.horizonsYears.enumerated()), id: \.offset) { hIdx, years in
                matrixRow(hIdx: hIdx, years: years)
                Rectangle().fill(Palette.borderSubtle).frame(height: 1)
            }
        }
    }

    /// Caption calls out the Current column when rendered so LOs can
    /// narrate the "status quo vs proposed" framing. Matches the
    /// anchor-card language from 5P.10.
    private var matrixCaption: String {
        if viewModel.showsCurrentColumn {
            return "Principal + interest + points. 'Current' = staying put. Winner highlighted among proposed scenarios."
        }
        return "Principal + interest + points. Winner highlighted per row."
    }

    private var matrixHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 52)
            if viewModel.showsCurrentColumn {
                Text("CURRENT")
                    .textStyle(Typography.micro.withSize(9))
                    .foregroundStyle(Palette.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityIdentifier("tca.matrix.header.current")
            }
            ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.element.id) { idx, s in
                Text(s.label.uppercased())
                    .textStyle(Typography.micro.withSize(9))
                    .foregroundStyle(matrixScenarioColor(idx))
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

    private func matrixRow(hIdx: Int, years: Int) -> some View {
        guard let result = viewModel.result,
              hIdx < (result.scenarioTotalCosts.first?.count ?? 0) else {
            return AnyView(EmptyView())
        }
        // Winner determination honors the "Include consumer debts" toggle:
        // when on (and in refi mode), each scenario's horizon cost adds
        // its remaining-debt monthly × horizon months. When off — or in
        // purchase mode — costs are the engine's PITI-only totals.
        //
        // The Current column (5Q.4) does NOT participate in winner calc
        // — it's a status-quo baseline, not a candidate. Scenarios still
        // compete against each other; Current renders as a neutral
        // reference on the left.
        let horizonMonths = Decimal(years * 12)
        let costs: [Decimal] = result.scenarioTotalCosts.indices.map { i in
            let piti = result.scenarioTotalCosts[i][hIdx]
            guard viewModel.inputs.mode == .refinance,
                  viewModel.inputs.includeDebts,
                  i < viewModel.inputs.scenarios.count,
                  let d = viewModel.inputs.scenarios[i].otherDebts
                        ?? viewModel.inputs.currentOtherDebts,
                  !d.isZero else {
                return piti
            }
            return piti + d.monthlyPayment * horizonMonths
        }
        let winner = costs.indices.reduce(0) { costs[$1] < costs[$0] ? $1 : $0 }
        return AnyView(
            HStack(spacing: 0) {
                Text("\(years)-yr")
                    .textStyle(Typography.num.withSize(11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.inkSecondary)
                    .frame(width: 52, alignment: .leading)
                if viewModel.showsCurrentColumn {
                    Text(matrixDollarsShort(viewModel.inputs.currentHorizonCost(years: years)))
                        .textStyle(Typography.num.withSize(12.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(Palette.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                ForEach(costs.indices, id: \.self) { i in
                    let value = costs[i]
                    let isW = i == winner
                    HStack(spacing: 2) {
                        if isW {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Palette.gain)
                        }
                        Text(matrixDollarsShort(value))
                            .textStyle(Typography.num.withSize(12.5, weight: isW ? .semibold : .medium, design: .monospaced))
                            .foregroundStyle(isW ? Palette.gain : Palette.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.vertical, Spacing.s8)
        )
    }

    /// Mirrors the private `scenarioColors` array on TCAScreen — kept
    /// here so the extension's matrix rows pick up the same per-index
    /// color without depending on access to the private member.
    private func matrixScenarioColor(_ idx: Int) -> Color {
        let colors: [Color] = [
            Palette.accent, Palette.scenario2, Palette.scenario3, Palette.scenario4,
        ]
        return colors[min(idx, colors.count - 1)]
    }

    private func matrixDollarsShort(_ value: Decimal) -> String {
        let d = Double(truncating: value as NSNumber)
        if d >= 1_000_000 {
            return String(format: "$%.2fM", d / 1_000_000)
        }
        return String(format: "$%.0fk", d / 1_000)
    }
}
