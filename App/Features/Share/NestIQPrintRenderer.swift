// NestIQPrintRenderer.swift
// UIPrintPageRenderer subclass that draws the NestIQ brand header +
// page-counter footer on every page, over top of the paginated body
// content supplied by WKWebView's viewPrintFormatter().
//
// Core Graphics is used for the header/footer because WebKit's PDF
// pipeline does not implement CSS Paged Media running elements
// (session 5O / D8).

import UIKit

final class NestIQPrintRenderer: UIPrintPageRenderer {

    // Ink / accent / muted match Theme/Colors.swift Assets catalog
    // values. Hard-coded here — not dynamic — because the PDF is a
    // fixed deliverable, not a themed UI surface.
    private static let inkColor = UIColor(red: 0x17 / 255.0,
                                          green: 0x16 / 255.0,
                                          blue: 0x0F / 255.0,
                                          alpha: 1)
    private static let accentColor = UIColor(red: 0x1F / 255.0,
                                             green: 0x4D / 255.0,
                                             blue: 0x3F / 255.0,
                                             alpha: 1)
    private static let mutedColor = UIColor(red: 0x85 / 255.0,
                                            green: 0x81 / 255.0,
                                            blue: 0x6F / 255.0,
                                            alpha: 1)
    private static let dividerColor = UIColor(red: 0x17 / 255.0,
                                              green: 0x16 / 255.0,
                                              blue: 0x0F / 255.0,
                                              alpha: 0.16)

    override var headerHeight: CGFloat {
        get { 54 }
        set { _ = newValue }
    }

    override var footerHeight: CGFloat {
        get { 40 }
        set { _ = newValue }
    }

    override func drawHeaderForPage(at pageIndex: Int, in headerRect: CGRect) {
        // Wordmark: "Nest" in ink + italic "IQ" in accent green.
        let baseFont = UIFont(name: "Georgia", size: 15)
            ?? UIFont.systemFont(ofSize: 15, weight: .regular)
        let italicFont: UIFont = {
            if let italicDescriptor = baseFont.fontDescriptor
                .withSymbolicTraits(.traitItalic) {
                return UIFont(descriptor: italicDescriptor, size: baseFont.pointSize)
            }
            return baseFont
        }()
        let nest = NSAttributedString(
            string: "Nest",
            attributes: [
                .font: baseFont,
                .foregroundColor: Self.inkColor,
                .kern: -0.2
            ]
        )
        let iq = NSAttributedString(
            string: "IQ",
            attributes: [
                .font: italicFont,
                .foregroundColor: Self.accentColor,
                .kern: -0.2
            ]
        )
        let nestSize = nest.size()
        let iqSize = iq.size()
        let totalWidth = nestSize.width + iqSize.width
        let baseY = headerRect.minY + (headerRect.height - nestSize.height) / 2 - 4
        let originX = headerRect.midX - totalWidth / 2
        nest.draw(at: CGPoint(x: originX, y: baseY))
        iq.draw(at: CGPoint(x: originX + nestSize.width, y: baseY))

        // Divider below the wordmark.
        drawHorizontalRule(
            y: headerRect.maxY - 8,
            inset: 54,
            rectMinX: 0,
            rectMaxX: headerRect.width + headerRect.minX * 2
        )
    }

    override func drawFooterForPage(at pageIndex: Int, in footerRect: CGRect) {
        drawHorizontalRule(
            y: footerRect.minY + 8,
            inset: 54,
            rectMinX: 0,
            rectMaxX: footerRect.width + footerRect.minX * 2
        )

        let font = UIFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: Self.mutedColor,
            .kern: 0.4
        ]
        let textY = footerRect.minY + 18

        let pageText = "Page \(pageIndex + 1) of \(numberOfPages)"
        pageText.draw(
            at: CGPoint(x: 54, y: textY),
            withAttributes: attrs
        )

        let urlText = "nestiq.mortgage"
        let urlSize = urlText.size(withAttributes: attrs)
        let rightEdge = footerRect.width + footerRect.minX * 2 - 54
        urlText.draw(
            at: CGPoint(x: rightEdge - urlSize.width, y: textY),
            withAttributes: attrs
        )
    }

    /// Core Graphics doesn't inherit UIBezierPath's default line width
    /// reset, and headerHeight/footerHeight rectangles are drawn into
    /// the current graphics context. We draw a thin hairline by
    /// setting stroke color + width explicitly.
    private func drawHorizontalRule(
        y: CGFloat,
        inset: CGFloat,
        rectMinX: CGFloat,
        rectMaxX: CGFloat
    ) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        ctx.setStrokeColor(Self.dividerColor.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: rectMinX + inset, y: y))
        ctx.addLine(to: CGPoint(x: rectMaxX - inset, y: y))
        ctx.strokePath()
        ctx.restoreGState()
    }
}
