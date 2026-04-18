// States.swift
// State-specific disclosure library.
//
// Population policy (per 2026-04-17 kickoff):
//   - 11 named states: CA, TX, FL, NY, IL, PA, OH, GA, NC, MI, IA carry
//     state-specific drafted text with a regulator / statute citation
//     retrieved 2026-04-17. All tagged `CounselReviewStatus.pendingReview`,
//     `DisclosureProvenance.stateSpecific`.
//   - 39 remaining states + DC: generic fallback via `fallbackDisclosure`
//     with `DisclosureProvenance.fallback`. `needsCounselReview` on these
//     is always true (both the text and the state-specific drafting are
//     outstanding).
//
// Compliance counsel review flow:
//   - Session 5 walks each `pendingReview` entry and moves it to
//     `.reviewedApproved(attorney:date:)` or `.reviewedNeedsRevision(notes:)`
//     in place. The 39 fallbacks also need state-specific drafting before
//     they move past `.fallback`.
//
// Citation discipline:
//   - Every named state's `sourceCitation` begins with the issuing
//     authority followed by the statute or guidance citation. Do NOT
//     modify these without re-verifying the source and updating
//     `retrievalDate`. `sourceCitation` strings are audited by counsel
//     against the live source during Session 5.

import Foundation
import QuotientFinance

/// Canonical retrieval date stamp for Session 2's state-specific texts.
private let retrieved = iso8601("2026-04-17")

// MARK: - Public lookup

/// Return the (up to one) state-specific disclosure for the given scenario
/// type in `state`. Current library contains exactly one disclosure per
/// state (scenarioType = nil, applies to all scenario types); the API
/// surface supports multiple entries per state for future expansion.
func stateDisclosures(for state: USState, scenarioType: ScenarioType) -> [Disclosure] {
    let entry = entries[state] ?? fallbackDisclosure(for: state)
    // Filter to entries whose scenarioType is nil (universal) or matches.
    if let st = entry.scenarioType, st != scenarioType { return [] }
    return [entry]
}

// MARK: - Named states (11)

private let entries: [USState: Disclosure] = [
    .CA: california,
    .TX: texas,
    .FL: florida,
    .NY: newYork,
    .IL: illinois,
    .PA: pennsylvania,
    .OH: ohio,
    .GA: georgia,
    .NC: northCarolina,
    .MI: michigan,
    .IA: iowa
]

private let california = Disclosure(
    state: .CA,
    textEN: """
    This document is an illustrative calculation prepared by a licensed \
    mortgage loan originator for informational purposes only. It is not a \
    Loan Estimate under 12 C.F.R. §1026.37, nor a commitment to lend. \
    Actual rates, APR, closing costs, and loan eligibility are subject to \
    underwriting, credit, property, income, and program verification. In \
    California, residential mortgage lending is regulated by the \
    Department of Financial Protection and Innovation (DFPI) under the \
    California Residential Mortgage Lending Act (Fin. Code §50000 et seq.).
    """,
    textES: """
    Este documento es un cálculo ilustrativo preparado por un oficial de \
    préstamos hipotecarios licenciado solo con fines informativos. No es \
    una Estimación del Préstamo según 12 C.F.R. §1026.37, ni un \
    compromiso de préstamo. Las tasas reales, APR, costos de cierre y \
    elegibilidad del préstamo están sujetos a verificación de \
    suscripción, crédito, propiedad, ingresos y programa. En California, \
    los préstamos hipotecarios residenciales están regulados por el \
    Departamento de Protección Financiera e Innovación (DFPI) bajo la \
    Ley de Préstamos Hipotecarios Residenciales de California (Fin. Code \
    §50000 et seq.).
    """,
    // Source: California Department of Financial Protection and Innovation,
    // California Residential Mortgage Lending Act — dfpi.ca.gov, retrieved
    // 2026-04-17.
    sourceCitation: "CA DFPI · Cal. Fin. Code §50000 et seq. (California Residential Mortgage Lending Act)",
    retrievalDate: retrieved,
    provenance: .stateSpecific
)

