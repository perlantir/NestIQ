// AmortizationViewModel.swift
// Owns the inputs + derived schedule. `@Observable` lets the results
// screen re-render whenever any input changes — which is what makes the
// "results update live" behavior per the design README cheap.

import Foundation
import Observation
import QuotientFinance

@MainActor
@Observable
final class AmortizationViewModel {
    var inputs: AmortizationFormInputs
    var borrower: Borrower?
    var schedule: AmortizationSchedule?
    var computeError: String?

    /// Set to true once the user has hit Compute at least once; after
    /// that every input edit re-runs the engine automatically.
    var hasComputed: Bool = false

    init(inputs: AmortizationFormInputs = .sampleDefault, borrower: Borrower? = nil) {
        self.inputs = inputs
        self.borrower = borrower
    }

    func compute() {
        let loan = inputs.toLoan()
        let options = inputs.toOptions()
        let monthly = amortize(loan: loan, options: options)
        // Biweekly toggle wires to the accelerated engine primitive — pay
        // monthlyPMT/2 every 14 days until balance=0 — NOT the "same term
        // over 780 periods" convertToBiweekly re-slice. See Biweekly.swift.
        schedule = inputs.biweekly ? biweeklyAccelerated(schedule: monthly) : monthly
        monthlyScheduleForReference = inputs.biweekly ? monthly : nil
        hasComputed = true
    }

    /// Monthly-cadence schedule for the same loan, preserved when the
    /// borrower has the biweekly toggle on so the Results view can show
    /// "monthly equivalent $X" alongside the accelerated schedule.
    var monthlyScheduleForReference: AmortizationSchedule?

    // Derived displays pulled off the schedule for the results screen.

    /// Monthly principal + interest. Always the monthly-equivalent amount —
    /// when the biweekly toggle is on, `schedule.payments.first.payment` is
    /// the biweekly payment (half of this), so we pull from the monthly
    /// reference schedule (or fall back to a fresh engine compute).
    var monthlyPI: Decimal {
        if inputs.biweekly, let ref = monthlyScheduleForReference?.payments.first {
            return ref.payment
        }
        if !inputs.biweekly, let p = schedule?.payments.first?.payment {
            return p
        }
        return paymentFor(loan: inputs.toLoan())
    }

    /// Biweekly scheduled payment (= monthlyPI / 2 rounded to cents). Only
    /// meaningful when `inputs.biweekly == true`; returns 0 otherwise.
    var biweeklyPayment: Decimal {
        guard inputs.biweekly else { return 0 }
        if let p = schedule?.payments.first?.payment { return p }
        return (paymentFor(loan: inputs.toLoan()) / 2).money()
    }

    /// Calendar months shaved off the monthly-schedule payoff by turning on
    /// biweekly acceleration. 0 when the toggle is off or when no reference
    /// is available.
    var biweeklyMonthsSaved: Int {
        guard inputs.biweekly,
              let ref = monthlyScheduleForReference?.payments.last?.date,
              let cur = schedule?.payments.last?.date else { return 0 }
        return Calendar(identifier: .gregorian)
            .dateComponents([.month], from: cur, to: ref).month ?? 0
    }

    /// Interest saved vs the monthly reference schedule for the same loan.
    /// 0 when the biweekly toggle is off.
    var biweeklyInterestSaved: Decimal {
        guard inputs.biweekly,
              let ref = monthlyScheduleForReference else { return 0 }
        return max(ref.totalInterest - totalInterest, 0)
    }

    var monthlyTax: Decimal { inputs.annualTaxes / 12 }
    var monthlyInsurance: Decimal { inputs.annualInsurance / 12 }
    var monthlyHOA: Decimal { inputs.monthlyHOA }
    var monthlyPMI: Decimal {
        guard inputs.includePMI, let first = schedule?.payments.first else { return 0 }
        return first.pmi
    }

    var monthlyPITI: Decimal {
        monthlyPI + monthlyTax + monthlyInsurance + monthlyHOA + monthlyPMI
    }

    var totalInterest: Decimal { schedule?.totalInterest ?? 0 }
    var totalPaid: Decimal { schedule?.totalPayments ?? 0 }
    var payoffDate: Date? { schedule?.payoffDate }

