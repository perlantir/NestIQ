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
        schedule = amortize(loan: loan, options: options)
        hasComputed = true
    }

    // Derived displays pulled off the schedule for the results screen.

    var monthlyPI: Decimal {
        guard let p = schedule?.payments.first?.payment else {
            return paymentFor(loan: inputs.toLoan())
        }
        return p
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
    var ltv: Double {
        Double(truncating: (inputs.loanAmount / inputs.propertyValueGuess) as NSNumber)
    }

    /// One yearly sample of the outstanding balance — used by the
    /// Balance-over-time chart on the results screen.
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
        if result.last?.0 != inputs.termYears {
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