private let texas = Disclosure(
    state: .TX,
    textEN: """
    This calculation is informational only and does not constitute a Loan \
    Estimate, a commitment to lend, or an offer of credit. In Texas, \
    consumers wishing to file a complaint against a residential mortgage \
    loan originator should contact the Texas Department of Savings and \
    Mortgage Lending, which regulates licensed RMLOs under Texas Finance \
    Code Chapter 157. Additional consumer protections apply under the \
    Texas Home Equity Provisions of Article XVI, Section 50 of the Texas \
    Constitution.
    """,
    textES: """
    Este cálculo es solo informativo y no constituye una Estimación del \
    Préstamo, un compromiso de préstamo, ni una oferta de crédito. En \
    Texas, los consumidores que deseen presentar una queja contra un \
    oficial de préstamos hipotecarios residenciales deben contactar al \
    Departamento de Ahorros y Préstamos Hipotecarios de Texas (TDSML), \
    que regula a los RMLOs licenciados bajo el Capítulo 157 del Código \
    Financiero de Texas. Se aplican protecciones adicionales bajo las \
    Disposiciones de Préstamo con Garantía Hipotecaria del Artículo XVI, \
    Sección 50, de la Constitución de Texas.
    """,
    // Source: Texas Department of Savings and Mortgage Lending (sml.texas.gov);
    // Tex. Fin. Code Ch. 157; Tex. Const. art. XVI, §50 — retrieved 2026-04-17.
    sourceCitation: "TX Department of Savings and Mortgage Lending · Tex. Fin. Code Ch. 157 · Tex. Const. art. XVI, §50",
    retrievalDate: retrieved,
    provenance: .stateSpecific
)

private let florida = Disclosure(
    state: .FL,
    textEN: """
    Illustrative calculation only. Not a Loan Estimate under 12 C.F.R. \
    §1026.37 and not a commitment to lend. In Florida, residential \
    mortgage loan originators, brokers, and lenders are licensed and \
    regulated by the Florida Office of Financial Regulation (OFR) under \
    Chapter 494, Florida Statutes. Actual rate, APR, and program \
    availability are determined at underwriting and may differ from \
    figures presented here.
    """,
    textES: """
    Cálculo solo ilustrativo. No es una Estimación del Préstamo según \
    12 C.F.R. §1026.37 ni un compromiso de préstamo. En Florida, los \
    oficiales, corredores y prestamistas hipotecarios residenciales están \
    licenciados y regulados por la Oficina de Regulación Financiera de \
    Florida (OFR) bajo el Capítulo 494, Estatutos de Florida. La tasa \
    real, APR y disponibilidad del programa se determinan en la \
    suscripción y pueden diferir de las cifras presentadas aquí.
    """,
    // Source: Florida Office of Financial Regulation (flofr.gov); Fla. Stat.
    // Ch. 494 — retrieved 2026-04-17.
    sourceCitation: "FL Office of Financial Regulation · Fla. Stat. Ch. 494",
    retrievalDate: retrieved,
    provenance: .stateSpecific
)

private let newYork = Disclosure(
    state: .NY,
    textEN: """
    Illustrative calculation prepared by a licensed mortgage loan \
    originator. Not a Loan Estimate, not a commitment to lend, and not an \
    offer of credit. In New York, residential mortgage loan originators \
    and lenders are supervised by the New York State Department of \
    Financial Services (DFS) under Banking Law Article 12-D and 3 NYCRR \
    Part 38. Rates and terms are subject to change without notice until \
    locked at application.
    """,
    textES: """
    Cálculo ilustrativo preparado por un oficial de préstamos \
    hipotecarios licenciado. No es una Estimación del Préstamo, no es un \
    compromiso de préstamo, ni una oferta de crédito. En Nueva York, los \
    oficiales y prestamistas hipotecarios residenciales son supervisados \
    por el Departamento de Servicios Financieros del Estado de Nueva \
    York (DFS) bajo el Artículo 12-D de la Ley Bancaria y 3 NYCRR Parte \
    38. Las tasas y los términos están sujetos a cambios sin previo \
    aviso hasta que se bloqueen en la solicitud.
    """,
    // Source: NYS Department of Financial Services (dfs.ny.gov); N.Y. Banking
    // Law Art. 12-D; 3 NYCRR Part 38 — retrieved 2026-04-17.
    sourceCitation: "NY Department of Financial Services · N.Y. Banking Law Art. 12-D · 3 NYCRR Part 38",
    retrievalDate: retrieved,
    provenance: .stateSpecific
)

