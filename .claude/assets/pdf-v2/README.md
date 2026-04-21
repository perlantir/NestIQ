# NestIQ PDF Templates — v2.1.1

Print-ready editorial PDF templates for the NestIQ mortgage calculator suite. Consumed by the iOS `UIPrintPageRenderer` + `WKWebView.viewPrintFormatter()` pipeline and by the upcoming web Puppeteer / Playwright export path.

## What's in this zip

```
pdf-v2/
├── templates/
│   ├── pdf-amortization-with-masthead.html    ✅ v2.0
│   ├── pdf-amortization-body-only.html        ✅ v2.0
│   ├── pdf-refinance-with-masthead.html       ✅ v2.0
│   ├── pdf-refinance-body-only.html           ✅ v2.0
│   ├── pdf-tca-with-masthead.html             ✅ v2.0
│   ├── pdf-tca-body-only.html                 ✅ v2.0
│   ├── pdf-heloc-with-masthead.html           🆕 v2.1
│   └── pdf-heloc-body-only.html               🆕 v2.1
├── fonts/
│   └── README.txt                             ⚠️  TTFs to be added (see below)
├── tokens.css                                 ✅ shared styles + @font-face
├── tokens.schema.json                         ✅ token contract (JSON Schema)
└── README.md                                  (this file)
```

## What's new in v2.1

- **HELOC vs Refinance template** (`pdf-heloc-*.html`) — 3-page editorial layout:
  - Page 1: lien-stack diagram + recommendation hero + HELOC lifecycle timeline
  - Page 2: side-by-side HELOC vs cash-out refi comparison matrix
  - Page 3: variable-rate stress-test table (+0, +100, +200, +300 bps paths), assumptions, signature
- Introduces the **Option A-recommended / Option B** comparison pattern (binary), complementing the 3-option refi pattern from v2.0
- Full token contract added to `tokens.schema.json` — see `templates.heloc.tokens`

**Not shipped:** Income Qualification and Self-Employment / Fannie 1084 templates. The app generates those flows in-product; PDF export is not required for them.

## What changed vs v1

- **No more Google Fonts `@import`.** Replaced with `@font-face { src: url('../fonts/*.ttf') }` — see `fonts/README.txt` for the 7 TTFs to drop in.
- **Shared `tokens.css`** extracted from inline `<style>` blocks. One place to edit colors, type, page geometry. All 6 templates link it.
- **Mustache `{{tokens}}`** replace hardcoded borrower names, dollar amounts, dates, rates. See `tokens.schema.json` for the full contract.
- **Body-only variants** — masthead + footer stripped so iOS Core Graphics can draw its own headers/footers. Use `class="page body-only"` — the CSS auto-adjusts margins.
- **Print-safe schedule tables** — `thead { display: table-header-group; }` + `tr { page-break-inside: avoid; }` means a 360-row amortization schedule flows cleanly across pages.
- **`.monogram`, `.wordmark`, `.masthead`, `.hero`, `.kpi-strip`, `.schedule`** are now standardized classes — component-ready for any future template.

## Fonts to add

See `fonts/README.txt`. Seven TTFs total:
- Source Serif 4 Regular, Italic, Semibold, SemiboldItalic (SIL OFL)
- JetBrains Mono Regular, Medium, SemiBold (SIL OFL)

Both families are freely redistributable. Not bundled in the zip because binary font files can't be generated — download once and drop into `fonts/`.

## Testing

Before shipping to iOS:

1. Open each `*-with-masthead.html` in Safari on Mac with the fonts folder populated.
2. `Cmd+P` → **Save as PDF** → preview the output.
3. Confirm: serif masthead + wordmark render (not falling back to Times), mono figures are tabular-aligned, scenario color stripes print (requires `-webkit-print-color-adjust: exact` — already set).
4. Safari's WebKit is the same engine used by `WKWebView.viewPrintFormatter()` on iOS — if it prints cleanly in Safari, it prints cleanly on device.

For the amortization report specifically, test with a real 360-row schedule payload to verify `page-break-inside: avoid;` behaves as expected on long tables.

## Consuming the tokens

Minimal iOS example (Swift):

```swift
let raw = try String(contentsOf: templateURL, encoding: .utf8)
var html = raw
for (key, value) in tokens {
    html = html.replacingOccurrences(of: "{{\(key)}}", with: value)
}
webView.loadHTMLString(html, baseURL: resourcesFolderURL)  // baseURL lets ../fonts/*.ttf resolve
```

Web (TypeScript) — use [mustache.js](https://github.com/janl/mustache.js) or any Mustache renderer. JSON Schema in `tokens.schema.json` can drive a `zod` / `typebox` type at compile time.

## Version notes

- **v2.0** — tokenization, local fonts, body-only variants, 3 templates (amortization, refinance, TCA).
- **v2.0.1** — cleanup patch: swept hardcoded borrower names ("Garcia-Reyes", "Venkatesan") and literal doc numbers that remained in `<title>` tags, page footers, and sidebar doctype chips across refi + TCA. All now use `{{borrower_last}}` and `{{doc_num}}` tokens.
- **v2.1** — adds HELOC vs Refinance template (masthead + body-only).
- **v2.1.1** (this release) — same cleanup as v2.0.1 re-applied on top of v2.1 (the v2.1 base was built on v2.0, not v2.0.1, so the refi/TCA leaks reappeared). All 8 templates verified clean. No changes to HELOC templates or token contract.
- **Out of scope permanently** — Income Qualification and Self-Employment PDF exports are not planned. Both are flows designed to stay in-product; rendering them to a branded, LO-signed PDF would read as a pre-qualification letter and cross into CFPB Regulation B / ECOA territory.
- **v3.0** (future) — data-driven `<tbody>` loops for schedule + matrix rows, reducing literal HTML.
