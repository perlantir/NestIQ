// Rates.swift
// Rate conversions and blended-rate math.
//
// All rates are expressed as decimal fractions (6.75% → 0.0675).

import Foundation

/// Effective annual rate (EAR) implied by a nominal rate compounded
/// `compoundingsPerYear` times per year.
///
/// Formula: `EAR = (1 + r_nominal / m)^m − 1`
///
/// Day-count convention: assumes `nominalRate` is already expressed for the
/// chosen compounding convention (e.g. a monthly-compounded APR passed as
/// nominal gives the EAR directly).
public func effectiveRate(nominalRate: Double, compoundingsPerYear: Int) -> Double {
    guard compoundingsPerYear > 0 else { return 0 }
    if nominalRate == 0 { return 0 }
    let m = Double(compoundingsPerYear)
    return pow(1.0 + nominalRate / m, m) - 1.0
}

/// Alias for `effectiveRate` — the explicit name used in DEVELOPMENT.md.
public func nominalToEffective(nominalRate: Double, compoundingsPerYear: Int) -> Double {
    effectiveRate(nominalRate: nominalRate, compoundingsPerYear: compoundingsPerYear)
}

/// Nominal rate that produces a given effective annual rate under
/// `compoundingsPerYear` compounding.
///
/// Formula: `r_nominal = m × ((1 + EAR)^(1/m) − 1)`
public func effectiveToNominal(effectiveRate: Double, compoundingsPerYear: Int) -> Double {
    guard compoundingsPerYear > 0, effectiveRate > -1 else { return 0 }
    if effectiveRate == 0 { return 0 }
    let m = Double(compoundingsPerYear)
    return m * (pow(1.0 + effectiveRate, 1.0 / m) - 1.0)
}

/// A tranche of a blended-rate calculation: balance and its note rate.
public struct RateTranche: Sendable, Hashable, Codable {
    public let balance: Decimal
    public let annualRate: Double

    public init(balance: Decimal, annualRate: Double) {
        self.balance = balance
        self.annualRate = annualRate
    }
}

/// Principal-weighted blended rate across several tranches.
///
/// Formula: `r_blended = Σ(Pᵢ × rᵢ) / Σ Pᵢ`
///
/// Use for combined first-lien + HELOC scenarios where the effective cost of
/// capital is what matters, not the individual rates.
public func blendedRate(tranches: [RateTranche]) -> Double {
    guard !tranches.isEmpty else { return 0 }
    let totalBalance = tranches.reduce(Decimal(0)) { $0 + $1.balance }
    guard totalBalance > 0 else { return 0 }

    let weightedSum = tranches.reduce(0.0) { acc, t in
        acc + t.balance.asDouble * t.annualRate
    }
    return weightedSum / totalBalance.asDouble
}
