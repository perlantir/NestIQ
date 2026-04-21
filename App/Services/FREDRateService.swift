// FREDRateService.swift
// Session 6.4 — Live Freddie Mac PMMS rates via the Federal Reserve
// Economic Data (FRED) API at the Federal Reserve Bank of St. Louis.
//
// Policy:
//   - Two series: MORTGAGE30US, MORTGAGE15US.
//   - Fetch the last two observations per series so the widget can
//     show a week-over-week delta + up/down/flat arrow.
//   - Cache each series in UserDefaults with a 24 h staleness window.
//     Cached values render immediately on launch; a stale cache kicks
//     off a background refresh but the UI never blocks.
//   - On cache miss and fetch failure, fall back to the hardcoded Apr 16
//     2026 constants so the widget is never empty. `isFallback` on the
//     resulting RateReport triggers the "· offline" eyebrow suffix.
//   - URLSession.shared with a 10 s timeout, zero retries. This is a
//     non-critical informational widget, not a calculator path.

import Foundation

// MARK: - FRED JSON shape

struct FREDObservationsResponse: Decodable {
    let observations: [FREDObservation]
}

struct FREDObservation: Decodable {
    let date: String  // "YYYY-MM-DD"
    let value: String // "6.30" or "." for missing
}

// MARK: - Rate observation

/// Single FRED observation in typed form. Decimal preserves the wire
/// precision so the cache round-trip doesn't drift.
struct RateObservation: Sendable, Hashable, Codable {
    let rate: Decimal
    let observationDate: Date
    let series: String
}

// MARK: - Cache entry

struct CachedRateEntry: Codable {
    let current: RateObservation
    let prior: RateObservation?
    let fetchedAt: Date
}

// MARK: - Networking seam

/// Protocol-based seam so tests can inject canned responses without
/// hitting the network. Production uses URLSessionRateFetcher.
protocol RateFetching: Sendable {
    func fetch(_ url: URL) async throws -> Data
}

struct URLSessionRateFetcher: RateFetching {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let (data, _) = try await session.data(for: request)
        return data
    }
}

// MARK: - Cache storage seam

protocol RateCacheStore: Sendable {
    func data(forKey key: String) -> Data?
    func setData(_ data: Data?, forKey key: String)
}

/// `UserDefaults` is thread-safe but not marked Sendable by Foundation,
/// so wrap the reference behind `@unchecked Sendable` with the
/// thread-safety promise documented.
struct UserDefaultsRateCacheStore: RateCacheStore, @unchecked Sendable {
    let defaults: UserDefaults

    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    func setData(_ data: Data?, forKey key: String) {
        defaults.set(data, forKey: key)
    }
}

// MARK: - FREDRateService

struct FREDRateService: RateService {

    // MARK: Series definitions

    struct Series: Sendable, Hashable {
        let id: String       // "MORTGAGE30US"
        let label: String    // "30-yr fixed"
        let cacheKey: String // "rate.30yr.cached"
    }

    static let series30yr = Series(
        id: "MORTGAGE30US",
        label: "30-yr fixed",
        cacheKey: "rate.30yr.cached"
    )

    static let series15yr = Series(
        id: "MORTGAGE15US",
        label: "15-yr fixed",
        cacheKey: "rate.15yr.cached"
    )

    // MARK: Fallback constants

