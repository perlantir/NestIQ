// TCAPDFHTMLTests.swift
// Session 5O.3 — PDF integrity tests for the TCA HTML builder and
// the shared break-even SVG. The HTML builder feeds HTMLPDFRenderer;
// integrity here means "the composed PDF carries the expected
// anchors/sections" (signature block name once, borrower, matrix
// header, at least one scenario label, disclaimers appendix, per-page
// footer counter).

import XCTest
import PDFKit
import QuotientFinance
@testable import Quotient

@MainActor
final class TCAPDFHTMLTests: XCTestCase {

    func testTCAPDFRendersAllSections() async throws {
        let profile = makeProfile()
        let borrower = makeBorrower()
        let vm = TCAViewModel(borrower: borrower)
        vm.compute()

        let url = try await PDFBuilder.buildTCAPDF(
            profile: profile,
            borrower: borrower,
            viewModel: vm,
            narrative: ""
        )
        let doc = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThanOrEqual(doc.pageCount, 2,
                                    "TCA PDF should paginate cover + detail + disclaimers")

        let full = (0..<doc.pageCount)
            .compactMap { doc.page(at: $0)?.string }
            .joined(separator: "\n")
        let cover = doc.page(at: 0)?.string ?? ""
        XCTAssertTrue(cover.contains("Nick Gallick"),
                      "Signature block LO name missing on cover. Got first 400 chars: \(cover.prefix(400))")
        // Single-source signature check (5N.3 regression pin). The
        // name legitimately appears once on the cover signature and
        // once in the disclaimers footer — only the cover is the
        // surface where the double-block regression surfaced.
        let coverOccurrences = cover.components(separatedBy: "Nick Gallick").count - 1
        XCTAssertEqual(coverOccurrences, 1,
                       "Expected exactly one 'Nick Gallick' on the cover; got \(coverOccurrences)")

        XCTAssertTrue(full.contains("Smith"),
                      "Borrower name missing from TCA PDF cover")
        XCTAssertTrue(full.contains("Scenarios compared"),
                      "TCA scenarios-compared heading missing")
        XCTAssertTrue(full.contains("Total cost by horizon"),
                      "Horizon matrix heading missing")

        // At least one scenario label (A / B / C / D) should appear.
        let labels = vm.inputs.scenarios.map { $0.label.uppercased() }
        XCTAssertTrue(labels.contains(where: { full.contains($0) }),
                      "No scenario label present in TCA PDF. Expected any of \(labels)")

        // Disclaimers appendix
        XCTAssertTrue(full.contains("The fine print"),
                      "Disclaimers page missing its H1")

        // D12 (Session 7 / 2026-04-21): the Core Graphics per-page chrome
        // (NestIQPrintRenderer wordmark header + "Page N of M ·
        // nestiq.mortgage" footer) was retired — PDF chrome is now
        // HTML-template-driven. TCA stays on base.html + PDFHTMLComposition
        // until its v2.1.1 migration in Session 7.3e/f, so the interim
        // TCA PDF renders without a masthead band or live page counter.
        // The disclaimers appendix "Equal Housing Opportunity" footer
        // strip (still emitted by PDFHTMLComposition.disclaimersHTML) is
        // the remaining compliance anchor we can assert on.
        XCTAssertTrue(full.contains("Equal Housing Opportunity"),
                      "Disclaimers footer EHO statement missing")
    }

    func testBreakEvenSVGDomainMatchesTerm() {
        // 360-month (30-yr) scenario. If x-axis domain is hard-coded
        // to the term, SVG's viewBox should reference 360 months in
        // its x-tick labels (0, 5yr, 10yr, … 30yr terminal).
        let series: [(month: Int, cumulative: Double)] = (0...360).map {
            (month: $0, cumulative: 100.0 * Double($0))
        }
        let svg = BreakEvenChartSVG.build(
            series: series,
            closingCosts: 12_000,
            termMonths: 360
        )
        XCTAssertTrue(svg.contains(">30yr<"),
                      "Terminal tick '30yr' missing — x-axis may not span termMonths")
        XCTAssertTrue(svg.contains(">0<"),
                      "Zero tick missing")
        // 360 months * $100 savings = $36,000 peak; closing $12k
        // crosses at month 120.
        XCTAssertTrue(svg.contains("Break-even · Month 120"),
                      "Crossover marker missing or at wrong month")
    }

    func testBreakEvenSVGEmptyWhenNoCrossover() {
        // Scenario where monthly savings never recoup closing costs
        // within the term.
        let series: [(month: Int, cumulative: Double)] = (0...360).map {
            (month: $0, cumulative: 10.0 * Double($0))  // $10/mo × 360 = $3,600
        }
        let svg = BreakEvenChartSVG.build(
            series: series,
            closingCosts: 8_000,
            termMonths: 360
        )
        // Chart still renders to show trajectory, but no crossover
        // marker should appear.
        XCTAssertFalse(svg.contains("Break-even · Month"),
                       "Crossover marker rendered for non-crossing series")
    }