private let illinois = Disclosure(
    state: .IL,
    textEN: """
    Illustrative calculation only. Not a Loan Estimate under 12 C.F.R. \
    §1026.37 and not a commitment to lend. In Illinois, residential \
    mortgage licensees are regulated by the Illinois Department of \
    Financial and Professional Regulation (IDFPR), Division of Banking, \
    under the Residential Mortgage License Act of 1987, 205 ILCS 635. \
    Actual rates, fees, and APR are determined at underwriting.
    """,
    textES: """
    Cálculo solo ilustrativo. No es una Estimación del Préstamo según \
    12 C.F.R. §1026.37 ni un compromiso de préstamo. En Illinois, los \
    licenciatarios hipotecarios residenciales están regulados por el \
    Departamento de Regulación Financiera y Profesional de Illinois \
    (IDFPR), División Bancaria, bajo la Ley de Licencias Hipotecarias \
    Residenciales de 1987, 205 ILCS 635. Las tasas, tarifas y APR \
    reales se determinan en la suscripción.
    """,
    // Source: Illinois Department of Financial and Professional Regulation —
    // Division of Banking (idfpr.illinois.gov); 205 ILCS 635 — retrieved 2026-04-17.
    sourceCitation: "IL Department of Financial and Professional Regulation · 205 ILCS 635 (RMLA of 1987)",
    retrievalDate: retrieved,
    provenance: .stateSpecific
)

private let pennsylvania = Disclosure(
    state: .PA,
    textEN: """
    Illustrative calculation only. Not a Loan Estimate and not a \
    commitment to lend. In Pennsylvania, residential mortgage lending is \
    licensed and supervised by the Department of Banking and Securities \
    under the Mortgage Licensing Act, 7 Pa.C.S. Chapter 61. Actual \
    rate, APR, and closing costs are subject to change until locked at \
    application and may differ from the figures shown here.
    """,
    textES: """
    Cálculo solo ilustrativo. No es una Estimación del Préstamo ni un \
    compromiso de préstamo. En Pensilvania, los préstamos hipotecarios \
    residenciales están licenciados y supervisados por el Departamento \
    de Banca y Valores bajo la Ley de Licencias Hipotecarias, 7 Pa.C.S. \
    Capítulo 61. La tasa, APR y costos de cierre reales están sujetos \
    a cambios hasta que se bloqueen en la solicitud y pueden diferir \
    de las cifras mostradas aquí.
    """,
    // Source: Pennsylvania Department of Banking and Securities (dobs.pa.gov);
    // 7 Pa.C.S. Ch. 61 (Mortgage Licensing Act) — retrieved 2026-04-17.
    sourceCitation: "PA Department of Banking and Securities · 7 Pa.C.S. Ch. 61 (Mortgage Licensing Act)",
    retrievalDate: retrieved,
    provenance: .stateSpecific
)

