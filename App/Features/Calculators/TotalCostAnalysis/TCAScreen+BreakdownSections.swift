// TCAScreen+BreakdownSections.swift
// Session 5M.5 onwards: interest-vs-principal / unrecoverable costs /
// break-even graph / reinvestment / equity sections extracted to an
// extension so TCAScreen stays under SwiftLint's type_body_length cap.

import SwiftUI
import QuotientFinance

extension TCAScreen {

    // MARK: - 5M.5 Interest vs principal

    /// "Interest vs principal" cross-scenario / cross-horizon grid.
    /// Each cell renders "XX% int / YY% prin" per D5M.5. Text only —
    /// no bar chart (D5M.5 — "text is sufficient, chart is scope creep").
    @ViewBuilder var interestPrincipalSection: some View {
        if !viewModel.scenarioSchedules.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text("Interest vs principal · by horizon")
                    .textStyle(Typography.section)
                    .foregroundStyle(Palette.ink)
                Text("Cumulative share of total paid at each horizon. Interest-heavy early; principal catches up later.")
                    .textStyle(Typography.body.withSize(12))
                    .foregroundStyle(Palette.inkSecondary)
                    .padding(.bottom, Spacing.s12)

                breakdownHeader
                ForEach(Array(viewModel.inputs.horizonsYears.enumerated()), id: \.offset) { _, years in
                    interestPrincipalRow(years: years)
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                }
            }
        }
    }

    /// Reuses the same header layout as the horizon matrix above —
    /// 52-pt gutter + column-per-scenario.
    private var breakdownHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 52)
            ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.element.id) { idx, s in
                Text(s.label.uppercased())
                    .textStyle(Typography.micro.withSize(9))
                    .foregroundStyle(breakdownColor(idx))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, Spacing.s8)
        .overlay(alignment: .top) { Rectangle().fill(Palette.borderSubtle).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(Palette.borderSubtle).frame(height: 1) }
    }

    private func interestPrincipalRow(years: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(years)yr")
                .textStyle(Typography.num.withSize(12, design: .monospaced))
                .foregroundStyle(Palette.inkSecondary)
                .frame(width: 52, alignment: .leading)
            ForEach(Array(viewModel.scenarioSchedules.enumerated()), id: \.offset) { _, schedule in
                Text(interestPrincipalSplit(schedule: schedule, years: years))
                    .textStyle(Typography.num.withSize(11, design: .monospaced))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, Spacing.s8)
    }

    /// "82% int / 18% prin" per D5M.5. Computes cumulative interest and
    /// principal through month `years × 12` and normalizes. Returns
    /// "—" when the schedule doesn't reach the horizon (e.g. 15yr
    /// schedule at the 30yr horizon — fully paid off, all principal).
    func interestPrincipalSplit(schedule: AmortizationSchedule, years: Int) -> String {
        let month = years * 12
        let interest = schedule.cumulativeInterest(throughMonth: month)
        let principal = schedule.cumulativePrincipal(throughMonth: month)
        let total = interest + principal
        guard total > 0 else { return "—" }
        let intPct = (interest.asDouble / total.asDouble) * 100
        let prinPct = 100 - intPct
        return String(format: "%.0f%% int / %.0f%% prin", intPct, prinPct)
    }

    /// Scenario colors — mirrors `TCAScreen.scenarioColors` which is
    /// private. Keep this synced.
    private func breakdownColor(_ idx: Int) -> Color {
        let colors: [Color] = [
            Palette.accent, Palette.scenario2, Palette.scenario3, Palette.scenario4,
        ]
        return colors[min(idx, colors.count - 1)]
    }

    // MARK: - Narrative (moved from TCAScreen in 5M.5)

    var narrative: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Narrative")
            Text(narrativeText)
                .textStyle(Typography.body.withSize(13.5))
                .foregroundStyle(Palette.ink)
                .lineSpacing(3)
                .padding(.horizontal, Spacing.s16)
                .padding(.vertical, Spacing.s12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.surfaceRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.listCard)
                        .stroke(Palette.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
        }
    }
}
