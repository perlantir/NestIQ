// MockRateService.swift
// Stubbed rate snapshot. Session 5 replaces this with a live call to
// the Vercel-edge / Cloudflare-workers proxy that re-exports FRED.
//
// Values intentionally pinned to plausible April-2026 levels with small
// deltas so design QA has stable numbers to check. Document as an open
// item in SESSION-3-SUMMARY.md.

import Foundation

public struct RateSnapshot: Sendable, Hashable {
    public let name: String
    public let rate: Double
    public let delta: Double // change from prior publication, percentage points
    public let move: Move

    public enum Move: String, Sendable, Hashable { case up, down, flat }
}

public struct RateReport: Sendable, Hashable {
    public let rates: [RateSnapshot]
    public let asOf: Date

    public init(rates: [RateSnapshot], asOf: Date) {
        self.rates = rates
        self.asOf = asOf
    }
}

public protocol RateService: Sendable {
    func fetchSnapshot() async throws -> RateReport
}

public struct MockRateService: RateService {
    public init() {}

    public func fetchSnapshot() async throws -> RateReport {
        let asOf = Date()
        return RateReport(
            rates: [
                .init(name: "30-yr fixed", rate: 6.850, delta: -0.03, move: .down),
                .init(name: "15-yr fixed", rate: 6.120, delta: -0.02, move: .down),
                .init(name: "5/6 ARM", rate: 6.450, delta: +0.01, move: .up),
                .init(name: "FHA 30", rate: 6.520, delta: 0.00, move: .flat),
                .init(name: "VA 30", rate: 6.280, delta: -0.04, move: .down),
                .init(name: "Jumbo 30", rate: 7.050, delta: +0.05, move: .up),
            ],
            asOf: asOf
        )
    }
}
