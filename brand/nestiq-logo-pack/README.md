# NestIQ — Logo Pack

Everything you need to put NestIQ in front of customers, in every surface, at every scale.

---

## What's inside

```
nestiq-logo-pack/
├── svg/                   ← vector masters. USE THESE WHEREVER YOU CAN.
├── png/                   ← raster exports at multiple widths (1x/2x/3x)
├── ios-app-icon/
│   └── AppIcon.appiconset/   ← drop into Xcode; run RENAME.sh first
├── favicon/               ← web favicons, 16–512px
└── README.md              ← this file
```

---

## Which logo to use where

### 🟢 **Wordmark A — primary. Use this 90% of the time.**
`Nest` (roman) + `IQ` (italic, accent green).

It's the logo. It matches the in-app typography (Source Serif 4 roman + italic emphasis — same gesture as "For *John & Maya Smith*" on the Quotient cover). It scales cleanly from 13px nav bars to 96pt PDF covers.

**Use for:** website header, marketing site, PDF cover, email signature, social profile banner, press kit, business cards, invoices, slide-deck title slide, keynote lower-third, any place you'd say "put the logo here."

| File | When |
|---|---|
| `wordmark-a-primary.svg/png` | Default. On paper (#FAF9F5) or white. |
| `wordmark-a-ink.svg/png` | Single-color jobs — stamps, foils, fax, single-ink print. |
| `wordmark-a-reverse-ink.svg/png` | On dark backgrounds (#17160F ink). |
| `wordmark-a-reverse-accent.svg/png` | On the brand green (#1F4D3F). |

---

### 🟡 Wordmark B — **secondary only**. Product stamp / badge.
`Nest` (serif) + `IQ` (mono, boxed chip).

A "product ribbon" feel. Reads as a tag or version stamp. Muddy below ~24px tall — don't shrink it.

**Use for:** marketing taglines ("Introducing NestIQ"), ribbons at the top of a landing page hero, a "Product of Year" style badge, a footer kicker. **Not** for the main logo position.

---

### 🟡 Wordmark C — stacked. Square/narrow contexts only.
Two-line lockup. `IQ.` has a terminal period that gives the mark editorial finality.

**Use for:** app tile labels, narrow sidebar, square social avatar where a wordmark needs to read, corner wordmarks on portrait-orientation documents.

---

### 🟢 Monogram — the `N` with `iq` subscript
Your icon mark. Square. Scales down to 16px.

| File | When |
|---|---|
| `monogram-accent.svg` | **Default app icon.** Green on cream `N`, brand-feeling. Use for iOS, favicon, social avatar. |
| `monogram-ink.svg` | Dark mode app icon, dark UI chrome. |
| `monogram-paper.svg` | When the icon sits on a dark background and needs to be a paper-colored chip. |
| `monogram-paper-accent-ring.svg` | Letterhead, cover-page seals, watermarks. More editorial. |

---

### 🟡 Masthead — PDF + letterhead
`masthead-pdf-letterhead.svg/png`. A double-rule lockup with "MORTGAGE INTELLIGENCE · EST. 2026" above the wordmark. Use it as the top-of-page header on:
- PDF cover pages (Quotient, offer letters, term sheets)
- Physical letterhead
- Any document that needs a newspaper-masthead gravitas.

Don't use it in-app — it's too formal.

---

### 🔴 With-house variant — **use sparingly; not recommended as primary**
`with-house-primary.svg`, `with-house-reverse.svg`.

You asked for it, so it's here. A thin-line pitched-roof house sits left of the wordmark. Honest caveat: **this fights the brand's editorial restraint.** The whole system is about type doing the work — adding literal illustrative iconography (a house on a mortgage product) is the trope the system was designed to avoid.

**Where it might earn its keep:**
- Facebook / LinkedIn ad creative where you have 2 seconds of attention and need an unambiguous "this is about homes" signal.
- Physical yard signs, mailers, realtor co-branded materials where the audience isn't yet brand-aware.

**Where to keep it out:** app UI, PDFs, slide decks, the website header. Use wordmark A instead.

---

## File formats — what to reach for

| Need | Use |
|---|---|
| Web, app, Figma, marketing design files | **SVG** |
| Print (offset, business cards, signage) | **SVG** → your print shop will convert to CMYK PDF |
| Microsoft Office (PowerPoint, Word), Google Docs | PNG @ 1620w or 3240w |
| iOS app icon | `ios-app-icon/AppIcon.appiconset/` (see below) |
| Favicon | `favicon/favicon-32.png` + 192 + 512 for web manifest |
| Social profile avatar | `monogram-accent-1024.png` |
| Email signature | `wordmark-a-primary-540.png` (≤540w keeps it crisp on retina) |

**SVGs reference Source Serif 4 and JetBrains Mono via Google Fonts.** They render correctly in any modern browser, Figma, Sketch, and most design tools. If your target environment won't load web fonts (old print RIPs, some Office setups), use the PNG instead or have a designer convert the SVG text to outlines.

---

## iOS app icon — how to install

The sandbox that generated these files doesn't allow `@` or `.` in filenames, so the AppIcon files are renamed. **Before dragging into Xcode:**

```bash
cd nestiq-logo-pack/ios-app-icon/AppIcon.appiconset
sh RENAME.sh     # restores the @2x / @3x / .5 naming Xcode expects
```

Then drag the `AppIcon.appiconset` folder into your Xcode project's `Assets.xcassets`. Done.

All icons are the accent-green monogram. No alpha channel (iOS requires opaque).

---

## Favicons — how to install

In your `<head>`:

```html
<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32.png">
<link rel="icon" type="image/png" sizes="192x192" href="/favicon-192.png">
<link rel="apple-touch-icon" sizes="180x180" href="/favicon-180.png">
<link rel="manifest" href="/site.webmanifest">
```

For the web manifest, reference `favicon-192.png` and `favicon-512.png`.

---

## Clear space + minimum sizes

**Clear space:** on all sides of any wordmark, keep empty padding equal to the x-height of `Nest`. Don't crowd it.

**Minimum sizes:**
- Wordmark A: 80px wide on screen, 0.75" in print.
- Wordmark B: 140px wide on screen (the chip gets unreadable below this).
- Wordmark C: 60px wide.
- Monogram: 16px (favicon floor).

---

## Colors (the brand palette this is built on)

| Token | Hex | Use |
|---|---|---|
| Ink | `#17160F` | Primary text, outline |
| Paper | `#FAF9F5` | Primary background |
| Accent | `#1F4D3F` | IQ italic, app icon, emphasis |
| Accent light | `#DFE6E0` | Reversed italic on dark |
| Accent bright | `#4F9E7D` | Reversed house-icon stroke |
| Muted | `#85816F` | Kicker text, dividers |

---

## Don't

- Don't redraw the logo. Use the masters.
- Don't change the italic `IQ` to roman — the italic is the idea.
- Don't substitute the fonts. If Source Serif 4 isn't available, fall back to Charter, then Iowan Old Style, then Georgia — never Inter/Roboto/Arial.
- Don't add the house icon unless you've read the "not recommended" note above.
- Don't place the logo on busy photography without a solid-color scrim underneath.
- Don't recolor — the palette exists for a reason.

---

That's it. Wordmark A + monogram-accent is 95% of what you'll ever need. Everything else is for edge cases you'll know when you hit.
