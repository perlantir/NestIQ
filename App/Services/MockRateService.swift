// MockRateService.swift
// Session 6.4 — RateService shape collapsed to PMMS-only (MORTGAGE30US +
// MORTGAGE15US via FRED). Product list trimmed from six to two because
// FRED only publishes Freddie Mac PMMS 30/15 fixed; any other product
// would need a separate data provider and its own attribution.
//
// This file owns the shared data types and the mock implementation used
// by SwiftUI previews and unit tests. The production fetcher lives in
// FREDRateService.swift.

import Foundation

public struct RateSnapshot: Sendable, Hashable {
    public let name: String
    /// Current rate, e.g. 6.30 for 6.30 %. Double for view-layer
    /// formatting; the raw FRED decimal survives inside the cache.
    public let rate: Double
    /// Week-over-week change in percentage points, rounded to 2 dp.
    /// Zero when fewer than two observations are available.
    public let delta: Double
    public let move: Move
    /// False on the first observation of a new FRED series (e.g. a
    /// freshly-introduced product). Drives the widget to hide the delta
    /// chip rather than rendering a misleading zero-move indicator.
    public let hasPriorObservation: Bool

    public enum Move: String, Sendable, Hashable { case up, down, flat }

    public init(
        name: String,
        rate: Double,
        delta: Double,
        move: Move,
        hasPriorObservation: Bool = true
    ) {
        self.name = name
        self.rate = rate
        self.delta = delta
        self.move = move
        self.hasPriorObservation = hasPriorObservation
    }
}

public struct RateReport: Sendable, Hashable {
    public let rates: [RateSnapshot]
    public let asOf: Date
    /// True when the report was served from hardcoded fallback constants
    /// because no cached fetch and no live fetch succeeded. Drives the
    /// "· offline" eyebrow suffix on the home widget.
    public let isFallback: Bool

    public init(rates: [RateSnapshot], asOf: Date, isFallback: Bool = false) {
        self.rates = rates
        self.asOf = asOf
        self.isFallback = isFallback
    }
}

public protocol RateService: Sendable {
    func fetchSnapshot() async throws -> RateReport
}

public struct MockRateService: RateService {
    public init() {}

    public func fetchSnapshot() async throws -> RateReport {
        RateReport(
            rates: [
                .init(name: "30-yr fixed", rate: 6.30, delta: -0.07, move: .down),
                .init(name: "15-yr fixed", rate: 5.65, delta: +0.03, move: .up)
            ],
            asOf: Date(),
            isFallback: false
        )
    }
}
