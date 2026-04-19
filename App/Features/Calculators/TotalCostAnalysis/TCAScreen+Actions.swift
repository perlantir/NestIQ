// TCAScreen+Actions.swift
// Save + PDF-share helpers split off from TCAScreen to keep the parent
// struct under SwiftLint's type_body_length cap after the 5F.4.b
// include-debts toggle landed more state + winner logic on the main view.

import SwiftUI
import SwiftData
import QuotientPDF

extension TCAScreen {

    func generatePDFAndShare() {
        guard let profile = profiles.first else { return }
        do {
            let url = try PDFBuilder.buildTCAPDF(
                profile: profile,
                borrower: viewModel.borrower,
                viewModel: viewModel,
                narrative: narrativeText
            )
            shareBundle = ShareBundle(
                url: url,
                pageCount: PDFInspector(url: url)?.pageCount ?? 1,
                profile: profile
            )
        } catch {
            #if DEBUG
            print("[TCAScreen] PDF gen failed: \(error)")
            #endif
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = (try? encoder.encode(viewModel.inputs)) ?? Data()
        let name = viewModel.borrower?.fullName ?? "TCA"
        let key = "\(viewModel.inputs.scenarios.count) scenarios · 10-yr horizon"
        if let existing = existingScenario {
            existing.inputsJSON = data
            existing.keyStatLine = key
            existing.name = name
            existing.updatedAt = Date()
        } else {
            let s = Scenario(
                borrower: viewModel.borrower,
                calculatorType: .totalCostAnalysis,
                name: name,
                inputsJSON: data,
                keyStatLine: key
            )
            modelContext.insert(s)
        }
        try? modelContext.save()
        justSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { justSaved = false }
    }
}
