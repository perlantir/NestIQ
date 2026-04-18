// Models.swift
// SwiftData models per DEVELOPMENT.md § "Data model (SwiftData)".
// Three root models — LenderProfile (single-row), Borrower, Scenario —
// plus their supporting enums. Inputs / outputs are stored as JSON blobs
// so the calculator-specific payloads stay isolated from the schema.

import Foundation
import SwiftData

public enum CalculatorType: String, Codable, Sendable, CaseIterable {
    case amortization
    case incomeQualification
    case refinance
    case totalCostAnalysis
    case helocVsRefinance

    public var shortLabel: String {
        switch self {
        case .amortization: "Amortization"
        case .incomeQualification: "Income qual"
        case .refinance: "Refi compare"
        case .totalCostAnalysis: "Total cost"
        case .helocVsRefinance: "HELOC vs Refi"
        }
    }

    public var number: String {
        switch self {
        case .amortization: "01"
        case .incomeQualification: "02"
        case .refinance: "03"
        case .totalCostAnalysis: "04"
        case .helocVsRefinance: "05"
        }
    }
}

public enum BorrowerSource: String, Codable, Sendable {
    case contacts
    case manual
    case recent
}

public enum AppearancePreference: String, Codable, Sendable, CaseIterable {
    case light, dark, system
}

public enum DensityPreference: String, Codable, Sendable, CaseIterable {
    case comfortable, compact
}

/// How the LO's NMLS ID surfaces on the borrower-facing PDF.
public enum NMLSDisplayFormat: String, Codable, Sendable, CaseIterable {
    /// `NMLS #1428391` — the ID alone.
    case idOnly
    /// `NMLS #1428391 · nmlsconsumeraccess.org/...` — ID plus the
    /// individual's Consumer Access deep link. Default.
    case idAndURL
    /// Omit the NMLS line from the PDF entirely. LOs who don't want the
    /// footer on their borrower-facing output pick this.
    case none

    public var display: String {
        switch self {
        case .idOnly:  "ID only"
        case .idAndURL: "ID + Consumer Access"
        case .none:    "Omit"
        }
    }
}

/// Language the federal Equal Housing Opportunity statement renders in
/// on borrower-facing PDFs. Distinct from the app's `preferredLanguage`
/// so an EN-speaking LO can still issue ES statements.
public enum EHOLanguage: String, Codable, Sendable, CaseIterable {
    case en, es

    public var display: String {
        switch self {
        case .en: "English"
        case .es: "Español"
        }
    }
}

