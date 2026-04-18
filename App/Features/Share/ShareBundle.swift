// ShareBundle.swift
// Identifiable wrapper so `.sheet(item:)` can present the Share
// preview deterministically — the URL+profile pair becomes the sheet
// trigger, avoiding the `isPresented` / content-nil race where the
// sheet body is evaluated before the URL / profile are populated.

import Foundation

struct ShareBundle: Identifiable {
    let id = UUID()
    let url: URL
    let pageCount: Int
    let profile: LenderProfile
}
