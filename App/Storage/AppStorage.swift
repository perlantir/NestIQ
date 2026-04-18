// AppStorage.swift
// Central SwiftData container + helpers. One singleton profile per app
// install; cleared when Nick signs out.

import Foundation
import SwiftData

public enum QuotientSchema {
    public static let models: [any PersistentModel.Type] = [
        LenderProfile.self,
        Borrower.self,
        Scenario.self,
    ]

    public static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema(models)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }
}
