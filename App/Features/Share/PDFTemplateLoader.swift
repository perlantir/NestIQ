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
        case templatesFolderMissing
        case templateNotFound(name: String)

        var description: String {
            switch self {
            case .templatesFolderMissing:
                return "Main bundle resource URL unavailable — cannot resolve PDF template assets."
            case .templateNotFound(let name):
                return "PDF template '\(name).html' not found in the main bundle."
            }
        }
    }

    /// Folder URL WKWebView uses as baseURL so `<link href="tokens.css">`
    /// inside each template resolves against the app bundle where
    /// tokens.css was copied by the pre-build rsync. The XcodeGen folder
    /// reference flattens nested directories, so templates and
    /// tokens.css both sit at the bundle root — we therefore use the
    /// bundle's resourceURL as the base and rewrite `../tokens.css`
    /// hrefs to `tokens.css` at load time.
    static var templatesFolderURL: URL {
        get throws {
            guard let url = Bundle.main.resourceURL else {
                throw Error.templatesFolderMissing
            }
            return url
        }
    }

    /// Load a v2.1.1 with-masthead template's raw HTML by name
    /// (without the `.html` extension).
    static func load(_ name: String) throws -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: "html") else {
            throw Error.templateNotFound(name: name)
        }
        let raw = try String(contentsOf: url, encoding: .utf8)
        // XcodeGen flattens the PDFTemplates folder into the app bundle
        // root; tokens.css sits next to the HTML instead of one level
        // up. Rewrite the stylesheet href so WKWebView finds it against
        // `baseURL = Bundle.main.resourceURL`.
        return raw.replacingOccurrences(
            of: "href=\"../tokens.css\"",
            with: "href=\"tokens.css\""
        )
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
