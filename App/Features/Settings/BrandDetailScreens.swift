// BrandDetailScreens.swift
// Three Settings detail screens that edit the branding bits applied to
// the borrower-facing PDF cover + the Home greeting:
//
//   - AccentColorPickerScreen — picks from a curated palette + a custom
//     ColorPicker fallback; persists `LenderProfile.brandColorHex`.
//   - LogoPickerScreen — SwiftUI `PhotosPicker` (iOS 16+, no Info.plist
//     permission needed since it's out-of-process); persists
//     `LenderProfile.companyLogoData`.
//   - SignatureBlockEditor — multi-line text editor that writes to
//     `LenderProfile.tagline` (a short line the PDF prints beneath the
//     name + NMLS block).
//
// Scope per Session 5A: the accent color tints only the PDF cover and
// the Home greeting eyebrow. Global CTA tinting is a separate
// architectural project and explicitly out of scope.

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Accent color

struct AccentColorPickerScreen: View {
    @Bindable var profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    @State private var customColor: Color = .green
    @State private var usingCustom: Bool = false

    /// Curated palette — tuned for borrower-facing PDFs (high-contrast,
    /// print-safe, consistent luminance with the design README's accent
    /// role). Keep this list short; too many choices stalls LOs.
    static let palette: [(name: String, hex: String)] = [
        ("Ledger green", "#1F4D3F"),
        ("Pine", "#2C5F4D"),
        ("Moss", "#4F9E7D"),
        ("Navy", "#1F3A5F"),
        ("Slate", "#3A4553"),
        ("Ink", "#171610"),
        ("Copper", "#B45E3F"),
        ("Burgundy", "#6B2B3A"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                Text("Tints the PDF cover eyebrow and the Home greeting. Other UI elements keep the app theme.")
                    .textStyle(Typography.body.withSize(13))
                    .foregroundStyle(Palette.inkSecondary)
                    .padding(.horizontal, Spacing.s20)

                preview
                    .padding(.horizontal, Spacing.s20)

                paletteGrid
                    .padding(.horizontal, Spacing.s20)

                customSection
                    .padding(.horizontal, Spacing.s20)
            }
            .padding(.top, Spacing.s16)
            .padding(.bottom, Spacing.s32)
        }
        .background(Palette.surface)
        .scrollIndicators(.hidden)
        .navigationTitle("Accent color")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            usingCustom = !Self.palette.contains { $0.hex.lowercased() == profile.brandColorHex.lowercased() }
            customColor = Color(brandHex: profile.brandColorHex)
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("PREVIEW")
                .textStyle(Typography.micro)
                .foregroundStyle(Palette.inkTertiary)
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text("AMORTIZATION · APR 18, 2026")
                    .textStyle(Typography.num.withSize(10, weight: .semibold))
                    .tracking(1.05)
                    .foregroundStyle(Color(brandHex: profile.brandColorHex))
                Text("Prepared for Alex Martinez")
                    .font(.custom(Typography.serifFamily, size: 22))
                    .foregroundStyle(Palette.ink)
                Rectangle()
                    .fill(Color(brandHex: profile.brandColorHex))
                    .frame(height: 2)
                    .padding(.top, Spacing.s8)
            }
            .padding(Spacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.listCard)
                    .stroke(Palette.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
        }
    }

    private var paletteGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Curated")
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.s12),
                GridItem(.flexible(), spacing: Spacing.s12),
            ], spacing: Spacing.s12) {
                ForEach(Self.palette, id: \.hex) { item in
                    swatch(name: item.name, hex: item.hex)
                }
            }
        }
    }

    private func swatch(name: String, hex: String) -> some View {
        let selected = !usingCustom
            && profile.brandColorHex.lowercased() == hex.lowercased()
        return Button {
            apply(hex: hex, custom: false)
        } label: {
            HStack(spacing: Spacing.s12) {
                Circle()
                    .fill(Color(brandHex: hex))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle().stroke(Palette.borderSubtle, lineWidth: 1)
                    )
                Text(name)
                    .textStyle(Typography.body.withSize(13, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Palette.accent)
                }
            }
            .padding(.horizontal, Spacing.s12)
            .padding(.vertical, Spacing.s12)
            .background(Palette.surfaceRaised)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.listCard)
                    .stroke(
                        selected ? Palette.accent : Palette.borderSubtle,
                        lineWidth: selected ? 1.5 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
        }
        .buttonStyle(.plain)
    }

    private var customSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("Custom")
            HStack {
                ColorPicker(selection: $customColor, supportsOpacity: false) {
                    Text("Pick any color")
                        .textStyle(Typography.body.withSize(13, weight: .medium))
                        .foregroundStyle(Palette.ink)
                }
                .onChange(of: customColor) { _, new in
                    if usingCustom {
                        apply(hex: new.brandHex, custom: true)
                    }
                }
                if usingCustom {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Palette.accent)
                }
            }
            .padding(.horizontal, Spacing.s12)
            .padding(.vertical, Spacing.s12)
            .background(Palette.surfaceRaised)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.listCard)
                    .stroke(
                        usingCustom ? Palette.accent : Palette.borderSubtle,
                        lineWidth: usingCustom ? 1.5 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))

            Button {
                apply(hex: customColor.brandHex, custom: true)
            } label: {
                Text("Use custom color")
                    .textStyle(Typography.body.withWeight(.medium))
                    .foregroundStyle(Palette.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, Spacing.s4)
        }
    }

    private func apply(hex: String, custom: Bool) {
        profile.brandColorHex = hex
        profile.updatedAt = Date()
        usingCustom = custom
        try? modelContext.save()
    }
}