private let ohio = Disclosure(
    state: .OH,
    textEN: """
    Illustrative calculation only. Not a Loan Estimate under 12 C.F.R. \
    §1026.37 and not a commitment to lend. In Ohio, residential mortgage \
    lenders and loan originators are regulated by the Division of \
    Financial Institutions, Ohio Department of Commerce, under Ohio \
    Revised Code Chapter 1322. Final rate, APR, and program eligibility \
    are determined at underwriting.
    """,
    textES: """
    Cálculo solo ilustrativo. No es una Estimación del Préstamo según \
    12 C.F.R. §1026.37 ni un compromiso de préstamo. En Ohio, los \
    prestamistas hipotecarios residenciales y oficiales de préstamos \
    están regulados por la División de Instituciones Financieras, \
    Departamento de Comercio de Ohio, bajo el Código Revisado de Ohio \
    Capítulo 1322. La tasa, APR y elegibilidad del programa finales se \
    determinan en la suscripción.
    """,
    // Source: Ohio Division of Financial Institutions (com.ohio.gov/dfi);
    // O.R.C. Ch. 1322 — retrieved 2026-04-17.
    sourceCitation: "OH Division of Financial Institutions · O.R.C. Ch. 1322",
    retrievalDate: retrieved,
    provenance: .stateSpecific
)

private let georgia = Disclosure(
    state: .GA,
    textEN: """
    Illustrative calculation only. Not a Loan Estimate and not a \
    commitment to lend. In Georgia, residential mortgage lenders, \
    brokers, and processors are licensed and regulated by the Georgia \
    Department of Banking and Finance under the Georgia Residential \
    Mortgage Act, O.C.G.A. §7-1-1000 et seq. Actual rate, APR, and \
    loan eligibility are subject to underwriting.
    """,
    textES: """
    Cálculo solo ilustrativo. No es una Estimación del Préstamo ni un \
    compromiso de préstamo. En Georgia, los prestamistas, corredores y \
    procesadores hipotecarios residenciales están licenciados y \
    regulados por el Departamento de Banca y Finanzas de Georgia bajo \
    la Ley Hipotecaria Residencial de Georgia, O.C.G.A. §7-1-1000 \
    et seq. La tasa, APR y elegibilidad del préstamo reales están \
    sujetas a la suscripción.
    """,
    // Source: Georgia Department of Banking and Finance (dbf.georgia.gov);
    // O.C.G.A. §7-1-1000 et seq. — retrieved 2026-04-17.
    sourceCitation: "GA Department of Banking and Finance · O.C.G.A. §7-1-1000 et seq. (Georgia Residential Mortgage Act)",
    retrievalDate: retrieved,
    provenance: .stateSpecific
)

private let northCarolina = Disclosure(
    state: .NC,
    textEN: """
    Illustrative calculation only. Not a Loan Estimate and not a \
    commitment to lend. In North Carolina, mortgage loan originators, \
    brokers, and lenders are licensed and regulated by the North \
    Carolina Commissioner of Banks (NCCOB) under the Secure and Fair \
    Enforcement Mortgage Licensing Act, N.C.G.S. §53-244.010 et seq. \
    Actual rate, APR, and program terms are subject to change until \
    locked at application.
    """,
    textES: """
    Cálculo solo ilustrativo. No es una Estimación del Préstamo ni un \
    compromiso de préstamo. En Carolina del Norte, los oficiales, \
    corredores y prestamistas hipotecarios están licenciados y \
    regulados por el Comisionado de Bancos de Carolina del Norte \
    (NCCOB) bajo la Ley de Licencias Hipotecarias Segura y Justa, \
    N.C.G.S. §53-244.010 et seq. La tasa, APR y términos del programa \
    reales están sujetos a cambios hasta que se bloqueen en la \
    solicitud.
    """,
    // Source: NC Commissioner of Banks (nccob.gov); N.C.G.S. §53-244 —
    // retrieved 2026-04-17.
    sourceCitation: "NC Commissioner of Banks · N.C.G.S. §53-244.010 et seq. (SAFE Act)",
    retrievalDate: retrieved,
    provenance: .stateSpecific
)

