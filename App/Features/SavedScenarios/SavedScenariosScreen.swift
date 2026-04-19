// SavedScenariosScreen.swift
// Per design/screens/Saved.jsx. Search field + filter chips + list
// grouped by date bucket (Today / This week / Earlier per spec).
// Swipe actions: Archive / Share / Duplicate / Delete.

import SwiftUI
import SwiftData

struct SavedScenariosScreen: View {
    // modelContext/allScenarios/scenarios are `internal` (not private) so
    // the Edit-mode extension in SavedScenariosScreen+EditMode.swift can
    // read them when committing deletes.
    @Environment(\.modelContext)
    var modelContext

    @Query(sort: \Scenario.updatedAt, order: .reverse)
    var allScenarios: [Scenario]

    var scenarios: [Scenario] {
        allScenarios.filter { !$0.archived }
    }

    @State private var search: String = ""
    @State private var activeFilter: CalculatorFilter = .all
    @State private var editingScenario: Scenario?

    // MARK: Edit-mode state — internal (not private) so the Edit-mode
    // helpers in SavedScenariosScreen+EditMode.swift can mutate them.
    @State var isEditMode: Bool = false
    @State var selectedIDs: Set<UUID> = []
    @State var pendingDelete: PendingDelete?

    var body: some View {
        NavigationStack {
            listBody
                .listStyle(.plain)
                .listRowSpacing(0)
                .scrollContentBackground(.hidden)
                .background(Palette.surface)
                .scrollIndicators(.hidden)
                .contentMargins(.bottom, isEditMode ? Spacing.s96 * 2 : Spacing.s96)
                .navigationDestination(item: $editingScenario) { s in
                    openScenarioDestination(s)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        editToolbarButton
                    }
                    if isEditMode {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Select all") { selectAll() }
                                .disabled(filteredScenarios.isEmpty)
                                .accessibilityIdentifier("saved.selectAll")
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    if isEditMode {
                        editModeDock
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isEditMode)
                .alert(
                    "Delete",
                    isPresented: Binding(
                        get: { pendingDelete != nil },
                        set: { if !$0 { pendingDelete = nil } }
                    ),
                    presenting: pendingDelete
                ) { pd in
                    Button("Delete", role: .destructive) {
                        commitDelete(pd.scenarios)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: { pd in
                    Text(pd.count == 1
                         ? "Delete this scenario? This cannot be undone."
                         : "Delete \(pd.count) scenarios? This cannot be undone.")
                }
        }
    }

    @ViewBuilder private var listBody: some View {
        List {
            // Hero section: header + search + filter chips. `.plainListRow`
            // strips the default system row chrome so our custom surface
            // styling remains intact.
            Section {
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    header
                    searchRow
                    filterRow
                }
                .padding(.horizontal, Spacing.s20)
                .padding(.top, Spacing.s12)
                .padding(.bottom, Spacing.s4)
                .listRowBackground(Palette.surface)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }

            let groups = groupedFiltered()
            if groups.isEmpty {
                Section {
                    emptyState
                        .padding(.horizontal, Spacing.s20)
                        .padding(.top, Spacing.s32)
                        .listRowBackground(Palette.surface)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                }
            } else {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    Section {
                        ForEach(group.1, id: \.id) { scenario in
                            scenarioRow(scenario: scenario)
                                .listRowBackground(Palette.surfaceRaised)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparatorTint(Palette.borderSubtle)
                        }
                    } header: {
                        Eyebrow(group.0)
                            .padding(.horizontal, Spacing.s20)
                            .padding(.top, Spacing.s16)
                            .padding(.bottom, Spacing.s8)
                            .textCase(nil)
                    }
                }
            }
        }
    }

    // Edit-mode toolbar / dock / selection helpers live in
    // SavedScenariosScreen+EditMode.swift to keep this struct under the
    // SwiftLint type_body_length cap.

    @ViewBuilder
    private func openScenarioDestination(_ s: Scenario) -> some View {
        switch s.calculatorType {
        case .amortization:
            AmortizationInputsScreen(
                borrower: s.borrower,
                initialInputs: decode(AmortizationFormInputs.self, from: s.inputsJSON),
                existingScenario: s
            )
        case .incomeQualification:
            IncomeQualScreen(
                initialInputs: decode(IncomeQualFormInputs.self, from: s.inputsJSON),
                existingScenario: s
            )
        case .refinance:
            RefinanceScreen(
                initialInputs: decode(RefinanceFormInputs.self, from: s.inputsJSON),
                existingScenario: s
            )
        case .totalCostAnalysis:
            TCAScreen(
                initialInputs: decode(TCAFormInputs.self, from: s.inputsJSON),
                existingScenario: s
            )
        case .helocVsRefinance:
            HelocScreen(
                initialInputs: decode(HelocFormInputs.self, from: s.inputsJSON),
                existingScenario: s
            )
        case .selfEmployment:
            SelfEmploymentInputsScreen(
                borrower: s.borrower,
                initialInputs: decode(SelfEmploymentFormInputs.self, from: s.inputsJSON),
                existingScenario: s
            )
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
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

    // MARK: Empty state

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

    private func scenarioRow(scenario: Scenario) -> some View {
        let isSelected = selectedIDs.contains(scenario.id)
        return Button {
            if isEditMode {
                toggle(scenario: scenario)
            } else {
                editingScenario = scenario
            }
        } label: {
            HStack(alignment: .top, spacing: Spacing.s4) {
                if isEditMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(isSelected ? Palette.accent : Palette.inkTertiary)
                        .frame(width: 28, height: 24, alignment: .leading)
                        .padding(.top, 2)
                        .accessibilityIdentifier("saved.checkbox.\(scenario.calculatorType.rawValue)")
                }

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
            .background(isSelected ? Palette.accentTint.opacity(0.4) : Color.clear)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("saved.row.\(scenario.calculatorType.rawValue)")
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !isEditMode {
                Button(role: .destructive) {
                    pendingDelete = PendingDelete(scenarios: [scenario])
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .accessibilityIdentifier("saved.swipeDelete.\(scenario.calculatorType.rawValue)")
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
    }

    // MARK: Filtering + grouping

    var filteredScenarios: [Scenario] {
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
    case all, amort, income, refi, tca, heloc, selfEmp

    var label: String {
        switch self {
        case .all: "All"
        case .amort: "Amort"
        case .income: "Income"
        case .refi: "Refi"
        case .tca: "TCA"
        case .heloc: "HELOC"
        case .selfEmp: "Self-emp"
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
        case .selfEmp: .selfEmployment
        }
    }
}
