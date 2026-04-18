// Templates.swift
// EN + ES disclaimer copy for every `DisclaimerContext`.
//
// Keep entries short and plain — these appear under heroes, in rate cards,
// inside PDF footers. Longer state-specific legal text lives in
// Disclosures/States.swift.
//
// Counsel review policy: every template is Session-5 counsel-reviewable.
// Text tagged `pendingReview` by default at the bundle level via
// `DisclosureBundle`. Disclaimer text itself is not state-scoped and not
// versioned with `ComplianceRuleVersion` — it's foundational product copy.
//
// Source-line-wrapping pattern: triple-quoted string with a trailing `\`
// on each intermediate source line suppresses the newline, so the
// rendered string is a single paragraph while the source respects
// SwiftLint's line-length rule.

import Foundation

struct DisclaimerTemplate {
    let en: String
    let es: String
}

/// Map of every context → EN/ES copy. Internal; callers go through
/// `requiredDisclaimer(context:locale:)`.
let disclaimerTemplates: [DisclaimerContext: DisclaimerTemplate] = [
    .marketingGeneral: DisclaimerTemplate(
        en: """
            Calculations shown are for illustrative purposes only. Actual \
            rates, terms, and program availability are subject to change \
            and verification.
            """,
        es: """
            Los cálculos mostrados son solo para fines ilustrativos. Las \
            tasas, los términos y la disponibilidad del programa reales \
            están sujetos a cambios y verificación.
            """
    ),
    .rateQuoteNotOffer: DisclaimerTemplate(
        en: """
            Rates shown are indicative only and not a binding offer. Actual \
            rate is locked at time of application subject to credit, \
            income, and property review.
            """,
        es: """
            Las tasas mostradas son solo indicativas y no una oferta \
            vinculante. La tasa real se fija al momento de la solicitud \
            sujeto a revisión de crédito, ingresos y propiedad.
            """
    ),
    .preQualNotCommitment: DisclaimerTemplate(
        en: """
            Pre-qualification is not a commitment to lend. Full \
            underwriting, verification of income and assets, and property \
            approval are required before any loan can be issued.
            """,
        es: """
            La precalificación no es un compromiso de préstamo. Se \
            requiere una suscripción completa, verificación de ingresos y \
            activos, y aprobación de la propiedad antes de emitir \
            cualquier préstamo.
            """
    ),
    .aprApproximation: DisclaimerTemplate(
        en: """
            APR shown is calculated per the Regulation Z actuarial method \
            using estimated finance charges. Final APR may vary based on \
            actual fees and closing timing.
            """,
        es: """
            El APR mostrado se calcula según el método actuarial de la \
            Regulación Z usando cargos financieros estimados. El APR final \
            puede variar según los cargos reales y el momento del cierre.
            """
    ),
    .pdfCoverFooter: DisclaimerTemplate(
        en: """
            Prepared for illustrative purposes by a licensed mortgage loan \
            originator. Not a Loan Estimate. Not a commitment to lend. \
            Subject to credit, income, and property approval.
            """,
        es: """
            Preparado con fines ilustrativos por un oficial de préstamos \
            hipotecarios licenciado. No es una Estimación del Préstamo. \
            No es un compromiso de préstamo. Sujeto a aprobación de \
            crédito, ingresos y propiedad.
            """
    ),
    .pdfDisclaimersAppendix: DisclaimerTemplate(
        en: """
            Refer to the state-specific and general disclosures that \
            follow. Borrowers should review all disclosures before relying \
            on any figures presented.
            """,
        es: """
            Consulte las divulgaciones específicas del estado y generales \
            que siguen. Los prestatarios deben revisar todas las \
            divulgaciones antes de confiar en cualquier cifra presentada.
            """
    ),
    .narrationGenerated: DisclaimerTemplate(
        en: """
            This narrative was generated on-device from the figures above. \
            Review all calculations with your licensed loan officer before \
            making any financial decisions.
            """,
        es: """
            Esta narrativa fue generada en el dispositivo a partir de las \
            cifras anteriores. Revise todos los cálculos con su oficial de \
            préstamos licenciado antes de tomar decisiones financieras.
            """
    ),
    .narrativeRegenerated: DisclaimerTemplate(
        en: """
            This narrative has been regenerated. The wording may differ \
            from earlier versions, but the underlying figures remain \
            identical. Confirm all numbers with your loan officer.
            """,
        es: """
            Esta narrativa ha sido regenerada. La redacción puede diferir \
            de versiones anteriores, pero las cifras subyacentes siguen \
            siendo idénticas. Confirme todos los números con su oficial \
            de préstamos.
            """
    ),
    .helocStressProjection: DisclaimerTemplate(
        en: """
            HELOC stress projections use assumed index rate paths and do \
            not guarantee future rates. Actual monthly payments will vary \
            with the index and margin applied at each rate reset.
            """,
        es: """
            Las proyecciones de estrés de HELOC usan rutas de tasas de \
            índice asumidas y no garantizan tasas futuras. Los pagos \
            mensuales reales variarán con el índice y margen aplicados en \
            cada reinicio de tasa.
            """
    ),
    .scenarioSavedReminder: DisclaimerTemplate(
        en: """
            Saved calculations are illustrative and do not commit the \
            lender or the borrower to any specific loan terms.
            """,
        es: """
            Los cálculos guardados son ilustrativos y no comprometen al \
            prestamista ni al prestatario con términos de préstamo \
            específicos.
            """
    )
]
