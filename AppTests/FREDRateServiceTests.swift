// FREDRateServiceTests.swift
// Session 6.4 — unit coverage for the live PMMS rate pipeline.
// No live network calls. RateFetching + RateCacheStore are injected.

import XCTest
@testable import Quotient

@MainActor
final class FREDRateServiceTests: XCTestCase {

    // MARK: - Fallback constants (guard)

    func testFallbackConstantsMatchDocumentedValues() {
        XCTAssertEqual(FREDRateService.fallback30yr, 6.30, accuracy: 0.0001)
        XCTAssertEqual(FREDRateService.fallback15yr, 5.65, accuracy: 0.0001)

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        XCTAssertEqual(f.string(from: FREDRateService.fallbackAsOf), "2026-04-16")
    }

    // MARK: - Delta + move

    func testRoundedDeltaRoundsToTwoDecimals() {
        XCTAssertEqual(FREDRateService.roundedDelta(current: 6.30, prior: 6.37), -0.07, accuracy: 0.0001)
        XCTAssertEqual(FREDRateService.roundedDelta(current: 5.654, prior: 5.65), 0.00, accuracy: 0.0001)
        XCTAssertEqual(FREDRateService.roundedDelta(current: 5.657, prior: 5.65), 0.01, accuracy: 0.0001)
        XCTAssertEqual(FREDRateService.roundedDelta(current: 7.000, prior: 6.923), 0.08, accuracy: 0.0001)
    }

    func testMoveFlatBelowThreshold() {
        XCTAssertEqual(FREDRateService.move(for: 0.00), .flat)
        XCTAssertEqual(FREDRateService.move(for: 0.009), .flat)
        XCTAssertEqual(FREDRateService.move(for: -0.009), .flat)
    }

    func testMoveUpDownAboveThreshold() {
        XCTAssertEqual(FREDRateService.move(for: 0.01), .up)
        XCTAssertEqual(FREDRateService.move(for: 0.5), .up)
        XCTAssertEqual(FREDRateService.move(for: -0.01), .down)
        XCTAssertEqual(FREDRateService.move(for: -0.5), .down)
    }

    // MARK: - FRED JSON decode

    func testParseObservationsDecodesTwoObservations() throws {
        let json = """
        {
          "observations": [
            {"date": "2026-04-17", "value": "6.30"},
            {"date": "2026-04-10", "value": "6.37"}
          ]
        }
        """.data(using: .utf8)!
        let service = FREDRateService(
            fetcher: StubFetcher(data: json),
            cache: InMemoryCache(),
            apiKey: "testkey",
            now: { Date() }
        )
        let parsed = try service.parseObservations(data: json, series: "MORTGAGE30US")
        XCTAssertEqual(parsed.current.rate, Decimal(string: "6.30"))
        XCTAssertEqual(parsed.prior?.rate, Decimal(string: "6.37"))
        XCTAssertEqual(parsed.current.series, "MORTGAGE30US")
    }

    func testParseObservationsSingleObservationLeavesPriorNil() throws {
        let json = """
        {
          "observations": [
            {"date": "2026-04-17", "value": "6.30"}
          ]
        }
        """.data(using: .utf8)!
        let service = FREDRateService(
            fetcher: StubFetcher(data: json),
            cache: InMemoryCache(),
            apiKey: "testkey",
            now: { Date() }
        )
        let parsed = try service.parseObservations(data: json, series: "MORTGAGE30US")
        XCTAssertEqual(parsed.current.rate, Decimal(string: "6.30"))
        XCTAssertNil(parsed.prior)
    }

    func testParseObservationsThrowsWhenEmpty() {
        let json = "{\"observations\": []}".data(using: .utf8)!
        let service = FREDRateService(
            fetcher: StubFetcher(data: json),
            cache: InMemoryCache(),
            apiKey: "testkey",
            now: { Date() }
        )
        XCTAssertThrowsError(try service.parseObservations(data: json, series: "MORTGAGE30US")) { error in
            XCTAssertEqual(error as? FREDError, .noObservations)
        }
    }

    // MARK: - Fetch → snapshot

    func testFetchSnapshotUsesLiveDataOnFirstCall() async throws {
        let stub = StubFetcher(data: twoObservationJSON(current: "6.30", prior: "6.37"))
        let cache = InMemoryCache()
        let service = FREDRateService(
            fetcher: stub,
            cache: cache,
            apiKey: "testkey",
            now: { Date() }
        )
        let report = try await service.fetchSnapshot()
        XCTAssertFalse(report.isFallback)
        XCTAssertEqual(report.rates.count, 2)
        XCTAssertEqual(report.rates[0].name, "30-yr fixed")
        XCTAssertEqual(report.rates[0].rate, 6.30, accuracy: 0.0001)
        XCTAssertEqual(report.rates[0].delta, -0.07, accuracy: 0.0001)
        XCTAssertEqual(report.rates[0].move, .down)
    }

