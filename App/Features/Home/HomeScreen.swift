// HomeScreen.swift
// Per design/screens/Home.jsx. Greeting + rate ribbon + calculators
// list (01-05) + recent scenarios. Tab bar is provided by the host
// TabView in RootTabBar.
//
// Rate snapshot is stubbed via MockRateService until Session 5 wires the
// real Vercel-edge proxy.

import SwiftUI
import SwiftData

struct HomeScreen: View {
    let profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \Scenario.updatedAt, order: .reverse)
    private var allScenarios: [Scenario]

    private var recentScenarios: [Scenario] {
        allScenarios.filter { !$0.archived }
    }

    @State private var rateReport: RateReport?
    @State private var isRefreshing = false
    @State private var activeCalculator: CalculatorType?

    private let rateService: any RateService = MockRateService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    greeting
                        .padding(.horizontal, Spacing.s20)
                        .padding(.top, Spacing.s12)
                        .padding(.bottom, Spacing.s16)
                    rateRibbon
                        .padding(.bottom, Spacing.s20)
                    calculatorList
                        .padding(.horizontal, Spacing.s20)
                        .padding(.bottom, Spacing.s24)
                    recentSection
                        .padding(.horizontal, Spacing.s20)
                        .padding(.bottom, Spacing.s24)
                }
            }
            .refreshable { await refreshRates() }
            .background(Palette.surface)
            .scrollIndicators(.hidden)
            .navigationDestination(item: $activeCalculator) { type in
                CalculatorNewScenarioView(calculator: type)
            }
            .task {
                if rateReport == nil { await refreshRates() }
            }
        }
    }

    // MARK: Greeting

    private var greeting: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Eyebrow(greetingEyebrow)
                Text(greetingText)
                    .textStyle(Typography.display.withSize(28, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Circle()
                .fill(Palette.surfaceRaised)
                .overlay(
                    Circle().stroke(Palette.borderSubtle, lineWidth: 1)
                )
                .overlay(
                    Text(profile.initials.isEmpty ? "NM" : profile.initials)
                        .textStyle(Typography.micro.withSize(12, weight: .semibold))
                        .foregroundStyle(Palette.inkSecondary)
                )
                .frame(width: 34, height: 34)
        }
    }

    private var greetingText: String {
        let name = profile.firstName.isEmpty ? "there" : profile.firstName
        let hour = Calendar.current.component(.hour, from: Date())
        let greet: String
        switch hour {
        case 5..<12: greet = "Good morning"
        case 12..<17: greet = "Good afternoon"
        default: greet = "Good evening"
        }
        return "\(greet),\n\(name)."
    }

    private var greetingEyebrow: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        return f.string(from: Date())
    }

    // MARK: Rate ribbon

    private var rateRibbon: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            HStack {
                Eyebrow("Today · national average")
                Spacer()
                Text(asOfText)
                    .textStyle(Typography.num)
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.horizontal, Spacing.s20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(currentRates.enumerated()), id: \.offset) { idx, r in
                        rateCell(snapshot: r)
                            .frame(minWidth: 130, alignment: .leading)
                            .overlay(alignment: .trailing) {
                                if idx < currentRates.count - 1 {
                                    Rectangle()
                                        .fill(Palette.borderSubtle)
                                        .frame(width: 1)
                                }
                            }
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

    private var currentRates: [RateSnapshot] {
        rateReport?.rates ?? MockRateService.placeholderRates
    }

    private var asOfText: String {
        guard let d = rateReport?.asOf else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: d)) \(TimeZone.current.abbreviation() ?? "")"
    }

    private func rateCell(snapshot r: RateSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(r.name)
                .textStyle(Typography.body.withWeight(.medium))
                .foregroundStyle(Palette.inkTertiary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.3f", r.rate))
                    .textStyle(Typography.num.withSize(19, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.ink)
                Text("%")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            deltaChip(r: r)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    @ViewBuilder
    private func deltaChip(r: RateSnapshot) -> some View {
        let color: Color = r.move == .down ? Palette.gain
            : r.move == .up ? Palette.loss : Palette.inkTertiary
        let arrow: String = r.move == .down ? "▼"
            : r.move == .up ? "▲" : "—"
        Text("\(arrow) \(r.delta == 0 ? "0.00" : String(format: "%.2f", abs(r.delta)))")
            .textStyle(Typography.num.withSize(10.5))
            .foregroundStyle(color)
    }

    // MARK: Calculator list

    private var calculatorList: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Eyebrow("Calculators")
            VStack(spacing: 0) {
                ForEach(Array(CalculatorType.allCases.enumerated()), id: \.offset) { idx, type in
                    calculatorRow(type: type)
                    if idx < CalculatorType.allCases.count - 1 {
                        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
                    }
                }
            }
            .background(Palette.surfaceRaised)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.groupedList, style: .continuous)
                    .stroke(Palette.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.groupedList, style: .continuous))
        }
    }

    private func calculatorRow(type: CalculatorType) -> some View {
        Button {
            activeCalculator = type
        } label: {
            HStack(spacing: Spacing.s12) {
                Text(type.number)
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
                    .frame(width: 24, alignment: .leading)
                VStack(alignment: .leading, spacing: 1) {
                    Text(CalculatorCopy.longName(for: type))
                        .textStyle(Typography.bodyLg.withSize(16, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text(CalculatorCopy.hint(for: type))
                        .textStyle(Typography.body.withSize(12.5))
                        .foregroundStyle(Palette.inkSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.calculator.\(type.rawValue)")
    }

    // MARK: Recent section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            HStack {
                Eyebrow("Recent scenarios")
                Spacer()
                if !recentScenarios.isEmpty {
                    NavigationLink(value: "all") {
                        Text("See all")
                            .textStyle(Typography.body.withWeight(.medium))
                            .foregroundStyle(Palette.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            if recentScenarios.isEmpty {
                emptyRecent
            } else {
                VStack(spacing: Spacing.s8) {
                    ForEach(Array(recentScenarios.prefix(3)), id: \.id) { scenario in
                        recentRow(scenario: scenario)
                    }
                }
            }
        }
        .navigationDestination(for: String.self) { _ in
            SavedScenariosScreen()
        }
    }

    private var emptyRecent: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("No scenarios yet.")
                .textStyle(Typography.bodyLg)
                .foregroundStyle(Palette.inkSecondary)
            Text("Pick a calculator above to start your first analysis.")
                .textStyle(Typography.body)
                .foregroundStyle(Palette.inkTertiary)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard, style: .continuous)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard, style: .continuous))
    }

    private func recentRow(scenario: Scenario) -> some View {
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
                Text(relativeTime(for: scenario.updatedAt))
                    .textStyle(Typography.body.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Text(scenario.borrower?.fullName ?? scenario.name)
                .textStyle(Typography.bodyLg.withSize(14, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Text(scenario.keyStatLine)
                .textStyle(Typography.num.withSize(12, design: .monospaced))
                .foregroundStyle(Palette.inkSecondary)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard, style: .continuous)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard, style: .continuous))
    }

    private func relativeTime(for date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }

    // MARK: Rate refresh

    private func refreshRates() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            rateReport = try await rateService.fetchSnapshot()
        } catch {
            // Offline fallback — keep the last report in memory if any.
        }
    }
}

