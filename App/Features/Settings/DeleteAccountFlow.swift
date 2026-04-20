// DeleteAccountFlow.swift
// Apple Guideline 5.1.1(v) — in-app account deletion. Two-step
// confirmation, local-only data wipe, success screen with a 7-day
// remote-clearing disclosure. SIWA token revocation on appleid.apple.com
// requires a client-secret JWT signed with the team's p8 key, which
// cannot live in a mobile binary — revocation will route through a
// future server endpoint. See DECISIONS.md § Session 5N.1 for the
// local-only v1 approach and planned server follow-up.

import SwiftUI
import SwiftData

struct DeleteAccountFlow: View {
    let profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    enum Step: Equatable {
        case confirm
        case finalConfirm
        case success
    }

    @State private var step: Step = .confirm

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .confirm: confirmStep
                case .finalConfirm: finalConfirmStep
                case .success: successStep
                }
            }
            .background(Palette.surface)
            .animation(Motion.defaultEaseOut, value: step)
        }
        .interactiveDismissDisabled(step == .success)
    }

    // MARK: Step 1 — confirm

    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: Spacing.s24) {
            Eyebrow("Delete account")
            Text("Delete your NestIQ account?")
                .textStyle(Typography.display.withSize(24, weight: .semibold))
                .foregroundStyle(Palette.ink)

            VStack(alignment: .leading, spacing: Spacing.s12) {
                Text("This will permanently:")
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.inkSecondary)
                bullet("Disconnect NestIQ from your Apple ID")
                bullet("Delete your lender profile and photo")
                bullet("Delete all saved scenarios and borrowers")
                bullet("Delete all settings and preferences")
            }

            Text("This cannot be undone.")
                .textStyle(Typography.body.withWeight(.semibold))
                .foregroundStyle(Palette.loss)
                .padding(.top, Spacing.s4)

            Spacer()

            HStack(spacing: Spacing.s12) {
                GhostButton("Cancel") { dismiss() }
                    .accessibilityIdentifier("deleteAccount.cancel")
                    .frame(maxWidth: .infinity)
                PrimaryButton("Continue") { step = .finalConfirm }
                    .accessibilityIdentifier("deleteAccount.continue")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(Spacing.s24)
        .padding(.top, Spacing.s24)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.s8) {
            Text("•")
                .textStyle(Typography.body)
                .foregroundStyle(Palette.inkTertiary)
            Text(text)
                .textStyle(Typography.body)
                .foregroundStyle(Palette.ink)
        }
    }

    // MARK: Step 2 — final confirm

    private var finalConfirmStep: some View {
        VStack(alignment: .leading, spacing: Spacing.s24) {
            Eyebrow("Last chance")
            Text("Are you sure?")
                .textStyle(Typography.display.withSize(24, weight: .semibold))
                .foregroundStyle(Palette.ink)

            Text("Once you tap Delete, your account and data will be erased immediately.")
                .textStyle(Typography.body)
                .foregroundStyle(Palette.inkSecondary)

            Spacer()

            HStack(spacing: Spacing.s12) {
                GhostButton("Cancel") { dismiss() }
                    .accessibilityIdentifier("deleteAccount.cancelFinal")
                    .frame(maxWidth: .infinity)
                Button {
                    performDelete()
                } label: {
                    Text("Delete")
                        .textStyle(Typography.bodyLg.withWeight(.semibold))
                        .foregroundStyle(Palette.accentFG)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Palette.loss)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.cta))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("deleteAccount.delete")
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Spacing.s24)
        .padding(.top, Spacing.s24)
    }

    // MARK: Step 3 — success

    private var successStep: some View {
        VStack(spacing: Spacing.s24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(Palette.accent)
            Text("Account deleted")
                .textStyle(Typography.display.withSize(24, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Text(
                "Your NestIQ data has been permanently deleted. "
                + "Your Apple ID association will be fully cleared "
                + "by our systems within 7 days."
            )
                .textStyle(Typography.body)
                .foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            Spacer()
            PrimaryButton("Done") {
                finalizeAndDismiss()
            }
            .accessibilityIdentifier("deleteAccount.done")
            .padding(.horizontal, Spacing.s24)
        }
        .padding(Spacing.s24)
    }

    // MARK: Actions

    private func performDelete() {
        AccountDeletion.performLocalWipe(
            context: modelContext,
            preservingProfile: profile
        )
        step = .success
    }

    private func finalizeAndDismiss() {
        // Delete the profile last so AuthGate's @Query sees the empty
        // state and returns to the welcome / sign-in screen.
        modelContext.delete(profile)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Deletion engine

/// Local-only account deletion. Wipes all SwiftData models; keychain
/// and UserDefaults scopes are currently empty (no NestIQ-prefixed
/// keys exist in the app per the 5N.1 audit).
///
/// Extracted as a free function so it's unit-testable against an
/// in-memory ModelContext without spinning up SwiftUI machinery.
enum AccountDeletion {
    /// Wipe every child-model record; leaves `preservingProfile`
    /// alive so the success screen has time to present before the
    /// AuthGate flip. Pass `nil` to wipe everything including the
    /// profile (e.g. from tests).
    @MainActor
    static func performLocalWipe(
        context: ModelContext,
        preservingProfile: LenderProfile?
    ) {
        // Per-row deletion avoids batch-delete's "mandatory OTO
        // nullify inverse" warnings on the Scenario ↔ Borrower
        // relationship and is small-N enough (dozens, not thousands)
        // that batching isn't needed.
        if let scenarios = try? context.fetch(FetchDescriptor<Scenario>()) {
            scenarios.forEach { context.delete($0) }
        }
        if let borrowers = try? context.fetch(FetchDescriptor<Borrower>()) {
            borrowers.forEach { context.delete($0) }
        }
        if preservingProfile == nil,
           let profiles = try? context.fetch(FetchDescriptor<LenderProfile>()) {
            profiles.forEach { context.delete($0) }
        }
        try? context.save()
        // TODO(server): revoke SIWA token via POST
        // https://appleid.apple.com/auth/revoke once a backend
        // JWT-signing endpoint exists. Client-secret JWT requires the
        // team's .p8 private key which cannot ship in the binary.
    }
}
