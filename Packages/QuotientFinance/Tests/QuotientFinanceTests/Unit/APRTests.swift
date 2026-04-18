// APRTests.swift

import Testing
import Foundation
@testable import QuotientFinance

@Suite("APR")
struct APRTests {

    @Test("APR equals note rate when no prepaid finance charges")
    func aprEqualsNoteRateWithNoFees() {
        let loan = Loan(
            principal: 200_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let apr = calculateAPR(loan: loan, prepaidFinanceCharges: 0)
        #expect(apr.isApproximatelyEqual(to: 0.06, tolerance: 1e-9))
    }

    @Test("APR strictly greater than note rate when prepaid charges > 0")
    func aprExceedsNoteRate() {
        let loan = Loan(
            principal: 200_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let apr = calculateAPR(loan: loan, prepaidFinanceCharges: 4000)
        #expect(apr > loan.annualRate)
    }

    @Test("APR is self-consistent: PV of payments at APR = amount financed")
    func aprSelfConsistent() {
        let loan = Loan(
            principal: 350_000,
            annualRate: 0.065,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let prepaid: Decimal = 5000
        let apr = calculateAPR(loan: loan, prepaidFinanceCharges: prepaid)
        let pmt = paymentFor(loan: loan).asDouble
        let af = (loan.principal - prepaid).asDouble
        let i = apr / 12
        let pv = pmt * (1.0 - pow(1.0 + i, -360)) / i
        #expect(pv.isApproximatelyEqual(to: af, tolerance: 0.01))
    }

    @Test("APR: $200k 6% 30yr with $4k fees ≈ 6.19%")
    func aprTwoHundredKSixPct() {
        let loan = Loan(
            principal: 200_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let apr = calculateAPR(loan: loan, prepaidFinanceCharges: 4000)
        // Cross-checked against Bankrate's APR calculator: ~6.184%. Our
        // Reg Z Appendix J implementation gives 6.189%; the 0.5 bp
        // difference is well within the regulatory ±12.5 bp tolerance.
        #expect(apr.isApproximatelyEqual(to: 0.0619, tolerance: 0.0002))
    }
}

@Suite("APOR lookup")
struct APORTests {

    @Test("APOR returns nil for HELOC")
    func helocHasNoAPOR() {
        let lookup = calculateAPOR(
            loanType: .heloc,
            rateType: .fixed,
            termYears: 30,
            lockDate: date(2026, 3, 15)
        )
        #expect(lookup == nil)
    }

    @Test("APOR returns nil before the embedded table's start")
    func beforeTableStart() {
        let lookup = calculateAPOR(
            loanType: .conventional,
            rateType: .fixed,
            termYears: 30,
            lockDate: date(2020, 1, 1)
        )
        #expect(lookup == nil)
    }

    @Test("APOR returns most recent entry on or before lock date")
    func lookupRoundsDown() {
        // Lock date 2026-04-15 should find the 2026-04-09 entry (not 2026-04-16)
        let lookup = calculateAPOR(
            loanType: .conventional,
            rateType: .fixed,
            termYears: 30,
            lockDate: date(2026, 4, 15)
        )
        #expect(lookup != nil)
        if let value = lookup {
            #expect(value.isApproximatelyEqual(to: 0.0553, tolerance: 0.0005))
        }
    }

    @Test("APOR finds exact term when available")
    func exactTermMatch() {
        let thirty = calculateAPOR(
            loanType: .conventional,
            rateType: .fixed,
            termYears: 30,
            lockDate: date(2026, 4, 2)
        )
        let fifteen = calculateAPOR(
            loanType: .conventional,
            rateType: .fixed,
            termYears: 15,
            lockDate: date(2026, 4, 2)
        )
        #expect(thirty != nil)
        #expect(fifteen != nil)
        if let t = thirty, let f = fifteen {
            #expect(t > f)  // 30-year APOR is typically > 15-year
        }
    }
}

@Suite("HPML / HPCT")
struct HPMLTests {

    @Test("First-lien non-jumbo HPML at APR-APOR ≥ 1.5%")
    func firstLienHPMLThreshold() {
        #expect(!isHPML(apr: 0.065, apor: 0.055, lienPosition: .first, isJumbo: false))
        #expect(isHPML(apr: 0.070, apor: 0.055, lienPosition: .first, isJumbo: false))
    }

    @Test("Jumbo threshold is 2.5%")
    func jumboThreshold() {
        #expect(!isHPML(apr: 0.075, apor: 0.055, lienPosition: .first, isJumbo: true))
        #expect(isHPML(apr: 0.080, apor: 0.055, lienPosition: .first, isJumbo: true))
    }

    @Test("Subordinate lien threshold is 3.5%")
    func subordinateThreshold() {
        #expect(!isHPML(apr: 0.089, apor: 0.055, lienPosition: .subordinate, isJumbo: false))
        #expect(isHPML(apr: 0.091, apor: 0.055, lienPosition: .subordinate, isJumbo: false))
    }
}

@Suite("QM determination")
struct QMTests {

    @Test("Safe-harbor QM for standard 30-year fixed below HPCT threshold")
    func safeHarborQM() {
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let qm = calculateQMStatus(
            loan: loan,
            apr: 0.061,
            apor: 0.055,
            pointsAndFees: 5000,
            lienPosition: .first,
            isJumbo: false
        )
        #expect(qm.status == .generalQM)
        #expect(qm.presumption == .safeHarbor)
        #expect(qm.isHigherPriced == false)
    }

    @Test("Rebuttable presumption QM when APR-APOR spread exceeds threshold")
    func rebuttablePresumptionQM() {
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.08,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let qm = calculateQMStatus(
            loan: loan,
            apr: 0.082,
            apor: 0.055,
            pointsAndFees: 5000
        )
        #expect(qm.status == .generalQM)
        #expect(qm.presumption == .rebuttablePresumption)
        #expect(qm.isHigherPriced == true)
    }

    @Test("Not QM when term > 30 years")
    func notQMOnLongTerm() {
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.06,
            termMonths: 480, // 40 years
            startDate: date(2026, 1, 1)
        )
        let qm = calculateQMStatus(
            loan: loan,
            apr: 0.061,
            apor: 0.055,
            pointsAndFees: 2000
        )
        #expect(qm.status == .notQM)
        #expect(qm.termCompliant == false)
    }

    @Test("Not QM when points and fees exceed 3% cap")
    func notQMOnPointsAndFees() {
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let qm = calculateQMStatus(
            loan: loan,
            apr: 0.061,
            apor: 0.055,
            pointsAndFees: 15_000 // 5%
        )
        #expect(qm.status == .notQM)
    }

    @Test("Interest-only loan is not QM")
    func notQMOnInterestOnly() {
        let loan = Loan(
            principal: 300_000,
            annualRate: 0.06,
            termMonths: 360,
            startDate: date(2026, 1, 1)
        )
        let qm = calculateQMStatus(
            loan: loan,
            apr: 0.061,
            apor: 0.055,
            pointsAndFees: 2000,
            features: QMFeatures(interestOnly: true)
        )
        #expect(qm.status == .notQM)
        #expect(qm.featuresCompliant == false)
    }

    @Test("QMDetermination round-trips through Codable")
    func qmCodable() throws {
        let qm = QMDetermination(
            status: .generalQM,
            presumption: .safeHarbor,
            isHigherPriced: false,
            aprAporSpread: 0.005,
            pointsAndFeesAmount: 4500,
            pointsAndFeesPercent: 0.015,
            termCompliant: true,
            featuresCompliant: true,
            complianceRuleVersion: .current,
            reasons: ["APR-APOR spread 0.50 pp — safe-harbor QM."]
        )
        let encoded = try JSONEncoder().encode(qm)
        let decoded = try JSONDecoder().decode(QMDetermination.self, from: encoded)
        #expect(decoded == qm)
    }
}
