// OnboardingCopy.swift
// String constants for the 6-step tour pulled out to keep OnboardingFlow
// under SwiftLint's 140-column line-length rule. Session 5 i18n moves
// these into `Localizable.xcstrings`.

enum OnboardingCopy {
    static let welcome = """
Five calculators, built for loan officers who care about how the numbers \
read on paper. Swipe to see what's inside.
"""

    static let amortization = """
Enter loan, taxes, and insurance. See the PITI, the balance curve, every \
row of the schedule. Extra principal and recast built in.
"""

    static let incomeQual = """
Front- and back-end DTI against agency limits. Tells you not just the \
number — but why the number.
"""

    static let refinance = """
Three refi options against the current loan. Monthly savings, lifetime \
delta, NPV at a discount rate you choose.
"""

    static let tca = """
Compare 30-yr vs 15-yr vs buydown across 5, 7, 10, 15, and 30-year \
horizons. Winner highlighted per row.
"""

    static let heloc = """
Blended rate math, a stress path for rate shocks, and a plain-English \
verdict at the bottom.
"""
}
