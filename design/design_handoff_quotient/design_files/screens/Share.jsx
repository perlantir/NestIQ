// Share.jsx — Share / PDF preview (paged carousel: cover / schedule / disclaimers)

function ShareScreen({ dark = false }) {
  const bg = dark ? '#17160F' : '#FAF9F5';
  const raised = dark ? '#1E1D15' : '#FFFFFE';
  const sunken = dark ? '#121109' : '#F0EDE4';
  const ink = dark ? '#F2EFE2' : '#17160F';
  const ink2 = dark ? '#B4B0A0' : '#4A4840';
  const ink3 = dark ? '#7C7869' : '#85816F';
  const border = dark ? '#2A281F' : '#E5E1D5';
  const accent = dark ? '#4F9E7D' : '#1F4D3F';

  // Miniaturized page — portrait 8.5×11 scaled to fit
  const PageMini = ({ children, label, active }) => (
    <div style={{
      width: 248, height: 320, flexShrink: 0,
      background: '#FFFFFE', // pages always light
      border: `1px solid ${active ? accent : border}`,
      borderRadius: 4,
      boxShadow: active ? '0 18px 48px rgba(0,0,0,0.18)' : '0 6px 18px rgba(0,0,0,0.10)',
      position: 'relative', overflow: 'hidden',
      transform: active ? 'scale(1)' : 'scale(0.94)',
      transition: 'transform 180ms',
      color: '#17160F',
    }}>
      {children}
      <div style={{ position: 'absolute', top: 8, right: 8, fontSize: 8.5, fontFamily: 'var(--font-mono)', color: '#85816F' }}>{label}</div>
    </div>
  );

  // Each mini-page content (super simplified at 248w)
  const Cover = () => (
    <div style={{ padding: '18px 18px 14px', fontFamily: 'var(--font-sans)', height: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', borderBottom: '1.5px solid #17160F', paddingBottom: 10 }}>
        <div style={{ fontFamily: 'var(--font-serif)', fontSize: 15 }}>Quotient</div>
        <div style={{ fontSize: 7.5, color: '#4A4840' }}>Nicholas Metcalfe · NMLS 284011</div>
      </div>
      <div style={{ fontSize: 7.5, color: accent, marginTop: 12, letterSpacing: '0.08em', textTransform: 'uppercase', fontWeight: 600 }}>Amortization analysis · April 17, 2026</div>
      <div style={{ fontFamily: 'var(--font-serif)', fontSize: 20, marginTop: 4, letterSpacing: '-0.01em', lineHeight: 1.15 }}>For <i>John & Maya Smith</i></div>
      <div style={{ fontSize: 8, color: '#4A4840', fontFamily: 'var(--font-mono)', marginTop: 4 }}>$548,000 · 30-yr fixed · 6.750%</div>

      {/* Hero KPIs */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', borderTop: '1px solid #E5E1D5', borderBottom: '1px solid #E5E1D5', marginTop: 12, padding: '8px 0' }}>
        {[['$', '3,284', '/mo'], ['Int', '633K'], ['End', "'56"], ['Tot', '1.2M']].map((k, i) => (
          <div key={i} style={{ paddingLeft: i === 0 ? 0 : 6, borderLeft: i === 0 ? '0' : '1px solid #E5E1D5' }}>
            <div style={{ fontSize: 6.5, color: '#85816F', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase' }}>{k[0]}</div>
            <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', fontWeight: 500 }}>{k[1]}</div>
            {k[2] && <div style={{ fontSize: 7, color: '#85816F', fontFamily: 'var(--font-mono)' }}>{k[2]}</div>}
          </div>
        ))}
      </div>

      {/* Body */}
      <div style={{ fontFamily: 'var(--font-serif)', fontSize: 9, lineHeight: 1.5, marginTop: 12, color: '#17160F' }}>
        John and Maya — this is a <b style={{ fontFamily: 'var(--font-sans)' }}>30-year fixed</b> on
        $548,000 at 6.75%. Your monthly PITI is $3,284, of which $2,234 is principal
        &amp; interest. Over the life of the loan you'll pay $633K in interest…
      </div>

      {/* Mini chart */}
      <div style={{ marginTop: 'auto', border: '1px solid #E5E1D5', height: 52, position: 'relative', padding: 6 }}>
        <svg viewBox="0 0 220 40" style={{ width: '100%', height: '100%' }} preserveAspectRatio="none">
          <path d="M0 38 L220 4 L220 40 L0 40 Z" fill={accent} opacity="0.18"/>
          <path d="M0 38 L220 4" stroke={accent} strokeWidth="1.2" fill="none"/>
        </svg>
      </div>

      <div style={{ borderTop: '1px solid #17160F', marginTop: 8, paddingTop: 4, fontSize: 6.5, color: '#85816F', fontFamily: 'var(--font-mono)', display: 'flex', justifyContent: 'space-between' }}>
        <span>For illustration only · NMLS 284011 · CA, OR, WA</span>
        <span>1/3</span>
      </div>
    </div>
  );

  const Schedule = () => (
    <div style={{ padding: '18px 18px 14px', fontFamily: 'var(--font-sans)', height: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ fontSize: 7.5, color: accent, letterSpacing: '0.08em', textTransform: 'uppercase', fontWeight: 600 }}>Schedule</div>
      <div style={{ fontFamily: 'var(--font-serif)', fontSize: 14, marginTop: 2 }}>Year-by-year</div>

      {/* header */}
      <div style={{ display: 'grid', gridTemplateColumns: '26px repeat(4, 1fr)', padding: '5px 0', borderTop: '1px solid #17160F', borderBottom: '1px solid #E5E1D5', marginTop: 8 }}>
        {['Yr','Pmt','Int','Princ','Bal'].map(h => (
          <div key={h} style={{ fontSize: 6, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: '#85816F', textAlign: h === 'Yr' ? 'left' : 'right' }}>{h}</div>
        ))}
      </div>
      {[
        ['01','39.4k','36.7k','2.7k','545.3k'],
        ['05','39.4k','34.5k','4.9k','520.0k'],
        ['10','39.4k','31.0k','8.4k','471.6k'],
        ['15','39.4k','25.4k','14.0k','392.3k'],
        ['20','39.4k','16.8k','22.6k','260.7k'],
        ['25','39.4k','5.0k','34.4k','51.1k'],
        ['30','39.4k','1.5k','37.9k','0'],
      ].map((row, i) => (
        <div key={i} style={{ display: 'grid', gridTemplateColumns: '26px repeat(4, 1fr)', padding: '4px 0', borderBottom: '1px solid #E5E1D5', fontSize: 8, fontFamily: 'var(--font-mono)' }}>
          {row.map((v, j) => <div key={j} style={{ textAlign: j === 0 ? 'left' : 'right', color: j === 0 ? '#85816F' : '#17160F' }}>{v}</div>)}
        </div>
      ))}

      <div style={{ borderTop: '1px solid #17160F', marginTop: 'auto', paddingTop: 4, fontSize: 6.5, color: '#85816F', fontFamily: 'var(--font-mono)', display: 'flex', justifyContent: 'space-between' }}>
        <span>Full monthly schedule on request</span>
        <span>2/3</span>
      </div>
    </div>
  );

  const Disclaimers = () => (
    <div style={{ padding: '18px 18px 14px', fontFamily: 'var(--font-sans)', height: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ fontSize: 7.5, color: accent, letterSpacing: '0.08em', textTransform: 'uppercase', fontWeight: 600 }}>Disclosures</div>
      <div style={{ fontFamily: 'var(--font-serif)', fontSize: 14, marginTop: 2 }}>The fine print</div>

      <div style={{ fontSize: 8.5, lineHeight: 1.55, color: '#4A4840', marginTop: 10, fontFamily: 'var(--font-serif)' }}>
        This illustration is not a commitment to lend. Rates shown reflect pricing
        available on April 17, 2026 at 09:22 PDT for qualifying 740+ FICO borrowers
        with 20% down on an owner-occupied, single-family primary residence. Actual
        APR will vary by program, property, and borrower qualifications.
      </div>

      <div style={{ fontSize: 7.5, color: '#85816F', marginTop: 10, fontFamily: 'var(--font-mono)', borderTop: '1px solid #E5E1D5', paddingTop: 8 }}>
        <div>Metcalfe Home Lending · NMLS 19224</div>
        <div>Nicholas Metcalfe · Individual NMLS 284011</div>
        <div>Licensed: CA · OR · WA</div>
        <div style={{ marginTop: 6 }}>Equal Housing Opportunity</div>
      </div>

      <div style={{ borderTop: '1px solid #17160F', marginTop: 'auto', paddingTop: 4, fontSize: 6.5, color: '#85816F', fontFamily: 'var(--font-mono)', display: 'flex', justifyContent: 'space-between' }}>
        <span>Generated Apr 17, 2026 · 09:24 PDT</span>
        <span>3/3</span>
      </div>
    </div>
  );

  return (
    <div style={{ background: sunken, minHeight: '100%', color: ink, fontFamily: 'var(--font-sans)' }}>
      <div style={{ height: 59 }} />

      {/* Nav */}
      <div style={{ display: 'flex', alignItems: 'center', padding: '6px 16px 10px', justifyContent: 'space-between' }}>
        <div style={{ fontSize: 15, color: accent, fontWeight: 500 }}>Done</div>
        <div style={{ fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em' }}>Preview</div>
        <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: ink3, letterSpacing: '0.04em' }}>3 pp · 820 KB</div>
      </div>

      {/* Recipient row */}
      <div style={{ padding: '4px 20px 18px' }}>
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, marginBottom: 6 }}>For</div>
        <div style={{ background: raised, border: `1px solid ${border}`, borderRadius: 10, padding: '10px 12px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 28, height: 28, borderRadius: 14, background: sunken, border: `1px solid ${border}`, display: 'grid', placeItems: 'center', fontSize: 10, fontWeight: 600, color: ink2 }}>JS</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13.5, fontWeight: 600, letterSpacing: '-0.01em' }}>John & Maya Smith</div>
            <div style={{ fontSize: 11, color: ink3, fontFamily: 'var(--font-mono)' }}>john.smith@email.com</div>
          </div>
          <div style={{ fontSize: 12, color: accent, fontWeight: 500 }}>Change</div>
        </div>
      </div>

      {/* Paged carousel */}
      <div style={{ padding: '0 0 14px' }}>
        <div style={{ display: 'flex', gap: 14, padding: '0 44px', alignItems: 'center' }}>
          <PageMini active label="Cover · 1/3"><Cover/></PageMini>
          <PageMini label="Schedule · 2/3"><Schedule/></PageMini>
          <PageMini label="Disclosures · 3/3"><Disclaimers/></PageMini>
        </div>

        {/* Dots */}
        <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginTop: 14 }}>
          {[0,1,2].map(i => (
            <div key={i} style={{ width: i === 0 ? 20 : 6, height: 6, borderRadius: 3, background: i === 0 ? accent : ink3, opacity: i === 0 ? 1 : 0.4, transition: 'width 180ms' }}/>
          ))}
        </div>
      </div>

      {/* Edit toolbar */}
      <div style={{ padding: '8px 20px 10px' }}>
        <div style={{ background: raised, border: `1px solid ${border}`, borderRadius: 12, padding: '10px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div style={{ fontSize: 12.5, fontWeight: 600 }}>Narrative · editable</div>
            <div style={{ fontSize: 11, color: ink3, fontFamily: 'var(--font-mono)', marginTop: 1 }}>Tap to tweak before sending</div>
          </div>
          <svg width="16" height="16" viewBox="0 0 16 16"><path d="M11 2l3 3-8 8H3v-3l8-8z" stroke={ink2} strokeWidth="1.5" fill="none" strokeLinejoin="round"/></svg>
        </div>
      </div>

      <div style={{ height: 100 }} />

      {/* Bottom actions */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '10px 16px 30px',
        background: dark ? 'rgba(23,22,15,0.88)' : 'rgba(240,237,228,0.9)',
        backdropFilter: 'blur(20px) saturate(180%)',
        borderTop: `1px solid ${border}`,
        display: 'flex', gap: 8,
      }}>
        <div style={{ flex: 1, padding: '12px 0', textAlign: 'center', border: `1px solid ${border}`, borderRadius: 10, fontSize: 14, fontWeight: 500, background: raised }}>Save to Files</div>
        <div style={{ flex: 1.2, padding: '12px 0', textAlign: 'center', background: accent, color: dark ? '#0B0A04' : '#FAF9F5', borderRadius: 10, fontSize: 14, fontWeight: 600 }}>Share · AirDrop, Mail…</div>
      </div>
    </div>
  );
}

Object.assign(window, { ShareScreen });
