// Settings.jsx — editorial settings list

function SettingsScreen({ dark = false }) {
  const bg = dark ? '#17160F' : '#FAF9F5';
  const raised = dark ? '#1E1D15' : '#FFFFFE';
  const sunken = dark ? '#121109' : '#F0EDE4';
  const ink = dark ? '#F2EFE2' : '#17160F';
  const ink2 = dark ? '#B4B0A0' : '#4A4840';
  const ink3 = dark ? '#7C7869' : '#85816F';
  const border = dark ? '#2A281F' : '#E5E1D5';
  const accent = dark ? '#4F9E7D' : '#1F4D3F';
  const accentTint = dark ? '#22322C' : '#DFE6E0';
  const gain = dark ? '#6FB28D' : '#2D6A4E';

  const Row = ({ num, name, value, last }) => (
    <div style={{
      display: 'flex', alignItems: 'center', padding: '13px 16px',
      borderBottom: last ? '0' : `1px solid ${border}`,
    }}>
      <div style={{ width: 24, fontSize: 10.5, fontFamily: 'var(--font-mono)', color: ink3, letterSpacing: '0.05em' }}>{num}</div>
      <div style={{ flex: 1, fontSize: 14.5, fontWeight: 500, letterSpacing: '-0.005em' }}>{name}</div>
      {value && <div style={{ fontSize: 12.5, fontFamily: 'var(--font-mono)', color: ink3, marginRight: 8 }}>{value}</div>}
      <svg width="7" height="12" viewBox="0 0 7 12"><path d="M1 1l5 5-5 5" stroke={ink3} strokeWidth="1.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
    </div>
  );

  const Group = ({ label, children }) => (
    <div style={{ marginTop: 22 }}>
      <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, padding: '0 20px 8px' }}>{label}</div>
      <div style={{ background: raised, borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}` }}>{children}</div>
    </div>
  );

  return (
    <div style={{ background: bg, minHeight: '100%', color: ink, fontFamily: 'var(--font-sans)' }}>
      <div style={{ height: 59 }} />

      {/* Header */}
      <div style={{ padding: '12px 20px 18px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>Settings</div>
        <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: '-0.02em', marginTop: 2 }}>Nicholas Metcalfe</div>
      </div>

      {/* LO profile card — hero */}
      <div style={{ padding: '14px 20px 18px', background: raised, borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}`, display: 'flex', alignItems: 'center', gap: 14 }}>
        <div style={{ width: 58, height: 58, borderRadius: 29, background: sunken, border: `1px solid ${border}`, display: 'grid', placeItems: 'center', fontSize: 20, fontWeight: 600, fontFamily: 'var(--font-serif)', color: ink2 }}>NM</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em' }}>Nicholas Metcalfe</div>
          <div style={{ fontSize: 11.5, color: ink2, fontFamily: 'var(--font-mono)', marginTop: 2 }}>NMLS 284011 · Metcalfe Home Lending</div>
          <div style={{ display: 'flex', gap: 4, marginTop: 6 }}>
            {['CA','OR','WA'].map(s => (
              <span key={s} style={{ fontSize: 9.5, fontFamily: 'var(--font-mono)', padding: '1px 6px', background: accentTint, color: accent, borderRadius: 3, letterSpacing: '0.04em' }}>{s}</span>
            ))}
          </div>
        </div>
        <div style={{ fontSize: 12, color: accent, fontWeight: 500 }}>Edit</div>
      </div>

      {/* Brand */}
      <Group label="Brand · PDF export">
        <Row num="01" name="Accent color" value="Ledger green"/>
        <Row num="02" name="Logo" value="Uploaded · 512×512"/>
        <Row num="03" name="Header layout" value="Editorial"/>
        <Row num="04" name="Signature block" value="Default" last/>
      </Group>

      {/* Compliance */}
      <Group label="Disclaimers · compliance">
        <Row num="01" name="Per-state disclosures" value="3 of 3"/>
        <Row num="02" name="NMLS display"/>
        <Row num="03" name="Equal Housing language" last/>
      </Group>

      {/* Appearance */}
      <div style={{ marginTop: 22 }}>
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, padding: '0 20px 8px' }}>Appearance</div>
        <div style={{ background: raised, borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}` }}>
          {/* Theme seg */}
          <div style={{ padding: '12px 16px', borderBottom: `1px solid ${border}` }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
              <div style={{ fontSize: 14.5, fontWeight: 500 }}>Theme</div>
              <div style={{ fontSize: 11, color: ink3, fontFamily: 'var(--font-mono)' }}>auto</div>
            </div>
            <div style={{ display: 'flex', gap: 4 }}>
              {['Light','Dark','Auto'].map((t, i) => (
                <div key={t} style={{
                  flex: 1, padding: '7px 0', textAlign: 'center',
                  fontSize: 12, fontWeight: i === 2 ? 600 : 500,
                  fontFamily: 'var(--font-mono)',
                  background: i === 2 ? accent : sunken,
                  color: i === 2 ? (dark ? '#0B0A04' : '#FAF9F5') : ink2,
                  border: `1px solid ${i === 2 ? accent : border}`,
                  borderRadius: 6,
                }}>{t}</div>
              ))}
            </div>
          </div>
          {/* Density seg */}
          <div style={{ padding: '12px 16px', borderBottom: `1px solid ${border}` }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
              <div style={{ fontSize: 14.5, fontWeight: 500 }}>Density</div>
              <div style={{ fontSize: 11, color: ink3, fontFamily: 'var(--font-mono)' }}>comfortable</div>
            </div>
            <div style={{ display: 'flex', gap: 4 }}>
              {['Comfortable','Compact'].map((t, i) => (
                <div key={t} style={{
                  flex: 1, padding: '7px 0', textAlign: 'center',
                  fontSize: 12, fontWeight: i === 0 ? 600 : 500,
                  fontFamily: 'var(--font-mono)',
                  background: i === 0 ? accent : sunken,
                  color: i === 0 ? (dark ? '#0B0A04' : '#FAF9F5') : ink2,
                  border: `1px solid ${i === 0 ? accent : border}`,
                  borderRadius: 6,
                }}>{t}</div>
              ))}
            </div>
          </div>
          <Row num="—" name="Text size" value="Default" last/>
        </div>
      </div>

      {/* Language */}
      <Group label="Language · haptics">
        <Row num="01" name="App language" value="English"/>
        <Row num="02" name="Borrower-facing PDF" value="EN · ES"/>
        <div style={{ padding: '13px 16px', display: 'flex', alignItems: 'center', borderBottom: `1px solid ${border}` }}>
          <div style={{ width: 24, fontSize: 10.5, fontFamily: 'var(--font-mono)', color: ink3 }}>03</div>
          <div style={{ flex: 1, fontSize: 14.5, fontWeight: 500 }}>Haptics on calculate</div>
          {/* toggle ON */}
          <div style={{ width: 42, height: 24, borderRadius: 12, background: accent, padding: 2, display: 'flex', alignItems: 'center', justifyContent: 'flex-end', border: `1px solid ${accent}` }}>
            <div style={{ width: 18, height: 18, borderRadius: 9, background: '#FAF9F5' }}/>
          </div>
        </div>
        <div style={{ padding: '13px 16px', display: 'flex', alignItems: 'center' }}>
          <div style={{ width: 24, fontSize: 10.5, fontFamily: 'var(--font-mono)', color: ink3 }}>04</div>
          <div style={{ flex: 1, fontSize: 14.5, fontWeight: 500 }}>Sound on share</div>
          <div style={{ width: 42, height: 24, borderRadius: 12, background: sunken, padding: 2, display: 'flex', alignItems: 'center', border: `1px solid ${border}` }}>
            <div style={{ width: 18, height: 18, borderRadius: 9, background: ink3 }}/>
          </div>
        </div>
      </Group>

      {/* Privacy */}
      <Group label="Privacy · data">
        <div style={{ padding: '13px 16px', display: 'flex', alignItems: 'center', borderBottom: `1px solid ${border}` }}>
          <div style={{ width: 24, fontSize: 10.5, fontFamily: 'var(--font-mono)', color: ink3 }}>01</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14.5, fontWeight: 500 }}>Face ID to open</div>
            <div style={{ fontSize: 11, color: ink3, fontFamily: 'var(--font-mono)', marginTop: 1 }}>required on cold launch</div>
          </div>
          <div style={{ width: 42, height: 24, borderRadius: 12, background: accent, padding: 2, display: 'flex', alignItems: 'center', justifyContent: 'flex-end', border: `1px solid ${accent}` }}>
            <div style={{ width: 18, height: 18, borderRadius: 9, background: '#FAF9F5' }}/>
          </div>
        </div>
        <Row num="02" name="Export backup" value="iCloud"/>
        <Row num="03" name="Erase local data" last/>
      </Group>

      {/* Support */}
      <Group label="Support · about">
        <Row num="01" name="Send feedback"/>
        <Row num="02" name="Help center"/>
        <Row num="03" name="Licenses &amp; legal"/>
        <Row num="04" name="Version" value="1.2.4 · build 812" last/>
      </Group>

      <div style={{ textAlign: 'center', padding: '30px 20px 20px', fontSize: 11, color: ink3, fontStyle: 'italic', fontFamily: 'var(--font-serif)' }}>
        Quotient — made in Portland, OR
      </div>

      <div style={{ height: 60 }} />
    </div>
  );
}

Object.assign(window, { SettingsScreen });
