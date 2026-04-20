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

    // MARK: - 5M.6 Unrecoverable costs

    /// "Unrecoverable costs" grid per D5M.6. For each scenario × horizon:
    /// Interest + MI + Closing Costs, formatted as "$X (Y% of total paid)".
    /// A secondary "Ongoing housing costs (paid regardless)" row covers
    /// taxes + insurance + HOA so LOs can speak to the distinction —
    /// unrecoverable is the portion that doesn't build equity; ongoing
    /// applies whether you own or rent.
    @ViewBuilder var unrecoverableCostsSection: some View {
        if !viewModel.scenarioSchedules.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text("Unrecoverable costs · by horizon")
                    .textStyle(Typography.section)
                    .foregroundStyle(Palette.ink)
                Text(
                    "Interest + MI + closing costs. Ongoing housing costs (tax/ins/HOA) "
                    + "shown separately — those apply whether owning or renting."
                )
                    .textStyle(Typography.body.withSize(12))
                    .foregroundStyle(Palette.inkSecondary)
                    .padding(.bottom, Spacing.s12)

                breakdownHeader
                ForEach(Array(viewModel.inputs.horizonsYears.enumerated()), id: \.offset) { _, years in
                    unrecoverableRow(years: years)
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                }
                ongoingHousingRow
                    .padding(.top, Spacing.s4)
            }
        }
    }

    private func unrecoverableRow(years: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(years)yr")
                .textStyle(Typography.num.withSize(12, design: .monospaced))
                .foregroundStyle(Palette.inkSecondary)
                .frame(width: 52, alignment: .leading)
            ForEach(Array(viewModel.inputs.scenarios.enumerated()), id: \.offset) { idx, scenario in
                Text(unrecoverableDisplay(scenarioIndex: idx, scenario: scenario, years: years))
                    .textStyle(Typography.num.withSize(11, design: .monospaced))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, Spacing.s8)
    }

    /// Taxes + insurance + HOA × horizon months, aggregated across the
    /// form-level inputs (these don't vary per scenario in TCA). One row
    /// spanning all horizons — compact display "5yr $X · 10yr $Y · ...".
    private var ongoingHousingRow: some View {
        let monthly = viewModel.inputs.monthlyTaxes
            + viewModel.inputs.monthlyInsurance
            + viewModel.inputs.monthlyHOA
        let parts = viewModel.inputs.horizonsYears.map { years -> String in
            let total = monthly * Decimal(years * 12)
            return "\(years)yr " + MoneyFormat.shared.dollarsShort(total)
        }
        return VStack(alignment: .leading, spacing: 2) {
            Text("Ongoing housing costs (paid regardless)")
                .textStyle(Typography.num.withSize(10, weight: .semibold))
                .foregroundStyle(Palette.inkTertiary)
            Text(parts.joined(separator: " · "))
                .textStyle(Typography.num.withSize(11, design: .monospaced))
                .foregroundStyle(Palette.inkSecondary)
        }
        .padding(.top, Spacing.s8)
        .padding(.horizontal, Spacing.s4)
    }

    /// "$87k (32%)" — sum of interest, MI, and closing through horizon;
    /// the % is share of total mortgage paid (unrecoverable + principal).
    /// Ongoing housing costs are deliberately excluded from the "total
    /// paid" denominator so the percentage reads as "share of what
    /// doesn't build equity" rather than "share of all housing cash."
    func unrecoverableDisplay(scenarioIndex: Int, scenario: TCAScenario, years: Int) -> String {
        guard scenarioIndex < viewModel.scenarioSchedules.count else { return "—" }
        let schedule = viewModel.scenarioSchedules[scenarioIndex]
        let unrecoverable = viewModel.inputs.unrecoverableCost(
            scenario: scenario,
            schedule: schedule,
            years: years
        )
        let principal = schedule.cumulativePrincipal(throughMonth: years * 12)
        let totalPaid = unrecoverable + principal
        let dollar = MoneyFormat.shared.dollarsShort(unrecoverable)
        guard totalPaid > 0 else { return dollar }
        let pct = (unrecoverable.asDouble / totalPaid.asDouble) * 100
        return String(format: "%@ (%.0f%%)", dollar, pct)
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
