// Home.jsx — Quotient iPhone Home / Calculator picker
// Editorial finance. Data-first. No icons for calculators — typographic list.

function HomeScreen({ dark = false }) {
  const bg = dark ? '#17160F' : '#FAF9F5';
  const raised = dark ? '#1E1D15' : '#FFFFFE';
  const ink = dark ? '#F2EFE2' : '#17160F';
  const ink2 = dark ? '#B4B0A0' : '#4A4840';
  const ink3 = dark ? '#7C7869' : '#85816F';
  const border = dark ? '#2A281F' : '#E5E1D5';
  const accent = dark ? '#4F9E7D' : '#1F4D3F';
  const gain = dark ? '#6FB28D' : '#2D6A4E';
  const loss = dark ? '#C47566' : '#8A3D34';

  const rates = [
    { name: '30-yr fixed',  rate: '6.825', delta: -0.03, move: 'down' },
    { name: '15-yr fixed',  rate: '6.125', delta: -0.02, move: 'down' },
    { name: '5/6 ARM',      rate: '6.625', delta: +0.01, move: 'up' },
    { name: 'FHA 30',       rate: '6.500', delta:  0.00, move: 'flat' },
    { name: 'VA 30',        rate: '6.375', delta: -0.04, move: 'down' },
    { name: 'Jumbo 30',     rate: '7.050', delta: +0.05, move: 'up' },
  ];

  const calcs = [
    { num: '01', name: 'Amortization',        hint: 'Schedule, PITI, extra principal, recast.' },
    { num: '02', name: 'Income qualification', hint: 'Max loan from income and debts.' },
    { num: '03', name: 'Refinance comparison', hint: 'Break-even, NPV, side-by-side.' },
    { num: '04', name: 'Total cost analysis',  hint: 'Two to four scenarios over 5/7/10/15/30 yr.' },
    { num: '05', name: 'HELOC vs refinance',   hint: 'Blended rate vs cash-out, with stress paths.' },
  ];

  const recent = [
    { label: 'Amortization', who: 'John & Maya Smith', sub: '$548,000 · 30-yr · 6.75%', when: '2h ago' },
    { label: 'Refi compare', who: 'Priya Venkatesan',  sub: 'break-even · month 27',    when: 'Yesterday' },
    { label: 'TCA',          who: 'Okoye / Owens',     sub: 'four scenarios · 10-yr',   when: 'Mon' },
  ];

  return (
    <div style={{ background: bg, minHeight: '100%', color: ink, fontFamily: 'var(--font-sans)' }}>
      {/* Status bar spacer */}
      <div style={{ height: 59 }} />

      {/* Greeting header */}
      <div style={{ padding: '12px 20px 18px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>
              Thursday · April 17
            </div>
            <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: '-0.02em', marginTop: 4, lineHeight: 1.15 }}>
              Good morning,<br/>Nick.
            </div>
          </div>
          <div style={{
            width: 34, height: 34, borderRadius: 17,
            background: raised, border: `1px solid ${border}`,
            display: 'grid', placeItems: 'center',
            fontSize: 12, fontWeight: 600, color: ink2,
          }}>NM</div>
        </div>
      </div>

      {/* Rate ribbon — today's rates, editorial ticker style */}
      <div style={{ padding: '0 0 20px' }}>
        <div style={{ padding: '0 20px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>
            Today · national average
          </div>
          <div style={{ fontSize: 11, color: ink3, fontFamily: 'var(--font-mono)' }}>09:22 EST</div>
        </div>
        <div style={{
          display: 'flex', gap: 0, overflow: 'hidden',
          borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}`,
          background: raised,
        }}>
          <div style={{ display: 'flex', padding: '0', overflow: 'auto' }}>
            {rates.map((r, i) => (
              <div key={i} style={{
                padding: '12px 16px',
                borderRight: i < rates.length - 1 ? `1px solid ${border}` : '0',
                minWidth: 130, flexShrink: 0,
              }}>
                <div style={{ fontSize: 11, color: ink3, fontWeight: 500, marginBottom: 4 }}>{r.name}</div>
                <div style={{
                  fontSize: 19, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums',
                  fontWeight: 500, color: ink, letterSpacing: '-0.01em',
                }}>{r.rate}<span style={{ fontSize: 11, color: ink3, marginLeft: 2 }}>%</span></div>
                <div style={{
                  fontSize: 10.5, fontFamily: 'var(--font-mono)',
                  color: r.move === 'down' ? gain : r.move === 'up' ? loss : ink3,
                  marginTop: 2,
                }}>
                  {r.move === 'flat' ? '—' : (r.delta > 0 ? '▲' : '▼')}
                  {' '}{r.delta === 0 ? '0.00' : Math.abs(r.delta).toFixed(2)}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Calculators — numbered editorial list, no icons */}
      <div style={{ padding: '0 20px 24px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, marginBottom: 12 }}>
          Calculators
        </div>
        <div style={{
          background: raised, border: `1px solid ${border}`,
          borderRadius: 14, overflow: 'hidden',
        }}>
          {calcs.map((c, i) => (
            <div key={c.num} style={{
              display: 'flex', alignItems: 'center', padding: '14px 16px',
              borderBottom: i < calcs.length - 1 ? `1px solid ${border}` : '0',
            }}>
              <div style={{
                fontSize: 11, fontFamily: 'var(--font-mono)',
                color: ink3, width: 24, flexShrink: 0, letterSpacing: '0.05em',
              }}>{c.num}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 16, fontWeight: 600, letterSpacing: '-0.01em' }}>{c.name}</div>
                <div style={{ fontSize: 12.5, color: ink2, marginTop: 1 }}>{c.hint}</div>
              </div>
              <svg width="7" height="12" viewBox="0 0 7 12" style={{ flexShrink: 0, marginLeft: 8 }}>
                <path d="M1 1l5 5-5 5" stroke={ink3} strokeWidth="1.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </div>
          ))}
        </div>
      </div>

      {/* Recent scenarios */}
      <div style={{ padding: '0 20px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 12 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>
            Recent scenarios
          </div>
          <div style={{ fontSize: 12, color: accent, fontWeight: 500 }}>See all</div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {recent.map((r, i) => (
            <div key={i} style={{
              background: raised, border: `1px solid ${border}`,
              borderRadius: 10, padding: '12px 14px',
              display: 'flex', alignItems: 'center',
            }}>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 3 }}>
                  <span style={{
                    fontSize: 10, fontFamily: 'var(--font-mono)', color: ink2,
                    padding: '1px 6px', border: `1px solid ${border}`, borderRadius: 3,
                    letterSpacing: '0.04em',
                  }}>{r.label}</span>
                  <span style={{ fontSize: 11, color: ink3 }}>{r.when}</span>
                </div>
                <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.01em' }}>{r.who}</div>
                <div style={{ fontSize: 12, color: ink2, fontFamily: 'var(--font-mono)', marginTop: 1 }}>{r.sub}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Tab bar spacer */}
      <div style={{ height: 100 }} />

      {/* Tab bar */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: dark ? 'rgba(23,22,15,0.85)' : 'rgba(250,249,245,0.88)',
        backdropFilter: 'blur(20px) saturate(180%)',
        borderTop: `1px solid ${border}`,
        padding: '10px 0 32px',
        display: 'flex', justifyContent: 'space-around',
      }}>
        {[
          { n: 'Calculators', on: true,
            ico: <path d="M4 3h12v18H4zM8 7h4M8 11h4M8 15h4" stroke="currentColor" strokeWidth="1.6" fill="none" strokeLinecap="round"/> },
          { n: 'Scenarios',
            ico: <path d="M3 6h14M3 12h14M3 18h10" stroke="currentColor" strokeWidth="1.6" fill="none" strokeLinecap="round"/> },
          { n: 'Settings',
            ico: <><circle cx="10" cy="12" r="2.5" stroke="currentColor" strokeWidth="1.6" fill="none"/>
                 <path d="M10 4v2M10 18v2M4 12H2M18 12h-2M5.5 7.5L4 6M16 18l-1.5-1.5M5.5 16.5L4 18M16 6l-1.5 1.5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"/></> },
        ].map((t, i) => (
          <div key={i} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            color: t.on ? accent : ink3,
          }}>
            <svg width="22" height="22" viewBox="0 0 20 24">{t.ico}</svg>
            <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.02em' }}>{t.n}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { HomeScreen });
