// BreakEvenChartSVG.swift
// Session 5O.3 / 5O.9 — pure-SVG break-even chart for the refinance and
// TCA PDFs. Returns inline SVG markup that drops into a
// `<div class="chart-container">` in the body HTML.
//
// Produces a chart with:
//   - X axis: month 0 … termMonths (hard-coded to loan term per 5O.9)
//   - Y axis: 0 … max(savings, closingCosts) + 10% pad, non-negative
//   - Savings line in accent green #1F4D3F
//   - Dashed horizontal reference line at closingCosts (muted)
//   - Crossover marker (circle + "Break-even · Month N" label) when
//     savings cross the closing line within the term
//
// When savings never cross closing within the term, returns an empty
// string — callers render a text fallback instead.

import Foundation

@MainActor
enum BreakEvenChartSVG {

    /// Build an SVG for a single scenario's break-even curve.
    /// `closingCosts` is the $ reference line. `termMonths` pins the
    /// x-axis domain (5O.9 fix — was unbounded before).
    static func build(
        series: [(month: Int, cumulative: Double)],
        closingCosts: Double,
        termMonths: Int,
        caption: String? = nil
    ) -> String {
        guard !series.isEmpty, termMonths > 0 else { return "" }

        let maxSavings = series.map(\.cumulative).max() ?? 0
        // If max savings never reach closing → no break-even possible.
        // Render chart anyway (shows trajectory) up to the minimum pad.
        let yMax = max(maxSavings, closingCosts) * 1.1
        guard yMax > 0 else { return "" }

        let crossover = firstCrossover(
            series: series,
            closingCosts: closingCosts,
            termMonths: termMonths
        )

        // SVG logical canvas. CSS scales to width: 100% via
        // base.html .chart-container rule, so the intrinsic viewBox
        // controls the aspect ratio, not the output pixel size.
        let viewW = 560.0
        let viewH = 300.0
        let padL = 60.0   // axis label room
        let padR = 20.0
        let padT = 16.0
        let padB = 42.0   // axis label room
        let plotW = viewW - padL - padR
        let plotH = viewH - padT - padB

        func sx(_ month: Int) -> Double {
            padL + (Double(month) / Double(termMonths)) * plotW
        }
        func sy(_ value: Double) -> Double {
            padT + plotH - (value / yMax) * plotH
        }

        // Build the savings polyline.
        let seriesClipped = series.filter { $0.month <= termMonths && $0.cumulative >= 0 }
        let points = seriesClipped
            .map { "\(String(format: "%.1f", sx($0.month))),\(String(format: "%.1f", sy($0.cumulative)))" }
            .joined(separator: " ")

        // X-axis ticks at 5-year (60-month) intervals + terminal tick.
        let xTicks: [Int] = {
            var ticks = Array(stride(from: 0, through: termMonths, by: 60))
            if ticks.last != termMonths { ticks.append(termMonths) }
            return ticks
        }()
        let mono = "SF Mono, Menlo, monospace"
        let xTickMarkup = xTicks.map { m -> String in
            let x = sx(m)
            let y = padT + plotH
            let year = m / 12
            let label = m == 0 ? "0" : "\(year)yr"
            let tick = "<line x1=\"\(fmt(x))\" y1=\"\(fmt(y))\" x2=\"\(fmt(x))\" y2=\"\(fmt(y + 4))\""
                + " stroke=\"#85816F\" stroke-width=\"0.5\" />"
            let text = "<text x=\"\(fmt(x))\" y=\"\(fmt(y + 18))\" text-anchor=\"middle\""
                + " font-family=\"\(mono)\" font-size=\"9\" fill=\"#85816F\">\(label)</text>"
            return tick + text
        }.joined()

        // Y-axis ticks at 25%, 50%, 75%, 100% of yMax.
        let yTicks = [0.25, 0.5, 0.75, 1.0]
        let yTickMarkup = yTicks.map { frac -> String in
            let v = yMax * frac
            let y = sy(v)
            let label = moneyShort(v)
            let tick = "<line x1=\"\(fmt(padL - 4))\" y1=\"\(fmt(y))\" x2=\"\(fmt(padL))\" y2=\"\(fmt(y))\""
                + " stroke=\"#85816F\" stroke-width=\"0.5\" />"
            let text = "<text x=\"\(fmt(padL - 8))\" y=\"\(fmt(y + 3))\" text-anchor=\"end\""
                + " font-family=\"\(mono)\" font-size=\"9\" fill=\"#85816F\">\(label)</text>"
            let grid = "<line x1=\"\(fmt(padL))\" y1=\"\(fmt(y))\" x2=\"\(fmt(padL + plotW))\""
                + " y2=\"\(fmt(y))\" stroke=\"rgba(23,22,15,0.06)\" stroke-width=\"0.5\" />"
            return tick + text + grid
        }.joined()

        // Closing-costs reference line (dashed).
        let closingY = sy(closingCosts)
        let closingLine: String = {
            guard closingCosts > 0, closingCosts <= yMax else { return "" }
            return """
            <line x1="\(fmt(padL))" y1="\(fmt(closingY))" x2="\(fmt(padL + plotW))" y2="\(fmt(closingY))"
                  stroke="#85816F" stroke-width="1" stroke-dasharray="4 4" />
            <text x="\(fmt(padL + plotW - 4))" y="\(fmt(closingY - 4))" text-anchor="end"
                  font-family="SF Mono, Menlo, monospace" font-size="9" fill="#85816F">Closing \(moneyShort(closingCosts))</text>
            """
        }()

        // Break-even crossover marker.
        let crossoverMarker: String = {
            guard let cx = crossover else { return "" }
            let x = sx(cx.month)
            let y = sy(cx.cumulative)
            return """
            <circle cx="\(fmt(x))" cy="\(fmt(y))" r="4" fill="#1F4D3F" stroke="#FAF9F5" stroke-width="1.5" />
            <text x="\(fmt(x + 8))" y="\(fmt(y - 6))" font-family="SF Mono, Menlo, monospace" font-size="9.5"
                  font-weight="600" fill="#1F4D3F">Break-even · Month \(cx.month)</text>
            """
        }()

        let captionMarkup = caption.map {
            "<div class=\"chart-caption\">\(PDFHTMLComposition.escape($0))</div>"
        } ?? ""

        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(fmt(viewW)) \(fmt(viewH))"
             role="img" aria-label="Break-even chart">
          <rect x="\(fmt(padL))" y="\(fmt(padT))" width="\(fmt(plotW))" height="\(fmt(plotH))"
                fill="#FFFFFF" stroke="rgba(23,22,15,0.12)" stroke-width="0.5" />
          \(yTickMarkup)
          \(closingLine)
          <line x1="\(fmt(padL))" y1="\(fmt(padT + plotH))" x2="\(fmt(padL + plotW))" y2="\(fmt(padT + plotH))"
                stroke="#17160F" stroke-width="0.8" />
          <polyline points="\(points)" fill="none" stroke="#1F4D3F" stroke-width="2" />
          \(crossoverMarker)
          \(xTickMarkup)
          <text x="\(fmt(padL + plotW / 2))" y="\(fmt(viewH - 8))" text-anchor="middle"
                font-family="SF Mono, Menlo, monospace" font-size="9" fill="#85816F">Months from close</text>
        </svg>
        """
        return """
        <div class="chart-container">
          \(svg)
          \(captionMarkup)
        </div>
        """
    }

    /// First month where cumulative savings ≥ closingCosts, within the
    /// given term. Returns nil if the curve never crosses inside the
    /// term horizon.
    static func firstCrossover(
        series: [(month: Int, cumulative: Double)],
        closingCosts: Double,
        termMonths: Int
    ) -> (month: Int, cumulative: Double)? {
        guard closingCosts > 0, termMonths > 0 else { return nil }
        for pt in series where pt.month <= termMonths {
            if pt.cumulative >= closingCosts {
                return pt
            }
        }
        return nil
    }

    // MARK: - Formatting

    private static func fmt(_ v: Double) -> String {
        let rounded = (v * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return String(format: "%.0f", rounded)
        }
        return String(format: "%.1f", rounded)
    }

    /// Compact money labels for chart axes — mirrors
    /// MoneyFormat.dollarsShort so chart + in-doc copy match.
    private static func moneyShort(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.2fM", value / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "$%.0fk", value / 1_000)
        }
        return String(format: "$%.0f", value)
    }
}
