// Fields.swift
// Input fields matching Foundations.jsx — label on left, value
// (SF Mono tabular) + optional prefix/suffix on right, focused state
// draws a 1.5pt accent underline beneath the whole row.
//
// Four variants:
//   - CurrencyField    — numeric value with `$` prefix
//   - PercentageField  — numeric value with `%` suffix
//   - NumberField      — plain numeric value (optional prefix/suffix)
//   - InputTextField   — text value (non-numeric) — named InputTextField
//                       so it doesn't collide with SwiftUI.TextField.
//
// Tokens consumed: Typography.body, Typography.num, Palette.ink / accent /
// loss / inkTertiary / borderDefault, Spacing.s8 / s12,
// Motion.fastEaseOut.

import SwiftUI

public enum FieldValidationState: Sendable, Hashable {
    case idle
    case focused
    case error(String)
}

private struct FieldChrome<Content: View>: View {
    let label: String
    let state: FieldValidationState
    let content: Content
    let disabled: Bool

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    init(
        label: String,
        state: FieldValidationState,
        disabled: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.state = state
        self.disabled = disabled
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                Text(label)
                    .textStyle(Typography.body)
                    .foregroundStyle(disabled ? Palette.inkTertiary : Palette.inkSecondary)
                Spacer(minLength: Spacing.s8)
                content
                    .foregroundStyle(disabled ? Palette.inkTertiary : Palette.ink)
            }
            .padding(.vertical, Spacing.s8)
            Rectangle()
                .fill(underlineColor)
                .frame(height: underlineHeight)
                .animation(reduceMotion ? nil : Motion.fastEaseOut, value: underlineColor)
            if case let .error(message) = state {
                Text(message)
                    .textStyle(Typography.bodySm)
                    .foregroundStyle(Palette.loss)
                    .padding(.top, Spacing.s4)
            }
        }
    }

    private var underlineColor: Color {
        switch state {
        case .focused: return Palette.accent
        case .error:   return Palette.loss
        case .idle:    return Palette.borderDefault
        }
    }

    private var underlineHeight: CGFloat {
        if case .focused = state { return Tokens.Stroke.activeUnderline }
        if case .error = state { return Tokens.Stroke.activeUnderline }
        return Tokens.Stroke.hairline
    }
}

// MARK: - Currency

public struct CurrencyField: View {
    let label: String
    let displayValue: String
    let state: FieldValidationState
    let disabled: Bool

    public init(
        label: String,
        displayValue: String,
        state: FieldValidationState = .idle,
        disabled: Bool = false
    ) {
        self.label = label
        self.displayValue = displayValue
        self.state = state
        self.disabled = disabled
    }

    public var body: some View {
        FieldChrome(label: label, state: state, disabled: disabled) {
            HStack(spacing: 2) {
                Text("$").textStyle(Typography.num)
                    .foregroundStyle(Palette.inkTertiary)
                Text(displayValue).textStyle(Typography.numLg)
            }
        }
    }
}

// MARK: - Percentage

public struct PercentageField: View {
    let label: String
    let displayValue: String
    let state: FieldValidationState
    let disabled: Bool

    public init(
        label: String,
        displayValue: String,
        state: FieldValidationState = .idle,
        disabled: Bool = false
    ) {
        self.label = label
        self.displayValue = displayValue
        self.state = state
        self.disabled = disabled
    }

    public var body: some View {
        FieldChrome(label: label, state: state, disabled: disabled) {
            HStack(spacing: 2) {
                Text(displayValue).textStyle(Typography.numLg)
                Text("%").textStyle(Typography.num)
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
    }
}

// MARK: - Plain number

public struct NumberField: View {
    let label: String
    let displayValue: String
    let prefix: String?
    let suffix: String?
    let state: FieldValidationState
    let disabled: Bool

    public init(
        label: String,
        displayValue: String,
        prefix: String? = nil,
        suffix: String? = nil,
        state: FieldValidationState = .idle,
        disabled: Bool = false
    ) {
        self.label = label
        self.displayValue = displayValue
        self.prefix = prefix
        self.suffix = suffix
        self.state = state
        self.disabled = disabled
    }

    public var body: some View {
        FieldChrome(label: label, state: state, disabled: disabled) {
            HStack(spacing: 2) {
                if let prefix {
                    Text(prefix).textStyle(Typography.num)
                        .foregroundStyle(Palette.inkTertiary)
                }
                Text(displayValue).textStyle(Typography.numLg)
                if let suffix {
                    Text(suffix).textStyle(Typography.num)
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
        }
    }
}

// MARK: - Text

public struct InputTextField: View {
    let label: String
    let value: String
    let state: FieldValidationState
    let disabled: Bool

    public init(
        label: String,
        value: String,
        state: FieldValidationState = .idle,
        disabled: Bool = false
    ) {
        self.label = label
        self.value = value
        self.state = state
        self.disabled = disabled
    }

    public var body: some View {
        FieldChrome(label: label, state: state, disabled: disabled) {
            Text(value).textStyle(Typography.bodyLg)
        }
    }
}

#Preview("Fields · states") {
    VStack(spacing: Spacing.s16) {
        CurrencyField(label: "Loan amount", displayValue: "400,000")
        PercentageField(label: "Interest rate", displayValue: "6.750", state: .focused)
        NumberField(
            label: "Term",
            displayValue: "30",
            suffix: "yr",
            state: .idle
        )
        InputTextField(label: "Property state", value: "California")
        CurrencyField(
            label: "Monthly HOA",
            displayValue: "−100",
            state: .error("HOA must be non-negative")
        )
        InputTextField(label: "Disabled", value: "—", disabled: true)
    }
    .padding()
    .background(Palette.surfaceRaised)
}
