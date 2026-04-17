// Refinance.jsx — Refinance comparison screen

function RefinanceScreen({ dark = false }) {
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
  const loss = dark ? '#C47566' : '#8A3D34';
  const grid = dark ? '#26241C' : '#ECE8DC';

  // Break-even chart: cumulative savings vs closing costs
  const w = 362, h = 190, pad = { t: 10, r: 40, b: 22, l: 12 };
  // net savings after month m = monthlySavings*m − closingCosts
  const monthlySavings = 412;
  const closingCosts = 9800;
  const be = Math.ceil(closingCosts / monthlySavings); // ~24

  const pathFor = (ms, cc) => {
    const pts = [];
    for (let m = 0; m <= 60; m++) pts.push({ m, v: ms * m - cc });
    const maxV = 18000, minV = -12000;
    const x = (m) => pad.l + (m / 60) * (w - pad.l - pad.r);
    const y = (v) => pad.t + (1 - (v - minV) / (maxV - minV)) * (h - pad.t - pad.b);
    return { d: pts.map((p, i) => `${i ? 'L' : 'M'}${x(p.m).toFixed(1)} ${y(p.v).toFixed(1)}`).join(' '), x, y, pts };
  };
  const A = pathFor(412, 9800);
  const B = pathFor(338, 5200);
  const C = pathFor(496, 14800);

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
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>
          03 · Refinance
        </div>
        <div style={{ width: 28 }} />
      </div>

      {/* borrower */}
      <div style={{ padding: '8px 20px 16px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, marginBottom: 4 }}>
          Borrower
        </div>
        <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.015em', lineHeight: 1.2 }}>
          Priya Venkatesan
        </div>
        <div style={{ fontSize: 12.5, color: ink2, marginTop: 3, fontFamily: 'var(--font-mono)' }}>
          Current: $412,300 · 7.375% · 28 yr remaining
        </div>
      </div>

      {/* Option tabs */}
      <div style={{
        display: 'flex', padding: '0 20px', gap: 6,
        borderBottom: `1px solid ${border}`,
      }}>
        {[
          { n: 'Current', on: false, c: ink3 },
          { n: 'Option A', on: true,  c: accent,  tag: 'winner' },
          { n: 'Option B', on: false, c: '#264B6A' },
          { n: 'Option C', on: false, c: '#6A3F5A' },
        ].map((t, i) => (
          <div key={i} style={{
            padding: '8px 10px',
            fontSize: 12, fontWeight: t.on ? 600 : 500,
            color: t.on ? ink : ink3,
            borderBottom: t.on ? `2px solid ${accent}` : '2px solid transparent',
            display: 'flex', alignItems: 'center', gap: 6,
            marginBottom: -1,
          }}>
            <span style={{ width: 7, height: 7, background: t.c, borderRadius: 1 }} />
            {t.n}
            {t.tag && (
              <span style={{
                fontSize: 9, fontFamily: 'var(--font-mono)', letterSpacing: '0.06em',
                textTransform: 'uppercase', padding: '1px 4px',
                background: accentTint, color: accent, borderRadius: 2,
              }}>best</span>
            )}
          </div>
        ))}
      </div>

      {/* Winner summary */}
      <div style={{ padding: '18px 20px 18px', background: raised, borderBottom: `1px solid ${border}` }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>
          Option A · 6.125% · 30 yr · $9,800 closing
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', marginTop: 6, gap: 6 }}>
          <div style={{ fontSize: 13, color: ink3, fontFamily: 'var(--font-mono)' }}>Save</div>
          <div style={{ fontSize: 13, color: ink3, fontFamily: 'var(--font-mono)' }}>$</div>
          <div style={{ fontSize: 40, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, letterSpacing: '-0.02em', lineHeight: 1 }}>412</div>
          <div style={{ fontSize: 13, color: ink3, fontFamily: 'var(--font-mono)' }}>/mo</div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', marginTop: 14, gap: 0 }}>
          {[
            { l: 'Break-even', v: `${be} mo`, sub: 'Mar 2028' },
            { l: 'Lifetime Δ', v: '+$68.4K', sub: 'saved', c: gain },
            { l: 'NPV @ 5%', v: '+$42.1K', sub: 'discounted', c: gain },
          ].map((k, i) => (
            <div key={i} style={{
              paddingLeft: i === 0 ? 0 : 10, paddingRight: i === 2 ? 0 : 10,
              borderLeft: i === 0 ? '0' : `1px solid ${border}`,
            }}>
              <div style={{ fontSize: 9.5, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: ink3 }}>{k.l}</div>
              <div style={{ fontSize: 16, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, marginTop: 3, letterSpacing: '-0.01em', color: k.c || ink }}>{k.v}</div>
              <div style={{ fontSize: 10.5, color: ink3, fontFamily: 'var(--font-mono)', marginTop: 1 }}>{k.sub}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Break-even chart */}
      <div style={{ padding: '22px 20px 4px' }}>
        <div style={{ fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em', marginBottom: 2 }}>
          Cumulative savings
        </div>
        <div style={{ fontSize: 12, color: ink2, marginBottom: 10 }}>
          Net of closing costs. Intersects zero at break-even.
        </div>
        <svg width={w} height={h}>
          {/* Zero line */}
          {(() => {
            const zY = A.y(0);
            return <line x1={pad.l} x2={w - pad.r} y1={zY} y2={zY} stroke={ink3} strokeWidth="1" strokeDasharray="3 3" opacity="0.6"/>;
          })()}
          {/* horizontal faint grid */}
          {[-12, -6, 6, 12].map((k) => (
            <line key={k} x1={pad.l} x2={w - pad.r} y1={A.y(k * 1000)} y2={A.y(k * 1000)} stroke={grid} strokeWidth="0.5"/>
          ))}
          {/* Option C (losing) */}
          <path d={C.d} fill="none" stroke="#6A3F5A" strokeWidth="1.25" opacity="0.45"/>
          {/* Option B */}
          <path d={B.d} fill="none" stroke="#264B6A" strokeWidth="1.25" opacity="0.55"/>
          {/* Option A (bold) */}
          <path d={A.d} fill="none" stroke={accent} strokeWidth="1.8" strokeLinejoin="round"/>
          {/* Break-even marker */}
          <line x1={A.x(be)} x2={A.x(be)} y1={pad.t} y2={h - pad.b} stroke={accent} strokeWidth="1" strokeDasharray="2 2" opacity="0.6"/>
          <circle cx={A.x(be)} cy={A.y(0)} r="3.5" fill={bg} stroke={accent} strokeWidth="1.75"/>
          <text x={A.x(be) + 5} y={A.y(0) - 6} fontSize="10" fontFamily="var(--font-mono)" fill={accent} fontWeight="600">
            {be} mo
          </text>
          {/* x axis */}
          {[0, 12, 24, 36, 48, 60].map((m) => (
            <text key={m} x={A.x(m)} y={h - 6}
              fontSize="9.5" fill={ink3}
              textAnchor={m === 0 ? 'start' : m === 60 ? 'end' : 'middle'}
              fontFamily="var(--font-mono)">{m === 0 ? 'now' : `${m}m`}</text>
          ))}
          {/* y axis labels */}
          {[-10, 0, 10].map((v) => (
            <text key={v} x={w - pad.r + 4} y={A.y(v * 1000) + 3}
              fontSize="9.5" fill={ink3} textAnchor="start"
              fontFamily="var(--font-mono)">{v === 0 ? '0' : `${v > 0 ? '+' : ''}${v}k`}</text>
          ))}
          {/* end labels */}
          <text x={A.x(60) - 4} y={A.y(A.pts[60].v) - 5} fontSize="10" fill={accent} fontWeight="600" textAnchor="end" fontFamily="var(--font-mono)">A</text>
        </svg>
      </div>

      {/* Comparison table */}
      <div style={{ padding: '18px 20px 4px' }}>
        <div style={{ fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em', marginBottom: 10 }}>
          Side by side
        </div>
        <div style={{ borderTop: `1px solid ${border}` }}>
          {[
            { k: 'Rate',        cur: '7.375%', a: '6.125%', b: '6.500%', c: '5.875%' },
            { k: 'Term',        cur: '28 yr',  a: '30 yr',  b: '25 yr',  c: '30 yr'  },
            { k: 'Points',      cur: '—',      a: '0.500',  b: '0.000',  c: '1.500'  },
            { k: 'Closing',     cur: '—',      a: '$9,800', b: '$5,200', c: '$14,800'},
            { k: 'Payment',     cur: '$2,962', a: '$2,550', b: '$2,624', c: '$2,466', winner: 'c' },
            { k: 'Break-even',  cur: '—',      a: '24 mo',  b: '16 mo',  c: '30 mo', winner: 'b' },
            { k: 'Lifetime Δ',  cur: '—',      a: '+68.4K', b: '+41.2K', c: '+91.6K', winner: 'c' },
          ].map((r, i) => {
            const cols = [
              { v: r.cur, color: ink3 },
              { v: r.a, color: r.winner === 'a' ? gain : ink, winner: r.winner === 'a' },
              { v: r.b, color: r.winner === 'b' ? gain : ink, winner: r.winner === 'b' },
              { v: r.c, color: r.winner === 'c' ? gain : ink, winner: r.winner === 'c' },
            ];
            return (
              <div key={i} style={{
                display: 'grid', gridTemplateColumns: '72px 1fr 1fr 1fr 1fr',
                padding: '9px 0',
                borderBottom: `1px solid ${border}`,
                alignItems: 'center',
              }}>
                <div style={{ fontSize: 11, fontWeight: 500, color: ink2 }}>{r.k}</div>
                {cols.map((col, j) => (
                  <div key={j} style={{
                    textAlign: 'right',
                    fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums',
                    fontSize: 12, fontWeight: col.winner ? 600 : 500,
                    color: col.color,
                  }}>
                    {col.v}
                  </div>
                ))}
              </div>
            );
          })}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '72px 1fr 1fr 1fr 1fr', marginTop: 6 }}>
          <div/>
          <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: ink3, textAlign: 'right' }}>Cur</div>
          <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: accent, textAlign: 'right' }}>A</div>
          <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: '#264B6A', textAlign: 'right' }}>B</div>
          <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: '#6A3F5A', textAlign: 'right' }}>C</div>
        </div>
      </div>

      {/* AI narrative excerpt */}
      <div style={{ padding: '22px 20px 24px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, marginBottom: 8 }}>
          Narrative
        </div>
        <div style={{
          background: raised, border: `1px solid ${border}`,
          padding: '14px 16px', borderRadius: 10,
          fontSize: 13.5, lineHeight: 1.55, color: ink, letterSpacing: '-0.005em',
        }}>
          Option A is the most durable choice for Priya. She breaks even on closing
          costs in <b style={{ color: accent }}>24 months</b> and saves ~<b>$68K</b> over the loan's life.
          Option B pays off faster but saves less; Option C has the lowest monthly
          payment but requires 30 months to recoup the higher points.
          <div style={{ marginTop: 8, fontSize: 11, color: ink3, fontStyle: 'italic' }}>
            Generated Apr 17, 2026 · edit in Share preview.
          </div>
        </div>
      </div>

      <div style={{ height: 100 }} />

      {/* Bottom dock */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '10px 16px 30px',
        background: dark ? 'rgba(23,22,15,0.88)' : 'rgba(250,249,245,0.9)',
        backdropFilter: 'blur(20px) saturate(180%)',
        borderTop: `1px solid ${border}`,
        display: 'flex', gap: 8,
      }}>
        <div style={{ flex: 1, padding: '12px 0', textAlign: 'center', border: `1px solid ${border}`, borderRadius: 10, fontSize: 14, fontWeight: 500, background: raised }}>Stress test</div>
        <div style={{ flex: 1.2, padding: '12px 0', textAlign: 'center', background: accent, color: dark ? '#0B0A04' : '#FAF9F5', borderRadius: 10, fontSize: 14, fontWeight: 600 }}>Share as PDF</div>
      </div>
    </div>
  );
}

Object.assign(window, { RefinanceScreen });
