// FieldRow.swift
// Shared numeric-input row used across every calculator's Inputs
// screen: left-aligned label (with optional hint), right-aligned
// `TextField` in SF Mono with optional prefix (e.g. "$") and suffix
// (e.g. "%"). Focused state draws an accent underline.
//
// The row owns a local `@State` `text` buffer so the user can type
// freely; on `onChange(text)` we reparse into the bound `Decimal`.
// When the bound decimal changes externally (and the field isn't
// focused), we reformat back into the buffer. This matches the
// Amortization Inputs screen's original behaviour — lifted here so
// every calculator can reuse it.

import SwiftUI

struct FieldRow: View {
    let label: String
    var prefix: String?
    var suffix: String?
    var hint: String?
    /// Empty-state placeholder shown in the TextField. Defaults to
    /// "—" matching pre-5M behavior. APR fields override to
    /// "Same as rate" so blank reads as an explicit state rather than
    /// an unpopulated zero.
    var placeholder: String = "—"
    @Binding var decimal: Decimal
    /// When false, the field starts empty regardless of the bound
    /// `decimal` value — treats `0` as "no value yet" (placeholder
    /// visible). Used by APR fields whose nil storage maps to 0 on
    /// the Decimal binding. On external changes the field still
    /// updates, so loading a saved scenario with an APR value still
    /// populates the row.
    var showsInitialValue: Bool = true
    var fractionDigits: Int = 0
    var usesGroupingSeparator: Bool = true

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: Spacing.s12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .textStyle(Typography.bodyLg.withSize(14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                if let hint {
                    Text(hint)
                        .textStyle(Typography.num.withSize(11))
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            Spacer()
            HStack(spacing: 2) {
                if let prefix {
                    Text(prefix)
                        .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                        .foregroundStyle(Palette.inkTertiary)
                }
                TextField(placeholder, text: $text)
                    .focused($focused)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.ink)
                    .frame(minWidth: 80)
                if let suffix {
                    Text(suffix)
                        .textStyle(Typography.num.withSize(15, weight: .medium, design: .monospaced))
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(focused ? Palette.accent : Color.clear)
                    .frame(height: 1.5)
                    .offset(y: 4)
            }
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s12)
        .onAppear {
            if text.isEmpty, showsInitialValue { text = format(decimal) }
        }
        .onChange(of: text) { _, new in
            if let parsed = parse(new) {
                decimal = parsed
            }
        }
        .onChange(of: decimal) { _, new in
            if !focused {
                let formatted = format(new)
                if formatted != text { text = formatted }
            }
        }
    }

    private func format(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = fractionDigits
        f.minimumFractionDigits = fractionDigits
        f.usesGroupingSeparator = usesGroupingSeparator
        return f.string(from: value as NSNumber) ?? ""
    }

    private func parse(_ str: String) -> Decimal? {
        let cleaned = str.replacingOccurrences(of: ",", with: "")
        if cleaned.isEmpty { return 0 }
        return Decimal(string: cleaned)
    }
}
