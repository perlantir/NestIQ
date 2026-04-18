// NMLSTests.swift
// Unit tests for `nmlsConsumerAccessURL(for:)`.

import Testing
import Foundation
@testable import QuotientCompliance

@Suite("nmlsConsumerAccessURL")
struct NMLSTests {

    @Test("Valid numeric ID produces the documented individual URL")
    func validIDProducesURL() throws {
        let url = try nmlsConsumerAccessURL(for: "123456")
        #expect(
            url.absoluteString == "https://www.nmlsconsumeraccess.org/EntityDetails.aspx/INDIVIDUAL/123456"
        )
    }

    @Test("Leading/trailing whitespace is trimmed")
    func trimsWhitespace() throws {
        let url = try nmlsConsumerAccessURL(for: "  789012  ")
        #expect(
            url.absoluteString == "https://www.nmlsconsumeraccess.org/EntityDetails.aspx/INDIVIDUAL/789012"
        )
    }

    @Test("Empty string throws invalidNMLS")
    func emptyThrows() {
        #expect(throws: ComplianceError.self) {
            _ = try nmlsConsumerAccessURL(for: "")
        }
    }

    @Test("Whitespace-only string throws invalidNMLS")
    func whitespaceOnlyThrows() {
        #expect(throws: ComplianceError.self) {
            _ = try nmlsConsumerAccessURL(for: "   ")
        }
    }

    @Test("Non-digit characters throw invalidNMLS")
    func nonDigitThrows() {
        #expect(throws: ComplianceError.self) {
            _ = try nmlsConsumerAccessURL(for: "NMLS-12345")
        }
        #expect(throws: ComplianceError.self) {
            _ = try nmlsConsumerAccessURL(for: "12a34")
        }
        #expect(throws: ComplianceError.self) {
            _ = try nmlsConsumerAccessURL(for: "12 34")
        }
    }

    @Test("Error description reports the offending input")
    func errorMentionsInput() {
        do {
            _ = try nmlsConsumerAccessURL(for: "abc")
            Issue.record("expected throw")
        } catch let error as ComplianceError {
            #expect(error.description.contains("abc"))
        } catch {
            Issue.record("unexpected error type: \(error)")
        }
    }

    @Test("Empty-input error message mentions empty")
    func emptyMessage() {
        do {
            _ = try nmlsConsumerAccessURL(for: "")
            Issue.record("expected throw")
        } catch let error as ComplianceError {
            #expect(error.description.lowercased().contains("empty"))
        } catch {
            Issue.record("unexpected error type: \(error)")
        }
    }
}
