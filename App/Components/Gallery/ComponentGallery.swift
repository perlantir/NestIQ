// ComponentGallery.swift
// DEBUG-only scrollable surface covering every component in
// App/Components/. Organized in the same top-to-bottom groupings as
// `Foundations.jsx`: primitives → form controls → visualizations →
// composite rows → docks/drawers → flows. Each section is labeled with
// an Eyebrow so design QA can pair the two side-by-side.
//
// Surfaced from RootView in DEBUG during Session 2. Session 3 relocates
// the entry point behind Settings → About → Component gallery.

#if DEBUG
import SwiftUI

public struct ComponentGallery: View {
    @State private var segmentedTerm = 30
    @State private var faceID = true
    @State private var hapticsOn = true
    @State private var toggleSample = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s40) {
                header
                primitivesSection
                buttonsSection
                fieldsSection
                formControlsSection
                visualizationsSection
                tableSection
                compositeRowsSection
                docksAndDrawersSection
                flowsSection
            }
            .padding(.horizontal, Spacing.s24)
            .padding(.vertical, Spacing.s32)
        }
        .background(Palette.surface.ignoresSafeArea())
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Components · gallery · DEBUG")
            Text("Quotient · components")
                .textStyle(Typography.serifDisplay)
                .foregroundStyle(Palette.ink)
        }
    }

    // MARK: 1. Primitives

    private var primitivesSection: some View {
        gallerySection(title: "1 · Primitives") {
            Eyebrow("Eyebrow · Today · national average")
            MonoNumber("$4,207.00", size: .hero)
            MonoNumber("547,553.02")
            HairlineDivider()
            DataRow(label: "Principal", value: "$447")
            DataRow(label: "Interest", value: "$3,083", showDivider: false)
            HStack(spacing: Spacing.s20) {
                KPITile(label: "Break-even", value: "24 mo", subLabel: "Mar 2028")
                KPITile(label: "Lifetime Δ", value: "+$18,400", valueColor: Palette.gain)
            }
            HStack(spacing: Spacing.s12) {
                BorrowerPill(fullName: "John & Maya Smith")
                DatePill("Today")
                FilterChip(label: "All", isActive: true)
                FilterChip(label: "Amort", isActive: false)
            }
        }
    }

    // MARK: 2. Buttons

    private var buttonsSection: some View {
        gallerySection(title: "2 · Buttons") {
            PrimaryButton("Compute amortization")
            SecondaryButton("Save scenario")
            GhostButton("Cancel")
            DestructiveButton("Delete scenario")
        }
    }

    // MARK: 3. Fields

    private var fieldsSection: some View {
        gallerySection(title: "3 · Fields") {
            CurrencyField(label: "Loan amount", displayValue: "400,000")
            PercentageField(label: "Interest rate", displayValue: "6.750", state: .focused)
            NumberField(label: "Term", displayValue: "30", suffix: "yr")
            InputTextField(label: "Property state", value: "California")
            CurrencyField(
                label: "Monthly HOA",
                displayValue: "−100",
                state: .error("HOA must be non-negative")
            )
        }
    }

    // MARK: 4. Form controls

    private var formControlsSection: some View {
        gallerySection(title: "4 · Form controls") {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                Eyebrow("Term · years")
                SegmentedControl(
                    options: [10, 15, 20, 25, 30, 40],
                    selection: $segmentedTerm,
                    label: { "\($0)" }
                )
            }
            HStack {
                Text("Toggle").textStyle(Typography.bodyLg)
                    .foregroundStyle(Palette.ink)
                Spacer()
                TogglePill(isOn: $toggleSample)
            }
            Card(style: .flat) {
                Text("Flat card")
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.ink)
            }
            Card(style: .raised) {
                Text("Raised card")
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.ink)
            }
        }
    }

    // MARK: 5. Visualizations

    private var visualizationsSection: some View {
        gallerySection(title: "5 · Visualizations") {
            VStack(alignment: .leading, spacing: Spacing.s12) {
                Eyebrow("PITI breakdown")
                StackedHorizontalBar(segments: [
                    .init(id: "P", value: 447, color: Palette.accent),
                    .init(id: "I", value: 3_083, color: Palette.accentHover),
                    .init(id: "T", value: 542, color: Palette.scenario2),
                    .init(id: "Ins", value: 135, color: Palette.scenario3)
                ])
            }
            HStack(spacing: Spacing.s20) {
                DTIDial(title: "Front-end", ratio: 0.21, limit: 0.28, size: 120)
                DTIDial(title: "Back-end", ratio: 0.42, limit: 0.43, size: 120)
            }
            VStack(alignment: .leading, spacing: Spacing.s12) {
                Eyebrow("Balance over time")
                BalanceOverTimeChart(points: balanceSample, markerMonth: 120)
            }
            VStack(alignment: .leading, spacing: Spacing.s12) {
                Eyebrow("Cumulative savings")
                CumulativeSavingsChart(
                    series: [
                        .init(
                            id: "A",
                            label: "Refi A",
                            monthlySavings: makeSeries(offset: -7_500, slope: 215),
                            isWinner: true,
                            color: Palette.accent
                        ),
                        .init(
                            id: "B",
                            label: "Refi B",
                            monthlySavings: makeSeries(offset: -10_000, slope: 185),
                            isWinner: false,
                            color: Palette.scenario2
                        )
                    ],
                    breakEvenMonth: 35
                )
            }
            VStack(alignment: .leading, spacing: Spacing.s12) {
                Eyebrow("TCA — grouped totals")
                ComparisonGroupedBars(groups: [
                    .init(
                        id: "5",
                        horizon: "5yr",
                        costs: [180_000, 175_000, 178_000],
                        winnerIndex: 1
                    ),
                    .init(
                        id: "10",
                        horizon: "10yr",
                        costs: [320_000, 315_000, 319_000],
                        winnerIndex: 1
                    ),
                    .init(
                        id: "30",
                        horizon: "30yr",
                        costs: [830_000, 825_000, 850_000],
                        winnerIndex: 1
                    )
                ])
            }
            VStack(alignment: .leading, spacing: Spacing.s12) {
                Eyebrow("HELOC stress paths")
                StressPathsChart(paths: stressSample)
            }
        }
    }

    // MARK: 6. Table

    private var tableSection: some View {
        gallerySection(title: "6 · Amortization schedule") {
            AmortizationScheduleTable(rows: (1...12).map {
                AmortizationScheduleRow(
                    period: $0,
                    dateLabel: "Feb \(2026 + ($0 / 12))",
                    payment: "$2,528.27",
                    principal: "$428.\($0 % 100)",
                    interest: "$2,099.\(99 - ($0 % 100))",
                    balance: "$399,\(1000 - $0 * 47)"
                )
            })
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: Radius.default))
        }
    }

    // MARK: 7. Composite rows

    private var compositeRowsSection: some View {
        gallerySection(title: "7 · Composite rows") {
            ScenarioCard(
                calculatorLabel: "Amortization",
                borrowerName: "John & Maya Smith",
                keyStat: "$4,207 / mo",
                timestamp: "2h ago"
            )
            ScenarioCard(
                calculatorLabel: "Refinance",
                calculatorColor: Palette.scenario2,
                borrowerName: "Abimbola Okonkwo",
                keyStat: "+$212 savings",
                timestamp: "yesterday"
            )
            CalculatorListRow(number: "01", title: "Amortization", metric: "12 saved")
            HairlineDivider()
            CalculatorListRow(number: "02", title: "Income Qualification", metric: "4 saved")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s8) {
                    RateRibbonCell(
                        product: "30yr fixed",
                        rate: "6.750%",
                        delta: .init(bps: -8)
                    )
                    RateRibbonCell(
                        product: "15yr fixed",
                        rate: "6.125%",
                        delta: .init(bps: -4)
                    )
                    RateRibbonCell(product: "FHA 30", rate: "6.375%")
                    RateRibbonCell(
                        product: "Jumbo",
                        rate: "7.050%",
                        delta: .init(bps: 6)
                    )
                }
            }
            SettingsSection(title: "Privacy") {
                SettingsRow(label: "Face ID unlock", trailing: .toggle($faceID))
                SettingsRow(label: "Haptics & sounds", trailing: .toggle($hapticsOn))
            }
        }
    }

    // MARK: 8. Docks & drawers

    private var docksAndDrawersSection: some View {
        gallerySection(title: "8 · Docks & drawers") {
            BottomActionDock()
            AssumptionsDrawer(assumptions: [
                .init(id: "lock", label: "Rate lock", value: "30 days"),
                .init(id: "points", label: "Discount points", value: "0.00 pts"),
                .init(id: "tax", label: "Property tax rate", value: "1.25%")
            ])
            .frame(height: 260)
            let narrationSample = """
                Your refinance saves $212 per month, recovers the closing \
                cost at month 24, and nets $18,400 over ten years.
                """
            NarrationDrawer(streamedText: narrationSample, isStreaming: false)
                .frame(height: 260)
        }
    }

    // MARK: 9. Flows

    private var flowsSection: some View {
        gallerySection(title: "9 · Flows") {
            OnboardingStep(
                eyebrow: "Refinance comparison",
                title: "Pit your current loan against up to three refi options.",
                paragraph: "Break-even, lifetime delta, NPV at 5% — all on one page."
            ) {
                KPITile(
                    label: "Savings",
                    value: "+$212 / mo",
                    subLabel: "vs current",
                    valueColor: Palette.gain
                )
            }
            .frame(height: 420)
        }
    }

    // MARK: - Layout helpers

    private func gallerySection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            Eyebrow(title)
            VStack(alignment: .leading, spacing: Spacing.s16) {
                content()
            }
        }
    }

    // MARK: - Sample data

    private var balanceSample: [BalancePoint] {
        (0...360).compactMap { m -> BalancePoint? in
            guard m % 6 == 0 else { return nil }
            let decay = pow(0.996, Double(m))
            return BalancePoint(month: m, balance: 400_000 * decay)
        }
    }

    private func makeSeries(offset: Double, slope: Double) -> [Double] {
        (0..<60).map { offset + Double($0) * slope }
    }

    private var stressSample: [StressPath] {
        let months = 120
        func series(rate: Double) -> [Double] {
            (0..<months).map { Double(50_000 * rate / 12.0) * Double($0) }
        }
        return [
            .init(
                id: "flat",
                label: "Flat 7%",
                monthlyCumulativeCost: series(rate: 0.07),
                color: Palette.accent
            ),
            .init(
                id: "+100bps",
                label: "+100bps",
                monthlyCumulativeCost: series(rate: 0.08),
                color: Palette.warn
            ),
            .init(
                id: "+200bps",
                label: "+200bps",
                monthlyCumulativeCost: series(rate: 0.09),
                color: Palette.loss
            )
        ]
    }
}

#Preview("Gallery · light") {
    ComponentGallery()
}

#Preview("Gallery · dark") {
    ComponentGallery().preferredColorScheme(.dark)
}

#Preview("Gallery · Accessibility5") {
    ComponentGallery()
        .environment(\.dynamicTypeSize, .accessibility5)
}

// Note: `accessibilityReduceMotion` is a read-only system-driven
// environment value — not previewable via `.environment(...)` in SwiftUI
// macros. Toggle it in Simulator via Settings → Accessibility → Motion →
// Reduce Motion for on-device QA; each component wires the value
// correctly through its own `@Environment(\.accessibilityReduceMotion)`.
#endif
