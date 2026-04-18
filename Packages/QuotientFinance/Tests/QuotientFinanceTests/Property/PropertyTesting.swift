// PropertyTesting.swift
//
// Minimal property-based testing harness for the QuotientFinance test suite.
// Lives in the test target only — no production dependency.
//
// Design:
//   - `SeededPRNG`: a SplitMix64 RNG. Seeded, deterministic — same seed
//     yields the exact same sequence of inputs on every run and every
//     machine, so test failures reproduce bit-for-bit from a seed and
//     iteration index printed in the failure message.
//   - `forAll(...)`: iterates a generator `count` times, passes each
//     generated value to the body, and on failure re-runs the body on
//     progressively "smaller" inputs (the `shrink(_:)` hook) until none
//     fails. Reports both the failing iteration's original input and the
//     minimal shrunk input, plus the seed so it's reproducible.
//
// Usage:
//   try forAll(
//       "30yr fixed amortization",
//       generator: LoanGen.standardFixed,
//       count: 1000,
//       shrink: LoanGen.shrink
//   ) { loan in
//       let schedule = amortize(loan: loan)
//       try require(schedule.payments.last?.balance == 0,
//                   "final balance non-zero for loan \(loan)")
//   }

import Foundation

// MARK: - PRNG

/// Deterministic SplitMix64 — same seed produces the same sequence on any
/// platform. Small, fast, good statistical properties for testing.
struct SeededPRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Uniform in [low, high).
    mutating func double(in range: ClosedRange<Double>) -> Double {
        Double.random(in: range, using: &self)
    }
    mutating func int(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &self)
    }
}

// MARK: - Failure type

struct PropertyFailure: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

/// Assert within a property-test body. Throws on failure so the outer
/// `forAll` can catch, shrink, and report.
func require(_ condition: Bool, _ message: @autoclosure () -> String = "") throws {
    if !condition { throw PropertyFailure(message: message()) }
}

// MARK: - forAll

struct PropertyTestFailed: Error, CustomStringConvertible {
    let label: String
    let seed: UInt64
    let iteration: Int
    let originalInput: String
    let shrunkInput: String
    let underlying: Error
    var description: String {
        """
        [\(label)] property failed on iteration \(iteration) (seed 0x\(String(seed, radix: 16))):
          original input: \(originalInput)
          shrunk input:   \(shrunkInput)
          assertion:      \(underlying)
        """
    }
}

/// Run `body` on `count` randomly-generated inputs. On failure, shrink the
/// counterexample by repeatedly applying `shrink` until no smaller failing
/// input can be found, then throw a failure that includes both the
/// original and shrunk values plus the seed for reproduction.
func forAll<Input>(
    _ label: String,
    generator: (inout SeededPRNG) -> Input,
    count: Int = 1_000,
    seed: UInt64 = 0xD1_EC_5E_ED,
    shrink: (Input) -> [Input] = { _ in [] },
    _ body: (Input) throws -> Void
) throws {
    var rng = SeededPRNG(seed: seed)
    for i in 0..<count {
        let original = generator(&rng)
        do {
            try body(original)
        } catch {
            var smallest = original
            var underlying = error
            shrinking: while true {
                for candidate in shrink(smallest) {
                    do {
                        try body(candidate)
                    } catch let e {
                        smallest = candidate
                        underlying = e
                        continue shrinking
                    }
                }
                break
            }
            throw PropertyTestFailed(
                label: label,
                seed: seed,
                iteration: i,
                originalInput: String(describing: original),
                shrunkInput: String(describing: smallest),
                underlying: underlying
            )
        }
    }
}
