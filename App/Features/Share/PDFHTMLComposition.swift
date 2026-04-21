// PDFHTMLComposition.swift
// Shared HTML composition primitives for the HTML-to-PDF pipeline
// (Session 5O / D8). Per-calculator HTML builders (AmortizationPDFHTML,
// TCAPDFHTML, RefinancePDFHTML, etc.) delegate to these helpers for
// the pieces common to every PDF: base template loading, signature
// block, disclaimers appendix, small format utilities.

import Foundation
import UIKit
import QuotientCompliance

@MainActor
enum PDFHTMLComposition {

    // MARK: - Templates

    /// Load and cache base.html from the app bundle. Calls after the
    /// first hit hit the in-memory cache, so the common render path
    /// doesn't re-read the file on every PDF build.
    static func baseTemplate() -> String {
        if let cached = cachedBaseTemplate { return cached }
        guard let url = Bundle.main.url(forResource: "base", withExtension: "html"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            assertionFailure("base.html missing from app bundle")
            return "<html><body>{{CONTENT}}</body></html>"
        }
        cachedBaseTemplate = contents
        return contents
    }

    static func signatureTemplate() -> String {
        if let cached = cachedSignatureTemplate { return cached }
        guard let url = Bundle.main.url(forResource: "SignatureBlock", withExtension: "html"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            assertionFailure("SignatureBlock.html missing from app bundle")
            return ""
        }
        cachedSignatureTemplate = contents
        return contents
    }

    nonisolated(unsafe) private static var cachedBaseTemplate: String?
    nonisolated(unsafe) private static var cachedSignatureTemplate: String?

    // MARK: - Document assembly

    /// Wrap a content body HTML fragment in base.html.
    static func wrap(body: String) -> String {
        baseTemplate().replacingOccurrences(of: "{{CONTENT}}", with: body)
    }

    // MARK: - Signature block

    /// Session 5N.3 single-source signature rules preserved verbatim:
    /// serif name, "Senior Loan Officer · NMLS N" title line, company
    /// on its own line only when populated (not "—", not empty), email
    /// · phone joined line, photo only when showPhotoOnPDF && photoData
    /// non-nil.
    static func signatureHTML(profile: LenderProfile) -> String {
        let name = profile.fullName.isEmpty ? "Loan Officer" : profile.fullName
        let nmls = profile.nmlsId.isEmpty ? "—" : profile.nmlsId
        let titleLine = "Senior Loan Officer · NMLS \(escape(nmls))"
        let company = profile.companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let companyLine: String = {
            guard !company.isEmpty, company != "—" else { return "" }
            return "<div class=\"company\">\(escape(company))</div>"
        }()
        let contact = contactLine(email: profile.email, phone: profile.phone)
        let photoTag: String = {
            guard profile.showPhotoOnPDF,
                  let data = profile.photoData,
                  !data.isEmpty,
                  UIImage(data: data) != nil else { return "" }
            let base64 = data.base64EncodedString()
            return "<img class=\"signature-photo\" src=\"data:image/jpeg;base64,\(base64)\" alt=\"\">"
        }()
        let values: [String: String] = [
            "NAME": escape(name),
            "TITLE_LINE": titleLine,
            "COMPANY_LINE": companyLine,
            "CONTACT_LINE": escape(contact),
            "PHOTO_TAG": photoTag
        ]
        return HTMLPDFRenderer.shared.interpolate(
            template: signatureTemplate(),
            values: values
        )
    }

    // MARK: - Disclaimers appendix