private let michigan = Disclosure(
    state: .MI,
    textEN: """
    Illustrative calculation only. Not a Loan Estimate under 12 C.F.R. \
    §1026.37 and not a commitment to lend. In Michigan, residential \
    mortgage brokers, lenders, and servicers are licensed and regulated \
    by the Department of Insurance and Financial Services (DIFS) under \
    the Mortgage Brokers, Lenders, and Servicers Licensing Act, \
    MCL §445.1651 et seq. Actual rates and APR are determined at \
    underwriting.
    """,
    textES: """
    Cálculo solo ilustrativo. No es una Estimación del Préstamo según \
    12 C.F.R. §1026.37 ni un compromiso de préstamo. En Míchigan, los \
    corredores, prestamistas y administradores hipotecarios \
    residenciales están licenciados y regulados por el Departamento de \
    Seguros y Servicios Financieros (DIFS) bajo la Ley de Licencias \
    para Corredores, Prestamistas y Administradores Hipotecarios, MCL \
    §445.1651 et seq. Las tasas reales y el APR se determinan en la \
    suscripción.
    """,
    // Source: MI Department of Insurance and Financial Services (michigan.gov/difs);
    // MCL §445.1651 et seq. — retrieved 2026-04-17.
    sourceCitation: "MI Department of Insurance and Financial Services · MCL §445.1651 et seq.",
    retrievalDate: retrieved,
    provenance: .stateSpecific
)

private let iowa = Disclosure(
    state: .IA,
    textEN: """
    Illustrative calculation only. Not a Loan Estimate and not a \
    commitment to lend. In Iowa, mortgage bankers and brokers are \
    licensed and regulated by the Iowa Division of Banking under Iowa \
    Code Chapter 535B. Actual rate, APR, and loan terms are subject \
    to underwriting and verification before any loan can be issued.
    """,
    textES: """
    Cálculo solo ilustrativo. No es una Estimación del Préstamo ni un \
    compromiso de préstamo. En Iowa, los banqueros y corredores \
    hipotecarios están licenciados y regulados por la División de \
    Banca de Iowa bajo el Capítulo 535B del Código de Iowa. La tasa, \
    APR y los términos del préstamo reales están sujetos a la \
    suscripción y verificación antes de que se emita cualquier préstamo.
    """,
    // Source: Iowa Division of Banking (idob.state.ia.us); Iowa Code
    // Ch. 535B — retrieved 2026-04-17.
    sourceCitation: "IA Division of Banking · Iowa Code Ch. 535B (Mortgage Bankers and Brokers)",
    retrievalDate: retrieved,
    provenance: .stateSpecific
)

// MARK: - Fallback for the 39 stubbed states + DC

/// Generic fallback disclosure for states whose state-specific text has
/// not yet been drafted. Used verbatim for all 39 remaining states + DC.
/// Counsel-reviewable in Session 5 after state-specific drafting lands.
func fallbackDisclosure(for state: USState) -> Disclosure {
    Disclosure(
        state: state,
        textEN: """
        Illustrative calculation only. Not a Loan Estimate under \
        12 C.F.R. §1026.37 and not a commitment to lend. Rates, APR, \
        closing costs, and loan eligibility are subject to underwriting, \
        credit, property, income, and program verification. \
        State-specific disclosures for \(state.displayName) will be \
        populated before distribution.
        """,
        textES: """
        Cálculo solo ilustrativo. No es una Estimación del Préstamo \
        según 12 C.F.R. §1026.37 ni un compromiso de préstamo. Las \
        tasas, APR, costos de cierre y elegibilidad del préstamo están \
        sujetos a verificación de suscripción, crédito, propiedad, \
        ingresos y programa. Las divulgaciones específicas del estado \
        para \(state.displayName) se completarán antes de la \
        distribución.
        """,
        sourceCitation: "Generic fallback — state-specific text pending drafting",
        retrievalDate: retrieved,
        counselReviewStatus: .pendingReview,
        provenance: .fallback
    )
}

// MARK: - Internals

/// Build a UTC Date from a `YYYY-MM-DD` string. Deterministic across locales.
private func iso8601(_ yyyymmdd: String) -> Date {
    let parts = yyyymmdd.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return Date() }
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    var dc = DateComponents()
    dc.timeZone = cal.timeZone
    dc.year = parts[0]
    dc.month = parts[1]
    dc.day = parts[2]
    return cal.date(from: dc) ?? Date()
}
