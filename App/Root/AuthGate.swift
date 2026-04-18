// AuthGate.swift
// First gate in the root hierarchy. Three cases:
//   1. No profile stored → "Sign in with Apple" gate.
//   2. Profile stored + faceIDEnabled + not yet unlocked this launch →
//      biometric prompt.
//   3. Otherwise → signed-in content (Onboarding if not finished,
//      otherwise RootTabBar).

import SwiftUI
import SwiftData
import AuthenticationServices

struct AuthGate<Content: View>: View {
    @Query private var profiles: [LenderProfile]

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.colorScheme)
    private var colorScheme

    @State private var unlocked = false
    @State private var biometricError: String?

    let content: (LenderProfile) -> Content

    init(@ViewBuilder content: @escaping (LenderProfile) -> Content) {
        self.content = content
    }

    var body: some View {
        Group {
            if let profile = profiles.first {
                if profile.faceIDEnabled, !unlocked, FaceIDUnlock.isAvailable {
                    biometricLock(profile: profile)
                } else {
                    content(profile)
                }
            } else {
                signInScreen
            }
        }
        .animation(Motion.defaultEaseOut, value: profiles.count)
        .animation(Motion.defaultEaseOut, value: unlocked)
    }

    // MARK: Sign in

    private var signInScreen: some View {
        ZStack {
            Palette.surface.ignoresSafeArea()
            VStack(spacing: Spacing.s32) {
                Spacer()
                VStack(spacing: Spacing.s16) {
                    Text("Q")
                        .font(.custom(Typography.serifFamily, size: 84))
                        .foregroundStyle(Palette.ink)
                    Text("Quotient")
                        .textStyle(Typography.eyebrow)
                        .foregroundStyle(Palette.inkTertiary)
                    Text("Five calculators, built for loan officers.")
                        .textStyle(Typography.body)
                        .foregroundStyle(Palette.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                SignInWithAppleButton(
                    onRequest: { req in
                        req.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        handleSignIn(result: result)
                    }
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 48)
                .cornerRadius(Radius.cta)
                .padding(.horizontal, Spacing.s24)
                Text("Your profile stays on this device. No tracking.")
                    .textStyle(Typography.bodySm)
                    .foregroundStyle(Palette.inkTertiary)
                    .padding(.bottom, Spacing.s32)
            }
            .padding(Spacing.s24)
        }
    }

    private func handleSignIn(result: Result<ASAuthorization, any Error>) {
        guard case let .success(authz) = result,
              let r = AppleAuth.result(from: authz) else { return }
        let profile = LenderProfile(
            appleUserID: r.userID,
            firstName: r.firstName,
            lastName: r.lastName,
            email: r.email
        )
        modelContext.insert(profile)
        try? modelContext.save()
    }

    // MARK: Biometric lock

    private func biometricLock(profile: LenderProfile) -> some View {
        ZStack {
            Palette.surface.ignoresSafeArea()
            VStack(spacing: Spacing.s24) {
                Spacer()
                Image(systemName: "faceid")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundStyle(Palette.accent)
                Text("Unlock Quotient")
                    .textStyle(Typography.h2)
                    .foregroundStyle(Palette.ink)
                if let biometricError {
                    Text(biometricError)
                        .textStyle(Typography.bodySm)
                        .foregroundStyle(Palette.loss)
                }
                Spacer()
                PrimaryButton("Use Face ID") {
                    Task { await attemptUnlock() }
                }
                .padding(.horizontal, Spacing.s24)
                GhostButton("Sign out") {
                    modelContext.delete(profile)
                    try? modelContext.save()
                }
                .padding(.bottom, Spacing.s32)
            }
            .padding(Spacing.s24)
        }
        .task { await attemptUnlock() }
    }

    private func attemptUnlock() async {
        biometricError = nil
        let res = await FaceIDUnlock.authenticate()
        switch res {
        case .success:
            unlocked = true
        case .userCancelled:
            biometricError = nil
        case .unavailable:
            unlocked = true
        case .failed(let msg):
            biometricError = msg
        }
    }
}
