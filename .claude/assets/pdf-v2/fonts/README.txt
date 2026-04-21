NestIQ PDF templates — required font files
===========================================

Drop these 7 files into this fonts/ folder before use.
All fonts are freely redistributable (SIL Open Font License).

-------------------------------------------------------------
1. Source Serif 4  (4 files)
-------------------------------------------------------------
Download:  https://fonts.google.com/specimen/Source+Serif+4
           or https://github.com/adobe-fonts/source-serif/releases

Place these TTFs:
    SourceSerif4-Regular.ttf          (weight 400)
    SourceSerif4-Italic.ttf           (weight 400 italic)
    SourceSerif4-Semibold.ttf         (weight 600)
    SourceSerif4-SemiboldItalic.ttf   (weight 600 italic)

The Adobe release ships as a zip containing a `TTF/` folder —
those four files above are inside it.

-------------------------------------------------------------
2. JetBrains Mono  (3 files)
-------------------------------------------------------------
Download:  https://www.jetbrains.com/lp/mono/
           or https://github.com/JetBrains/JetBrainsMono/releases

Place these TTFs:
    JetBrainsMono-Regular.ttf   (weight 400)
    JetBrainsMono-Medium.ttf    (weight 500)
    JetBrainsMono-SemiBold.ttf  (weight 600)

The JetBrains release zip contains a `fonts/ttf/` folder —
those three files above are inside it.

-------------------------------------------------------------
iOS bundling
-------------------------------------------------------------
Copy these 7 TTFs to App/Resources/Fonts/ and add each
filename to the UIAppFonts array in Info.plist.

-------------------------------------------------------------
Web bundling (Next.js)
-------------------------------------------------------------
Copy to /public/fonts/, or import via next/font/local in
app/layout.tsx — see web v2 skeleton for reference.
