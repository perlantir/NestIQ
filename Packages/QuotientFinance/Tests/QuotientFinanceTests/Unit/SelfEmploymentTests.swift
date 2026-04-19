// SelfEmploymentTests.swift
// Fannie 1084 subset — Schedule C, 1120S K-1, 1065 K-1, 2-year averaging,
// and trend classification. Property tests focus on the Fannie-specific
// eligibility rules (25% ownership × distribution history) and the
// lower-year-on-decline qualifying rule.

import Testing
import Foundation
@testable import QuotientFinance

@Suite("Schedule C cash flow")
struct ScheduleCCashFlowTests {

    @Test("Baseline: netProfit alone equals cash flow when every other field is zero")
    func baseline() {
        let y = ScheduleCYear(year: 2024, netProfit: 120_000)
        #expect(cashFlowScheduleC(y) == 120_000)
    }

    @Test("Depreciation, depletion, business-use-of-home, amortization all add back")
    func addbacks() {
        let y = ScheduleCYear(
            year: 2024,
            netProfit: 100_000,
            depletion: 1_000,
            depreciation: 4_500,
            businessUseOfHome: 3_200,
            amortizationOrCasualtyLoss: 800,
            mileageDepreciation: 2_500
        )
        // 100k + 0 + 1k + 4.5k - 0 + 3.2k + 0.8k + 2.5k = 112_000
        #expect(cashFlowScheduleC(y) == 112_000)
    }

    @Test("Non-deductible meals subtract from cash flow")
    func mealsSubtract() {
        let y = ScheduleCYear(
            year: 2024,
            netProfit: 100_000,
            nonDeductibleMealsAndEntertainment: 2_500
        )
        #expect(cashFlowScheduleC(y) == 97_500)
    }

    @Test("Negative net profit (loss year) carries through")
    func lossYear() {
        let y = ScheduleCYear(
            year: 2024,
            netProfit: -25_000,
            depreciation: 10_000
        )
        // -25k + 10k = -15k — addbacks don't mask a net loss
        #expect(cashFlowScheduleC(y) == -15_000)
    }

    @Test("Fannie B3-3.6-03 published example: $60k net profit + $5k depreciation → $65k")
    func fanniePublishedExample() {
        let y = ScheduleCYear(
            year: 2024,
            netProfit: 60_000,
            depreciation: 5_000
        )
        #expect(cashFlowScheduleC(y) == 65_000)
    }

    @Test("Property: netProfit X + depreciation Y (alone) == X + Y for 500 random cases")
    func propertyDepreciationAddsBack() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<500 {
            let x = Decimal(Int.random(in: -200_000...500_000, using: &rng))
            let yAmt = Decimal(Int.random(in: 0...100_000, using: &rng))
            let year = ScheduleCYear(
                year: 2024,
                netProfit: x,
                depreciation: yAmt
            )
            #expect(cashFlowScheduleC(year) == x + yAmt)
        }
    }

    @Test("Loss year + depreciation addback preserves negative sign (-50k + 10k = -40k)")
    func lossYearWithAddbackPreservesNegativeSign() {
        let y = ScheduleCYear(
            year: 2024,
            netProfit: -50_000,
            depreciation: 10_000
        )
        #expect(cashFlowScheduleC(y) == -40_000)
        #expect(cashFlowScheduleC(y) < 0)
    }

    @Test("Reproducibility — same input, same output (500 random cases)")
    func reproducibility() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<500 {
            let y = ScheduleCYear(
                year: 2024,
                netProfit: Decimal(Int.random(in: -50_000...200_000, using: &rng)),
                nonRecurringOtherIncomeOrLoss: Decimal(Int.random(in: -10_000...10_000, using: &rng)),
                depletion: Decimal(Int.random(in: 0...5_000, using: &rng)),
                depreciation: Decimal(Int.random(in: 0...50_000, using: &rng)),
                nonDeductibleMealsAndEntertainment: Decimal(Int.random(in: 0...5_000, using: &rng)),
                businessUseOfHome: Decimal(Int.random(in: 0...8_000, using: &rng)),
                amortizationOrCasualtyLoss: Decimal(Int.random(in: 0...3_000, using: &rng)),
                mileageDepreciation: Decimal(Int.random(in: 0...6_000, using: &rng))
            )
            let first = cashFlowScheduleC(y)
            let second = cashFlowScheduleC(y)
            #expect(first == second)
        }
    }
}

@Suite("1120S K-1 cash flow")
struct Form1120SCashFlowTests {

    @Test("Ownership 0.0 returns w2Wages only")
    func zeroOwnership() {
        let y = Form1120SYear(
            year: 2024,
            ownershipPercent: 0,
            w2WagesFromBusiness: 75_000,
            ordinaryIncomeLoss: 100_000
        )
        #expect(cashFlowForm1120S(y) == 75_000)
    }

    @Test("Ownership 1.0 gets all pass-through plus w2 wages")
    func fullOwnership() {
        let y = Form1120SYear(
            year: 2024,
            ownershipPercent: 1.0,
            w2WagesFromBusiness: 60_000,
            ordinaryIncomeLoss: 80_000,
            depreciation: 10_000
        )
        // 60k + 1.0 × (80k + 10k) = 150k
        #expect(cashFlowForm1120S(y) == 150_000)
    }

    @Test("< 25% ownership + no distribution history → pass-through zeroed, w2 retained")
    func kickOutRule() {
        let y = Form1120SYear(
            year: 2024,
            ownershipPercent: 0.20,
            w2WagesFromBusiness: 85_000,
            ordinaryIncomeLoss: 200_000,
            depreciation: 20_000,
            hasConsistentDistributionHistory: false
        )
        // Pass-through not usable → 85k only
        #expect(cashFlowForm1120S(y) == 85_000)
    }

