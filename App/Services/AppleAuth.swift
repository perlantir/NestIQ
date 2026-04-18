// AppleAuth.swift
// Sign in with Apple bridge — minimal scopes (name, email). The AuthGate
// view drives the request; this model captures the result.

import Foundation
import AuthenticationServices

public struct AppleSignInResult: Sendable {
    public let userID: String
    public let firstName: String
    public let lastName: String
    public let email: String

    public init(userID: String, firstName: String, lastName: String, email: String) {
        self.userID = userID
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
}

public enum AppleAuth {

    /// Translate a completed `ASAuthorization` into our shape. Apple only
    /// delivers name/email on the first sign-in; subsequent sign-ins just
    /// re-issue the userID. The caller merges with the stored profile.
    public static func result(from authorization: ASAuthorization) -> AppleSignInResult? {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential
        else { return nil }
        let first = credential.fullName?.givenName ?? ""
        let last = credential.fullName?.familyName ?? ""
        let email = credential.email ?? ""
        return AppleSignInResult(
            userID: credential.user,
            firstName: first,
            lastName: last,
            email: email
        )
    }
}
