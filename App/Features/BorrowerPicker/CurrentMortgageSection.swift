// CurrentMortgageSection.swift
// Session 5P.7: reusable "Current mortgage" input form used in two
// places:
//
//   1. NewBorrowerForm — optional section under the standard name /
//      email / phone fields. Collapsed by default so purchase-only
//      borrowers see a clean form.
//   2. Refi-mode calculator inputs (TCA refi, Refinance Comparison,
//      HELOC vs Refi) — inline prompt when the selected borrower has
//      no currentMortgage. Wired up by 5P.8 / 5P.12 / 5P.13.
//
// The draft model separates "typing state" from "final CurrentMortgage
// value type" so partial entries don't pollute the persisted model.

import SwiftUI

/// Scratch-space editable model the form binds to. All numeric
/// fields default to 0 for FieldRow's sake; the validation path
/// rejects "all-zero"-shaped drafts so blank forms don't accidentally
/// save an all-zero CurrentMortgage.
struct CurrentMortgageDraft: Equatable {
    var currentBalance: Decimal = 0
    var currentRatePercent: Decimal = 0
    var currentMonthlyPaymentPI: Decimal = 0
    var originalLoanAmount: Decimal = 0
    var originalTermYears: Int = 30
    var loanStartDate: Date
    var propertyValueToday: Decimal = 0

    init(
        currentBalance: Decimal = 0,
        currentRatePercent: Decimal = 0,
        currentMonthlyPaymentPI: Decimal = 0,
        originalLoanAmount: Decimal = 0,
        originalTermYears: Int = 30,
        loanStartDate: Date? = nil,
        propertyValueToday: Decimal = 0
    ) {
        self.currentBalance = currentBalance
        self.currentRatePercent = currentRatePercent
        self.currentMonthlyPaymentPI = currentMonthlyPaymentPI
        self.originalLoanAmount = originalLoanAmount
        self.originalTermYears = originalTermYears
        // Default: 24 months ago, rounded down to start-of-month.
        let fallback: Date = {
            let calendar = Calendar(identifier: .gregorian)
            let twoYearsAgo = calendar.date(byAdding: .year, value: -2, to: Date()) ?? Date()
            let components = calendar.dateComponents([.year, .month], from: twoYearsAgo)
            return calendar.date(from: components) ?? twoYearsAgo
        }()
        self.loanStartDate = loanStartDate ?? fallback
        self.propertyValueToday = propertyValueToday
    }

    init(from mortgage: CurrentMortgage) {
        self.currentBalance = mortgage.currentBalance
        self.currentRatePercent = mortgage.currentRatePercent
        self.currentMonthlyPaymentPI = mortgage.currentMonthlyPaymentPI
        self.originalLoanAmount = mortgage.originalLoanAmount
        self.originalTermYears = mortgage.originalTermYears
        self.loanStartDate = mortgage.loanStartDate
        self.propertyValueToday = mortgage.propertyValueToday
    }

    /// True when every required field carries a plausible value — all
    /// currency fields > 0, rate > 0, start date in the past, and
    /// `currentBalance ≤ originalLoanAmount` (you don't owe more than
    /// you borrowed originally).
    var isValid: Bool {
        guard currentBalance > 0,
              currentRatePercent > 0,
              currentMonthlyPaymentPI > 0,
              originalLoanAmount > 0,
              originalTermYears > 0,
              propertyValueToday > 0 else {
            return false
        }
        guard loanStartDate < Date() else { return false }
        guard currentBalance <= originalLoanAmount else { return false }
        return true
    }

    /// True when every field is still at its initial zero — "the LO
    /// opened the section but didn't fill anything in." Distinct from
    /// isValid==false so partial entries can surface validation errors
    /// without a fully blank draft looking like an invalid attempt.
    var isBlank: Bool {
        currentBalance == 0
            && currentRatePercent == 0
            && currentMonthlyPaymentPI == 0
            && originalLoanAmount == 0
            && propertyValueToday == 0
    }

    func toMortgage() -> CurrentMortgage? {
        guard isValid else { return nil }
        return CurrentMortgage(
            currentBalance: currentBalance,
            currentRatePercent: currentRatePercent,
            currentMonthlyPaymentPI: currentMonthlyPaymentPI,
            originalLoanAmount: originalLoanAmount,
            originalTermYears: originalTermYears,
            loanStartDate: loanStartDate,
            propertyValueToday: propertyValueToday
        )
    }
}

struct CurrentMortgageSection: View {
    @Binding var draft: CurrentMortgageDraft
    @Binding var isExpanded: Bool
    var showValidationHint: Bool = false

    private static let termOptions = [10, 15, 20, 25, 30, 40]

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: Spacing.s12) {
                hint
                fields
                if showValidationHint, !draft.isBlank, !draft.isValid {
                    validationError
                }
            }
            .padding(.top, Spacing.s12)
        } label: {
            HStack {
                Text("Current mortgage")
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text(draft.isBlank ? "optional" : "filled in")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
    }

    private var hint: some View {
        Text("For refinance comparisons. Leave blank for purchase-only borrowers.")
            .textStyle(Typography.body.withSize(11))
            .foregroundStyle(Palette.inkTertiary)
    }

    private var fields: some View {
        VStack(spacing: 0) {
            FieldRow(
                label: "Current balance",
                prefix: "$",
                decimal: $draft.currentBalance
            )
            HairlineDivider()
            FieldRow(
                label: "Current rate",
                suffix: "%",
                decimal: $draft.currentRatePercent,
                fractionDigits: 3
            )
            HairlineDivider()
            FieldRow(
                label: "Current P&I",
                prefix: "$",
                hint: "monthly, excluding escrow",
                decimal: $draft.currentMonthlyPaymentPI
            )
            HairlineDivider()
            FieldRow(
                label: "Original loan",
                prefix: "$",
                decimal: $draft.originalLoanAmount
            )
            HairlineDivider()
            termRow
            HairlineDivider()
            startDateRow
            HairlineDivider()
            FieldRow(
                label: "Property value today",
                prefix: "$",
                hint: "your estimate",
                decimal: $draft.propertyValueToday
            )
        }
    }

    private var termRow: some View {
        HStack {
            Text("Original term")
                .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
            Picker("Term", selection: $draft.originalTermYears) {
                ForEach(Self.termOptions, id: \.self) { years in
                    Text("\(years) yr").tag(years)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    private var startDateRow: some View {
        HStack {
            Text("Loan start date")
                .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
            DatePicker(
                "",
                selection: $draft.loanStartDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .labelsHidden()
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
    }

    private var validationError: some View {
        Text(validationMessage)
            .textStyle(Typography.body.withSize(11))
            .foregroundStyle(Palette.warn)
            .padding(.horizontal, Spacing.s16)
    }

    private var validationMessage: String {
        if draft.currentBalance > draft.originalLoanAmount, draft.originalLoanAmount > 0 {
            return "Current balance can't exceed the original loan amount."
        }
        if draft.loanStartDate >= Date() {
            return "Loan start date must be in the past."
        }
        return "All fields are required — or leave the section blank to skip."
    }
}
