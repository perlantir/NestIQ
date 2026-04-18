// PropertyDownPaymentConfig.swift
// One Codable struct embedded by every calculator form (Amort / Income
// / Refi / TCA / HELOC). Carries the shared Property + down-payment +
// MI intent, so the shared `PropertyDownPaymentSection` view can edit
// any of them uniformly.
//
// Designed so forms can opt into it WITHOUT removing their existing
// loanAmount / balance fields — Session 5B.5 delivers the live LTV /
// MI input surface; the full "loan amount becomes a derived value
// from purchase price − down payment" conversion is a follow-up.
//
// Backward-compat: forms that embed this do so via `= .empty` default
// on decode, so prior scenario blobs that don't carry the key still
// round-trip cleanly.

import Foundation
import QuotientFinance

struct PropertyDownPaymentConfig: Codable, Hashable, Sendable {
    var purchasePrice: Decimal
    var downPaymentPercent: Double
    var downPaymentDollar: Decimal
    /// When true, the "$" form is the source of truth and the percent
    /// is derived. When false, the "%" form is the source of truth.
    var useDownPaymentDollar: Bool
    /// User-entered monthly MI. When the computed LTV is ≤ 80%, this
    /// value is ignored at render time regardless of what's stored.
    var manualMonthlyMI: Decimal
    /// Shortens the MI-drop trigger from the HPA-required 78% LTV to
    /// 80% LTV. Requires a borrower-paid appraisal in practice.
    var requestMIRemovalAt80: Bool

    init(
        purchasePrice: Decimal = 0,
        downPaymentPercent: Double = 0.20,
        downPaymentDollar: Decimal = 0,
        useDownPaymentDollar: Bool = false,
        manualMonthlyMI: Decimal = 0,
        requestMIRemovalAt80: Bool = false
    ) {
        self.purchasePrice = purchasePrice
        self.downPaymentPercent = downPaymentPercent
        self.downPaymentDollar = downPaymentDollar
        self.useDownPaymentDollar = useDownPaymentDollar
        self.manualMonthlyMI = manualMonthlyMI
        self.requestMIRemovalAt80 = requestMIRemovalAt80
    }

    static let empty = PropertyDownPaymentConfig()

    // MARK: Derivations

    /// Down payment amount at the current price. Source of truth is
    /// whichever form `useDownPaymentDollar` points at.
    var downPaymentAmount: Decimal {
        if useDownPaymentDollar {
            return min(downPaymentDollar, purchasePrice)
        }
        return effectiveDownPayment.amount(purchasePrice: purchasePrice)
    }

    /// Down payment as a fraction (0.20 = 20%) at the current price.
    var downPaymentPct: Double {
        effectiveDownPayment.percentage(purchasePrice: purchasePrice)
    }

    /// DownPayment primitive from the active form.
    var effectiveDownPayment: DownPayment {
        useDownPaymentDollar
            ? .dollars(downPaymentDollar)
            : .percentage(downPaymentPercent)
    }

    /// Loan amount implied by price − down payment. Clamped at 0.
    var derivedLoanAmount: Decimal {
        effectiveDownPayment.loanAmount(purchasePrice: purchasePrice)
    }

    /// Live LTV against the entered purchase price. Falls back to 0
    /// when price is 0 so the UI renders "0.0%" rather than NaN.
    func ltv(loanAmount override: Decimal? = nil) -> Double {
        guard purchasePrice > 0 else { return 0 }
        let amt = override ?? derivedLoanAmount
        return calculateLTV(loanAmount: amt, propertyValue: purchasePrice)
    }

    /// True iff the computed LTV (at the given or derived loan amount)
    /// exceeds 80%. Drives the conditional reveal of the MI field.
    func miRequired(loanAmount override: Decimal? = nil) -> Bool {
        isMIRequired(ltv: ltv(loanAmount: override))
    }

    /// Build an MIProfile for engine-layer consumption, or nil when MI
    /// is not required / not configured.
    func miProfile(loanAmount: Decimal) -> MIProfile? {
        let lt = ltv(loanAmount: loanAmount)
        guard isMIRequired(ltv: lt) else { return nil }
        return MIProfile(
            monthlyMI: manualMonthlyMI,
            startLTV: lt,
            requestRemovalAt80: requestMIRemovalAt80
        )
    }
}
