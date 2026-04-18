// AssumptionsDrawer.swift
// Slide-up sheet listing the hidden assumptions behind any calculator
// (e.g., "APR computed per Reg Z Appendix J"; "Amortization assumes
// no prepayment"). Rows are DataRow pairs; presentation handled by
// the parent via `.sheet`.
//
// Tokens consumed: Typography.h2 / bodyLg, Palette.surfaceRaised /
// inkSecondary, Radius.iosGroupedList, Spacing.s16 / s24.

import SwiftUI

public struct AssumptionsDrawer: View {
    public struct Assumption: Identifiable, Sendable {
        public let id: String
        public let label: String
        public let value: String
        public init(id: String, label: String, value: String) {
            self.id = id
            self.label = label
            self.value = value
        }
    }

    let assumptions: [Assumption]

    public init(assumptions: [Assumption]) {
        self.assumptions = assumptions
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                Text("Assumptions")
                    .textStyle(Typography.h2)
                    .foregroundStyle(Palette.ink)
                Text("These values drive the calculation. Adjust in Inputs to change the result.")
                    .textStyle(Typography.bodyLg)
                    .foregroundStyle(Palette.inkSecondary)
                VStack(spacing: 0) {
                    ForEach(Array(assumptions.enumerated()), id: \.element.id) { idx, a in
                        DataRow(
                            label: a.label,
                            value: a.value,
                            showDivider: idx < assumptions.count - 1
                        )
                    }
                }
            }
            .padding(.horizontal, Spacing.s24)
            .padding(.vertical, Spacing.s24)
        }
        .background(Palette.surfaceRaised)
        .clipShape(
            RoundedRectangle(cornerRadius: Radius.iosGroupedList, style: .continuous)
        )
    }
}

#Preview {
    AssumptionsDrawer(assumptions: [
        .init(id: "rate-lock", label: "Rate lock", value: "30 days"),
        .init(id: "points", label: "Discount points", value: "0.00 pts"),
        .init(id: "tax-rate", label: "Property tax rate", value: "1.25%"),
        .init(id: "ins", label: "Hazard insurance", value: "$135 / mo"),
        .init(id: "apr", label: "APR method", value: "Reg Z App. J actuarial")
    ])
    .frame(height: 420)
    .padding()
    .background(Palette.surface)
}
