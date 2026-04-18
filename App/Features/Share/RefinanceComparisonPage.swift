// RefinanceComparisonPage.swift
// Landscape (792×612) PDF page with the Refi side-by-side table.
// Reuses the on-screen RefinanceTableView so the numbers / highlights
// stay identical across app and PDF.

import SwiftUI

struct RefinanceComparisonPage: View {
    let borrowerName: String
    let generatedDate: String
    let loFullName: String
    let loNMLSLine: String
    let tableView: RefinanceTableView
    let disclaimer: String
    let ehoStatement: String
    let accentHex: String

    private let inkPrimary = Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x0F / 255)
    private let inkSecondary = Color(red: 0x4A / 255, green: 0x48 / 255, blue: 0x40 / 255)
    private let inkTertiary = Color(red: 0x85 / 255, green: 0x81 / 255, blue: 0x6F / 255)
    private let border = Color(red: 0xE5 / 255, green: 0xE1 / 255, blue: 0xD5 / 255)
    private var accent: Color { Color(brandHex: accentHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            tableView
                .padding(.top, 22)
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 28)
        .frame(width: 792, height: 612)
        .background(Color.white)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Refinance comparison".uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(accent)
            HStack(alignment: .firstTextBaseline) {
                Text("For ")
                    .font(.custom("SourceSerif4", size: 26))
                    .foregroundStyle(inkPrimary)
                    +
                    Text(borrowerName)
                    .font(.custom("SourceSerif4-It", size: 26))
                    .foregroundStyle(inkPrimary)
                Spacer()
                Text(generatedDate)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(inkTertiary)
            }
            Rectangle().fill(inkPrimary).frame(height: 1.5)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle().fill(border).frame(height: 1).padding(.bottom, 6)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(disclaimer)
                        .font(.system(size: 8.5))
                        .foregroundStyle(inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(ehoStatement)
                        .font(.system(size: 8.5))
                        .foregroundStyle(inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 16)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(loFullName)
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(inkSecondary)
                    Text(loNMLSLine)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(inkTertiary)
                }
            }
        }
    }
}