// MARK: - Logo

struct LogoPickerScreen: View {
    @Bindable var profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    @State private var selection: PhotosPickerItem?
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                Text("Renders on the PDF cover brand strip + the Home greeting avatar when set.")
                    .textStyle(Typography.body.withSize(13))
                    .foregroundStyle(Palette.inkSecondary)
                    .padding(.horizontal, Spacing.s20)

                logoPreview
                    .padding(.horizontal, Spacing.s20)

                actions
                    .padding(.horizontal, Spacing.s20)

                if let loadError {
                    Text(loadError)
                        .textStyle(Typography.body.withSize(12))
                        .foregroundStyle(Palette.loss)
                        .padding(.horizontal, Spacing.s20)
                }

                Text("PNG or JPEG · 1024×1024 recommended · max ~2 MB")
                    .textStyle(Typography.num.withSize(11))
                    .foregroundStyle(Palette.inkTertiary)
                    .padding(.horizontal, Spacing.s20)
            }
            .padding(.top, Spacing.s16)
            .padding(.bottom, Spacing.s32)
        }
        .background(Palette.surface)
        .scrollIndicators(.hidden)
        .navigationTitle("Logo")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selection) { _, new in
            Task { await loadLogo(from: new) }
        }
    }

    @ViewBuilder private var logoPreview: some View {
        ZStack {
            if let data = profile.companyLogoData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
            } else {
                VStack(spacing: Spacing.s8) {
                    Image(systemName: "photo")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(Palette.inkTertiary)
                    Text("No logo set")
                        .textStyle(Typography.body)
                        .foregroundStyle(Palette.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
    }

    private var actions: some View {
        let hasLogo = profile.companyLogoData != nil
        return VStack(spacing: Spacing.s8) {
            PhotosPicker(
                selection: $selection,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text(hasLogo ? "Replace logo" : "Choose logo")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s12)
                    .background(Palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.cta))
            }
            if hasLogo {
                Button {
                    remove()
                } label: {
                    Text("Remove logo")
                        .textStyle(Typography.body.withWeight(.medium))
                        .foregroundStyle(Palette.loss)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.s12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func loadLogo(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                loadError = "Couldn't read the selected photo."
                return
            }
            // Keep the persisted blob reasonable — SwiftData row-size
            // limits aren't hard but 2 MB is generous for a logo.
            guard data.count < 4_000_000 else {
                loadError = "Image is too large (over 4 MB). Try a smaller file."
                return
            }
            await MainActor.run {
                profile.companyLogoData = data
                profile.updatedAt = Date()
                try? modelContext.save()
                loadError = nil
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func remove() {
        profile.companyLogoData = nil
        profile.updatedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Signature block

struct SignatureBlockEditor: View {
    @Bindable var profile: LenderProfile

    @Environment(\.modelContext)
    private var modelContext

    @State private var draft: String = ""

    private let maxLength = 200

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                Text("A short line printed beneath your name + NMLS on the PDF cover. Often used for a credential or a personal motto.")
                    .textStyle(Typography.body.withSize(13))
                    .foregroundStyle(Palette.inkSecondary)
                    .padding(.horizontal, Spacing.s20)

                editor
                    .padding(.horizontal, Spacing.s20)

                HStack {
                    Text("\(draft.count) / \(maxLength)")
                        .textStyle(Typography.num.withSize(11))
                        .foregroundStyle(draft.count > maxLength ? Palette.loss : Palette.inkTertiary)
                    Spacer()
                    if !draft.isEmpty {
                        Button("Clear") { draft = "" }
                            .textStyle(Typography.body.withSize(12, weight: .medium))
                            .foregroundStyle(Palette.accent)
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.s20)
            }
            .padding(.top, Spacing.s16)
            .padding(.bottom, Spacing.s32)
        }
        .background(Palette.surface)
        .scrollIndicators(.hidden)
        .navigationTitle("Signature block")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(draft.count > maxLength || draft == (profile.tagline ?? ""))
            }
        }
        .onAppear { draft = profile.tagline ?? "" }
    }

    private var editor: some View {
        TextField(
            "e.g. Mortgage advisor · serving the Pacific NW since 2012",
            text: $draft,
            axis: .vertical
        )
        .lineLimit(3...5)
        .textStyle(Typography.body)
        .foregroundStyle(Palette.ink)
        .padding(Spacing.s12)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard)
                .stroke(Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
    }

    private func save() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.tagline = trimmed.isEmpty ? nil : String(trimmed.prefix(maxLength))
        profile.updatedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Color → hex

extension Color {
    /// Serialize a SwiftUI Color to `#RRGGBB` so it round-trips through
    /// `LenderProfile.brandColorHex`. Uses UIKit to extract components.
    var brandHex: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int(round(max(0, min(1, r)) * 255))
        let gi = Int(round(max(0, min(1, g)) * 255))
        let bi = Int(round(max(0, min(1, b)) * 255))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
