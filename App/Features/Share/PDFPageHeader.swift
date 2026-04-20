// PDFPageHeader.swift
// Session 5N.2 — shared header rendered at the top of every PDF page.
// Centered NestIQ wordmark + "Page N of M" left / date right + hairline
// divider. Replaces the ad-hoc per-page headers that diverged across
// cover / disclaimers / comparison / schedule pages (QA caught "tIQ
// Mortgage Intelligence" clipped on page 2).

import SwiftUI

struct PDFPageHeader: View {
    let pageIndex: Int
    let pageCount: Int
    let date: String

    private let muted = Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255)

    var body: some View {
        VStack(spacing: 8) {
            Image("Wordmark-A")
                .resizable()
                .scaledToFit()
                .frame(height: 18)
                .frame(maxWidth: .infinity, alignment: .center)
            HStack {
                Text("Page \(pageIndex) of \(pageCount)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(muted)
                Spacer()
                Text(date)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(muted)
            }
            Rectangle()
                .fill(muted.opacity(0.5))
                .frame(height: 0.5)
        }
    }
}

extension PDFPageHeader {
    /// Standard long-form date used across all headers — "April 20, 2026".
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}
