// Saved.jsx — Saved scenarios list

function SavedScreen({ dark = false }) {
  const bg = dark ? '#17160F' : '#FAF9F5';
  const raised = dark ? '#1E1D15' : '#FFFFFE';
  const sunken = dark ? '#121109' : '#F0EDE4';
  const ink = dark ? '#F2EFE2' : '#17160F';
  const ink2 = dark ? '#B4B0A0' : '#4A4840';
  const ink3 = dark ? '#7C7869' : '#85816F';
  const border = dark ? '#2A281F' : '#E5E1D5';
  const accent = dark ? '#4F9E7D' : '#1F4D3F';
  const accentTint = dark ? '#22322C' : '#DFE6E0';

  const groups = [
    {
      date: 'This week',
      items: [
        { num: '01', calc: 'Amortization', who: 'John & Maya Smith', line: '$548,000 · 30-yr · 6.75%', when: '2h', piti: '$3,284' },
        { num: '03', calc: 'Refi compare', who: 'Priya Venkatesan', line: 'Break-even · month 24', when: 'Yesterday', piti: 'save $412/mo' },
        { num: '04', calc: 'Total cost', who: 'Alonzo Garcia-Reyes', line: '4 scenarios · 10-yr horizon', when: 'Mon', piti: '$2,955' },
      ],
    },
    {
      date: 'Earlier in April',
      items: [
        { num: '05', calc: 'HELOC vs Refi', who: 'Dana & Michael Kim', line: 'Blended 4.85% · keep 1st', when: 'Apr 12', piti: '$3,390' },
        { num: '02', calc: 'Income qual', who: 'Okoye / Owens', line: 'Max $612K · DTI 38.1', when: 'Apr 09', piti: '$4,284 max' },
        { num: '01', calc: 'Amortization', who: 'Rashida Bellamy', line: '$289,000 · 20-yr · 6.25%', when: 'Apr 04', piti: '$2,119' },
      ],
    },
    {
      date: 'March',
      items: [
        { num: '03', calc: 'Refi compare', who: 'Tom Wozniak', line: '3 options · 1.25pt buydown', when: 'Mar 28', piti: 'save $210/mo' },
        { num: '01', calc: 'Amortization', who: 'Evelyn Whitaker', line: '$712,000 · 30-yr · 6.625%', when: 'Mar 21', piti: '$4,428' },
      ],
    },
  ];

  return (
    <div style={{ background: bg, minHeight: '100%', color: ink, fontFamily: 'var(--font-sans)' }}>
      <div style={{ height: 59 }} />

      {/* Header */}
      <div style={{ padding: '12px 20px 16px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>Saved</div>
          <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: '-0.02em', marginTop: 2 }}>Scenarios</div>
        </div>
        <div style={{ fontSize: 12, fontFamily: 'var(--font-mono)', color: ink3 }}>23 total</div>
      </div>

      {/* Search */}
      <div style={{ padding: '0 20px 16px' }}>
        <div style={{ background: raised, border: `1px solid ${border}`, borderRadius: 999, padding: '9px 14px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <svg width="14" height="14" viewBox="0 0 14 14"><circle cx="6" cy="6" r="4.25" fill="none" stroke={ink3} strokeWidth="1.5"/><path d="M9.5 9.5L13 13" stroke={ink3} strokeWidth="1.5" strokeLinecap="round"/></svg>
          <div style={{ fontSize: 13, color: ink3 }}>Search borrowers, tags…</div>
        </div>
      </div>

      {/* Filter chips */}
      <div style={{ padding: '0 20px 6px', display: 'flex', gap: 6, overflow: 'hidden' }}>
        {[
          { n: 'All', on: true },
          { n: 'Amort' }, { n: 'Income' }, { n: 'Refi' }, { n: 'TCA' }, { n: 'HELOC' },
        ].map((f, i) => (
          <div key={i} style={{
            padding: '5px 10px', fontSize: 11, fontFamily: 'var(--font-mono)',
            border: `1px solid ${f.on ? accent : border}`,
            background: f.on ? accent : 'transparent',
            color: f.on ? (dark ? '#0B0A04' : '#FAF9F5') : ink2,
            borderRadius: 999, flexShrink: 0,
          }}>{f.n}</div>
        ))}
      </div>

      {/* Groups */}
      {groups.map((g, gi) => (
        <div key={gi} style={{ marginTop: 18 }}>
          <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, padding: '0 20px 8px' }}>{g.date}</div>
          <div style={{ background: raised, borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}` }}>
            {g.items.map((it, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', padding: '12px 16px',
                borderBottom: i < g.items.length - 1 ? `1px solid ${border}` : '0',
              }}>
                <div style={{ width: 26, fontSize: 10.5, fontFamily: 'var(--font-mono)', color: ink3, letterSpacing: '0.05em' }}>{it.num}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 2 }}>
                    <span style={{ fontSize: 10, fontFamily: 'var(--font-mono)', padding: '1px 6px', border: `1px solid ${border}`, borderRadius: 3, color: ink2, letterSpacing: '0.03em' }}>{it.calc}</span>
                    <span style={{ fontSize: 11, color: ink3 }}>{it.when}</span>
                  </div>
                  <div style={{ fontSize: 14.5, fontWeight: 600, letterSpacing: '-0.01em' }}>{it.who}</div>
                  <div style={{ fontSize: 12, color: ink2, fontFamily: 'var(--font-mono)', marginTop: 1 }}>{it.line}</div>
                </div>
                <div style={{ fontSize: 12, fontFamily: 'var(--font-mono)', fontWeight: 500, color: ink2, whiteSpace: 'nowrap' }}>{it.piti}</div>
              </div>
            ))}
          </div>
        </div>
      ))}

      <div style={{ height: 100 }} />
    </div>
  );
}

Object.assign(window, { SavedScreen });