    static let fallback30yr: Double = 6.30
    static let fallback15yr: Double = 5.65
    static let fallbackAsOf: Date = {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 4
        comps.day = 16
        comps.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: comps) ?? Date(timeIntervalSince1970: 0)
    }()

    // MARK: Config

    static let cacheTTL: TimeInterval = 24 * 60 * 60
    /// A delta is considered "flat" below this magnitude (in percentage
    /// points). 0.01 matches the 2dp display precision.
    static let flatThreshold: Double = 0.01

    // MARK: Dependencies

    private let fetcher: any RateFetching
    private let cache: any RateCacheStore
    private let apiKey: String
    private let now: @Sendable () -> Date

    init(
        fetcher: any RateFetching = URLSessionRateFetcher(),
        cache: any RateCacheStore = UserDefaultsRateCacheStore(defaults: .standard),
        apiKey: String = FREDRateService.readBundleAPIKey(),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.fetcher = fetcher
        self.cache = cache
        self.apiKey = apiKey
        self.now = now
    }

    // MARK: Public entry point

    func fetchSnapshot() async throws -> RateReport {
        async let s30 = snapshot(for: Self.series30yr)
        async let s15 = snapshot(for: Self.series15yr)
        let (a, b) = await (s30, s15)
        let anyFallback = a.isFallback || b.isFallback
        let asOf = [a.observationDate, b.observationDate].compactMap { $0 }.max() ?? Self.fallbackAsOf
        return RateReport(
            rates: [a.snapshot, b.snapshot],
            asOf: asOf,
            isFallback: anyFallback
        )
    }

    // MARK: - Per-series resolution

    private struct SeriesSnapshot {
        let snapshot: RateSnapshot
        let observationDate: Date?
        let isFallback: Bool
    }

    private func snapshot(for series: Series) async -> SeriesSnapshot {
        if let cached = loadCache(for: series), !isStale(cached) {
            return resolve(cached: cached, series: series)
        }
        if let fresh = try? await fetchAndStore(series: series) {
            return resolve(cached: fresh, series: series)
        }
        if let cached = loadCache(for: series) {
            return resolve(cached: cached, series: series)
        }
        return fallback(for: series)
    }

    // MARK: - Fetch + store

    private func fetchAndStore(series: Series) async throws -> CachedRateEntry {
        let url = Self.endpoint(seriesID: series.id, apiKey: apiKey)
        let data = try await fetcher.fetch(url)
        let observations = try parseObservations(data: data, series: series.id)
        let entry = CachedRateEntry(
            current: observations.current,
            prior: observations.prior,
            fetchedAt: now()
        )
        storeCache(entry, for: series)
        return entry
    }

    struct ParsedObservations {
        let current: RateObservation
        let prior: RateObservation?
    }

    func parseObservations(data: Data, series: String) throws -> ParsedObservations {
        let decoded = try JSONDecoder().decode(FREDObservationsResponse.self, from: data)
        let numeric = decoded.observations.compactMap { obs -> RateObservation? in
            guard let rate = Decimal(string: obs.value),
                  let date = Self.yyyyMMddFormatter.date(from: obs.date) else {
                return nil
            }
            return RateObservation(rate: rate, observationDate: date, series: series)
        }
        guard let current = numeric.first else {
            throw FREDError.noObservations
        }
        let prior = numeric.dropFirst().first
        return ParsedObservations(current: current, prior: prior)
    }

    // MARK: - Cache I/O

    private func loadCache(for series: Series) -> CachedRateEntry? {
        guard let data = cache.data(forKey: series.cacheKey) else { return nil }
        return try? JSONDecoder().decode(CachedRateEntry.self, from: data)
    }

    private func storeCache(_ entry: CachedRateEntry, for series: Series) {
        let data = try? JSONEncoder().encode(entry)
        cache.setData(data, forKey: series.cacheKey)
    }

    private func isStale(_ entry: CachedRateEntry) -> Bool {
        now().timeIntervalSince(entry.fetchedAt) > Self.cacheTTL
    }

    // MARK: - Resolution helpers

    private func resolve(cached: CachedRateEntry, series: Series) -> SeriesSnapshot {
        let currentDouble = Self.decimalToDouble(cached.current.rate)
        let snapshot: RateSnapshot
        if let prior = cached.prior {
            let priorDouble = Self.decimalToDouble(prior.rate)
            let delta = Self.roundedDelta(current: currentDouble, prior: priorDouble)
            snapshot = RateSnapshot(
                name: series.label,
                rate: currentDouble,
                delta: delta,
                move: Self.move(for: delta),
                hasPriorObservation: true
            )
        } else {
            snapshot = RateSnapshot(
                name: series.label,
                rate: currentDouble,
                delta: 0,
                move: .flat,
                hasPriorObservation: false
            )
        }
        return SeriesSnapshot(
            snapshot: snapshot,
            observationDate: cached.current.observationDate,
            isFallback: false
        )
    }

    private func fallback(for series: Series) -> SeriesSnapshot {
        let rate = series.id == Self.series30yr.id ? Self.fallback30yr : Self.fallback15yr
        let snapshot = RateSnapshot(
            name: series.label,
            rate: rate,
            delta: 0,
            move: .flat,
            hasPriorObservation: false
        )
        return SeriesSnapshot(
            snapshot: snapshot,
            observationDate: Self.fallbackAsOf,
            isFallback: true
        )
    }

    // MARK: - Math helpers

    static func roundedDelta(current: Double, prior: Double) -> Double {
        let raw = current - prior
        return (raw * 100).rounded() / 100
    }

    static func move(for delta: Double) -> RateSnapshot.Move {
        if abs(delta) < flatThreshold { return .flat }
        return delta > 0 ? .up : .down
    }

    static func decimalToDouble(_ decimal: Decimal) -> Double {
        NSDecimalNumber(decimal: decimal).doubleValue
    }

    // MARK: - URL + key

    /// Fallback used if the hard-coded base string ever becomes unparsable
    /// — compile-time known valid, so this is defensive rather than
    /// reachable in practice.
    private static let fallbackEndpoint = URL(fileURLWithPath: "/")

    static func endpoint(seriesID: String, apiKey: String) -> URL {
        guard var components = URLComponents(
            string: "https://api.stlouisfed.org/fred/series/observations"
        ) else {
            return fallbackEndpoint
        }
        components.queryItems = [
            URLQueryItem(name: "series_id", value: seriesID),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_type", value: "json"),
            URLQueryItem(name: "sort_order", value: "desc"),
            URLQueryItem(name: "limit", value: "2")
        ]
        return components.url ?? fallbackEndpoint
    }

    static func readBundleAPIKey() -> String {
        Bundle.main.object(forInfoDictionaryKey: "FREDAPIKey") as? String ?? ""
    }

    // MARK: - Formatters

    private static let yyyyMMddFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
}

// MARK: - Errors

enum FREDError: Error, Equatable {
    case noObservations
}
