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

        // Per-page counter from NestIQPrintRenderer footer
        XCTAssertTrue(full.contains("Page 1 of "),
                      "Cover page counter missing")
        XCTAssertTrue(full.contains("nestiq.mortgage"),
                      "Footer URL missing")
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