@Model
public final class LenderProfile {
    @Attribute(.unique)
    public var id: UUID
    public var appleUserID: String
    public var firstName: String
    public var lastName: String
    public var photoData: Data?
    public var nmlsId: String
    public var licensedStates: [String]
    public var companyName: String
    public var companyLogoData: Data?
    public var brandColorHex: String
    public var phone: String
    public var email: String
    public var tagline: String?
    public var preferredLanguage: String
    public var faceIDEnabled: Bool
    public var hapticsEnabled: Bool
    public var soundsEnabled: Bool
    public var densityPreferenceRaw: String
    public var appearanceRaw: String
    public var pdfLanguage: String = "en"
    public var nmlsDisplayFormatRaw: String = NMLSDisplayFormat.idAndURL.rawValue
    public var ehoLanguageRaw: String = EHOLanguage.en.rawValue
    public var hasCompletedOnboarding: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        appleUserID: String,
        firstName: String = "",
        lastName: String = "",
        nmlsId: String = "",
        licensedStates: [String] = [],
        companyName: String = "",
        brandColorHex: String = "#1F4D3F",
        phone: String = "",
        email: String = "",
        preferredLanguage: String = "en",
        pdfLanguage: String = "en",
        nmlsDisplayFormat: NMLSDisplayFormat = .idAndURL,
        ehoLanguage: EHOLanguage = .en,
        faceIDEnabled: Bool = false,
        hapticsEnabled: Bool = true,
        soundsEnabled: Bool = false,
        densityPreference: DensityPreference = .comfortable,
        appearance: AppearancePreference = .system,
        hasCompletedOnboarding: Bool = false
    ) {
        let now = Date()
        self.id = UUID()
        self.appleUserID = appleUserID
        self.firstName = firstName
        self.lastName = lastName
        self.nmlsId = nmlsId
        self.licensedStates = licensedStates
        self.companyName = companyName
        self.brandColorHex = brandColorHex
        self.phone = phone
        self.email = email
        self.preferredLanguage = preferredLanguage
        self.pdfLanguage = pdfLanguage
        self.nmlsDisplayFormatRaw = nmlsDisplayFormat.rawValue
        self.ehoLanguageRaw = ehoLanguage.rawValue
        self.faceIDEnabled = faceIDEnabled
        self.hapticsEnabled = hapticsEnabled
        self.soundsEnabled = soundsEnabled
        self.densityPreferenceRaw = densityPreference.rawValue
        self.appearanceRaw = appearance.rawValue
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = now
        self.updatedAt = now
    }

    public var appearance: AppearancePreference {
        get { AppearancePreference(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    public var density: DensityPreference {
        get { DensityPreference(rawValue: densityPreferenceRaw) ?? .comfortable }
        set { densityPreferenceRaw = newValue.rawValue }
    }

    public var nmlsDisplayFormat: NMLSDisplayFormat {
        get { NMLSDisplayFormat(rawValue: nmlsDisplayFormatRaw) ?? .idAndURL }
        set { nmlsDisplayFormatRaw = newValue.rawValue }
    }

    public var ehoLanguage: EHOLanguage {
        get { EHOLanguage(rawValue: ehoLanguageRaw) ?? .en }
        set { ehoLanguageRaw = newValue.rawValue }
    }

    public var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    public var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}

@Model
public final class Borrower {
    @Attribute(.unique)
    public var id: UUID
    public var firstName: String
    public var lastName: String
    public var email: String?
    public var phone: String?
    public var propertyAddress: String?
    public var propertyState: String?
    public var propertyZip: String?
    public var notes: String?
    public var sourceRaw: String
    public var contactIdentifier: String?
    @Relationship(deleteRule: .cascade, inverse: \Scenario.borrower)
    public var scenarios: [Scenario]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        firstName: String,
        lastName: String,
        email: String? = nil,
        phone: String? = nil,
        propertyAddress: String? = nil,
        propertyState: String? = nil,
        propertyZip: String? = nil,
        notes: String? = nil,
        source: BorrowerSource = .manual,
        contactIdentifier: String? = nil
    ) {
        let now = Date()
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.propertyAddress = propertyAddress
        self.propertyState = propertyState
        self.propertyZip = propertyZip
        self.notes = notes
        self.sourceRaw = source.rawValue
        self.contactIdentifier = contactIdentifier
        self.scenarios = []
        self.createdAt = now
        self.updatedAt = now
    }

    public var source: BorrowerSource {
        BorrowerSource(rawValue: sourceRaw) ?? .manual
    }

    public var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    public var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}

@Model
public final class Scenario {
    @Attribute(.unique)
    public var id: UUID
    public var borrower: Borrower?
    public var calculatorTypeRaw: String
    public var name: String
    public var inputsJSON: Data
    public var outputsJSON: Data?
    public var keyStatLine: String
    public var narrative: String?
    public var notes: String?
    public var archived: Bool
    public var complianceRuleVersion: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        borrower: Borrower? = nil,
        calculatorType: CalculatorType,
        name: String,
        inputsJSON: Data,
        outputsJSON: Data? = nil,
        keyStatLine: String = "",
        narrative: String? = nil,
        notes: String? = nil,
        archived: Bool = false,
        complianceRuleVersion: String = "2026-Q2"
    ) {
        let now = Date()
        self.id = UUID()
        self.borrower = borrower
        self.calculatorTypeRaw = calculatorType.rawValue
        self.name = name
        self.inputsJSON = inputsJSON
        self.outputsJSON = outputsJSON
        self.keyStatLine = keyStatLine
        self.narrative = narrative
        self.notes = notes
        self.archived = archived
        self.complianceRuleVersion = complianceRuleVersion
        self.createdAt = now
        self.updatedAt = now
    }

    public var calculatorType: CalculatorType {
        CalculatorType(rawValue: calculatorTypeRaw) ?? .amortization
    }
}