    /// First payment period where the scheduled balance crosses the
    /// MI-drop threshold (78% LTV by default, 80% when requested).
    /// Derived from the Property & down-payment config when set, or
    /// the legacy 125%-of-loan property guess otherwise. nil when MI
    /// isn't active or never crosses.
    var miDropoffPeriod: Int? {
        guard inputs.includePMI, inputs.manualMonthlyPMI > 0 else { return nil }
        let appraised = inputs.propertyDP.purchasePrice > 0
            ? inputs.propertyDP.purchasePrice
            : inputs.propertyValueGuess
        return miDropoffMonth(
            loanAmount: inputs.loanAmount,
            appraisedValue: appraised,
            rate: inputs.annualRate / 100,
            termMonths: inputs.termYears * 12,
            requestRemovalAt80: inputs.propertyDP.requestMIRemovalAt80
        )
    }

    /// Month-level date for the dropoff period.
    var miDropoffDate: Date? {
        guard let period = miDropoffPeriod,
              let payment = schedule?.payments.first(where: { $0.number == period })
        else { return nil }
        return payment.date
    }

    /// Total MI paid over the life of the loan up through dropoff.
    /// Computed from the manual monthly PMI × dropoff period count
    /// (engine-side schedule.pmi is still zero because 5B.3 doesn't
    /// attach a PMISchedule for the manual path — Session 5B.5.5
    /// lays the MIProfile groundwork; wiring into amortize() arrives
    /// in a follow-up).
    var totalMIPaid: Decimal {
        guard inputs.includePMI, inputs.manualMonthlyPMI > 0 else { return 0 }
        let period = miDropoffPeriod ?? (inputs.termYears * 12)
        return inputs.manualMonthlyPMI * Decimal(period)
    }
    var ltv: Double {
        Double(truncating: (inputs.loanAmount / inputs.propertyValueGuess) as NSNumber)
    }

    /// One yearly sample of the outstanding balance — used by the
    /// Balance-over-time chart on the results screen.
    ///
    /// When the schedule terminates off a year boundary (extra principal
    /// or a lump-sum recast retired the loan mid-year), anchor the final
    /// point at the actual payoff year rather than padding out to the
    /// scheduled `termYears` — otherwise the chart would draw a phantom
    /// linear tail from the true payoff year to the scheduled end.
    var yearlyBalances: [(year: Int, balance: Decimal)] {
        guard let sched = schedule else { return [] }
        var result: [(Int, Decimal)] = [(0, inputs.loanAmount)]
        let payments = sched.payments
        let perYear = max(1, inputs.biweekly ? 26 : 12)
        var yearIndex = 1
        var cursor = perYear
        while cursor <= payments.count {
            let bal = payments[cursor - 1].balance
            result.append((yearIndex, bal))
            cursor += perYear
            yearIndex += 1
        }
        let lastFullYearCursor = cursor - perYear
        if lastFullYearCursor < payments.count, let finalPayment = payments.last {
            let payoffYear = Int(ceil(Double(payments.count) / Double(perYear)))
            result.append((payoffYear, finalPayment.balance))
        } else if result.last?.1 != 0 {
            result.append((inputs.termYears, 0))
        }
        return result
    }

    struct ScenarioSnapshot {
        let inputsJSON: Data
        let outputsJSON: Data?
        let keyStat: String
    }

    func buildScenario() -> ScenarioSnapshot {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let inputsJSON: Data
        do {
            inputsJSON = try encoder.encode(inputs)
        } catch {
            inputsJSON = Data()
        }
        var outputsJSON: Data?
        if let schedule {
            outputsJSON = try? encoder.encode(ResultSnapshot(schedule: schedule))
        }
        let key = "$\(format(inputs.loanAmount)) · \(inputs.termYears)-yr · "
            + "\(String(format: "%.3f", inputs.annualRate))%"
        return ScenarioSnapshot(inputsJSON: inputsJSON, outputsJSON: outputsJSON, keyStat: key)
    }

    private func format(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: d as NSNumber) ?? "\(d)"
    }
}

// Minimal slice of the result preserved for offline display. The engine
// can always re-derive the full schedule from the inputs — this blob
// just keeps the "what did I see when I saved?" snapshot available so
// the Saved list can show key stats instantly without re-running.
struct ResultSnapshot: Codable, Hashable, Sendable {
    let totalInterest: Decimal
    let totalPayments: Decimal
    let paymentCount: Int
    let payoffDate: Date?

    init(schedule: AmortizationSchedule) {
        self.totalInterest = schedule.totalInterest
        self.totalPayments = schedule.totalPayments
        self.paymentCount = schedule.payments.count
        self.payoffDate = schedule.payoffDate
    }
}
