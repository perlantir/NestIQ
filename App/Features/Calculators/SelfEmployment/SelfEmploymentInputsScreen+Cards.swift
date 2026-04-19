// SelfEmploymentInputsScreen+Cards.swift
// Per-business-type year-card subforms. Extracted from the parent
// struct to keep its body under SwiftLint's type_body_length cap.

import SwiftUI
import QuotientFinance

extension SelfEmploymentInputsScreen {

    // MARK: Schedule C

    func scheduleCYearCard(title: String, isY1: Bool) -> some View {
        cardFrame(title: title) {
            FieldRow(
                label: "Tax year",
                decimal: yearDecimalBinding(isY1: isY1),
                usesGroupingSeparator: false
            )
            divider
            FieldRow(
                label: "Net profit (Line 31)",
                prefix: "$",
                decimal: scheduleCDecimal(\.netProfit, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Nonrecurring income/loss (Line 6)",
                prefix: "$",
                hint: "signed — enter negative for a loss",
                decimal: scheduleCDecimal(\.nonRecurringOtherIncomeOrLoss, isY1: isY1)
            )
            divider
            if isY1 {
                AddbackInfoButton()
                divider
            }
            FieldRow(
                label: "Depletion (Line 12)",
                prefix: "$",
                hint: "added back",
                decimal: scheduleCDecimal(\.depletion, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Depreciation (Line 13)",
                prefix: "$",
                hint: "added back",
                decimal: scheduleCDecimal(\.depreciation, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Non-deductible meals (Line 24b)",
                prefix: "$",
                hint: "subtracted",
                decimal: scheduleCDecimal(\.nonDeductibleMealsAndEntertainment, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Business use of home (Line 30)",
                prefix: "$",
                hint: "added back",
                decimal: scheduleCDecimal(\.businessUseOfHome, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Amortization / casualty loss",
                prefix: "$",
                hint: "added back",
                decimal: scheduleCDecimal(\.amortizationOrCasualtyLoss, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Mileage depreciation",
                prefix: "$",
                hint: "added back — business miles × std rate",
                decimal: scheduleCDecimal(\.mileageDepreciation, isY1: isY1)
            )
        }
    }

    // MARK: 1120S

    func form1120SYearCard(title: String, isY1: Bool) -> some View {
        cardFrame(title: title) {
            FieldRow(
                label: "Tax year",
                decimal: yearDecimalBinding(isY1: isY1),
                usesGroupingSeparator: false
            )
            divider
            form1120SOwnershipRow(isY1: isY1)
            divider
            FieldRow(
                label: "W-2 wages from business",
                prefix: "$",
                decimal: f1120SDecimal(\.w2WagesFromBusiness, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Ordinary income/loss (K-1 Box 1)",
                prefix: "$",
                decimal: f1120SDecimal(\.ordinaryIncomeLoss, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Net rental real estate (Box 2)",
                prefix: "$",
                decimal: f1120SDecimal(\.netRentalRealEstate, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Other net rental income (Box 3)",
                prefix: "$",
                decimal: f1120SDecimal(\.otherNetRentalIncome, isY1: isY1)
            )
            divider
            if isY1 {
                AddbackInfoButton()
                divider
            }
            FieldRow(
                label: "Depreciation",
                prefix: "$",
                hint: "added back",
                decimal: f1120SDecimal(\.depreciation, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Depletion",
                prefix: "$",
                hint: "added back",
                decimal: f1120SDecimal(\.depletion, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Amortization / casualty",
                prefix: "$",
                hint: "added back",
                decimal: f1120SDecimal(\.amortizationOrCasualtyLoss, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Mortgage / notes < 1 yr (Sched L)",
                prefix: "$",
                hint: "subtracted",
                decimal: f1120SDecimal(\.mortgageOrNotesLessThan1Yr, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Non-deductible travel / meals",
                prefix: "$",
                hint: "subtracted",
                decimal: f1120SDecimal(\.nonDeductibleTravelMeals, isY1: isY1)
            )
            divider
            distributionToggle(isY1: isY1, is1120S: true)
        }
    }

    // MARK: 1065

    func form1065YearCard(title: String, isY1: Bool) -> some View {
        cardFrame(title: title) {
            FieldRow(
                label: "Tax year",
                decimal: yearDecimalBinding(isY1: isY1),
                usesGroupingSeparator: false
            )
            divider
            form1065OwnershipRow(isY1: isY1)
            divider
            FieldRow(
                label: "Guaranteed payments (Box 4c)",
                prefix: "$",
                decimal: f1065Decimal(\.guaranteedPayments, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Ordinary income/loss (K-1 Box 1)",
                prefix: "$",
                decimal: f1065Decimal(\.ordinaryIncomeLoss, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Net rental real estate (Box 2)",
                prefix: "$",
                decimal: f1065Decimal(\.netRentalRealEstate, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Other net rental income (Box 3)",
                prefix: "$",
                decimal: f1065Decimal(\.otherNetRentalIncome, isY1: isY1)
            )
            divider
            if isY1 {
                AddbackInfoButton()
                divider
            }
            FieldRow(
                label: "Depreciation",
                prefix: "$",
                hint: "added back",
                decimal: f1065Decimal(\.depreciation, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Depletion",
                prefix: "$",
                hint: "added back",
                decimal: f1065Decimal(\.depletion, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Amortization / casualty",
                prefix: "$",
                hint: "added back",
                decimal: f1065Decimal(\.amortizationOrCasualtyLoss, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Mortgage / notes < 1 yr",
                prefix: "$",
                hint: "subtracted",
                decimal: f1065Decimal(\.mortgageOrNotesLessThan1Yr, isY1: isY1)
            )
            divider
            FieldRow(
                label: "Non-deductible travel / meals",
                prefix: "$",
                hint: "subtracted",
                decimal: f1065Decimal(\.nonDeductibleTravelMeals, isY1: isY1)
            )
            divider
            distributionToggle(isY1: isY1, is1120S: false)
        }
    }

    // MARK: Bindings

    private func yearDecimalBinding(isY1: Bool) -> Binding<Decimal> {
        let intBinding = yearBinding(isY1: isY1)
        return Binding(
            get: { Decimal(intBinding.wrappedValue) },
            set: { intBinding.wrappedValue = Int(truncating: $0 as NSNumber) }
        )
    }

    private func yearBinding(isY1: Bool) -> Binding<Int> {
        switch viewModel.inputs.businessType {
        case .scheduleC:
            return Binding(
                get: {
                    isY1
                        ? viewModel.inputs.scheduleCY1.year
                        : viewModel.inputs.scheduleCY2.year
                },
                set: { newVal in
                    if isY1 {
                        viewModel.inputs.scheduleCY1.year = newVal
                    } else {
                        viewModel.inputs.scheduleCY2.year = newVal
                    }
                }
            )
        case .form1120S:
            return Binding(
                get: {
                    isY1
                        ? viewModel.inputs.form1120SY1.year
                        : viewModel.inputs.form1120SY2.year
                },
                set: { newVal in
                    if isY1 {
                        viewModel.inputs.form1120SY1.year = newVal
                    } else {
                        viewModel.inputs.form1120SY2.year = newVal
                    }
                }
            )
        case .form1065:
            return Binding(
                get: {
                    isY1
                        ? viewModel.inputs.form1065Y1.year
                        : viewModel.inputs.form1065Y2.year
                },
                set: { newVal in
                    if isY1 {
                        viewModel.inputs.form1065Y1.year = newVal
                    } else {
                        viewModel.inputs.form1065Y2.year = newVal
                    }
                }
            )
        }
    }

    private func scheduleCDecimal(
        _ kp: WritableKeyPath<ScheduleCYear, Decimal>,
        isY1: Bool
    ) -> Binding<Decimal> {
        Binding(
            get: {
                isY1
                    ? viewModel.inputs.scheduleCY1[keyPath: kp]
                    : viewModel.inputs.scheduleCY2[keyPath: kp]
            },
            set: { newVal in
                if isY1 {
                    viewModel.inputs.scheduleCY1[keyPath: kp] = newVal
                } else {
                    viewModel.inputs.scheduleCY2[keyPath: kp] = newVal
                }
            }
        )
    }

    private func f1120SDecimal(
        _ kp: WritableKeyPath<Form1120SYear, Decimal>,
        isY1: Bool
    ) -> Binding<Decimal> {
        Binding(
            get: {
                isY1
                    ? viewModel.inputs.form1120SY1[keyPath: kp]
                    : viewModel.inputs.form1120SY2[keyPath: kp]
            },
            set: { newVal in
                if isY1 {
                    viewModel.inputs.form1120SY1[keyPath: kp] = newVal
                } else {
                    viewModel.inputs.form1120SY2[keyPath: kp] = newVal
                }
            }
        )
    }

    private func f1065Decimal(
        _ kp: WritableKeyPath<Form1065Year, Decimal>,
        isY1: Bool
    ) -> Binding<Decimal> {
        Binding(
            get: {
                isY1
                    ? viewModel.inputs.form1065Y1[keyPath: kp]
                    : viewModel.inputs.form1065Y2[keyPath: kp]
            },
            set: { newVal in
                if isY1 {
                    viewModel.inputs.form1065Y1[keyPath: kp] = newVal
                } else {
                    viewModel.inputs.form1065Y2[keyPath: kp] = newVal
                }
            }
        )
    }

    // MARK: Specialized rows

    private func form1120SOwnershipRow(isY1: Bool) -> some View {
        let pct = isY1
            ? viewModel.inputs.form1120SY1.ownershipPercent
            : viewModel.inputs.form1120SY2.ownershipPercent
        return HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Ownership %")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("< 25% + no distribution history → pass-through = 0")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Slider(
                value: Binding(
                    get: { pct },
                    set: { v in
                        if isY1 {
                            viewModel.inputs.form1120SY1.ownershipPercent = v
                        } else {
                            viewModel.inputs.form1120SY2.ownershipPercent = v
                        }
                    }
                ),
                in: 0...1,
                step: 0.01
            )
            .tint(Palette.accent)
            .frame(width: 130)
            Text(String(format: "%.0f%%", pct * 100))
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 48, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    private func form1065OwnershipRow(isY1: Bool) -> some View {
        let pct = isY1
            ? viewModel.inputs.form1065Y1.ownershipPercent
            : viewModel.inputs.form1065Y2.ownershipPercent
        return HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Ownership %")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("< 25% + no distribution history → pass-through = 0")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Slider(
                value: Binding(
                    get: { pct },
                    set: { v in
                        if isY1 {
                            viewModel.inputs.form1065Y1.ownershipPercent = v
                        } else {
                            viewModel.inputs.form1065Y2.ownershipPercent = v
                        }
                    }
                ),
                in: 0...1,
                step: 0.01
            )
            .tint(Palette.accent)
            .frame(width: 130)
            Text(String(format: "%.0f%%", pct * 100))
                .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 48, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    private func distributionToggle(isY1: Bool, is1120S: Bool) -> some View {
        let active: Bool = activeDistributionFlag(isY1: isY1, is1120S: is1120S)
        return HStack(spacing: Spacing.s12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Consistent distribution history")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text("per Fannie B3-3.6-07 — needed when ownership < 25%")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { active },
                set: { v in
                    setDistributionFlag(v, isY1: isY1, is1120S: is1120S)
                }
            ))
            .labelsHidden()
            .tint(Palette.accent)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    private func activeDistributionFlag(isY1: Bool, is1120S: Bool) -> Bool {
        if is1120S {
            return isY1
                ? viewModel.inputs.form1120SY1.hasConsistentDistributionHistory
                : viewModel.inputs.form1120SY2.hasConsistentDistributionHistory
        } else {
            return isY1
                ? viewModel.inputs.form1065Y1.hasConsistentDistributionHistory
                : viewModel.inputs.form1065Y2.hasConsistentDistributionHistory
        }
    }

    private func setDistributionFlag(_ value: Bool, isY1: Bool, is1120S: Bool) {
        if is1120S {
            if isY1 {
                viewModel.inputs.form1120SY1.hasConsistentDistributionHistory = value
            } else {
                viewModel.inputs.form1120SY2.hasConsistentDistributionHistory = value
            }
        } else {
            if isY1 {
                viewModel.inputs.form1065Y1.hasConsistentDistributionHistory = value
            } else {
                viewModel.inputs.form1065Y2.hasConsistentDistributionHistory = value
            }
        }
    }

    // MARK: Card shell

    @ViewBuilder
    func cardFrame<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(title)
                .padding(.horizontal, Spacing.s20)
                .padding(.bottom, Spacing.s8)
            VStack(spacing: 0) { content() }
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

    var divider: some View {
        Rectangle().fill(Palette.borderSubtle).frame(height: 1)
    }
}

// MARK: - Addback info button

/// Info icon + popover explaining the Fannie 1084 addback methodology.
/// Sits inline in each Year-1 card right before the first addback field.
struct AddbackInfoButton: View {
    @State private var showPopover = false

    var body: some View {
        Button { showPopover = true } label: {
            HStack(spacing: Spacing.s8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.accent)
                Text("About addbacks & subtractions")
                    .textStyle(Typography.body.withSize(12))
                    .foregroundStyle(Palette.inkSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("selfEmployment.addbackInfo")
        .popover(isPresented: $showPopover) {
            AddbackExplanationPopover()
                .presentationCompactAdaptation(.popover)
        }
    }
}

private struct AddbackExplanationPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Text("Fannie Mae Form 1084 methodology")
                .textStyle(Typography.bodyLg.withSize(13, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Text("""
                 Addbacks increase qualifying income. Depreciation, \
                 depletion, business use of home, and similar non-cash \
                 expenses are subtracted on the tax return but the \
                 borrower didn't actually pay them in cash. For mortgage \
                 qualification, Fannie Mae adds them back.
                 """)
                .textStyle(Typography.body.withSize(12.5))
                .foregroundStyle(Palette.inkSecondary)
            Text("""
                 Subtractions reduce qualifying income. Non-deductible \
                 meals and Schedule L short-term mortgages/notes \
                 represent real cash outflows the tax return doesn't \
                 reflect — they come out of cash flow.
                 """)
                .textStyle(Typography.body.withSize(12.5))
                .foregroundStyle(Palette.inkSecondary)
            Text("Selling Guide B3-3.6-03")
                .textStyle(Typography.num.withSize(11))
                .foregroundStyle(Palette.inkTertiary)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: 320)
    }
}
