// APRFieldRow.swift
// Session 5M.2: thin wrapper over FieldRow for optional-APR inputs.
// Handles the Decimal? ↔ Decimal-with-0-as-sentinel mapping inline,
// applies the "Same as rate" placeholder + disclosure-APR hint, and
// keeps the call sites to one line per calculator.

import SwiftUI

struct APRFieldRow: View {
    @Binding var aprRate: Decimal?
    /// Override the default hint when the calculator has multiple APR
    /// fields (e.g. HELOC has one per tranche) and a single generic
    /// hint would be ambiguous.
    var hint: String = "Optional — disclosure APR"

    var body: some View {
        FieldRow(
            label: "APR",
            suffix: "%",
            hint: hint,
            placeholder: "Same as rate",
            decimal: Binding(
                get: { aprRate ?? 0 },
                set: { aprRate = ($0 == 0) ? nil : $0 }
            ),
            showsInitialValue: aprRate != nil,
            fractionDigits: 3
        )
    }
}
