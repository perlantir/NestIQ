// SelfEmploymentInputs.swift
// Codable payload for a Self-Employment Income scenario. Stored in
// Scenario.inputsJSON when saved standalone; returned as inline
// bridge data when invoked as an income source from IncomeQual.

import Foundation
import QuotientFinance

struct SelfEmploymentFormInputs: Codable, Hashable, Sendable {
    /// Which subform of Fannie 1084 the LO is running.
    var businessType: BusinessType
    /// Schedule C year-1 / year-2 values. Always defined so switching
    /// between business types preserves per-type draft state without
    /// losing the other entries.
    var scheduleCY1: ScheduleCYear
    var scheduleCY2: ScheduleCYear
    var form1120SY1: Form1120SYear
    var form1120SY2: Form1120SYear
    var form1065Y1: Form1065Year
    var form1065Y2: Form1065Year

    enum CodingKeys: String, CodingKey {
        case businessType
        case scheduleCY1, scheduleCY2
        case form1120SY1, form1120SY2
        case form1065Y1, form1065Y2
    }

    init(
        businessType: BusinessType = .scheduleC,
        scheduleCY1: ScheduleCYear = .blankScheduleC(year: 2023),
        scheduleCY2: ScheduleCYear = .blankScheduleC(year: 2024),
        form1120SY1: Form1120SYear = .blank1120S(year: 2023),
        form1120SY2: Form1120SYear = .blank1120S(year: 2024),
        form1065Y1: Form1065Year = .blank1065(year: 2023),
        form1065Y2: Form1065Year = .blank1065(year: 2024)
    ) {
        self.businessType = businessType
        self.scheduleCY1 = scheduleCY1
        self.scheduleCY2 = scheduleCY2
        self.form1120SY1 = form1120SY1
        self.form1120SY2 = form1120SY2
        self.form1065Y1 = form1065Y1
        self.form1065Y2 = form1065Y2
    }

    static let sampleDefault = SelfEmploymentFormInputs()

    /// Current analysis input, derived from the active business type.
    var currentInput: SelfEmploymentInput {
        switch businessType {
        case .scheduleC:
            return .scheduleC(y1: scheduleCY1, y2: scheduleCY2)
        case .form1120S:
            return .form1120S(y1: form1120SY1, y2: form1120SY2)
        case .form1065:
            return .form1065(y1: form1065Y1, y2: form1065Y2)
        }
    }
}

extension ScheduleCYear {
    static func blankScheduleC(year: Int) -> ScheduleCYear {
        ScheduleCYear(year: year, netProfit: 0)
    }
}

extension Form1120SYear {
    static func blank1120S(year: Int) -> Form1120SYear {
        Form1120SYear(year: year, ownershipPercent: 1.0)
    }
}

extension Form1065Year {
    static func blank1065(year: Int) -> Form1065Year {
        Form1065Year(year: year, ownershipPercent: 0.50)
    }
}