    func testFetchSnapshotReturnsCachedValueWhenFresh() async throws {
        let cache = InMemoryCache()
        let baseDate = Date(timeIntervalSince1970: 1_800_000_000)
        let clock = MutableClock(date: baseDate)

        let stub = StubFetcher(data: twoObservationJSON(current: "6.30", prior: "6.37"))
        let service = FREDRateService(
            fetcher: stub,
            cache: cache,
            apiKey: "testkey",
            now: { clock.now }
        )
        _ = try await service.fetchSnapshot()
        XCTAssertEqual(stub.callCount, 2, "expected one fetch per series on first call")

        clock.now = baseDate.addingTimeInterval(3600)
        _ = try await service.fetchSnapshot()
        XCTAssertEqual(stub.callCount, 2, "fresh cache must not trigger a refetch")
    }

    func testFetchSnapshotRefetchesWhenCacheStale() async throws {
        let cache = InMemoryCache()
        let baseDate = Date(timeIntervalSince1970: 1_800_000_000)
        let clock = MutableClock(date: baseDate)

        let stub = StubFetcher(data: twoObservationJSON(current: "6.30", prior: "6.37"))
        let service = FREDRateService(
            fetcher: stub,
            cache: cache,
            apiKey: "testkey",
            now: { clock.now }
        )
        _ = try await service.fetchSnapshot()
        XCTAssertEqual(stub.callCount, 2)

        clock.now = baseDate.addingTimeInterval(25 * 60 * 60)
        _ = try await service.fetchSnapshot()
        XCTAssertEqual(stub.callCount, 4, "stale cache must trigger a refetch per series")
    }

    func testFetchSnapshotFallsBackWhenCacheEmptyAndFetchFails() async throws {
        let cache = InMemoryCache()
        let failingFetcher = FailingFetcher()
        let service = FREDRateService(
            fetcher: failingFetcher,
            cache: cache,
            apiKey: "testkey",
            now: { Date() }
        )
        let report = try await service.fetchSnapshot()
        XCTAssertTrue(report.isFallback)
        XCTAssertEqual(report.rates[0].rate, FREDRateService.fallback30yr, accuracy: 0.0001)
        XCTAssertEqual(report.rates[1].rate, FREDRateService.fallback15yr, accuracy: 0.0001)
        XCTAssertFalse(report.rates[0].hasPriorObservation)
    }

    func testFetchSnapshotSinglePastObservationReturnsFlatWithoutCrash() async throws {
        let cache = InMemoryCache()
        let json = """
        {
          "observations": [
            {"date": "2026-04-17", "value": "6.30"}
          ]
        }
        """.data(using: .utf8)!
        let service = FREDRateService(
            fetcher: StubFetcher(data: json),
            cache: cache,
            apiKey: "testkey",
            now: { Date() }
        )
        let report = try await service.fetchSnapshot()
        XCTAssertFalse(report.isFallback)
        XCTAssertFalse(report.rates[0].hasPriorObservation)
        XCTAssertEqual(report.rates[0].delta, 0.00, accuracy: 0.0001)
        XCTAssertEqual(report.rates[0].move, .flat)
    }

    // MARK: - Home widget compliance strings

    func testHomeScreenExposesPMMSAttribution() {
        XCTAssertEqual(
            HomeScreen.pmmsAttributionPrefix,
            "Source: Freddie Mac PMMS® via FRED"
        )
    }

    func testHomeScreenExposesMarketAverageDisclaimer() {
        XCTAssertEqual(
            HomeScreen.marketAverageDisclaimer,
            "Market average. Not an offer of credit."
        )
    }

    // MARK: - Helpers

    private func twoObservationJSON(current: String, prior: String) -> Data {
        """
        {
          "observations": [
            {"date": "2026-04-17", "value": "\(current)"},
            {"date": "2026-04-10", "value": "\(prior)"}
          ]
        }
        """.data(using: .utf8) ?? Data()
    }
}

// MARK: - Stubs

/// Reference-typed clock so test bodies can mutate `now` after handing
/// a read-only closure to FREDRateService. The tests run single-threaded
/// through their await points, so no lock is required to uphold the
/// `@unchecked Sendable` promise.
private final class MutableClock: @unchecked Sendable {
    var now: Date
    init(date: Date) { self.now = date }
}

private final class StubFetcher: RateFetching, @unchecked Sendable {
    let data: Data
    private(set) var callCount: Int = 0

    init(data: Data) {
        self.data = data
    }

    func fetch(_ url: URL) async throws -> Data {
        callCount += 1
        return data
    }
}

private struct FailingFetcher: RateFetching {
    struct FetchFailure: Error {}
    func fetch(_ url: URL) async throws -> Data {
        throw FetchFailure()
    }
}

private final class InMemoryCache: RateCacheStore, @unchecked Sendable {
    private var storage: [String: Data] = [:]

    func data(forKey key: String) -> Data? {
        storage[key]
    }

    func setData(_ data: Data?, forKey key: String) {
        if let data { storage[key] = data } else { storage.removeValue(forKey: key) }
    }
}
