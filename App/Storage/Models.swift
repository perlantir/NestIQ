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
    case selfEmployment

    public var shortLabel: String {
        switch self {
        case .amortization: "Amortization"
        case .incomeQualification: "Income qual"
        case .refinance: "Refi compare"
        case .totalCostAnalysis: "Total cost"
        case .helocVsRefinance: "HELOC vs Refi"
        case .selfEmployment: "Self-employ"
        }
    }

    public var number: String {
        switch self {
        case .amortization: "01"
        case .incomeQualification: "02"
        case .refinance: "03"
        case .totalCostAnalysis: "04"
        case .helocVsRefinance: "05"
        case .selfEmployment: "06"
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
    /// Comma-separated USPS abbreviations ("CA,TX,IA"). Stored as a
    /// String because SwiftData on iOS 18 fails to materialize
    /// `[String]` attributes at container init — the CoreData bridge
    /// can't synthesize the Objective-C class for the generic. When
    /// that happens the whole container goes into a degraded state
    /// and every `try modelContext.save()` throws silently, which is
    /// why Saved scenarios never appeared in Nick's QA (5E.1).
    /// Computed `licensedStates: [String]` preserves the read/write
    /// API everything else in the app consumes.
    public var licensedStatesCSV: String = ""
    public var companyName: String
    public var companyLogoData: Data?
    public var brandColorHex: String
    public var phone: String
    public var email: String
    public var preferredLanguage: String
    public var faceIDEnabled: Bool
    public var hapticsEnabled: Bool
    public var soundsEnabled: Bool
    public var densityPreferenceRaw: String
    public var appearanceRaw: String
    public var pdfLanguage: String = "en"
    public var nmlsDisplayFormatRaw: String = NMLSDisplayFormat.idAndURL.rawValue
    public var ehoLanguageRaw: String = EHOLanguage.en.rawValue
    public var showPhotoOnPDF: Bool = false
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
        showPhotoOnPDF: Bool = false,
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
        self.licensedStatesCSV = Self.encode(licensedStates: licensedStates)
        self.companyName = companyName
        self.brandColorHex = brandColorHex
        self.phone = phone
        self.email = email
        self.preferredLanguage = preferredLanguage
        self.pdfLanguage = pdfLanguage
        self.nmlsDisplayFormatRaw = nmlsDisplayFormat.rawValue
        self.ehoLanguageRaw = ehoLanguage.rawValue
        self.showPhotoOnPDF = showPhotoOnPDF
        self.faceIDEnabled = faceIDEnabled
        self.hapticsEnabled = hapticsEnabled
        self.soundsEnabled = soundsEnabled
        self.densityPreferenceRaw = densityPreference.rawValue
        self.appearanceRaw = appearance.rawValue
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = now
        self.updatedAt = now
    }

    /// USPS abbreviations derived from the CSV storage. Empty array
    /// when the profile hasn't picked any states yet. Normalizes on
    /// write — trims whitespace, uppercases, dedupes while preserving
    /// input order.
    public var licensedStates: [String] {
        get {
            licensedStatesCSV
                .split(separator: ",", omittingEmptySubsequences: true)
                .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
                .filter { !$0.isEmpty }
        }
        set { licensedStatesCSV = Self.encode(licensedStates: newValue) }
    }

    private static func encode(licensedStates: [String]) -> String {
        var seen = Set<String>()
        var ordered: [String] = []
        for raw in licensedStates {
            let trimmed = raw.trimmingCharacters(in: .whitespaces).uppercased()
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else { continue }
            ordered.append(trimmed)
        }
        return ordered.joined(separator: ",")
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
