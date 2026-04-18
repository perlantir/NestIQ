// RateRibbonCell.swift
// Horizontal-scroll rate card on Home. Product label (30yr, 15yr, ARM,
// FHA, VA, Jumbo) + big mono rate + delta chip. Delta uses gain/loss
// semantics with a small arrow glyph.
//
// Tokens consumed: Typography.eyebrow / numLg / micro, Palette.surfaceRaised
// / ink / inkSecondary / gain / loss / borderSubtle, Radius.listCard,
// Spacing.s8 / s12.

import SwiftUI

public struct RateRibbonCell: View {
    public struct Delta: Sendable, Hashable {
        public let bps: Int
        public init(bps: Int) { self.bps = bps }
        public var isGain: Bool { bps <= 0 }
    }

    let product: String
    let rate: String             // "6.750%"
    let delta: Delta?            // nil when no comparison data available

    public init(product: String, rate: String, delta: Delta? = nil) {
        self.product = product
        self.rate = rate
        self.delta = delta
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Eyebrow(product)
            MonoNumber(rate, size: .large)
            if let delta {
                HStack(spacing: 2) {
                    Image(systemName: delta.isGain ? "arrow.down" : "arrow.up")
                        .font(.system(size: 10, weight: .semibold))
                    Text("\(abs(delta.bps)) bps")
                        .textStyle(Typography.micro)
                }
                .foregroundStyle(delta.isGain ? Palette.gain : Palette.loss)
            }
        }
        .padding(Spacing.s12)
        .frame(width: 132, alignment: .leading)
        .background(Palette.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.listCard)
                .stroke(Palette.borderSubtle, lineWidth: Tokens.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.listCard))
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: Spacing.s8) {
            RateRibbonCell(product: "30yr fixed", rate: "6.750%", delta: .init(bps: -8))
            RateRibbonCell(product: "15yr fixed", rate: "6.125%", delta: .init(bps: -4))
            RateRibbonCell(product: "5/6 ARM", rate: "6.500%", delta: .init(bps: 2))
            RateRibbonCell(product: "FHA 30", rate: "6.375%")
            RateRibbonCell(product: "VA 30", rate: "6.200%", delta: .init(bps: 0))
            RateRibbonCell(product: "Jumbo", rate: "7.050%", delta: .init(bps: 6))
        }
        .padding(Spacing.s16)
    }
    .background(Palette.surface)
}
