// SaveScenarioNamePrompt.swift
// Shared alert+TextField modifier that intercepts the Save tap across all
// six calculators, lets the LO pick a per-scenario name (defaulted to
// "{Borrower} · {Calculator}"), and forwards the confirmed name to each
// screen's saveScenario(name:) implementation.
//
// Added in Session 5J.3 to replace the pre-5J behavior where every Save
// tap persisted silently with a generic name pulled from the borrower or
// the calculator type.

import SwiftUI

private let maxScenarioNameLength = 60

struct SaveScenarioNameAlert: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var name: String
    let defaultName: String
    let onSave: (String) -> Void

    func body(content: Content) -> some View {
        content.alert("Save scenario", isPresented: $isPresented) {
            TextField("Scenario name", text: $name)
                .onChange(of: name) { _, newValue in
                    if newValue.count > maxScenarioNameLength {
                        name = String(newValue.prefix(maxScenarioNameLength))
                    }
                }
            Button("Save") {
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                onSave(trimmed.isEmpty ? defaultName : trimmed)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Name this scenario so you can find it in Saved later.")
        }
    }
}

extension View {
    /// Presents a single-field alert that captures a user-chosen scenario
    /// name. Clearing the field and tapping Save falls back to
    /// `defaultName`. Names longer than 60 characters are truncated.
    func saveScenarioNameAlert(
        isPresented: Binding<Bool>,
        name: Binding<String>,
        defaultName: String,
        onSave: @escaping (String) -> Void
    ) -> some View {
        modifier(SaveScenarioNameAlert(
            isPresented: isPresented,
            name: name,
            defaultName: defaultName,
            onSave: onSave
        ))
    }
}

/// Default name helper used by every calculator save site so the
/// "{Borrower} · {Calculator}" format stays identical across screens.
/// Falls back to "New scenario · {Calculator}" when no borrower is
/// selected (DEBUG skip path or borrowers-disabled flow).
enum SaveScenarioDefaults {
    static func name(borrower: Borrower?, calculator: String) -> String {
        if let borrower, !borrower.fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            return "\(borrower.fullName) · \(calculator)"
        }
        return "New scenario · \(calculator)"
    }
}
