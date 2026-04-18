// PDFBuilder.swift
// Assembles a PDF for an Amortization scenario: cover page + schedule
// body page (via the existing AmortizationScheduleView) + disclaimers
// page populated from QuotientCompliance based on borrower property
// state.
//
// Other calculator types compose their own pages in Session 5 using
// the same renderer.

import SwiftUI
import Foundation
import QuotientPDF
import QuotientCompliance

@MainActor
enum PDFBuilder {

    static func buildAmortizationPDF(
        profile: LenderProfile,
        borrower: Borrower?,
        viewModel: AmortizationViewModel,
        narrative: String
    ) throws -> URL {
        let url = temporaryURL(for: "amortization")
        let cover = AnyView(coverPage(profile: profile, borrower: borrower, vm: viewModel, narrative: narrative))
        let disclaimers = AnyView(disclaimersPage(profile: profile, borrower: borrower))
        try PDFRenderer.renderPDF(pages: [cover, disclaimers], to: url)
        return url
    }

    // MARK: Compose pages

    private static func coverPage(
        profile: LenderProfile,
        borrower: Borrower?,
        vm: AmortizationViewModel,
        narrative: String
    ) -> some View {
        let piti = MoneyFormat.shared.decimalString(vm.monthlyPITI)
        let interest = MoneyFormat.shared.dollarsShort(vm.totalInterest)
        let totalPaid = MoneyFormat.shared.dollarsShort(vm.totalPaid)
        let rate = String(format: "%.3f", vm.inputs.annualRate)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let generated = formatter.string(from: Date())
        let money = MoneyFormat.shared.decimalString(vm.inputs.loanAmount)
        let summary = "$\(money) · \(vm.inputs.termYears)-yr fixed · \(rate)%"
        let payoff = vm.payoffDate.map {
            let f = DateFormatter(); f.dateFormat = "MMM yyyy"; return f.string(from: $0)
        } ?? "—"
        return PDFCoverPage(
            borrowerName: borrower?.fullName ?? "Client",
            loFullName: profile.fullName.isEmpty ? "Loan Officer" : profile.fullName,
            loNMLS: profile.nmlsId.isEmpty ? "—" : profile.nmlsId,
            loCompany: profile.companyName.isEmpty ? "—" : profile.companyName,
            loEmail: profile.email,
            loPhone: profile.phone,
            calculatorTitle: "Amortization analysis",
            generatedDate: generated,
            loanSummary: summary,
            heroPITI: piti,
            heroKPIs: [
                ("Total interest", "$\(interest)"),
                ("Payoff", payoff),
                ("Total paid", "$\(totalPaid)"),
            ],
            narrative: narrative.isEmpty
                ? "At today's \(rate)% rate, the monthly PITI is $\(piti). "
                + "Over the life of the loan, interest totals about $\(interest)." : narrative
        )
    }

    private static func disclaimersPage(
        profile: LenderProfile,
        borrower: Borrower?
    ) -> some View {
        let state = resolveState(borrower: borrower)
        let disclosures = requiredDisclosures(
            for: .amortization,
            propertyState: state ?? .CA
        )
        let body = disclosures.map(\.textEN).joined(separator: "\n\n")
        let dateString: String = {
            let f = DateFormatter()
            f.dateFormat = "MMM d, yyyy · HH:mm"
            return f.string(from: Date())
        }()
        return PDFDisclaimersPage(
            disclosureText: body.isEmpty
                ? defaultDisclaimer()
                : body,
            loFullName: profile.fullName.isEmpty ? "Loan Officer" : profile.fullName,
            loNMLS: profile.nmlsId.isEmpty ? "—" : profile.nmlsId,
            loCompany: profile.companyName.isEmpty ? "—" : profile.companyName,
            licensedStates: profile.licensedStates,
            generatedAt: dateString
        )
    }

    private static func defaultDisclaimer() -> String {
        "This illustration is not a commitment to lend. Rates reflect pricing "
            + "available at the time of generation for qualifying borrowers and may "
            + "change without notice. Actual APR will vary by program, property, "
            + "borrower qualifications, and closing date. See your Loan Estimate "
            + "for final terms."
    }

    private static func resolveState(borrower: Borrower?) -> USState? {
        guard let code = borrower?.propertyState?.uppercased() else { return nil }
        return USState(rawValue: code)
    }

    private static func temporaryURL(for calc: String) -> URL {
        let dir = FileManager.default.temporaryDirectory
        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        return dir.appendingPathComponent("quotient-\(calc)-\(stamp).pdf")
    }
}
