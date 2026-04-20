// PDFBuilder+Pages.swift
// Cover + disclaimers page composition helpers, extracted from
// PDFBuilder.swift so the main enum stays under SwiftLint's
// `type_body_length` cap (400 lines).

import SwiftUI
import Foundation
import QuotientCompliance

extension PDFBuilder {
    @MainActor
    static func coverPage(
        profile: LenderProfile,
        borrower: Borrower?,
        payload: Payload,
        pageIndex: Int,
        pageCount: Int
    ) -> some View {
        let generated = PDFPageHeader.formatDate(Date())
        return PDFCoverPage(
            borrowerName: borrower?.fullName ?? "Client",
            loFullName: profile.fullName.isEmpty ? "Loan Officer" : profile.fullName,
            loNMLS: profile.nmlsId.isEmpty ? "—" : profile.nmlsId,
            loCompany: profile.companyName.isEmpty ? "—" : profile.companyName,
            loEmail: profile.email,
            loPhone: profile.phone,
            calculatorTitle: payload.calculatorTitle,
            generatedDate: generated,
            loanSummary: payload.loanSummary,
            heroPITI: payload.heroValue,
            heroKPIs: payload.heroKPIs,
            narrative: payload.narrative,
            accentHex: profile.brandColorHex,
            logoData: profile.companyLogoData,
            loPhotoData: profile.showPhotoOnPDF ? profile.photoData : nil,
            heroLabel: payload.heroLabel,
            heroValuePrefix: payload.heroValuePrefix,
            heroValueSuffix: payload.heroValueSuffix,
            pageIndex: pageIndex,
            pageCount: pageCount
        )
    }

    @MainActor
    static func disclaimersPage(
        profile: LenderProfile,
        borrower: Borrower?,
        scenarioType: ScenarioType,
        pageIndex: Int,
        pageCount: Int
    ) -> some View {
        let state = resolveState(borrower: borrower)
        let disclosures = requiredDisclosures(
            for: scenarioType,
            propertyState: state ?? .CA
        )
        let body = disclosures.map(\.textEN).joined(separator: "\n\n")
        let detailedDate: String = {
            let f = DateFormatter()
            f.dateFormat = "MMM d, yyyy · HH:mm"
            return f.string(from: Date())
        }()
        return PDFDisclaimersPage(
            disclosureText: body.isEmpty ? defaultDisclaimer() : body,
            loFullName: profile.fullName.isEmpty ? "Loan Officer" : profile.fullName,
            loNMLS: profile.nmlsId.isEmpty ? "—" : profile.nmlsId,
            loCompany: profile.companyName.isEmpty ? "—" : profile.companyName,
            licensedStates: profile.licensedStates,
            generatedAt: detailedDate,
            headerDate: PDFPageHeader.formatDate(Date()),
            pageIndex: pageIndex,
            pageCount: pageCount
        )
    }
}
