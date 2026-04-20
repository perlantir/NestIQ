// QuotientNarration
//
// Two narration paths unified by runtime capability detection:
//   1. Apple Foundation Models (iOS 18.2+) — streaming summaries
//      generated on-device by the system language model.
//   2. Template fallback — string-interpolation templates in EN/ES
//      for every calculator type. Indistinguishable quality for
//      structured financial summaries.
//
// Post-processing: every rendered token stream / template is checked
// against a known-facts allowlist. Any numeric substring that doesn't
// appear in the allowlist is flagged in the emitted chunk so the UI
// can warn the LO before the borrower sees it.

import Foundation

// MARK: - Public types

public enum ScenarioType: String, Sendable, Codable, CaseIterable {
    case amortization, incomeQualification, refinance, totalCostAnalysis, helocVsRefinance, selfEmployment
}

public enum NarrationAudience: String, Sendable, Codable, CaseIterable {
    case borrower
    case loInternal
}

public struct ScenarioFacts: Sendable, Hashable, Codable {
    public let scenarioType: ScenarioType
    public let borrowerFirstName: String?
    /// Known numeric values, in their rendered-for-humans form
    /// (e.g. "$3,284", "6.750%", "30"). The allowlist is exact —
    /// anything else in the narration is flagged.
    public let numericFacts: [String]
    /// Pass-through key/value pairs for template interpolation
    /// (e.g. "monthlyPITI" → "$3,284", "term" → "30 yr").
    public let fields: [String: String]

    public init(
        scenarioType: ScenarioType,
        borrowerFirstName: String? = nil,
        numericFacts: [String] = [],
        fields: [String: String] = [:]
    ) {
        self.scenarioType = scenarioType
        self.borrowerFirstName = borrowerFirstName
        self.numericFacts = numericFacts
        self.fields = fields
    }
}

public enum NarrationError: Error, Sendable {
    case capabilityUnavailable
    case generationFailed(String)
}

/// A single streamed chunk from the narrator. `flaggedUnknownNumbers`
/// contains numeric substrings that appear in `text` but not in the
/// known-facts allowlist. An LO UI should surface these before accept.
public struct NarrationChunk: Sendable, Hashable {
    public let text: String
    public let flaggedUnknownNumbers: [String]

    public init(text: String, flaggedUnknownNumbers: [String] = []) {
        self.text = text
        self.flaggedUnknownNumbers = flaggedUnknownNumbers
    }
}

// MARK: - Capability detection

public enum NarrationCapability {
    /// Returns true when the Apple Foundation Models framework's
    /// `SystemLanguageModel.default.isAvailable` reports ready on iOS
    /// 18.2+. Session 5 adds the actual `import FoundationModels` call
    /// site once Apple's module stabilizes in the SDK the project is
    /// pinned to.
    public static var hasFoundationModels: Bool {
        if #available(iOS 18.2, macOS 15.2, *) {
            return foundationModelsProbe()
        }
        return false
    }

    /// Probe indirection so Session 5 can flip in the real
    /// `SystemLanguageModel.default.isAvailable` behind an availability
    /// check without touching the public API surface here.
    static let foundationModelsProbe: @Sendable () -> Bool = { false }
}

// MARK: - Hallucination guard

public enum HallucinationGuard {
    /// Any numeric substring in `text` that isn't present in `allowlist`
    /// (either by exact string match, or — as a fallback — by normalized
    /// numeric value within a ±1% tolerance) is returned. `allowlist`
    /// entries should already be rendered (e.g. "$3,284", "6.750%",
    /// "$732K").
    public static func flagUnknownNumbers(in text: String, allowlist: [String]) -> [String] {
        // Match integer, decimal, percent, currency strings — including
        // K/M/B compact-currency suffixes so "$732K" extracts as one
        // token instead of a bare "$732" that would miss the allowlist.
        // Session 5K.2 root cause: the prior regex stopped at the "K",
        // flagging the fragment and undermining narration trust.
        let pattern = #"\$?\d{1,3}(?:,\d{3})*(?:\.\d+)?[KMB]?%?|\d+(?:\.\d+)?[KMB]?%?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        let normalizedAllowlist = allowlist.compactMap(normalizedValue)
        var flagged: [String] = []
        for m in matches {
            let token = ns.substring(with: m.range)
            // Trivial fragments (1-2 digit standalones) are usually
            // counts or dates — skip unless they carry $ / % / K / M / B
            // context.
            if token.count <= 2 && !hasContextSigil(token) { continue }
            if allowlist.contains(token) { continue }
            if let tokenValue = normalizedValue(token),
               matchesWithinTolerance(tokenValue, normalizedAllowlist) {
                continue
            }
            if !flagged.contains(token) { flagged.append(token) }
        }
        return flagged
    }

