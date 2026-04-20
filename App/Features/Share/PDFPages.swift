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
    public let accentHex: String
    public let logoData: Data?
    public let loPhotoData: Data?
    public let heroLabel: String
    public let heroValuePrefix: String
    public let heroValueSuffix: String
    public let pageIndex: Int
    public let pageCount: Int

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
        narrative: String,
        accentHex: String = "#1F4D3F",
        logoData: Data? = nil,
        loPhotoData: Data? = nil,
        heroLabel: String = "Monthly payment · PITI",
        heroValuePrefix: String = "$",
        heroValueSuffix: String = "",
        pageIndex: Int = 1,
        pageCount: Int = 1
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
        self.accentHex = accentHex
        self.logoData = logoData
        self.loPhotoData = loPhotoData
        self.heroLabel = heroLabel
        self.heroValuePrefix = heroValuePrefix
        self.heroValueSuffix = heroValueSuffix
        self.pageIndex = pageIndex
        self.pageCount = pageCount
    }

    private let inkPrimary = Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x0F / 255)
    private let inkSecondary = Color(red: 0x4A / 255, green: 0x48 / 255, blue: 0x40 / 255)
    private let inkTertiary = Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255)
    private let border = Color(red: 0xE5 / 255, green: 0xE1 / 255, blue: 0xD5 / 255)
    private var accent: Color { Color(brandHex: accentHex) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PDFPageHeader(pageIndex: pageIndex, pageCount: pageCount, date: generatedDate)
                .padding(.bottom, 24)
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
        .padding(.top, 18)
        .padding(.bottom, 28)
        .frame(width: 612, height: 792)
        .background(Color.white)
    }

    private var brandStrip: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Optional custom company logo on page 1. The NestIQ wordmark
            // now lives in PDFPageHeader above; this block is only for an
            // LO's own mark if they've uploaded one.
            if let logoData, let logo = UIImage(data: logoData) {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 36)
            }
            HStack(alignment: .top, spacing: 14) {
                signatureBlock
                Spacer(minLength: 0)
                if let loPhotoData, let photo = UIImage(data: loPhotoData) {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(border, lineWidth: 1))
                }
            }
            Rectangle().fill(inkPrimary).frame(height: 2)
        }
    }

    /// Session 5N.3: single-source-of-truth signature block. Four lines
    /// from one LenderProfile record (no more `tagline` second block).
    /// Company renders on its own line only when populated; email +
    /// phone join on one line with a middot separator.
    private var signatureBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(loFullName)
                .font(.custom("SourceSerif4", size: 16))
                .foregroundStyle(inkPrimary)
            Text("Senior Loan Officer · NMLS \(loNMLS)")
                .font(.system(size: 10.5))
                .foregroundStyle(inkSecondary)
            if !loCompany.isEmpty, loCompany != "—" {
                Text(loCompany)
                    .font(.system(size: 10.5))
                    .foregroundStyle(inkSecondary)
            }
            Text(contactLine)
                .font(.system(size: 10.5))
                .foregroundStyle(inkSecondary)
        }
    }

    private var contactLine: String {
        switch (loEmail.isEmpty, loPhone.isEmpty) {
        case (true, true): return ""
        case (false, true): return loEmail
        case (true, false): return loPhone
        case (false, false): return "\(loEmail) · \(loPhone)"
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
                    Text(heroLabel.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.0)
                        .foregroundStyle(inkTertiary)
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        if !heroValuePrefix.isEmpty {
                            Text(heroValuePrefix)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(inkTertiary)
                        }
                        Text(heroPITI)
                            .font(.system(size: 44, weight: .medium, design: .monospaced))
                            .foregroundStyle(inkPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        if !heroValueSuffix.isEmpty {
                            Text(heroValueSuffix)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(inkTertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(2)
                ForEach(heroKPIs.indices, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(heroKPIs[i].label.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.0)
                            .foregroundStyle(inkTertiary)
                        Text(heroKPIs[i].value)
                            .font(.system(size: 22, weight: .medium, design: .monospaced))
                            .foregroundStyle(inkPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
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
        VStack(spacing: 4) {
            Rectangle().fill(border).frame(height: 1)
            Text("Estimates for educational purposes · not a commitment to lend")
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundStyle(inkTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
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
    public let headerDate: String
    public let pageIndex: Int
    public let pageCount: Int

    public init(
        disclosureText: String,
        loFullName: String,
        loNMLS: String,
        loCompany: String,
        licensedStates: [String],
        generatedAt: String,
        headerDate: String? = nil,
        pageIndex: Int = 2,
        pageCount: Int = 2
    ) {
        self.disclosureText = disclosureText
        self.loFullName = loFullName
        self.loNMLS = loNMLS
        self.loCompany = loCompany
        self.licensedStates = licensedStates
        self.generatedAt = generatedAt
        // Fall back to generatedAt if no explicit header date passed;
        // most callers supply one matching the cover's "MMMM d, yyyy"
        // format so the header reads consistently across pages.
        self.headerDate = headerDate ?? generatedAt
        self.pageIndex = pageIndex
        self.pageCount = pageCount
    }

    private let ink = Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x0F / 255)
    private let ink2 = Color(red: 0x4A / 255, green: 0x48 / 255, blue: 0x40 / 255)
    private let ink3 = Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255)
    private let border = Color(red: 0xE5 / 255, green: 0xE1 / 255, blue: 0xD5 / 255)
    private let accent = Color(red: 0x1F / 255, green: 0x4D / 255, blue: 0x3F / 255)

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PDFPageHeader(pageIndex: pageIndex, pageCount: pageCount, date: headerDate)
                .padding(.bottom, 24)
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
                Text("Equal Housing Opportunity · Generated \(generatedAt)")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(ink2)
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, 48)
        .padding(.top, 18)
        .padding(.bottom, 28)
        .frame(width: 612, height: 792)
        .background(Color.white)
    }
}
