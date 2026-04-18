// SavedScenariosScreen.swift
// Per design/screens/Saved.jsx. Search field + filter chips + list
// grouped by date bucket (Today / This week / Earlier per spec).
// Swipe actions: Archive / Share / Duplicate / Delete.

import SwiftUI
import SwiftData

struct SavedScenariosScreen: View {
    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \Scenario.updatedAt, order: .reverse)
    private var allScenarios: [Scenario]

    private var scenarios: [Scenario] {
        allScenarios.filter { !$0.archived }
    }

    @State private var search: String = ""
    @State private var activeFilter: CalculatorFilter = .all
    @State private var editingScenario: Scenario?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                    header
                        .padding(.horizontal, Spacing.s20)
                        .padding(.top, Spacing.s12)
                        .padding(.bottom, Spacing.s16)

                    searchRow
                        .padding(.horizontal, Spacing.s20)
                        .padding(.bottom, Spacing.s16)

                    filterRow
                        .padding(.horizontal, Spacing.s20)
                        .padding(.bottom, Spacing.s4)

                    groupedList
                }
                .padding(.bottom, Spacing.s96)
            }
            .background(Palette.surface)
            .scrollIndicators(.hidden)
            .navigationDestination(item: $editingScenario) { s in
                openScenarioDestination(s)
            }
        }
    }

    @ViewBuilder
    private func openScenarioDestination(_ s: Scenario) -> some View {
        switch s.calculatorType {
        case .amortization:
            AmortizationInputsScreen(
                borrower: s.borrower,
                initialInputs: decodeAmortization(from: s.inputsJSON),
                existingScenario: s
            )
        default:
            ComingSoonStub(calculator: s.calculatorType)
        }
    }

    private func decodeAmortization(from data: Data) -> AmortizationFormInputs? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(AmortizationFormInputs.self, from: data)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow("Saved")
                Text("Scenarios")
                    .textStyle(Typography.display.withSize(28, weight: .bold))
                    .foregroundStyle(Palette.ink)
            }
            Spacer()
            Text("\(filteredScenarios.count) total")
                .textStyle(Typography.num)
                .foregroundStyle(Palette.inkTertiary)
        }
    }

    // MARK: Search

    private var searchRow: some View {
        HStack(spacing: Spacing.s8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.inkTertiary)
            TextField("Search borrowers, tags…", text: $search)
                .textStyle(Typography.body)
                .foregroundStyle(Palette.ink)
                .submitLabel(.search)
        }
        .padding(.horizontal, Spacing.s12)
        .padding(.vertical, 9)
        .background(Palette.surfaceRaised)
        .overlay(
            Capsule().stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    // MARK: Filter chips

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s8) {
                ForEach(CalculatorFilter.allCases, id: \.self) { filter in
                    chip(for: filter)
                }
            }
        }
    }

    private func chip(for filter: CalculatorFilter) -> some View {
        let active = filter == activeFilter
        return Button {
            activeFilter = filter
        } label: {
            Text(filter.label)
                .textStyle(Typography.num.withSize(11))
                .foregroundStyle(active ? Palette.accentFG : Palette.inkSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(active ? Palette.accent : Color.clear)
                .overlay(
                    Capsule().stroke(active ? Palette.accent : Palette.borderSubtle,
                                     lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Groups

    @ViewBuilder private var groupedList: some View {
        let groups = groupedFiltered()
        if groups.isEmpty {
            emptyState
                .padding(.horizontal, Spacing.s20)
                .padding(.top, Spacing.s32)
        } else {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                dateGroup(label: group.0, items: group.1)
                    .padding(.top, Spacing.s16)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(scenarios.isEmpty ? "Nothing saved yet." : "No matches.")
                .textStyle(Typography.h2)
                .foregroundStyle(Palette.ink)
            Text(scenarios.isEmpty
                 ? "When you save a scenario it'll show up here."
                 : "Try a different filter or search.")
                .textStyle(Typography.body)
                .foregroundStyle(Palette.inkSecondary)
        }
    }

    private func dateGroup(label: String, items: [Scenario]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(label)
                .padding(.horizontal, Spacing.s20)
                .padding(.bottom, Spacing.s8)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, scenario in
                    scenarioRow(scenario: scenario)
                    if idx < items.count - 1 {
                        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                    }
                }
            }
            .background(Palette.surfaceRaised)
            .overlay(
                VStack(spacing: 0) {
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                    Spacer()
                    Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                }
            )
        }
    }

    private func scenarioRow(scenario: Scenario) -> some View {
        Button {
            editingScenario = scenario
        } label: {
            HStack(alignment: .top, spacing: Spacing.s4) {
                Text(scenario.calculatorType.number)
                    .textStyle(Typography.num.withSize(10.5))
                    .foregroundStyle(Palette.inkTertiary)
                    .frame(width: 26, alignment: .leading)

                VStack(alignment: .leading, spacing: Spacing.s4) {
                    HStack(spacing: Spacing.s8) {
                        Text(scenario.calculatorType.shortLabel)
                            .textStyle(Typography.num.withSize(10))
                            .foregroundStyle(Palette.inkSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.monoChip)
                                    .stroke(Palette.borderSubtle, lineWidth: 1)
                            )
                        Text(relativeTimestamp(scenario.updatedAt))
                            .textStyle(Typography.body.withSize(11))
                            .foregroundStyle(Palette.inkTertiary)
                    }
                    Text(scenario.borrower?.fullName ?? scenario.name)
                        .textStyle(Typography.bodyLg.withSize(14.5, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text(scenario.keyStatLine)
                        .textStyle(Typography.num.withSize(12, design: .monospaced))
                        .foregroundStyle(Palette.inkSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                delete(scenario: scenario)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                duplicate(scenario: scenario)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            .tint(Palette.accent)
            Button {
                archive(scenario: scenario)
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            .tint(Palette.inkSecondary)
        }
    }

    // MARK: Filtering + grouping

    private var filteredScenarios: [Scenario] {
        scenarios.filter { s in
            (activeFilter == .all || activeFilter.calculator == s.calculatorType)
                && (search.isEmpty ||
                    (s.borrower?.fullName.localizedCaseInsensitiveContains(search) == true)
                    || s.name.localizedCaseInsensitiveContains(search)
                    || s.keyStatLine.localizedCaseInsensitiveContains(search))
        }
    }

    private func groupedFiltered() -> [(String, [Scenario])] {
        let cal = Calendar.current
        let now = Date()
        let startOfDay = cal.startOfDay(for: now)
        let startOfWeek = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? startOfDay

        var today: [Scenario] = []
        var thisWeek: [Scenario] = []
        var earlier: [Scenario] = []

        for s in filteredScenarios {
            if s.updatedAt >= startOfDay {
                today.append(s)
            } else if s.updatedAt >= startOfWeek {
                thisWeek.append(s)
            } else {
                earlier.append(s)
            }
        }
        var result: [(String, [Scenario])] = []
        if !today.isEmpty { result.append(("Today", today)) }
        if !thisWeek.isEmpty { result.append(("This week", thisWeek)) }
        if !earlier.isEmpty { result.append(("Earlier", earlier)) }
        return result
    }

    private func relativeTimestamp(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }

    // MARK: Swipe actions

    private func delete(scenario: Scenario) {
        modelContext.delete(scenario)
        try? modelContext.save()
    }

    private func archive(scenario: Scenario) {
        scenario.archived = true
        scenario.updatedAt = Date()
        try? modelContext.save()
    }

    private func duplicate(scenario: Scenario) {
        let copy = Scenario(
            borrower: scenario.borrower,
            calculatorType: scenario.calculatorType,
            name: "\(scenario.name) copy",
            inputsJSON: scenario.inputsJSON,
            outputsJSON: scenario.outputsJSON,
            keyStatLine: scenario.keyStatLine,
            narrative: scenario.narrative,
            notes: scenario.notes,
            archived: false,
            complianceRuleVersion: scenario.complianceRuleVersion
        )
        modelContext.insert(copy)
        try? modelContext.save()
    }
}

enum CalculatorFilter: Hashable, CaseIterable {
    case all, amort, income, refi, tca, heloc

    var label: String {
        switch self {
        case .all: "All"
        case .amort: "Amort"
        case .income: "Income"
        case .refi: "Refi"
        case .tca: "TCA"
        case .heloc: "HELOC"
        }
    }

    var calculator: CalculatorType? {
        switch self {
        case .all: nil
        case .amort: .amortization
        case .income: .incomeQualification
        case .refi: .refinance
        case .tca: .totalCostAnalysis
        case .heloc: .helocVsRefinance
        }
    }
}
