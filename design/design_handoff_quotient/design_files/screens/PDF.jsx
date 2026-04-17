// PDF.jsx — Branded PDF preview (page 1 cover)
// This is a desktop/tablet-ish artboard, not a phone screen.

function PDFPreview() {
  const bg = '#FFFFFE';
  const ink = '#17160F';
  const ink2 = '#4A4840';
  const ink3 = '#85816F';
  const border = '#D3CEBE';
  const hair = '#E5E1D5';
  const accent = '#1F4D3F';
  const accentTint = '#DFE6E0';

  return (
    <div style={{ background: bg, width: '100%', height: '100%', color: ink, fontFamily: 'var(--font-sans)' }}>
      {/* Top brand strip */}
      <div style={{
        padding: '28px 48px 18px',
        borderBottom: `2px solid ${ink}`,
        display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between',
      }}>
        <div>
          <div style={{ fontFamily: 'var(--font-serif)', fontSize: 30, fontWeight: 400, letterSpacing: '-0.02em', lineHeight: 1 }}>
            Quotient
          </div>
          <div style={{ fontSize: 10.5, color: ink3, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', marginTop: 4 }}>
            Mortgage analysis · prepared for you
          </div>
        </div>
        <div style={{ textAlign: 'right', fontSize: 10.5, color: ink2, lineHeight: 1.5 }}>
          <div style={{ fontWeight: 600, color: ink, fontSize: 12 }}>Nick Moretti</div>
          <div>Senior Loan Officer · NMLS 1428391</div>
          <div>Cascade Lending Group · nick@cascade.com</div>
          <div>(415) 555-0123</div>
        </div>
      </div>

      {/* Document title */}
      <div style={{ padding: '36px 48px 8px' }}>
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: accent }}>
          Amortization analysis · April 17, 2026
        </div>
        <div style={{ fontFamily: 'var(--font-serif)', fontSize: 38, fontWeight: 400, letterSpacing: '-0.02em', marginTop: 6, lineHeight: 1.1 }}>
          For <i>John &amp; Maya Smith</i>
        </div>
        <div style={{ fontSize: 13, color: ink2, marginTop: 6, fontFamily: 'var(--font-mono)' }}>
          $548,000 · 30-yr fixed · 6.750% · start Apr 2026
        </div>
      </div>

      {/* Hero metric */}
      <div style={{
        margin: '26px 48px 0',
        borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}`,
        padding: '22px 0',
        display: 'grid', gridTemplateColumns: '1.3fr 1fr 1fr 1fr', gap: 24,
      }}>
        <div>
          <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: ink3 }}>Monthly payment · PITI</div>
          <div style={{ display: 'flex', alignItems: 'baseline', marginTop: 4 }}>
            <span style={{ fontSize: 14, color: ink3, fontFamily: 'var(--font-mono)' }}>$</span>
            <span style={{ fontSize: 44, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, letterSpacing: '-0.02em', lineHeight: 1 }}>4,207</span>
          </div>
        </div>
        {[
          { l: 'Total interest', v: '$560,961' },
          { l: 'Payoff',         v: 'Mar 2056' },
          { l: 'Total paid',     v: '$1.28M'   },
        ].map((k, i) => (
          <div key={i} style={{ borderLeft: `1px solid ${border}`, paddingLeft: 20 }}>
            <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: ink3 }}>{k.l}</div>
            <div style={{ fontSize: 22, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, marginTop: 6, letterSpacing: '-0.01em' }}>{k.v}</div>
          </div>
        ))}
      </div>

      {/* Narrative */}
      <div style={{ padding: '28px 48px 10px' }}>
        <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: ink3, marginBottom: 10 }}>
          Summary
        </div>
        <div style={{ fontFamily: 'var(--font-serif)', fontSize: 16, lineHeight: 1.55, color: ink, textWrap: 'pretty', maxWidth: 620 }}>
          At today's 30-year fixed rate of <b style={{ fontFamily: 'var(--font-sans)', fontWeight: 600 }}>6.75%</b>,
          a $548,000 loan on your anticipated purchase yields a blended monthly payment of
          <b style={{ fontFamily: 'var(--font-sans)', fontWeight: 600 }}> $4,207</b> including
          estimated taxes and insurance. The first year, roughly 87% of each payment covers interest;
          by year ten, the balance crosses below $474,000, and by year twenty you'll hold over $220,000 of equity.
        </div>
        <div style={{ fontFamily: 'var(--font-serif)', fontSize: 16, lineHeight: 1.55, color: ink, textWrap: 'pretty', maxWidth: 620, marginTop: 14 }}>
          Adding $250 of extra principal each month shortens the loan by approximately five years and
          saves $127,400 in lifetime interest — worth discussing against your cash-flow priorities.
        </div>
      </div>

      {/* Mini chart thumbnail */}
      <div style={{ margin: '22px 48px 0', padding: '18px 20px 14px', background: '#FAF9F5', border: `1px solid ${hair}`, borderRadius: 4 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <div style={{ fontSize: 12, fontWeight: 600 }}>Balance over time</div>
          <div style={{ fontSize: 10.5, color: ink3, fontFamily: 'var(--font-mono)' }}>30 yr · detail on page 2</div>
        </div>
        <svg width="100%" height="100" style={{ display: 'block', marginTop: 8 }} viewBox="0 0 620 100" preserveAspectRatio="none">
          <path d="M10 10 Q 200 20, 310 45 T 610 95" fill="none" stroke={accent} strokeWidth="1.5"/>
          <path d="M10 10 Q 200 20, 310 45 T 610 95 L 610 95 L 10 95 Z" fill={accentTint} opacity="0.6"/>
          <line x1="10" y1="95" x2="610" y2="95" stroke={border} strokeWidth="0.5"/>
        </svg>
      </div>

      {/* Footer */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        padding: '16px 48px',
        borderTop: `1px solid ${border}`,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        fontSize: 9.5, color: ink3, fontFamily: 'var(--font-mono)',
      }}>
        <div>Estimates for educational purposes · not a commitment to lend</div>
        <div>Page 1 of 6</div>
      </div>
    </div>
  );
}

Object.assign(window, { PDFPreview });
