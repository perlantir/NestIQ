// Foundations.jsx — Token sheet: palette, type, icons, components

function Foundations() {
  const ink = '#17160F', ink2 = '#4A4840', ink3 = '#85816F';
  const border = '#E5E1D5', accent = '#1F4D3F';
  const swatch = (name, hex, fg = ink) => (
    <div style={{ border: `1px solid ${border}`, borderRadius: 4, overflow: 'hidden' }}>
      <div style={{ background: hex, height: 54 }} />
      <div style={{ padding: '7px 9px', background: '#FAF9F5' }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: fg }}>{name}</div>
        <div style={{ fontSize: 10, fontFamily: 'var(--font-mono)', color: ink3, marginTop: 1 }}>{hex}</div>
      </div>
    </div>
  );

  return (
    <div style={{
      background: '#FAF9F5', padding: '32px 36px',
      width: '100%', height: '100%', overflow: 'auto',
      fontFamily: 'var(--font-sans)', color: ink,
    }}>
      <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: ink3 }}>
        Foundations · 00
      </div>
      <div style={{ fontFamily: 'var(--font-serif)', fontSize: 34, fontWeight: 400, letterSpacing: '-0.02em', marginTop: 4 }}>
        Quotient — design system
      </div>
      <div style={{ fontSize: 13, color: ink2, marginTop: 6, maxWidth: 560, lineHeight: 1.5 }}>
        Editorial finance aesthetic. Warm paper base; deep ledger-green accent; SF Pro for UI,
        SF Mono for all financial numerals. Restrained, data-first, never decorative.
      </div>

      {/* Palette */}
      <div style={{ marginTop: 28 }}>
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: ink3, marginBottom: 12 }}>Palette</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 10 }}>
          {swatch('Surface', '#FAF9F5')}
          {swatch('Raised',  '#FFFFFE')}
          {swatch('Sunken',  '#F0EDE4')}
          {swatch('Border',  '#E5E1D5')}
          {swatch('Ink',     '#17160F', '#FFF')}
          {swatch('Ink 2',   '#4A4840', '#FFF')}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 10, marginTop: 10 }}>
          {swatch('Accent',  '#1F4D3F', '#FFF')}
          {swatch('Accent tint', '#DFE6E0')}
          {swatch('Gain',    '#2D6A4E', '#FFF')}
          {swatch('Loss',    '#8A3D34', '#FFF')}
          {swatch('Warn',    '#8C6A1E', '#FFF')}
          {swatch('Grid',    '#ECE8DC')}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10, marginTop: 10 }}>
          {swatch('Scenario 1 · green', '#1F4D3F', '#FFF')}
          {swatch('Scenario 2 · blue',  '#264B6A', '#FFF')}
          {swatch('Scenario 3 · wine',  '#6A3F5A', '#FFF')}
          {swatch('Scenario 4 · umber', '#73522A', '#FFF')}
        </div>
      </div>

      {/* Type */}
      <div style={{ marginTop: 36 }}>
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: ink3, marginBottom: 14 }}>Type</div>
        <div style={{ borderTop: `1px solid ${border}` }}>
          {[
            { n: 'Display · SF Pro 34 / 700', s: { fontSize: 34, fontWeight: 700, letterSpacing: '-0.02em' }, t: 'Good morning, Nick.' },
            { n: 'Title · SF Pro 22 / 700', s: { fontSize: 22, fontWeight: 700, letterSpacing: '-0.015em' }, t: 'John & Maya Smith' },
            { n: 'Section · SF Pro 15 / 600', s: { fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em' }, t: 'Balance over time' },
            { n: 'Body · SF Pro 13', s: { fontSize: 13, fontWeight: 400 }, t: 'Results update live as you adjust inputs.' },
            { n: 'Eyebrow · SF Pro 11 / 600 / tracked', s: { fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }, t: 'Today · national average' },
            { n: 'Numeric · SF Mono 32 tnum', s: { fontSize: 32, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, letterSpacing: '-0.02em' }, t: '$4,207.00' },
            { n: 'Tabular · SF Mono 12 tnum', s: { fontSize: 12, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums' }, t: '547,553.02' },
            { n: 'Serif (print only) · Source Serif 4 26', s: { fontSize: 26, fontFamily: 'var(--font-serif)', fontWeight: 400, letterSpacing: '-0.02em', fontStyle: 'italic' }, t: 'For John & Maya Smith' },
          ].map((r, i) => (
            <div key={i} style={{
              display: 'grid', gridTemplateColumns: '220px 1fr',
              padding: '14px 0', borderBottom: `1px solid ${border}`, alignItems: 'baseline',
            }}>
              <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: ink3 }}>{r.n}</div>
              <div style={r.s}>{r.t}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Components */}
      <div style={{ marginTop: 36 }}>
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: ink3, marginBottom: 14 }}>Components</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
          {/* Buttons */}
          <div style={{ background: '#FFFFFE', border: `1px solid ${border}`, borderRadius: 8, padding: 16 }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: ink3, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10 }}>Buttons</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <div style={{ padding: '10px 0', textAlign: 'center', background: accent, color: '#FAF9F5', borderRadius: 8, fontSize: 13, fontWeight: 600 }}>Primary</div>
              <div style={{ padding: '10px 0', textAlign: 'center', background: '#FAF9F5', color: ink, border: `1px solid ${border}`, borderRadius: 8, fontSize: 13, fontWeight: 500 }}>Secondary</div>
              <div style={{ padding: '10px 0', textAlign: 'center', color: accent, fontSize: 13, fontWeight: 500 }}>Ghost</div>
            </div>
          </div>

          {/* Data tile */}
          <div style={{ background: '#FFFFFE', border: `1px solid ${border}`, borderRadius: 8, padding: 16 }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: ink3, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10 }}>Data tile</div>
            <div style={{ fontSize: 9.5, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: ink3 }}>Break-even</div>
            <div style={{ fontSize: 26, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, letterSpacing: '-0.02em', marginTop: 4 }}>24 mo</div>
            <div style={{ fontSize: 11, color: ink3, fontFamily: 'var(--font-mono)', marginTop: 2 }}>Mar 2028</div>
          </div>

          {/* Badges */}
          <div style={{ background: '#FFFFFE', border: `1px solid ${border}`, borderRadius: 8, padding: 16 }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: ink3, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10 }}>Badges</div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
              <div style={{ fontSize: 10, fontFamily: 'var(--font-mono)', color: accent, padding: '2px 7px', border: `1px solid #DFE6E0`, background: '#DFE6E0', borderRadius: 3, letterSpacing: '0.04em' }}>GEN-QM</div>
              <div style={{ fontSize: 10, fontFamily: 'var(--font-mono)', color: '#8A3D34', padding: '2px 7px', border: `1px solid #EDDAD4`, background: '#EDDAD4', borderRadius: 3, letterSpacing: '0.04em' }}>HPML</div>
              <div style={{ fontSize: 10, fontFamily: 'var(--font-mono)', color: ink2, padding: '2px 7px', border: `1px solid ${border}`, borderRadius: 3, letterSpacing: '0.04em' }}>Amortization</div>
            </div>
          </div>

          {/* Input */}
          <div style={{ background: '#FFFFFE', border: `1px solid ${border}`, borderRadius: 8, padding: 16 }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: ink3, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10 }}>Input (focused)</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: `1.5px solid ${accent}` }}>
              <div style={{ flex: 1, fontSize: 13 }}>Interest rate</div>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 15, fontWeight: 500 }}>6.750<span style={{ color: ink3 }}> %</span></div>
            </div>
          </div>

          {/* Segmented */}
          <div style={{ background: '#FFFFFE', border: `1px solid ${border}`, borderRadius: 8, padding: 16 }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: ink3, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10 }}>Segmented</div>
            <div style={{ display: 'flex', gap: 4 }}>
              {['10','15','20','30'].map(t => (
                <div key={t} style={{
                  flex: 1, padding: '6px 0', textAlign: 'center',
                  fontSize: 12, fontWeight: t === '30' ? 600 : 500, fontFamily: 'var(--font-mono)',
                  background: t === '30' ? accent : '#F0EDE4',
                  color: t === '30' ? '#FAF9F5' : ink2,
                  border: `1px solid ${t === '30' ? accent : border}`,
                  borderRadius: 6,
                }}>{t}</div>
              ))}
            </div>
          </div>

          {/* Row */}
          <div style={{ background: '#FFFFFE', border: `1px solid ${border}`, borderRadius: 8, padding: 16 }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: ink3, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10 }}>Data row</div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, padding: '6px 0', borderBottom: `1px solid ${border}` }}>
              <span style={{ color: ink2 }}>Principal</span>
              <span style={{ fontFamily: 'var(--font-mono)' }}>$447</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, padding: '6px 0', borderBottom: `1px solid ${border}` }}>
              <span style={{ color: ink2 }}>Interest</span>
              <span style={{ fontFamily: 'var(--font-mono)' }}>$3,083</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, padding: '6px 0' }}>
              <span style={{ color: ink2 }}>Taxes</span>
              <span style={{ fontFamily: 'var(--font-mono)' }}>$542</span>
            </div>
          </div>
        </div>
      </div>

      {/* Principles */}
      <div style={{ marginTop: 36, paddingTop: 20, borderTop: `1px solid ${border}` }}>
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: ink3, marginBottom: 10 }}>
          Principles
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, fontSize: 13, lineHeight: 1.55, color: ink2, maxWidth: 760 }}>
          <div><b style={{ color: ink }}>Numbers are the protagonist.</b> Every financial figure uses SF Mono with tabular numerals so columns align; never mix sans into a column of numbers.</div>
          <div><b style={{ color: ink }}>Hierarchy by rule and space.</b> Division comes from hairline rules and negative space, not boxes-within-boxes.</div>
          <div><b style={{ color: ink }}>One accent, used like a highlighter.</b> Ledger green marks active state, primary CTA, links, and winning scenarios. Nothing else.</div>
          <div><b style={{ color: ink }}>Editorial charts.</b> No thick strokes, no chartjunk. Labels anchor to lines; grids are whispered, not stated.</div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { Foundations });
