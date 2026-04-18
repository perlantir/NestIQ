// PDFPages.swift
// SwiftUI views that render each PDF page at 612×792. Kept separate
// from the on-device results screens because PDFs are designed for
// print (always-light surfaces, serif narrative, fixed paper margins).

import SwiftUI

public struct PDFCoverPage: View {
    public let borrowerName: String
    public let loFullName: String
    public let loNMLS: String
    public let loCompany: String
    public let loEmail: String
    public let loPhone: String
    public let calculatorTitle: String
    public let generatedDate: String
    public let loanSummary: String
    public let heroPITI: String
    public let heroKPIs: [(label: String, value: String)]
    public let narrative: String

    public init(
        borrowerName: String,
        loFullName: String,
        loNMLS: String,
        loCompany: String,
        loEmail: String,
        loPhone: String,
        calculatorTitle: String,
        generatedDate: String,
        loanSummary: String,
        heroPITI: String,
        heroKPIs: [(label: String, value: String)],
        narrative: String
    ) {
        self.borrowerName = borrowerName
        self.loFullName = loFullName
        self.loNMLS = loNMLS
        self.loCompany = loCompany
        self.loEmail = loEmail
        self.loPhone = loPhone
        self.calculatorTitle = calculatorTitle
        self.generatedDate = generatedDate
        self.loanSummary = loanSummary
        self.heroPITI = heroPITI
        self.heroKPIs = heroKPIs
        self.narrative = narrative
    }

    private let inkPrimary = Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x0F / 255)
    private let inkSecondary = Color(red: 0x4A / 255, green: 0x48 / 255, blue: 0x40 / 255)
    private let inkTertiary = Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255)
    private let border = Color(red: 0xE5 / 255, green: 0xE1 / 255, blue: 0xD5 / 255)
    private let accent = Color(red: 0x1F / 255, green: 0x4D / 255, blue: 0x3F / 255)

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandStrip
            titleBlock
                .padding(.top, 36)
            heroStrip
                .padding(.top, 26)
            narrativeBlock
                .padding(.top, 28)
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 28)
        .frame(width: 612, height: 792)
        .background(Color.white)
    }

    private var brandStrip: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quotient")
                        .font(.custom("SourceSerif4", size: 30))
                        .foregroundStyle(inkPrimary)
                    Text("Mortgage analysis · prepared for you".uppercased())
                        .font(.system(size: 10.5, weight: .semibold))
                        .tracking(1.05)
                        .foregroundStyle(inkTertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(loFullName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(inkPrimary)
                    Text("Senior Loan Officer · NMLS \(loNMLS)")
                        .font(.system(size: 10.5))
                        .foregroundStyle(inkSecondary)
                    Text("\(loCompany) · \(loEmail)")
                        .font(.system(size: 10.5))
                        .foregroundStyle(inkSecondary)
                    Text(loPhone)
                        .font(.system(size: 10.5))
                        .foregroundStyle(inkSecondary)
                }
            }
            Rectangle().fill(inkPrimary).frame(height: 2)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(calculatorTitle + " · " + generatedDate)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(1.05)
                .foregroundStyle(accent)
            Text("For ")
                .font(.custom("SourceSerif4", size: 38))
                .foregroundStyle(inkPrimary)
                +
                Text(borrowerName)
                .font(.custom("SourceSerif4-It", size: 38))
                .foregroundStyle(inkPrimary)
            Text(loanSummary)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(inkSecondary)
        }
    }

    private var heroStrip: some View {
        VStack(spacing: 0) {
            Rectangle().fill(border).frame(height: 1)
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly payment · PITI".uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.0)
                        .foregroundStyle(inkTertiary)
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("$")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(inkTertiary)
                        Text(heroPITI)
                            .font(.system(size: 44, weight: .medium, design: .monospaced))
                            .foregroundStyle(inkPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(heroKPIs.indices, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(heroKPIs[i].label.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.0)
                            .foregroundStyle(inkTertiary)
                        Text(heroKPIs[i].value)
                            .font(.system(size: 22, weight: .medium, design: .monospaced))
                            .foregroundStyle(inkPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(border).frame(width: 1)
                    }
                }
            }
            .padding(.vertical, 22)
            Rectangle().fill(border).frame(height: 1)
        }
    }

    private var narrativeBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary".uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.0)
                .foregroundStyle(inkTertiary)
            Text(narrative)
                .font(.custom("SourceSerif4", size: 16))
                .foregroundStyle(inkPrimary)
                .lineSpacing(5)
                .frame(maxWidth: 520, alignment: .leading)
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle().fill(border).frame(height: 1)
            HStack {
                Text("Estimates for educational purposes · not a commitment to lend")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(inkTertiary)
                Spacer()
                Text("Page 1")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(inkTertiary)
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - Disclaimers page

public struct PDFDisclaimersPage: View {
    public let disclosureText: String
    public let loFullName: String
    public let loNMLS: String
    public let loCompany: String
    public let licensedStates: [String]
    public let generatedAt: String

    public init(
        disclosureText: String,
        loFullName: String,
        loNMLS: String,
        loCompany: String,
        licensedStates: [String],
        generatedAt: String
    ) {
        self.disclosureText = disclosureText
        self.loFullName = loFullName
        self.loNMLS = loNMLS
        self.loCompany = loCompany
        self.licensedStates = licensedStates
        self.generatedAt = generatedAt
    }

    private let ink = Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x0F / 255)
    private let ink2 = Color(red: 0x4A / 255, green: 0x48 / 255, blue: 0x40 / 255)
    private let ink3 = Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255)
    private let border = Color(red: 0xE5 / 255, green: 0xE1 / 255, blue: 0xD5 / 255)
    private let accent = Color(red: 0x1F / 255, green: 0x4D / 255, blue: 0x3F / 255)

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Disclosures".uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(1.05)
                .foregroundStyle(accent)
            Text("The fine print")
                .font(.custom("SourceSerif4", size: 28))
                .foregroundStyle(ink)
                .padding(.top, 4)

            Text(disclosureText)
                .font(.custom("SourceSerif4", size: 11))
                .foregroundStyle(ink2)
                .lineSpacing(4)
                .padding(.top, 18)
                .frame(maxWidth: 520, alignment: .leading)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 2) {
                Rectangle().fill(border).frame(height: 1).padding(.bottom, 8)
                Text(loCompany)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(ink2)
                Text("\(loFullName) · Individual NMLS \(loNMLS)")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(ink2)
                Text("Licensed: \(licensedStates.joined(separator: " · "))")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(ink2)
                Text("Equal Housing Opportunity")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(ink2)
                    .padding(.top, 6)
            }

            HStack {
                Text("Generated \(generatedAt)")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(ink3)
                Spacer()
                Text("Page 2")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(ink3)
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 28)
        .frame(width: 612, height: 792)
        .background(Color.white)
    }
}
