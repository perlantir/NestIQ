// Income.jsx — Income qualification calculator (Calc 02)
// Editorial: big max-loan hero, DTI dials, income/debts breakdown.

function IncomeScreen({ dark = false }) {
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
  const warn = dark ? '#D6A758' : '#8C6A1E';
  const grid = dark ? '#26241C' : '#ECE8DC';

  // DTI dial: front 28%, back 36% agency limits; applicant 24 / 38
  const Dial = ({ label, value, limit, unit = '%', size = 98, over }) => {
    const r = size / 2 - 6, cx = size / 2, cy = size / 2;
    const circ = 2 * Math.PI * r;
    const frac = Math.min(value / (limit * 1.4), 1);
    const stroke = over ? warn : accent;
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
        <svg width={size} height={size}>
          <circle cx={cx} cy={cy} r={r} fill="none" stroke={grid} strokeWidth="6"/>
          {/* limit tick */}
          {(() => { const a = -Math.PI/2 + (limit / (limit * 1.4)) * Math.PI * 2; return (
            <line x1={cx + (r-6)*Math.cos(a)} y1={cy + (r-6)*Math.sin(a)} x2={cx + (r+6)*Math.cos(a)} y2={cy + (r+6)*Math.sin(a)} stroke={ink3} strokeWidth="1.25"/>
          ); })()}
          <circle cx={cx} cy={cy} r={r} fill="none" stroke={stroke} strokeWidth="6"
            strokeLinecap="round" transform={`rotate(-90 ${cx} ${cy})`}
            strokeDasharray={`${circ * frac} ${circ}`}/>
          <text x={cx} y={cy - 2} textAnchor="middle" fontSize="20" fontFamily="var(--font-mono)" fontWeight="500" fill={ink}
            style={{ fontVariantNumeric: 'tabular-nums' }} letterSpacing="-0.01em">{value.toFixed(1)}</text>
          <text x={cx} y={cy + 14} textAnchor="middle" fontSize="9.5" fill={ink3} fontFamily="var(--font-mono)">{unit} · lim {limit}</text>
        </svg>
        <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: ink3 }}>{label}</div>
      </div>
    );
  };

  const Row = ({ k, v, sub, bold }) => (
    <div style={{ display: 'flex', alignItems: 'center', padding: '10px 16px', borderBottom: `1px solid ${border}` }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13.5, color: ink, fontWeight: bold ? 600 : 500 }}>{k}</div>
        {sub && <div style={{ fontSize: 10.5, color: ink3, fontFamily: 'var(--font-mono)', marginTop: 1 }}>{sub}</div>}
      </div>
      <div style={{ fontSize: 14, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: bold ? 600 : 500 }}>{v}</div>
    </div>
  );

  return (
    <div style={{ background: bg, minHeight: '100%', color: ink, fontFamily: 'var(--font-sans)' }}>
      <div style={{ height: 59 }} />
      {/* nav */}
      <div style={{ display: 'flex', alignItems: 'center', padding: '6px 16px 10px', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', color: accent, fontSize: 16, fontWeight: 500 }}>
          <svg width="10" height="16" viewBox="0 0 10 16" style={{ marginRight: 4 }}>
            <path d="M8 2L2 8l6 6" stroke={accent} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          Home
        </div>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>02 · Income qualification</div>
        <div style={{ width: 28 }} />
      </div>

      {/* Borrower */}
      <div style={{ padding: '8px 20px 14px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, marginBottom: 4 }}>Borrower</div>
        <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.015em' }}>Okoye / Owens</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4 }}>
          <span style={{ fontSize: 10.5, fontFamily: 'var(--font-mono)', padding: '1px 6px', background: accentTint, color: accent, borderRadius: 3, letterSpacing: '0.04em' }}>CONV · 740</span>
          <span style={{ fontSize: 12.5, color: ink2, fontFamily: 'var(--font-mono)' }}>Dual income · W-2</span>
        </div>
      </div>

      {/* Hero: max loan */}
      <div style={{ padding: '16px 20px 18px', background: raised, borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}` }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>Max loan · qualifying</div>
        <div style={{ display: 'flex', alignItems: 'baseline', marginTop: 6, gap: 2 }}>
          <span style={{ fontSize: 14, color: ink3, fontFamily: 'var(--font-mono)' }}>$</span>
          <span style={{ fontSize: 46, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, letterSpacing: '-0.02em', lineHeight: 1 }}>612,400</span>
        </div>
        <div style={{ fontSize: 12, color: ink3, fontFamily: 'var(--font-mono)', marginTop: 6 }}>
          at 6.750% · 30-yr · 20% down · $3,200/mo tax &amp; ins
        </div>
        {/* KPI row */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', marginTop: 14 }}>
          {[
            { l: 'Max PITI', v: '$4,284' },
            { l: 'Max purchase', v: '$765,500' },
            { l: 'Reserves', v: '5.2 mo', c: gain },
          ].map((k, i) => (
            <div key={i} style={{ paddingLeft: i === 0 ? 0 : 10, borderLeft: i === 0 ? '0' : `1px solid ${border}` }}>
              <div style={{ fontSize: 9.5, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: ink3 }}>{k.l}</div>
              <div style={{ fontSize: 15, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, marginTop: 3, color: k.c || ink }}>{k.v}</div>
            </div>
          ))}
        </div>
      </div>

      {/* DTI dials */}
      <div style={{ padding: '20px 20px 6px' }}>
        <div style={{ fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em', marginBottom: 2 }}>Debt-to-income</div>
        <div style={{ fontSize: 12, color: ink2, marginBottom: 14 }}>Front = housing only. Back = housing + monthly debts.</div>
        <div style={{ display: 'flex', justifyContent: 'space-around', padding: '4px 0' }}>
          <Dial label="Front-end" value={24.2} limit={28}/>
          <Dial label="Back-end" value={38.1} limit={43} over/>
        </div>
        <div style={{ marginTop: 10, padding: '10px 12px', background: raised, border: `1px solid ${border}`, borderRadius: 8, display: 'flex', alignItems: 'start', gap: 10 }}>
          <div style={{ width: 7, height: 7, borderRadius: 1, background: warn, marginTop: 6 }}/>
          <div style={{ flex: 1, fontSize: 12, color: ink2, lineHeight: 1.45 }}>
            Back-end sits <b style={{ color: ink }}>2.1 pts</b> over the 36% comfort zone but within agency 45% limit. Pay down the $482 auto lease to recover headroom.
          </div>
        </div>
      </div>

      {/* Income breakdown */}
      <div style={{ marginTop: 22 }}>
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, padding: '0 20px 8px' }}>Qualifying income · monthly</div>
        <div style={{ background: raised, borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}` }}>
          <Row k="Borrower 1 · W-2" v="$8,750" sub="base · 24mo avg"/>
          <Row k="Borrower 2 · W-2" v="$6,320" sub="base + bonus"/>
          <Row k="Rental · Schedule E" v="$980" sub="75% of $1,307"/>
          <Row k="Total qualifying" v="$16,050" bold/>
        </div>
      </div>

      {/* Debts breakdown */}
      <div style={{ marginTop: 22 }}>
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, padding: '0 20px 8px' }}>Monthly debts</div>
        <div style={{ background: raised, borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}` }}>
          <Row k="Auto · lease" v="$482"/>
          <Row k="Student loans · IBR" v="$215"/>
          <Row k="Minimum CC" v="$130"/>
          <Row k="Total" v="$827" bold/>
        </div>
      </div>

      <div style={{ height: 120 }} />

      {/* Bottom dock */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '10px 16px 30px',
        background: dark ? 'rgba(23,22,15,0.88)' : 'rgba(250,249,245,0.9)',
        backdropFilter: 'blur(20px) saturate(180%)',
        borderTop: `1px solid ${border}`,
        display: 'flex', gap: 8,
      }}>
        <div style={{ flex: 1, padding: '12px 0', textAlign: 'center', border: `1px solid ${border}`, borderRadius: 10, fontSize: 14, fontWeight: 500, background: raised }}>Adjust inputs</div>
        <div style={{ flex: 1.2, padding: '12px 0', textAlign: 'center', background: accent, color: dark ? '#0B0A04' : '#FAF9F5', borderRadius: 10, fontSize: 14, fontWeight: 600 }}>Share pre-qual</div>
      </div>
    </div>
  );
}

Object.assign(window, { IncomeScreen });
