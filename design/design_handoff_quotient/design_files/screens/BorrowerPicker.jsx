// BorrowerPicker.jsx — bottom sheet for choosing borrower

function BorrowerPickerScreen({ dark = false }) {
  const bg = dark ? '#17160F' : '#FAF9F5';
  const raised = dark ? '#1E1D15' : '#FFFFFE';
  const sunken = dark ? '#121109' : '#F0EDE4';
  const ink = dark ? '#F2EFE2' : '#17160F';
  const ink2 = dark ? '#B4B0A0' : '#4A4840';
  const ink3 = dark ? '#7C7869' : '#85816F';
  const border = dark ? '#2A281F' : '#E5E1D5';
  const accent = dark ? '#4F9E7D' : '#1F4D3F';
  const accentTint = dark ? '#22322C' : '#DFE6E0';

  const people = [
    { init: 'JS', name: 'John & Maya Smith', sub: '2 scenarios · last 2h ago', tag: 'CONV' },
    { init: 'PV', name: 'Priya Venkatesan', sub: '5 scenarios · refi in motion', tag: 'CONV', active: true },
    { init: 'OO', name: 'Okoye / Owens', sub: '1 scenario · pre-qual', tag: 'FHA' },
    { init: 'AG', name: 'Alonzo Garcia-Reyes', sub: '4 scenarios · TCA', tag: 'VA' },
    { init: 'DK', name: 'Dana & Michael Kim', sub: 'HELOC vs refi', tag: 'CONV' },
    { init: 'RB', name: 'Rashida Bellamy', sub: '1 scenario', tag: 'JUMBO' },
    { init: 'TW', name: 'Tom Wozniak', sub: '3 scenarios', tag: 'CONV' },
    { init: 'EW', name: 'Evelyn Whitaker', sub: '2 scenarios', tag: 'CONV' },
  ];

  return (
    <div style={{ background: 'rgba(0,0,0,0.35)', minHeight: '100%', color: ink, fontFamily: 'var(--font-sans)', position: 'relative' }}>
      {/* Dimmed background — mock of home screen */}
      <div style={{ position: 'absolute', inset: 0, background: bg, opacity: 0.4 }}/>

      {/* Sheet */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: bg,
        borderTopLeftRadius: 20, borderTopRightRadius: 20,
        maxHeight: '88%',
        overflow: 'hidden',
        boxShadow: '0 -12px 40px rgba(0,0,0,0.22)',
        display: 'flex', flexDirection: 'column',
      }}>
        {/* Grabber */}
        <div style={{ display: 'flex', justifyContent: 'center', padding: '8px 0 4px' }}>
          <div style={{ width: 36, height: 4, borderRadius: 2, background: ink3, opacity: 0.5 }}/>
        </div>

        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '6px 16px 14px', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 13, color: ink3 }}>Cancel</div>
          <div style={{ fontSize: 16, fontWeight: 600, letterSpacing: '-0.01em' }}>Borrower</div>
          <div style={{ fontSize: 13, color: accent, fontWeight: 500 }}>New</div>
        </div>

        {/* Search */}
        <div style={{ padding: '0 16px 12px' }}>
          <div style={{ background: sunken, border: `1px solid ${border}`, borderRadius: 10, padding: '9px 12px', display: 'flex', alignItems: 'center', gap: 8 }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><circle cx="6" cy="6" r="4.25" fill="none" stroke={ink3} strokeWidth="1.5"/><path d="M9.5 9.5L13 13" stroke={ink3} strokeWidth="1.5" strokeLinecap="round"/></svg>
            <div style={{ fontSize: 13, color: ink3 }}>Search contacts or past borrowers</div>
          </div>
        </div>

        {/* Quick: from Contacts */}
        <div style={{ padding: '0 16px 12px' }}>
          <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, marginBottom: 8 }}>Quick add</div>
          <div style={{ display: 'flex', gap: 8, overflow: 'hidden' }}>
            {['MR','TK','LN','EH','AB'].map((c, i) => (
              <div key={i} style={{ width: 52, flexShrink: 0, textAlign: 'center' }}>
                <div style={{ width: 44, height: 44, borderRadius: 22, margin: '0 auto', background: sunken, border: `1px solid ${border}`, display: 'grid', placeItems: 'center', fontSize: 13, fontWeight: 600, color: ink2 }}>{c}</div>
                <div style={{ fontSize: 10, color: ink3, marginTop: 4, fontFamily: 'var(--font-mono)' }}>Contact</div>
              </div>
            ))}
          </div>
        </div>

        {/* List */}
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, padding: '8px 20px' }}>Recent</div>
        <div style={{ flex: 1, overflow: 'auto', background: raised, borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}` }}>
          {people.map((p, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', padding: '12px 16px', gap: 12,
              borderBottom: i < people.length - 1 ? `1px solid ${border}` : '0',
              background: p.active ? accentTint : 'transparent',
            }}>
              <div style={{ width: 36, height: 36, borderRadius: 18, background: p.active ? accent : sunken, color: p.active ? (dark ? '#0B0A04' : '#FAF9F5') : ink2, display: 'grid', placeItems: 'center', fontSize: 12, fontWeight: 600, border: `1px solid ${p.active ? accent : border}` }}>{p.init}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14.5, fontWeight: p.active ? 600 : 500, letterSpacing: '-0.01em' }}>{p.name}</div>
                <div style={{ fontSize: 12, color: ink2, marginTop: 1 }}>{p.sub}</div>
              </div>
              <div style={{ fontSize: 9.5, fontFamily: 'var(--font-mono)', padding: '2px 7px', border: `1px solid ${border}`, borderRadius: 3, color: ink3, letterSpacing: '0.04em' }}>{p.tag}</div>
              {p.active && (
                <svg width="16" height="16" viewBox="0 0 16 16" style={{ marginLeft: 4 }}>
                  <path d="M3 8l3.5 3.5L13 4.5" stroke={accent} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              )}
            </div>
          ))}
        </div>

        {/* Home indicator spacer */}
        <div style={{ height: 34 }}/>
      </div>
    </div>
  );
}

Object.assign(window, { BorrowerPickerScreen });
