// ColorHex.swift
// Convert the LenderProfile.brandColorHex string into a SwiftUI Color.
// Kept in the Theme layer so both on-device views and the PDF renderer
// can round-trip the hex to a color without duplicating parse logic.
//
// The initializer is non-failable — unparseable hex falls back to the
// default Ledger-green accent so PDF renders never blow up on a typo
// in a persisted profile.

import SwiftUI

extension Color {
    /// Parse a `#RRGGBB` (or `RRGGBB`) hex string. Returns the Ledger-green
    /// default if parsing fails — callers should pass validated input but
    /// don't need to guard against malformed strings.
    init(brandHex raw: String) {
        let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard trimmed.count == 6,
              let value = UInt32(trimmed, radix: 16) else {
            self = Palette.accent
            return
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
