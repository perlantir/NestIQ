// NarrationTemplates.swift
// EN + ES string-interpolation templates per ScenarioType. Session 5
// adds a full translator pass; Session 4 ships a first cut sufficient
// for internal LO-facing summaries.

import Foundation

public enum NarrationTemplates {

    public static func render(
        facts: ScenarioFacts,
        audience: NarrationAudience,
        locale: Locale
    ) -> String {
        let isES = locale.language.languageCode?.identifier == "es"
        switch facts.scenarioType {
        case .amortization:
            return isES ? amortizationES(facts) : amortizationEN(facts)
        case .incomeQualification:
            return isES ? incomeQualES(facts) : incomeQualEN(facts)
        case .refinance:
            return isES ? refinanceES(facts) : refinanceEN(facts)
        case .totalCostAnalysis:
            return isES ? tcaES(facts) : tcaEN(facts)
        case .helocVsRefinance:
            return isES ? helocES(facts) : helocEN(facts)
        }
    }

    // MARK: Amortization

    private static func amortizationEN(_ f: ScenarioFacts) -> String {
        let name = f.borrowerFirstName ?? "the borrower"
        let piti = f.fields["monthlyPITI"] ?? "—"
        let rate = f.fields["rate"] ?? "—"
        let term = f.fields["termYears"] ?? "30"
        let totalInterest = f.fields["totalInterest"] ?? "—"
        return "At today's \(rate) note rate, \(name)'s \(term)-year fixed carries a monthly PITI of \(piti). "
            + "Across the life of the loan, interest totals roughly \(totalInterest). "
            + "Extra principal or a recast would shorten the payoff without refinancing."
    }

    private static func amortizationES(_ f: ScenarioFacts) -> String {
        let name = f.borrowerFirstName ?? "el prestatario"
        let piti = f.fields["monthlyPITI"] ?? "—"
        let rate = f.fields["rate"] ?? "—"
        let term = f.fields["termYears"] ?? "30"
        return "Con la tasa de \(rate), el pago mensual PITI de \(name) es de \(piti) a \(term) años. "
            + "Principal extra o un recast acortan el plazo sin necesidad de refinanciar."
    }

    // MARK: Income qualification

    private static func incomeQualEN(_ f: ScenarioFacts) -> String {
        let name = f.borrowerFirstName ?? "the borrower"
        let maxLoan = f.fields["maxLoan"] ?? "—"
        let frontDTI = f.fields["frontEndDTI"] ?? "—"
        let backDTI = f.fields["backEndDTI"] ?? "—"
        return "\(name) qualifies for up to \(maxLoan). Front-end DTI lands at \(frontDTI) "
            + "and back-end at \(backDTI) — both within agency limits for the selected program."
    }

    private static func incomeQualES(_ f: ScenarioFacts) -> String {
        let name = f.borrowerFirstName ?? "el prestatario"
        let maxLoan = f.fields["maxLoan"] ?? "—"
        return "\(name) califica para hasta \(maxLoan). DTI dentro de los límites de la agencia."
    }

    // MARK: Refinance

    private static func refinanceEN(_ f: ScenarioFacts) -> String {
        let name = f.borrowerFirstName ?? "the borrower"
        let savings = f.fields["monthlySavings"] ?? "—"
        let be = f.fields["breakEven"] ?? "—"
        return "The selected refi saves \(name) \(savings) per month. "
            + "Break-even on closing costs: \(be). Lifetime savings scale with hold period."
    }

    private static func refinanceES(_ f: ScenarioFacts) -> String {
        let savings = f.fields["monthlySavings"] ?? "—"
        return "El refinanciamiento ahorra \(savings) al mes frente al préstamo actual."
    }

    // MARK: TCA

    private static func tcaEN(_ f: ScenarioFacts) -> String {
        let winner = f.fields["lifeWinner"] ?? "the short-term option"
        return "Across horizons, \(winner) wins on total cost for most hold periods. "
            + "Shorter horizons may favor lower-closing options — match the horizon to the hold plan."
    }

    private static func tcaES(_ f: ScenarioFacts) -> String {
        let winner = f.fields["lifeWinner"] ?? "la opción más corta"
        return "En la mayoría de los horizontes, \(winner) gana en costo total."
    }

    // MARK: HELOC vs Refi

    private static func helocEN(_ f: ScenarioFacts) -> String {
        let blended = f.fields["blendedRate"] ?? "—"
        let refi = f.fields["refiRate"] ?? "—"
        return "Keeping the first mortgage and adding a HELOC blends to \(blended) — "
            + "vs a cash-out refi at \(refi). The HELOC is favorable when you expect "
            + "rates to normalize within the first-lien's remaining term."
    }

    private static func helocES(_ f: ScenarioFacts) -> String {
        let blended = f.fields["blendedRate"] ?? "—"
        return "Mantener la primera hipoteca con una HELOC resulta en una tasa mezclada de \(blended)."
    }
}
