// MIProfile.swift
// UI-facing mortgage-insurance intent captured on a per-scenario
// basis. Wraps the (monthly premium, origination LTV, removal policy)
// triple so Inputs screens and Results hero cards can pass a single
// value instead of juggling the lower-level `PMISchedule` shape.
//
// For Session 5B, the monthly premium is user-entered (see
// AmortizationFormInputs.manualMonthlyPMI). A future session can add
// an auto-calc path that populates `monthlyMI` from `calculatePMI(...)`;
// the dropoff semantics stay identical so calling code doesn't need
// to change.
//
// FHA MIP is intentionally out of scope here — FHA loans with
// originating LTV > 90% carry permanent MIP which this struct can't
// represent. TODO: FHA MIP matrix (Session 7).

import Foundation

public struct MIProfile: Sendable, Hashable, Codable {
    public let monthlyMI: Decimal
    public let startLTV: Double
    /// When `true`, MI drops at 80% LTV instead of the HPA-required 78%.
    /// Requires a borrower-paid appraisal in practice; flag only here.
    public let requestRemovalAt80: Bool

    public init(
        monthlyMI: Decimal,
        startLTV: Double,
        requestRemovalAt80: Bool = false
    ) {
        self.monthlyMI = monthlyMI
        self.startLTV = startLTV
        self.requestRemovalAt80 = requestRemovalAt80
    }

    /// LTV threshold at which MI drops for this profile.
    public var dropAtLTV: Double {
        requestRemovalAt80 ? 0.80 : 0.78
    }

    /// Project this profile onto the existing engine-side
    /// `PMISchedule` shape consumed by `AmortizationOptions`. The
    /// `appraisedValue` is the origination property value; PMI drops
    /// when the *scheduled* balance crosses `dropAtLTV × appraisedValue`.
    public func asPMISchedule(appraisedValue: Decimal) -> PMISchedule {
        PMISchedule(
            monthlyAmount: monthlyMI,
            originalValue: appraisedValue,
            dropAtLTV: dropAtLTV,
            minimumPeriods: 0,
            isPermanent: false
        )
    }
}

/// First period where the scheduled balance crosses below
/// `dropAtLTV × appraisedValue` (HPA 78% by default; 80% when the
/// borrower is requesting removal with appraisal). Returns `nil` if
/// the loan never crosses the threshold — happens when the starting
/// LTV is already below the threshold, or when the term is too short
/// for the schedule to amortize down that far.
///
/// Conventional fixed-rate assumption. FHA MIP lives elsewhere.
public func miDropoffMonth(
    loanAmount: Decimal,
    appraisedValue: Decimal,
    rate: Double,
    termMonths: Int,
    requestRemovalAt80: Bool = false
) -> Int? {
    guard appraisedValue > 0, loanAmount > 0, termMonths > 0 else { return nil }
    let threshold = requestRemovalAt80 ? 0.80 : 0.78
    let cutoff = appraisedValue * Decimal(threshold)

    // If the origination balance already sits below the cutoff, MI
    // wasn't required in the first place. Nothing to drop.
    if loanAmount <= cutoff { return nil }

    let loan = Loan(
        principal: loanAmount,
        annualRate: rate,
        termMonths: termMonths,
        startDate: Date()
    )
    let schedule = amortize(loan: loan, options: .none)
    for payment in schedule.payments where payment.balance <= cutoff {
        return payment.number
    }
    return nil
}
