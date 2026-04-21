// SettingsScreen+Compliance.swift
// Session 5L.5: Disclaimers · compliance section + licensed-states
// preview helper pulled out of SettingsScreen to keep the parent
// struct under SwiftLint's type_body_length cap. Same extension-file
// pattern SavedScenariosScreen / TCAScreen / IncomeQualScreen use.

import SwiftUI

extension SettingsScreen {

    @ViewBuilder var complianceSection: some View {
        settingsGroup(header: "Disclaimers · compliance") {
            settingsNavRow(
                label: "NMLS display",
                trailing: profile.nmlsDisplayFormat.display
            ) {
                NMLSDisplayFormatPicker(profile: profile)
            }
            divider
            settingsNavRow(
                label: "Equal Housing language",
                trailing: profile.ehoLanguage.display
            ) {
                EqualHousingLanguagePicker(profile: profile)
            }
        }
    }

    /// "IA, CA, TX · 4 states" (abbreviations for up to the first 3
    /// states, then the total count). "None" when empty. Used by the
    /// ProfileEditor row.
    var licensedStatesPreview: String {
        let states = profile.licensedStates.sorted()
        if states.isEmpty { return "None" }
        let abbrev = states.prefix(3).joined(separator: ", ")
        let unit = states.count == 1 ? "state" : "states"
        return "\(abbrev) · \(states.count) \(unit)"
    }
}