// MARK: - Copy

enum CalculatorCopy {
    static func longName(for t: CalculatorType) -> String {
        switch t {
        case .amortization: "Amortization"
        case .incomeQualification: "Income qualification"
        case .refinance: "Refinance comparison"
        case .totalCostAnalysis: "Total cost analysis"
        case .helocVsRefinance: "HELOC vs refinance"
        }
    }

    static func hint(for t: CalculatorType) -> String {
        switch t {
        case .amortization: "Schedule, PITI, extra principal, recast."
        case .incomeQualification: "Max loan from income and debts."
        case .refinance: "Break-even, NPV, side-by-side."
        case .totalCostAnalysis: "Two to four scenarios over 5/7/10/15/30 yr."
        case .helocVsRefinance: "Blended rate vs cash-out, with stress paths."
        }
    }
}

// MARK: - Placeholder while MockRateService resolves

extension MockRateService {
    static let placeholderRates: [RateSnapshot] = [
        .init(name: "30-yr fixed", rate: 6.850, delta: 0, move: .flat),
        .init(name: "15-yr fixed", rate: 6.120, delta: 0, move: .flat),
        .init(name: "5/6 ARM", rate: 6.450, delta: 0, move: .flat),
        .init(name: "FHA 30", rate: 6.520, delta: 0, move: .flat),
        .init(name: "VA 30", rate: 6.280, delta: 0, move: .flat),
        .init(name: "Jumbo 30", rate: 7.050, delta: 0, move: .flat),
    ]
}

// CalculatorType needs to be Hashable+Identifiable for NavigationStack
// (value-based navigation uses hashable already; NavigationDestination
// `item:` requires Identifiable here since we use an optional @State).
extension CalculatorType: Identifiable {
    public var id: String { rawValue }
}