    /// Renders the universal educational-use disclosure plus the
    /// company / NMLS / EHO footer strip. Always occupies its own page
    /// via `.break-before` — callers append this fragment to the body
    /// as the final section.
    static func disclaimersHTML(
        profile: LenderProfile,
        borrower: Borrower?,
        scenarioType: ScenarioType,
        generatedAt: Date = Date()
    ) -> String {
        let paragraphs = defaultDisclaimer
            .components(separatedBy: "\n\n")
            .map { "<p>\(escape($0))</p>" }
            .joined()
        let timestampFmt = DateFormatter()
        timestampFmt.dateFormat = "MMM d, yyyy · HH:mm"
        let generatedAtStr = timestampFmt.string(from: generatedAt)
        let loName = profile.fullName.isEmpty ? "Loan Officer" : profile.fullName
        let nmls = profile.nmlsId.isEmpty ? "—" : profile.nmlsId
        let company = profile.companyName.isEmpty ? "—" : profile.companyName
        return """
        <section class="break-before">
          <p class="eyebrow">Disclosures</p>
          <h1>The fine print</h1>
          <div class="summary-text">
            \(paragraphs)
          </div>
          <div class="disclaimer">
            <p class="mono">\(escape(company))</p>
            <p class="mono">\(escape(loName)) · Individual NMLS \(escape(nmls))</p>
            <p class="mono">Equal Housing Opportunity · Generated \(escape(generatedAtStr))</p>
          </div>
        </section>
        """
    }

    // MARK: - Hero + KPI helpers

    static func heroCardHTML(
        label: String,
        value: String,
        prefix: String = "$",
        suffix: String = ""
    ) -> String {
        let prefixSpan = prefix.isEmpty ? "" : "<span class=\"prefix\">\(escape(prefix))</span>"
        let suffixSpan = suffix.isEmpty ? "" : "<span class=\"suffix\">\(escape(suffix))</span>"
        return """
        <div class="hero-card">
          <div class="hero-label">\(escape(label))</div>
          <div class="hero-value">\(prefixSpan)\(escape(value))\(suffixSpan)</div>
        </div>
        """
    }

    static func kpiGridHTML(_ kpis: [(label: String, value: String)]) -> String {
        let cells = kpis.map { kpi in
            """
            <div class="kpi">
              <div class="kpi-label">\(escape(kpi.label))</div>
              <div class="kpi-value">\(escape(kpi.value))</div>
            </div>
            """
        }.joined()
        return "<div class=\"kpi-grid\">\(cells)</div>"
    }

    // MARK: - Cover "For {Borrower}" title block

    static func titleBlockHTML(
        eyebrow: String,
        borrowerName: String,
        loanSummary: String
    ) -> String {
        """
        <p class="eyebrow">\(escape(eyebrow))</p>
        <h1>For <em>\(escape(borrowerName))</em></h1>
        <p class="meta mono">\(escape(loanSummary))</p>
        """
    }

    // MARK: - Formatting

    static func formatDate(_ date: Date, style: DateStyle = .long) -> String {
        let f = DateFormatter()
        switch style {
        case .long:
            f.dateFormat = "MMMM d, yyyy"
        case .short:
            f.dateFormat = "MMM d, yyyy"
        case .monthYear:
            f.dateFormat = "MMM yyyy"
        case .year:
            f.dateFormat = "yyyy"
        }
        return f.string(from: date)
    }

    enum DateStyle {
        case long, short, monthYear, year
    }

    static func contactLine(email: String, phone: String) -> String {
        switch (email.isEmpty, phone.isEmpty) {
        case (true, true): return ""
        case (false, true): return email
        case (true, false): return phone
        case (false, false): return "\(email) · \(phone)"
        }
    }

    /// HTML-escape a user-provided string before interpolating into
    /// template HTML. Conservative set: &, <, >, ", '.
    static func escape(_ input: String) -> String {
        var out = input
        out = out.replacingOccurrences(of: "&", with: "&amp;")
        out = out.replacingOccurrences(of: "<", with: "&lt;")
        out = out.replacingOccurrences(of: ">", with: "&gt;")
        out = out.replacingOccurrences(of: "\"", with: "&quot;")
        out = out.replacingOccurrences(of: "'", with: "&#39;")
        return out
    }

    // MARK: - Shared constants / helpers

    static let defaultDisclaimer =
        "This calculator is for educational and illustrative purposes only. "
        + "Results are based on user-entered inputs and do not represent actual "
        + "loan terms, a loan commitment, or a Loan Estimate. Actual rates and "
        + "payments will vary."

    static func resolveState(borrower: Borrower?) -> USState? {
        guard let code = borrower?.propertyState?.uppercased() else { return nil }
        return USState(rawValue: code)
    }

    static func temporaryURL(for calc: String) -> URL {
        let dir = FileManager.default.temporaryDirectory
        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        return dir.appendingPathComponent("nestiq-\(calc)-\(stamp).pdf")
    }
}
