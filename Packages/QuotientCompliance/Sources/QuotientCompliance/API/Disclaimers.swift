// Disclaimers.swift
// Public disclaimer API: fixed federal + context-keyed plain-language text.

import Foundation

/// Federal Equal Housing Opportunity statement.
///
/// The exact-wording federal statement is required on most mortgage
/// marketing, PDFs, and borrower-facing summaries per 12 C.F.R. §1002.4(b)
/// and HUD rules. Not state-scoped; not `CounselReviewStatus`-wrapped — the
/// wording is fixed federal language.
///
/// - Parameter locale: Pick EN or ES; any non-ES language returns EN.
public func equalHousingOpportunityStatement(locale: Locale) -> String {
    let lang = locale.language.languageCode?.identifier ?? "en"
    if lang == "es" {
        return """
            Prestamista de Igualdad de Oportunidades en la Vivienda. Creemos \
            y apoyamos la letra y el espíritu de las leyes federales de \
            Igualdad de Oportunidades de Crédito y Vivienda Justa.
            """
    }
    return """
        Equal Housing Opportunity Lender. We do business in accordance with \
        the Federal Fair Housing Act and the Federal Equal Credit \
        Opportunity Act.
        """
}

/// Short plain-language disclaimer for the given context and locale.
///
/// Never returns an empty string — every `DisclaimerContext` case has an
/// EN + ES template defined in `Disclaimers/Templates.swift`. If a new
/// context is added without a template, this function will trap in debug
/// via `assertionFailure` and return a generic fallback in release.
///
/// - Parameters:
///   - context: Where the disclaimer will appear (hero card, PDF footer, etc.).
///   - locale: Pick EN or ES; any non-ES language returns EN.
public func requiredDisclaimer(context: DisclaimerContext, locale: Locale) -> String {
    guard let template = disclaimerTemplates[context] else {
        assertionFailure("Missing DisclaimerContext template for \(context)")
        return "Illustrative calculation. Not a commitment to lend."
    }
    let lang = locale.language.languageCode?.identifier ?? "en"
    return lang == "es" ? template.es : template.en
}