    @Test("< 25% ownership but with distribution history → pass-through counts")
    func distributionOverridesOwnershipFloor() {
        let y = Form1120SYear(
            year: 2024,
            ownershipPercent: 0.10,
            w2WagesFromBusiness: 50_000,
            ordinaryIncomeLoss: 200_000,
            hasConsistentDistributionHistory: true
        )
        // 50k + 0.10 × 200k = 70k
        #expect(cashFlowForm1120S(y) == 70_000)
    }

    @Test("Mortgage/notes < 1yr and travel-meals both subtract")
    func pageLSubtractions() {
        let y = Form1120SYear(
            year: 2024,
            ownershipPercent: 1.0,
            w2WagesFromBusiness: 0,
            ordinaryIncomeLoss: 100_000,
            mortgageOrNotesLessThan1Yr: 15_000,
            nonDeductibleTravelMeals: 5_000
        )
        // 0 + 1.0 × (100k - 15k - 5k) = 80k
        #expect(cashFlowForm1120S(y) == 80_000)
    }
}

@Suite("1065 partnership K-1 cash flow")
struct Form1065CashFlowTests {

    @Test("Zero ownership + no guaranteed payments → zero cash flow")
    func zeroEverything() {
        let y = Form1065Year(year: 2024, ownershipPercent: 0)
        #expect(cashFlowForm1065(y) == 0)
    }

    @Test("Guaranteed payments count in full even when pass-through kicked out")
    func guaranteedAlwaysCounts() {
        let y = Form1065Year(
            year: 2024,
            ownershipPercent: 0.10,
            ordinaryIncomeLoss: 500_000,
            guaranteedPayments: 90_000,
            hasConsistentDistributionHistory: false
        )
        // Pass-through not usable; guaranteed payments = 90k still count
        #expect(cashFlowForm1065(y) == 90_000)
    }

    @Test("50% partner with distribution history gets half of pass-through plus gp")
    func halfOwnerWithHistory() {
        let y = Form1065Year(
            year: 2024,
            ownershipPercent: 0.5,
            ordinaryIncomeLoss: 200_000,
            guaranteedPayments: 40_000,
            depreciation: 20_000,
            hasConsistentDistributionHistory: true
        )
        // 40k + 0.5 × (200k + 20k) = 40k + 110k = 150k
        #expect(cashFlowForm1065(y) == 150_000)
    }
}

@Suite("Two-year average + trend classification")
struct TwoYearAverageTests {

    @Test("Stable trend: within ±5% → qualifying = average")
    func stable() {
        let result = twoYearAverage(100_000, 103_000)
        #expect(result.trend == .stable)
        #expect(result.qualifyingAnnualIncome == 101_500)
    }

    @Test("Increasing trend: y2 >= y1 × 1.05 → qualifying = average (conservative)")
    func increasing() {
        let result = twoYearAverage(100_000, 120_000)
        #expect(result.trend == .increasing)
        #expect(result.qualifyingAnnualIncome == 110_000)
    }

    @Test("Declining trend: -5% to -20% → qualifying = y2 (lower year)")
    func declining() {
        let result = twoYearAverage(100_000, 90_000)
        #expect(result.trend == .declining)
        #expect(result.qualifyingAnnualIncome == 90_000)
    }

    @Test("Significant decline: > -20% → qualifying = y2 + written explanation required")
    func significantDecline() {
        let result = twoYearAverage(100_000, 70_000)
        #expect(result.trend == .significantDecline)
        #expect(result.qualifyingAnnualIncome == 70_000)
    }

    @Test("Monthly qualifying = annual qualifying / 12")
    func monthlyDerived() {
        let result = twoYearAverage(120_000, 120_000)
        #expect(result.qualifyingAnnualIncome == 120_000)
        #expect(result.qualifyingMonthlyIncome == 10_000)
    }

    @Test("y1 ≤ 0 defaults to stable with mean as qualifying (avoid divide-by-zero)")
    func zeroFirstYear() {
        let result = twoYearAverage(0, 50_000)
        #expect(result.trend == .stable)
        #expect(result.qualifyingAnnualIncome == 25_000)
    }

    @Test("Property: declining always selects the lower year (500 random cases)")
    func propertyLowerYearWhenDeclining() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<500 {
            let y1Int = Int.random(in: 50_000...500_000, using: &rng)
            // Force y2 < y1 × 0.95 → declining or significantDecline
            let y2Int = Int(Double(y1Int) * Double.random(in: 0.40...0.94, using: &rng))
            let result = twoYearAverage(Decimal(y1Int), Decimal(y2Int))
            #expect(result.trend.usesLowerYear,
                    "expected decline, got \(result.trend) for y1=\(y1Int) y2=\(y2Int)")
            #expect(result.qualifyingAnnualIncome == Decimal(y2Int))
        }
    }

    @Test("Property: stable or increasing always selects the mean (500 random cases)")
    func propertyMeanWhenStableOrIncreasing() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<500 {
            let y1Int = Int.random(in: 50_000...500_000, using: &rng)
            // Force y2 ≥ y1 × 0.95 → stable or increasing
            let y2Int = Int(Double(y1Int) * Double.random(in: 0.96...1.50, using: &rng))
            let result = twoYearAverage(Decimal(y1Int), Decimal(y2Int))
            #expect(!result.trend.usesLowerYear,
                    "expected stable/increasing, got \(result.trend) for y1=\(y1Int) y2=\(y2Int)")
            #expect(result.qualifyingAnnualIncome
                    == (Decimal(y1Int) + Decimal(y2Int)) / 2)
        }
    }
}
