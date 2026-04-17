// Inputs.jsx — Amortization INPUT state screen (before "compute")
// Shows form idiom: currency, percent, stepper, chips, toggle, accordion.

function InputsScreen({ dark = false }) {
  const bg = dark ? '#17160F' : '#FAF9F5';
  const raised = dark ? '#1E1D15' : '#FFFFFE';
  const sunken = dark ? '#121109' : '#F0EDE4';
  const ink = dark ? '#F2EFE2' : '#17160F';
  const ink2 = dark ? '#B4B0A0' : '#4A4840';
  const ink3 = dark ? '#7C7869' : '#85816F';
  const border = dark ? '#2A281F' : '#E5E1D5';
  const accent = dark ? '#4F9E7D' : '#1F4D3F';
  const accentTint = dark ? '#22322C' : '#DFE6E0';

  const Field = ({ label, value, prefix, suffix, hint, active }) => (
    <div style={{
      padding: '12px 16px',
      borderBottom: `1px solid ${border}`,
      display: 'flex', alignItems: 'center', gap: 12,
      background: active ? accentTint : 'transparent',
    }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 14, color: ink, fontWeight: 500 }}>{label}</div>
        {hint && <div style={{ fontSize: 11, color: ink3, marginTop: 1, fontFamily: 'var(--font-mono)' }}>{hint}</div>}
      </div>
      <div style={{
        display: 'flex', alignItems: 'center',
        fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums',
        fontSize: 15, fontWeight: 500,
        color: value ? ink : ink3,
      }}>
        {prefix && <span style={{ color: ink3, marginRight: 2 }}>{prefix}</span>}
        <span style={{
          borderBottom: active ? `1.5px solid ${accent}` : 'none',
          paddingBottom: active ? 1 : 0,
        }}>{value || '—'}</span>
        {suffix && <span style={{ color: ink3, marginLeft: 2 }}>{suffix}</span>}
      </div>
    </div>
  );

  return (
    <div style={{ background: bg, minHeight: '100%', color: ink, fontFamily: 'var(--font-sans)' }}>
      <div style={{ height: 59 }} />
      <div style={{ display: 'flex', alignItems: 'center', padding: '6px 16px 10px', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', color: accent, fontSize: 16, fontWeight: 500 }}>
          <svg width="10" height="16" viewBox="0 0 10 16" style={{ marginRight: 4 }}>
            <path d="M8 2L2 8l6 6" stroke={accent} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          Home
        </div>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>
          01 · Amortization
        </div>
        <div style={{ width: 28 }} />
      </div>

      <div style={{ padding: '8px 20px 18px' }}>
        <div style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.02em' }}>New scenario</div>
        <div style={{ fontSize: 13, color: ink2, marginTop: 4 }}>
          Enter loan terms and property details. Results update live.
        </div>

        {/* Borrower chip */}
        <div style={{
          marginTop: 14, display: 'inline-flex', alignItems: 'center', gap: 8,
          padding: '6px 12px 6px 8px',
          background: raised, border: `1px solid ${border}`, borderRadius: 999,
          fontSize: 12.5,
        }}>
          <div style={{ width: 20, height: 20, borderRadius: 10, background: sunken, display: 'grid', placeItems: 'center', fontSize: 9, fontWeight: 600, color: ink2 }}>JS</div>
          John Smith
          <svg width="10" height="10" viewBox="0 0 10 10" style={{ marginLeft: 2 }}>
            <path d="M1 3l4 4 4-4" stroke={ink3} strokeWidth="1.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
      </div>

      {/* LOAN section */}
      <div>
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, padding: '0 20px 8px' }}>
          Loan
        </div>
        <div style={{ background: raised, borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}` }}>
          <Field label="Loan amount" value="548,000" prefix="$"/>
          <Field label="Interest rate" value="6.750" suffix="%" active />
          <div style={{ padding: '12px 16px', borderBottom: `1px solid ${border}` }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ fontSize: 14, color: ink, fontWeight: 500 }}>Term</div>
              <div style={{ fontSize: 15, fontFamily: 'var(--font-mono)', fontWeight: 500 }}>30 yr</div>
            </div>
            <div style={{ display: 'flex', gap: 4, marginTop: 10 }}>
              {['10','15','20','25','30','40'].map((t, i) => (
                <div key={t} style={{
                  flex: 1, padding: '6px 0', textAlign: 'center',
                  fontSize: 12, fontWeight: t === '30' ? 600 : 500,
                  fontFamily: 'var(--font-mono)',
                  background: t === '30' ? accent : sunken,
                  color: t === '30' ? (dark ? '#0B0A04' : '#FAF9F5') : ink2,
                  border: `1px solid ${t === '30' ? accent : border}`,
                  borderRadius: 6,
                }}>{t}</div>
              ))}
            </div>
          </div>
          <Field label="Start date" value="Apr 2026" />
        </div>
      </div>

      {/* PROPERTY section */}
      <div style={{ marginTop: 22 }}>
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, padding: '0 20px 8px' }}>
          Property
        </div>
        <div style={{ background: raised, borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}` }}>
          <Field label="Annual taxes" value="6,500" prefix="$" hint="1.19% of value"/>
          <Field label="Insurance" value="1,620" prefix="$" hint="annual"/>
          <Field label="HOA" value="0" prefix="$" hint="monthly (optional)"/>
          <div style={{ padding: '14px 16px', display: 'flex', alignItems: 'center' }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, color: ink, fontWeight: 500 }}>Include PMI</div>
              <div style={{ fontSize: 11, color: ink3, marginTop: 1, fontFamily: 'var(--font-mono)' }}>auto · LTV 78%</div>
            </div>
            <div style={{
              width: 42, height: 24, borderRadius: 12, background: sunken,
              padding: 2, display: 'flex', alignItems: 'center',
              border: `1px solid ${border}`,
            }}>
              <div style={{ width: 18, height: 18, borderRadius: 9, background: ink3 }} />
            </div>
          </div>
        </div>
      </div>

      {/* Advanced accordion */}
      <div style={{ marginTop: 22, padding: '0 20px' }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '14px 16px',
          background: raised, border: `1px solid ${border}`, borderRadius: 10,
        }}>
          <div style={{ fontSize: 14, fontWeight: 500 }}>Advanced</div>
          <div style={{ fontSize: 12, color: ink3, fontFamily: 'var(--font-mono)' }}>
            Extra principal · Recast · Biweekly
          </div>
          <svg width="10" height="10" viewBox="0 0 10 10" style={{ marginLeft: 8 }}>
            <path d="M1 3l4 4 4-4" stroke={ink3} strokeWidth="1.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
      </div>

      {/* Compute button */}
      <div style={{ padding: '26px 20px 30px' }}>
        <div style={{
          padding: '14px 0', textAlign: 'center',
          background: accent, color: dark ? '#0B0A04' : '#FAF9F5',
          borderRadius: 12, fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em',
        }}>
          Compute amortization
        </div>
        <div style={{ fontSize: 11, color: ink3, textAlign: 'center', marginTop: 10, fontStyle: 'italic' }}>
          Results live-update as you adjust inputs.
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { InputsScreen });
