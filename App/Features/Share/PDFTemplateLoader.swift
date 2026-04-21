// PDFTemplateLoader.swift
// Bundle loading helpers for v2.1.1 PDF templates (D12, Session 7.3).
//
// Templates live at App/Resources/PDFTemplates/templates/, mirrored from
// .claude/assets/pdf-v2/ at build time by a xcodegen preBuildScripts
// rsync (see project.yml). tokens.css sits one level up at
// App/Resources/PDFTemplates/tokens.css — templates link it via
// <link rel="stylesheet" href="../tokens.css">, which resolves against
// the baseURL passed to HTMLPDFRenderer.

import Foundation
import QuotientCompliance

enum PDFTemplateLoader {

    enum Error: Swift.Error, CustomStringConvertible {
        case templateFolderMissing
        case templateNotFound(name: String)

        var description: String {
            switch self {
            case .templateFolderMissing:
                return "PDFTemplates folder missing from main bundle — verify preBuildScripts rsync ran."
            case .templateNotFound(let name):
                return "PDF template '\(name).html' not found in PDFTemplates/templates/."
            }
        }
    }

    /// Folder URL WKWebView uses as baseURL so `<link href="../tokens.css">`
    /// inside each template resolves to `PDFTemplates/tokens.css`.
    static var templatesFolderURL: URL {
        get throws {
            guard let url = Bundle.main.url(
                forResource: "PDFTemplates",
                withExtension: nil
            )?.appendingPathComponent("templates") else {
                throw Error.templateFolderMissing
            }
            return url
        }
    }

    /// Load a v2.1.1 with-masthead template's raw HTML by name
    /// (without the `.html` extension).
    static func load(_ name: String) throws -> String {
        let url = try templatesFolderURL.appendingPathComponent("\(name).html")
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw Error.templateNotFound(name: name)
        }
    }

    /// Trailing compliance disclosures page appended after the editorial
    /// template pages (D12-C2). Inline `<style>` maps the base.html
    /// classes used by `PDFHTMLComposition.disclaimersHTML` onto v2.1.1
    /// design tokens so the trailer styles consistently with the rest
    /// of the document despite reusing the legacy fragment.
    ///
    /// v0.1.2 backlog: replace this inline trailer with a designed v2.2
    /// `pdf-disclosures.html` template when Claude Design ships one.
    @MainActor
    static func complianceTrailerPage(
        profile: LenderProfile,
        borrower: Borrower?,
        scenarioType: ScenarioType,
        generatedAt: Date = Date()
    ) -> String {
        let disclaimers = PDFHTMLComposition.disclaimersHTML(
            profile: profile,
            borrower: borrower,
            scenarioType: scenarioType,
            generatedAt: generatedAt
        )
        return """
        <article class="page" style="font-family: var(--serif); color: var(--ink); background: var(--paper);">
          <style>
            .compliance-trailer h2 {
              font-family: var(--serif); font-size: 20pt; font-weight: 600;
              letter-spacing: -0.015em; margin: 0 0 22pt; color: var(--ink);
            }
            .compliance-trailer .break-before {
              margin: 0;
            }
            .compliance-trailer .eyebrow {
              display: none;
            }
            .compliance-trailer h1 {
              font-family: var(--serif); font-size: 13pt; font-weight: 600;
              margin: 0 0 12pt; color: var(--ink);
            }
            .compliance-trailer .summary-text {
              font-size: 10pt; line-height: 1.4; color: var(--ink2);
            }
            .compliance-trailer .summary-text p {
              margin: 0 0 10pt;
            }
            .compliance-trailer .disclaimer {
              margin-top: 24pt; padding-top: 14pt;
              border-top: 0.5pt solid var(--rule);
              font-size: 9pt; line-height: 1.4; color: var(--ink3);
            }
            .compliance-trailer .disclaimer p {
              margin: 0 0 4pt;
            }
          </style>
          <section class="compliance-trailer">
            <h2>Disclosures</h2>
            \(disclaimers)
          </section>
        </article>
        """
    }
}
