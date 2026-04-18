// SharePreview.swift
// Per design/screens/Share.jsx. Paged carousel (cover / schedule /
// disclaimers) with dots indicator + recipient row + bottom action
// dock. Uses UIActivityViewController via a SwiftUI wrapper for the
// final share sheet.

import SwiftUI
import PDFKit
import QuotientPDF
import QuotientCompliance
import UIKit

struct QuotientSharePreview: View {
    let profile: LenderProfile
    let borrower: Borrower?
    let pdfURL: URL
    let pageCount: Int
    let onDismiss: () -> Void

    @State private var selectedPage: Int = 0
    @State private var showingShare: Bool = false

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            navigation
            recipientRow
                .padding(.horizontal, Spacing.s20)
                .padding(.bottom, Spacing.s16)

            carousel
                .padding(.bottom, Spacing.s16)

            dots
                .padding(.bottom, Spacing.s16)

            Spacer()

            bottomDock
        }
        .background(Palette.surfaceSunken)
        .sheet(isPresented: $showingShare) {
            ShareSheet(activityItems: [pdfURL])
                .presentationDetents([.medium, .large])
        }
    }

    private var navigation: some View {
        HStack {
            Button("Done") { onDismiss(); dismiss() }
                .foregroundStyle(Palette.accent)
            Spacer()
            Text("Preview")
                .textStyle(Typography.bodyLg.withWeight(.semibold))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text("\(pageCount) pp")
                .textStyle(Typography.num.withSize(11))
                .foregroundStyle(Palette.inkTertiary)
        }
        .padding(.horizontal, Spacing.s20)
        .padding(.vertical, Spacing.s12)
    }

    private var recipientRow: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow("For")
            HStack(spacing: Spacing.s12) {
                Circle()
                    .fill(Palette.surfaceSunken)
                    .overlay(Circle().stroke(Palette.borderSubtle, lineWidth: 1))
                    .overlay(
                        Text(borrower?.initials ?? "—")
                            .textStyle(Typography.num.withSize(10, weight: .semibold))
                            .foregroundStyle(Palette.inkSecondary)
                    )
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(borrower?.fullName ?? "No borrower")
                        .textStyle(Typography.bodyLg.withSize(13.5, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    if let email = borrower?.email {
                        Text(email)
                            .textStyle(Typography.num.withSize(11))
                            .foregroundStyle(Palette.inkTertiary)
                    }
                }
                Spacer()
                Button("Change") {}
                    .foregroundStyle(Palette.accent)
                    .textStyle(Typography.body.withWeight(.medium))
            }
            .padding(.horizontal, Spacing.s12)
            .padding(.vertical, Spacing.s12)
            .background(Palette.surfaceRaised)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.listCard)
                    .stroke(Palette.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
        }
    }

    @ViewBuilder private var carousel: some View {
        TabView(selection: $selectedPage) {
            ForEach(0..<pageCount, id: \.self) { idx in
                if let page = loadPage(at: idx) {
                    PDFPageImage(pdfPage: page)
                        .padding(.horizontal, 44)
                        .tag(idx)
                } else {
                    Text("Page \(idx + 1)")
                        .tag(idx)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 400)
    }

    private func loadPage(at index: Int) -> PDFPage? {
        PDFDocument(url: pdfURL)?.page(at: index)
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { i in
                Capsule()
                    .fill(i == selectedPage ? Palette.accent : Palette.inkTertiary.opacity(0.4))
                    .frame(width: i == selectedPage ? 20 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.18), value: selectedPage)
            }
        }
    }

    private var bottomDock: some View {
        HStack(spacing: Spacing.s8) {
            Button {
                saveToFiles()
            } label: {
                Text("Save to Files")
                    .textStyle(Typography.bodyLg)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s12)
                    .background(Palette.surfaceRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.listCard)
                            .stroke(Palette.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
            }
            .buttonStyle(.plain)
            Button {
                showingShare = true
            } label: {
                Text("Share · AirDrop, Mail…")
                    .textStyle(Typography.bodyLg.withWeight(.semibold))
                    .foregroundStyle(Palette.accentFG)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s12)
                    .background(Palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
            }
            .buttonStyle(.plain)
            .layoutPriority(1)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.top, Spacing.s12)
        .padding(.bottom, Spacing.s32)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Palette.borderSubtle).frame(height: 1),
                 alignment: .top)
    }

    private func saveToFiles() {
        // Save-to-files routes through the same activity sheet with
        // a file-picker activity type. iOS handles the detail.
        showingShare = true
    }
}

// MARK: - PDFPage thumbnail

struct PDFPageImage: View {
    let pdfPage: PDFPage

    var body: some View {
        GeometryReader { geo in
            Image(uiImage: pdfPage.thumbnail(of: geo.size, for: .cropBox))
                .resizable()
                .aspectRatio(612.0 / 792.0, contentMode: .fit)
                .shadow(radius: 12, y: 8)
        }
    }
}

// MARK: - UIActivityViewController bridge

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
