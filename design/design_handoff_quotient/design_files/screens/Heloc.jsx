// Heloc.jsx — HELOC vs Refinance (Calc 05)
// Blended-rate explanation + stress paths.

function HelocScreen({ dark = false }) {
  const bg = dark ? '#17160F' : '#FAF9F5';
  const raised = dark ? '#1E1D15' : '#FFFFFE';
  const ink = dark ? '#F2EFE2' : '#17160F';
  const ink2 = dark ? '#B4B0A0' : '#4A4840';
  const ink3 = dark ? '#7C7869' : '#85816F';
  const border = dark ? '#2A281F' : '#E5E1D5';
  const accent = dark ? '#4F9E7D' : '#1F4D3F';
  const gain = dark ? '#6FB28D' : '#2D6A4E';
  const loss = dark ? '#C47566' : '#8A3D34';
  const grid = dark ? '#26241C' : '#ECE8DC';
  const accentTint = dark ? '#22322C' : '#DFE6E0';

  // Stress paths
  const w = 346, h = 170, pad = { t: 10, r: 10, b: 22, l: 42 };
  const x = (m) => pad.l + (m / 120) * (w - pad.l - pad.r);
  // HELOC blended payment: varies with rate scenario
  const path = (fn) => {
    const pts = [];
    for (let m = 0; m <= 120; m += 3) pts.push({ m, v: fn(m) });
    const maxV = 4800, minV = 2400;
    const y = (v) => pad.t + (1 - (v - minV) / (maxV - minV)) * (h - pad.t - pad.b);
    return pts.map((p, i) => `${i ? 'L' : 'M'}${x(p.m).toFixed(1)} ${y(p.v).toFixed(1)}`).join(' ');
  };
  const y = (v) => pad.t + (1 - (v - 2400) / (4800 - 2400)) * (h - pad.t - pad.b);

  // Refi flat line
  const refiLine = path(() => 3420);
  // HELOC paths
  const base =  path(m => 3150 + Math.min(m,12)*12 + Math.max(0,m-36)*1.5);
  const up =    path(m => 3150 + Math.min(m,12)*12 + Math.max(0,m-12)*6 + Math.max(0,m-24)*4);
  const down =  path(m => 3150 + Math.min(m,12)*12 - Math.max(0,m-12)*2);

  return (
    <div style={{ background: bg, minHeight: '100%', color: ink, fontFamily: 'var(--font-sans)' }}>
      <div style={{ height: 59 }} />
      <div style={{ display: 'flex', alignItems: 'center', padding: '6px 16px 10px', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', color: accent, fontSize: 16, fontWeight: 500 }}>
          <svg width="10" height="16" viewBox="0 0 10 16" style={{ marginRight: 4 }}><path d="M8 2L2 8l6 6" stroke={accent} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
          Home
        </div>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>05 · HELOC vs Refi</div>
        <div style={{ width: 28 }} />
      </div>

      {/* Borrower */}
      <div style={{ padding: '8px 20px 14px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, marginBottom: 4 }}>Borrower</div>
        <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.015em' }}>Dana &amp; Michael Kim</div>
        <div style={{ fontSize: 12.5, color: ink2, marginTop: 3, fontFamily: 'var(--font-mono)' }}>1st: $318K @ 3.125% · need $80K cash</div>
      </div>

      {/* Blended rate hero */}
      <div style={{ padding: '16px 20px', background: raised, borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}` }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>Blended rate · HELOC path</div>
        <div style={{ display: 'flex', alignItems: 'baseline', marginTop: 6, gap: 2 }}>
          <span style={{ fontSize: 46, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, letterSpacing: '-0.02em', lineHeight: 1 }}>4.85</span>
          <span style={{ fontSize: 14, color: ink3, fontFamily: 'var(--font-mono)' }}>%</span>
          <span style={{ fontSize: 12, color: ink3, fontFamily: 'var(--font-mono)', marginLeft: 10 }}>vs refi 6.125%</span>
        </div>
        {/* composition bar */}
        <div style={{ marginTop: 14, display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ flex: 1, height: 10, borderRadius: 2, overflow: 'hidden', background: grid, display: 'flex' }}>
            <div style={{ width: '80%', background: accent }}/>
            <div style={{ width: '20%', background: '#264B6A' }}/>
          </div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontSize: 10, color: ink3, fontFamily: 'var(--font-mono)' }}>
          <span><span style={{ display: 'inline-block', width: 7, height: 7, background: accent, marginRight: 4, borderRadius: 1 }}/>1st @ 3.125% · $318K</span>
          <span><span style={{ display: 'inline-block', width: 7, height: 7, background: '#264B6A', marginRight: 4, borderRadius: 1 }}/>HELOC @ 8.75% · $80K</span>
        </div>
      </div>

      {/* Stress paths chart */}
      <div style={{ padding: '22px 20px 0' }}>
        <div style={{ fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em', marginBottom: 2 }}>Monthly payment · 10-yr stress</div>
        <div style={{ fontSize: 12, color: ink2, marginBottom: 10 }}>HELOC flexes with prime. Refi is flat but higher today.</div>
        <svg width={w} height={h}>
          {/* grid */}
          {[2800, 3200, 3600, 4000, 4400].map(v => (
            <g key={v}>
              <line x1={pad.l} x2={w - pad.r} y1={y(v)} y2={y(v)} stroke={grid} strokeWidth="0.5"/>
              <text x={pad.l - 4} y={y(v) + 3} fontSize="9" fill={ink3} textAnchor="end" fontFamily="var(--font-mono)">${(v/1000).toFixed(1)}k</text>
            </g>
          ))}
          {/* refi flat */}
          <path d={refiLine} fill="none" stroke="#264B6A" strokeWidth="1.5" strokeDasharray="4 3"/>
          {/* HELOC up (stress) */}
          <path d={up} fill="none" stroke={loss} strokeWidth="1.25" opacity="0.7"/>
          {/* HELOC down */}
          <path d={down} fill="none" stroke={gain} strokeWidth="1.25" opacity="0.7"/>
          {/* HELOC base (bold) */}
          <path d={base} fill="none" stroke={accent} strokeWidth="1.8"/>
          {/* x axis */}
          {[0, 24, 48, 72, 96, 120].map(m => (
            <text key={m} x={x(m)} y={h - 6} fontSize="9.5" fill={ink3} textAnchor={m === 0 ? 'start' : m === 120 ? 'end' : 'middle'} fontFamily="var(--font-mono)">
              {m === 0 ? 'now' : `${m/12}y`}
            </text>
          ))}
        </svg>
        <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap', fontSize: 10.5, fontFamily: 'var(--font-mono)', color: ink2, marginTop: 4 }}>
          <span><span style={{ display: 'inline-block', width: 14, height: 2, background: accent, verticalAlign: 'middle', marginRight: 5 }}/>HELOC base</span>
          <span><span style={{ display: 'inline-block', width: 14, height: 2, background: loss, verticalAlign: 'middle', marginRight: 5 }}/>+2pt shock</span>
          <span><span style={{ display: 'inline-block', width: 14, height: 2, background: gain, verticalAlign: 'middle', marginRight: 5 }}/>−1pt relief</span>
          <span><span style={{ display: 'inline-block', width: 14, height: 2, background: '#264B6A', borderTop: '1px dashed', verticalAlign: 'middle', marginRight: 5 }}/>Refi flat</span>
        </div>
      </div>

      {/* Verdict */}
      <div style={{ padding: '22px 20px 24px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, marginBottom: 8 }}>Verdict</div>
        <div style={{ background: raised, border: `1px solid ${border}`, padding: '14px 16px', borderRadius: 10, fontSize: 13.5, lineHeight: 1.55 }}>
          Keep the 3.125% 1st mortgage and take an $80K HELOC. Blended rate is
          <b style={{ color: accent }}> 4.85%</b> vs <b>6.125%</b> on a refi. Break-even on the
          stress case (+2pt) is month 58 — still favorable if they keep the home ≥ 5 yr.
        </div>
      </div>

      <div style={{ height: 120 }} />

      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '10px 16px 30px',
        background: dark ? 'rgba(23,22,15,0.88)' : 'rgba(250,249,245,0.9)',
        backdropFilter: 'blur(20px) saturate(180%)',
        borderTop: `1px solid ${border}`, display: 'flex', gap: 8,
      }}>
        <div style={{ flex: 1, padding: '12px 0', textAlign: 'center', border: `1px solid ${border}`, borderRadius: 10, fontSize: 14, fontWeight: 500, background: raised }}>Edit paths</div>
        <div style={{ flex: 1.2, padding: '12px 0', textAlign: 'center', background: accent, color: dark ? '#0B0A04' : '#FAF9F5', borderRadius: 10, fontSize: 14, fontWeight: 600 }}>Share as PDF</div>
      </div>
    </div>
  );
}

Object.assign(window, { HelocScreen });
