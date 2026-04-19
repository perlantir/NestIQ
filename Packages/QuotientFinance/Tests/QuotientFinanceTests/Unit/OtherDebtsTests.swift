// OtherDebtsTests.swift
// Session 5E.5 coverage for the aggregate debts primitive used by TCA
// refinance-mode scenarios. The struct itself is a thin value; the test
// locks the contract the Swift UI relies on: zero() identity, isZero
// semantics, and Codable round-trip so saved TCA scenarios re-open
// intact.

import XCTest
import QuotientFinance

final class OtherDebtsTests: XCTestCase {

    func testZeroInstanceIsZero() {
        XCTAssertTrue(OtherDebts.zero().isZero)
    }

    func testNonZeroIsNotZero() {
        let debts = OtherDebts(totalBalance: 12_000, monthlyPayment: 320)
        XCTAssertFalse(debts.isZero)
    }

    func testPartialZeroIsNotZero() {
        let onlyBalance = OtherDebts(totalBalance: 5_000, monthlyPayment: 0)
        XCTAssertFalse(onlyBalance.isZero)
        let onlyPayment = OtherDebts(totalBalance: 0, monthlyPayment: 50)
        XCTAssertFalse(onlyPayment.isZero)
    }

    func testCodableRoundTrip() throws {
        let debts = OtherDebts(totalBalance: 27_450, monthlyPayment: 612)
        let data = try JSONEncoder().encode(debts)
        let decoded = try JSONDecoder().decode(OtherDebts.self, from: data)
        XCTAssertEqual(decoded, debts)
    }

    /// Invariant the TCA refinance-mode results grid depends on: total
    /// monthly obligation = PITI + debts.monthlyPayment. With `nil`
    /// debts the scenario math is identical to pre-5E.5 behavior;
    /// with a set value the delta is exactly `debts.monthlyPayment`.
    func testTotalMonthlyObligationSemantics() {
        let piti: Decimal = 2_731
        let debts = OtherDebts(totalBalance: 18_000, monthlyPayment: 450)

        let noDebtsTotal = piti + OtherDebts.zero().monthlyPayment
        XCTAssertEqual(noDebtsTotal, piti)

        let withDebtsTotal = piti + debts.monthlyPayment
        XCTAssertEqual(withDebtsTotal, 3_181)
        XCTAssertEqual(withDebtsTotal - noDebtsTotal, debts.monthlyPayment)
    }
}
