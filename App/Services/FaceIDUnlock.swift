// FaceIDUnlock.swift
// LocalAuthentication wrapper. Profile's `faceIDEnabled` controls whether
// RootView asks for biometric unlock on cold launch.

import Foundation
import LocalAuthentication

public enum FaceIDUnlockResult: Sendable {
    case success
    case userCancelled
    case unavailable
    case failed(String)
}

public enum FaceIDUnlock {

    public static var isAvailable: Bool {
        var err: NSError?
        let ctx = LAContext()
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    public static func authenticate(reason: String = "Unlock Quotient") async -> FaceIDUnlockResult {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            return .unavailable
        }
        do {
            let ok = try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return ok ? .success : .failed("LAContext returned false")
        } catch let err as LAError {
            switch err.code {
            case .userCancel, .appCancel, .systemCancel:
                return .userCancelled
            default:
                return .failed(err.localizedDescription)
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