    func testBreakEvenSVGCrossoverAtExpectedMonth() {
        // $200/mo savings × month, closing $10k → crossover at month 50.
        let series: [(month: Int, cumulative: Double)] = (0...360).map {
            (month: $0, cumulative: 200.0 * Double($0))
        }
        let crossover = BreakEvenChartSVG.firstCrossover(
            series: series,
            closingCosts: 10_000,
            termMonths: 360
        )
        XCTAssertEqual(crossover?.month, 50)
    }

    // MARK: - Session 5Q.4 — Current column in refi mode

    /// When refi mode + borrower.currentMortgage is attached, the PDF's
    /// horizon matrix adds a "Current" column; purchase mode does not.
    func testTCAPDFRefiCurrentColumnRenders() async throws {
        let profile = makeProfile()
        let borrower = makeBorrower()
        borrower.currentMortgage = CurrentMortgage(
            currentBalance: 320_000,
            currentRatePercent: 6.875,
            currentMonthlyPaymentPI: 2_101,
            originalLoanAmount: 360_000,
            originalTermYears: 30,
            loanStartDate: Date(timeIntervalSince1970: 1_650_000_000),
            propertyValueToday: 500_000
        )
        let vm = TCAViewModel(borrower: borrower)
        vm.inputs.currentMortgage = borrower.currentMortgage
        vm.compute()

        let html = TCAPDFHTML.buildHTML(
            profile: profile,
            borrower: borrower,
            viewModel: vm,
            narrative: ""
        )
        // Horizon matrix header carries Current column.
        XCTAssertTrue(html.contains("<th class=\"num\">Current</th>"),
                      "Refi-mode PDF missing Current column header")
        // Caption reflects the status-quo framing.
        XCTAssertTrue(html.contains("'Current' = staying"),
                      "Refi-mode caption missing Current-column note")
        // Unrecoverable + Equity sections carry Current rows.
        XCTAssertTrue(html.contains("<td>Current</td>"),
                      "Refi-mode PDF missing Current row in unrecoverable / equity tables")
        XCTAssertTrue(html.contains("<td>Status quo</td>"),
                      "Refi-mode PDF missing 'Status quo' program label")
    }

    func testTCAPDFPurchaseModeHasNoCurrentColumn() async throws {
        let profile = makeProfile()
        let borrower = makeBorrower()
        let vm = TCAViewModel(borrower: borrower)
        vm.inputs.mode = .purchase
        vm.compute()

        let html = TCAPDFHTML.buildHTML(
            profile: profile,
            borrower: borrower,
            viewModel: vm,
            narrative: ""
        )
        XCTAssertFalse(html.contains("<th class=\"num\">Current</th>"),
                       "Purchase-mode PDF should not show Current column")
        XCTAssertFalse(html.contains("<td>Status quo</td>"),
                       "Purchase-mode PDF should not show Status quo row")
    }

    /// Spot-check the helper math: a known current mortgage, compute
    /// its 5-yr horizon cost. Expected = P&I × 60, bounded by remaining.
    func testTCAHorizonCurrentCostComputesCorrectly() {
        let mortgage = CurrentMortgage(
            currentBalance: 300_000,
            currentRatePercent: 6.5,
            currentMonthlyPaymentPI: 2_000,
            originalLoanAmount: 300_000,
            originalTermYears: 30,
            loanStartDate: Date(timeIntervalSince1970: 1_650_000_000),
            propertyValueToday: 450_000
        )
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .refinance
        inputs.currentMortgage = mortgage

        // 5-yr horizon = 60 months × $2,000 = $120,000 (loan still
        // running — plenty of remaining term).
        XCTAssertEqual(inputs.currentHorizonCost(years: 5), 120_000)
        // 7-yr horizon = 84 months × $2,000 = $168,000.
        XCTAssertEqual(inputs.currentHorizonCost(years: 7), 168_000)
    }

    /// Purchase mode: the helper returns 0 even when a currentMortgage
    /// is set on the inputs (shouldn't happen in practice, but the
    /// helper's guard makes this explicit).
    func testTCAHorizonCurrentCostZeroInPurchaseMode() {
        var inputs = TCAFormInputs.sampleDefault
        inputs.mode = .purchase
        inputs.currentMortgage = CurrentMortgage(
            currentBalance: 300_000,
            currentRatePercent: 6.5,
            currentMonthlyPaymentPI: 2_000,
            originalLoanAmount: 300_000,
            originalTermYears: 30,
            loanStartDate: Date(timeIntervalSince1970: 1_650_000_000),
            propertyValueToday: 450_000
        )
        XCTAssertEqual(inputs.currentHorizonCost(years: 5), 0)
        XCTAssertNil(inputs.buildCurrentMortgageSchedule())
    }

    // MARK: - Helpers

    private func makeProfile() -> LenderProfile {
        LenderProfile(
            appleUserID: "apple.tca.\(UUID().uuidString)",
            firstName: "Nick",
            lastName: "Gallick",
            nmlsId: "1428391",
            licensedStates: ["CA", "OR"],
            companyName: "Gallick Holdings LLC",
            phone: "(415) 555-0123",
            email: "nick@uberkiwi.com"
        )
    }

    private func makeBorrower() -> Borrower {
        Borrower(firstName: "John", lastName: "Smith",
                 propertyState: "CA", source: .manual)
    }
}