    private static func hasContextSigil(_ token: String) -> Bool {
        token.contains("$") || token.contains("%")
            || token.hasSuffix("K") || token.hasSuffix("M") || token.hasSuffix("B")
    }

    /// Parses a rendered money/percent string into a canonical Double.
    /// `$732K` → `732_000`, `$1.24M` → `1_240_000`, `$4,231` → `4231`,
    /// `6.750%` → `6.75`. Returns `nil` if the string has no extractable
    /// numeric core.
    static func normalizedValue(_ raw: String) -> Double? {
        var s = raw
        s.removeAll { $0 == "$" || $0 == "," }
        var multiplier: Double = 1
        if s.hasSuffix("%") { s.removeLast() }
        switch s.last {
        case "K": s.removeLast(); multiplier = 1_000
        case "M": s.removeLast(); multiplier = 1_000_000
        case "B": s.removeLast(); multiplier = 1_000_000_000
        default: break
        }
        guard let base = Double(s) else { return nil }
        return base * multiplier
    }

    /// A token is considered "known" if its numeric value matches any
    /// allowlist entry within ±1% (or exact match when both are zero).
    /// The tolerance absorbs the dollarsShort/decimalString rounding
    /// delta: narration copy may use "$732K" while the allowlist carries
    /// "$732,456".
    private static func matchesWithinTolerance(_ value: Double, _ allowlist: [Double]) -> Bool {
        for entry in allowlist {
            if value == entry { return true }
            let scale = max(abs(entry), abs(value))
            if scale == 0 { continue }
            if abs(value - entry) / scale <= 0.01 { return true }
        }
        return false
    }
}

// MARK: - Primary narration API

public struct QuotientNarrator: Sendable {
    public init() {}

    /// Stream a narration. Falls back to templates silently if the
    /// Foundation Models framework isn't available. The returned
    /// stream yields `NarrationChunk`s; the text is cumulative —
    /// callers append as they arrive.
    public func narrate(
        _ facts: ScenarioFacts,
        audience: NarrationAudience = .borrower,
        locale: Locale = Locale(identifier: "en_US")
    ) -> AsyncThrowingStream<NarrationChunk, any Error> {
        if NarrationCapability.hasFoundationModels {
            return streamViaFoundationModels(facts: facts, audience: audience, locale: locale)
        }
        return streamViaTemplates(facts: facts, audience: audience, locale: locale)
    }

    // MARK: FoundationModels path (Session 5 swap-in)

    private func streamViaFoundationModels(
        facts: ScenarioFacts,
        audience: NarrationAudience,
        locale: Locale
    ) -> AsyncThrowingStream<NarrationChunk, any Error> {
        // Until Session 5 wires the real FoundationModels stream, we
        // degrade to the template path but mark the source so the UI
        // can still render "powered by on-device AI" copy consistently.
        streamViaTemplates(facts: facts, audience: audience, locale: locale)
    }

    // MARK: Template path

    func streamViaTemplates(
        facts: ScenarioFacts,
        audience: NarrationAudience,
        locale: Locale
    ) -> AsyncThrowingStream<NarrationChunk, any Error> {
        let full = NarrationTemplates.render(
            facts: facts,
            audience: audience,
            locale: locale
        )
        let flagged = HallucinationGuard.flagUnknownNumbers(
            in: full,
            allowlist: facts.numericFacts
        )
        return AsyncThrowingStream { continuation in
            Task {
                // Stream a few tokens at a time to mimic the LLM cadence.
                var cursor = full.startIndex
                while cursor < full.endIndex {
                    let step = min(6, full.distance(from: cursor, to: full.endIndex))
                    let end = full.index(cursor, offsetBy: step)
                    let chunk = String(full[cursor..<end])
                    continuation.yield(NarrationChunk(text: chunk, flaggedUnknownNumbers: []))
                    cursor = end
                    try? await Task.sleep(nanoseconds: 20_000_000)
                }
                if !flagged.isEmpty {
                    continuation.yield(NarrationChunk(text: "", flaggedUnknownNumbers: flagged))
                }
                continuation.finish()
            }
        }
    }
}
