// ScenarioType.swift
// The five calculator output types that drive disclosure selection.
//
// Parallels the data-model `CalculatorType` that Session 3 will persist on
// `Scenario` (per DEVELOPMENT.md). Kept in the compliance package so the
// disclosure API doesn't depend on SwiftData.

import Foundation

public enum ScenarioType: String, Sendable, Hashable, Codable, CaseIterable {
    case amortization
    case incomeQualification
    case refinance
    case totalCostAnalysis
    case helocVsRefinance
}
