// Amortization.jsx — iPhone amortization result state
// Editorial layout: KPI strip, balance-over-time chart, PITI breakdown, schedule table.

function AmortizationScreen({ dark = false }) {
  const bg = dark ? '#17160F' : '#FAF9F5';
  const raised = dark ? '#1E1D15' : '#FFFFFE';
  const sunken = dark ? '#121109' : '#F0EDE4';
  const ink = dark ? '#F2EFE2' : '#17160F';
  const ink2 = dark ? '#B4B0A0' : '#4A4840';
  const ink3 = dark ? '#7C7869' : '#85816F';
  const border = dark ? '#2A281F' : '#E5E1D5';
  const accent = dark ? '#4F9E7D' : '#1F4D3F';
  const accentTint = dark ? '#22322C' : '#DFE6E0';
  const grid = dark ? '#26241C' : '#ECE8DC';
  const gain = dark ? '#6FB28D' : '#2D6A4E';

  // Balance-over-time chart geometry
  const w = 362, h = 170, pad = { t: 10, r: 12, b: 22, l: 12 };
  // Simple amortizing balance curve: start 548000, 30yr, 6.75%
  const points = [];
  const P = 548000, r = 0.0675 / 12, n = 360;
  const M = P * r / (1 - Math.pow(1 + r, -n));
  let bal = P;
  for (let i = 0; i <= 30; i++) {
    points.push({ yr: i, bal });
    for (let k = 0; k < 12 && bal > 0; k++) {
      const int = bal * r; bal = bal - (M - int);
    }
    if (bal < 0) bal = 0;
  }
  const maxBal = points[0].bal;
  const x = (yr) => pad.l + (yr / 30) * (w - pad.l - pad.r);
  const y = (b) => pad.t + (1 - b / maxBal) * (h - pad.t - pad.b);
  const path = points.map((p, i) => `${i ? 'L' : 'M'}${x(p.yr).toFixed(1)} ${y(p.bal).toFixed(1)}`).join(' ');
  const areaPath = path + ` L${x(30)} ${h - pad.b} L${x(0)} ${h - pad.b} Z`;

  // PITI composition (monthly)
  const principal = 447;
  const interest  = 3083;
  const taxes     = 542;
  const insurance = 135;
  const pmi       = 0;
  const hoa       = 0;
  const total = principal + interest + taxes + insurance + pmi + hoa;

  // Schedule rows
  const rows = [
    { n: '001', pay: '3,553', p: '447',   i: '3,083', bal: '547,553' },
    { n: '012', pay: '3,553', p: '477',   i: '3,053', bal: '543,023' },
    { n: '060', pay: '3,553', p: '620',   i: '2,910', bal: '517,146' },
    { n: '120', pay: '3,553', p: '864',   i: '2,666', bal: '473,900' },
    { n: '180', pay: '3,553', p: '1,206', i: '2,324', bal: '412,606' },
    { n: '240', pay: '3,553', p: '1,683', i: '1,847', bal: '328,083' },
    { n: '300', pay: '3,553', p: '2,347', i: '1,183', bal: '210,199' },
    { n: '360', pay: '3,553', p: '3,533', i: '   20', bal: '      0' },
  ];

  return (
    <div style={{ background: bg, minHeight: '100%', color: ink, fontFamily: 'var(--font-sans)' }}>
      {/* Status bar + nav */}
      <div style={{ height: 59 }} />
      <div style={{
        display: 'flex', alignItems: 'center', padding: '6px 16px 10px',
        justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', color: accent, fontSize: 16, fontWeight: 500 }}>
          <svg width="10" height="16" viewBox="0 0 10 16" style={{ marginRight: 4 }}>
            <path d="M8 2L2 8l6 6" stroke={accent} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          Home
        </div>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>
          01 · Amortization
        </div>
        <div style={{ width: 28, height: 28, borderRadius: 14, border: `1px solid ${border}`, display: 'grid', placeItems: 'center' }}>
          <svg width="14" height="14" viewBox="0 0 20 20">
            <path d="M10 3v10M5 8l5-5 5 5M4 15v2a1 1 0 001 1h10a1 1 0 001-1v-2" stroke={ink2} strokeWidth="1.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
      </div>

      {/* Borrower + scenario header */}
      <div style={{ padding: '8px 20px 16px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, marginBottom: 4 }}>
          Borrower
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.015em', lineHeight: 1.2 }}>
            John &amp; Maya Smith
          </div>
          <div style={{
            fontSize: 10.5, fontFamily: 'var(--font-mono)', color: accent,
            padding: '2px 7px', border: `1px solid ${accentTint}`,
            background: accentTint, borderRadius: 3,
            letterSpacing: '0.04em',
          }}>GEN-QM</div>
        </div>
        <div style={{ fontSize: 12.5, color: ink2, marginTop: 3, fontFamily: 'var(--font-mono)' }}>
          $548,000 · 30-yr · 6.750% · start Apr 2026
        </div>
      </div>

      {/* Hero number — editorial treatment */}
      <div style={{
        padding: '16px 20px 18px',
        borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}`,
        background: raised,
      }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>
          Monthly payment · PITI
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', marginTop: 2 }}>
          <div style={{ fontSize: 13, color: ink3, fontFamily: 'var(--font-mono)', marginRight: 4 }}>$</div>
          <div style={{
            fontSize: 46, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums',
            fontWeight: 500, letterSpacing: '-0.02em', lineHeight: 1,
          }}>{total.toLocaleString()}</div>
          <div style={{ fontSize: 13, color: ink3, fontFamily: 'var(--font-mono)', marginLeft: 4 }}>.00</div>
        </div>
        {/* Four KPIs as rule-divided columns */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', marginTop: 16, gap: 0 }}>
          {[
            { l: 'Total interest', v: '$560,961' },
            { l: 'Payoff',         v: 'Mar 2056' },
            { l: 'Total paid',     v: '$1.28M' },
            { l: 'LTV',            v: '78%' },
          ].map((k, i) => (
            <div key={i} style={{
              paddingLeft: i === 0 ? 0 : 10, paddingRight: i === 3 ? 0 : 10,
              borderLeft: i === 0 ? '0' : `1px solid ${border}`,
            }}>
              <div style={{ fontSize: 9.5, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: ink3 }}>{k.l}</div>
              <div style={{ fontSize: 14, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, marginTop: 3, letterSpacing: '-0.01em' }}>{k.v}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Balance over time */}
      <div style={{ padding: '20px 20px 4px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 2 }}>
          <div style={{ fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em' }}>Balance over time</div>
          <div style={{ fontSize: 11, color: ink3, fontFamily: 'var(--font-mono)' }}>30 yr</div>
        </div>
        <div style={{ fontSize: 12, color: ink2, marginBottom: 10 }}>
          Principal remaining, year by year.
        </div>
        <svg width={w} height={h} style={{ display: 'block' }}>
          {/* horizontal grid */}
          {[0, 0.25, 0.5, 0.75, 1].map((f, i) => (
            <line key={i}
              x1={pad.l} x2={w - pad.r}
              y1={pad.t + f * (h - pad.t - pad.b)}
              y2={pad.t + f * (h - pad.t - pad.b)}
              stroke={grid} strokeWidth="1"
              strokeDasharray={f === 1 ? 'none' : '2 3'}
            />
          ))}
          {/* axis labels */}
          {[0, 10, 20, 30].map((yr) => (
            <text key={yr} x={x(yr)} y={h - 6}
              fontSize="9.5" fill={ink3} textAnchor={yr === 0 ? 'start' : yr === 30 ? 'end' : 'middle'}
              fontFamily="var(--font-mono)">
              {yr === 0 ? "'26" : yr === 30 ? "'56" : `'${26 + yr < 100 ? (26 + yr) : (26 + yr - 100)}`}
            </text>
          ))}
          {[0, 0.5, 1].map((f) => {
            const val = maxBal * (1 - f);
            return (
              <text key={f} x={w - pad.r} y={pad.t + f * (h - pad.t - pad.b) - 3}
                fontSize="9.5" fill={ink3} textAnchor="end"
                fontFamily="var(--font-mono)">
                {f === 1 ? '0' : `${Math.round(val / 1000)}k`}
              </text>
            );
          })}
          {/* area */}
          <path d={areaPath} fill={accentTint} opacity="0.7"/>
          {/* line */}
          <path d={path} fill="none" stroke={accent} strokeWidth="1.75" strokeLinejoin="round" strokeLinecap="round"/>
          {/* 10-yr marker */}
          <line x1={x(10)} x2={x(10)} y1={pad.t} y2={h - pad.b} stroke={ink3} strokeWidth="1" strokeDasharray="2 3" opacity="0.5"/>
          <circle cx={x(10)} cy={y(points[10].bal)} r="3" fill={bg} stroke={accent} strokeWidth="1.5"/>
        </svg>
        <div style={{ fontSize: 11, color: ink3, fontFamily: 'var(--font-mono)', marginTop: 4, paddingLeft: pad.l }}>
          Year 10 · ${Math.round(points[10].bal).toLocaleString()} remaining
        </div>
      </div>

      {/* PITI composition — horizontal stacked bar, labeled below */}
      <div style={{ padding: '20px 20px 6px' }}>
        <div style={{ fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em', marginBottom: 12 }}>
          Where the payment goes
        </div>
        <div style={{
          display: 'flex', height: 10, borderRadius: 2, overflow: 'hidden',
          border: `1px solid ${border}`,
        }}>
          {[
            { v: interest,  c: accent },
            { v: principal, c: dark ? '#6A8FB5' : '#264B6A' },
            { v: taxes,     c: dark ? '#BC976B' : '#73522A' },
            { v: insurance, c: dark ? '#B07D98' : '#6A3F5A' },
          ].map((s, i) => (
            <div key={i} style={{ background: s.c, width: `${(s.v / total) * 100}%` }} />
          ))}
        </div>
        {/* Legend rows */}
        <div style={{ marginTop: 12, display: 'grid', gridTemplateColumns: '1fr 1fr', columnGap: 16, rowGap: 8 }}>
          {[
            { name: 'Interest',  val: interest,  c: accent },
            { name: 'Taxes',     val: taxes,     c: dark ? '#BC976B' : '#73522A' },
            { name: 'Principal', val: principal, c: dark ? '#6A8FB5' : '#264B6A' },
            { name: 'Insurance', val: insurance, c: dark ? '#B07D98' : '#6A3F5A' },
          ].map((s, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{ width: 8, height: 8, background: s.c, borderRadius: 1, flexShrink: 0 }} />
              <div style={{ fontSize: 12, color: ink, flex: 1 }}>{s.name}</div>
              <div style={{ fontSize: 12, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', color: ink }}>
                ${s.val.toLocaleString()}
              </div>
              <div style={{ fontSize: 10.5, fontFamily: 'var(--font-mono)', color: ink3, width: 34, textAlign: 'right' }}>
                {((s.val / total) * 100).toFixed(0)}%
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Schedule table — dense, tabular */}
      <div style={{ padding: '22px 20px 6px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 12 }}>
          <div style={{ fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em' }}>Schedule</div>
          <div style={{ display: 'flex', gap: 2, padding: 2, background: sunken, border: `1px solid ${border}`, borderRadius: 6 }}>
            {['Month', 'Year'].map((t, i) => (
              <div key={t} style={{
                padding: '3px 9px', fontSize: 11, fontFamily: 'var(--font-mono)',
                color: i === 0 ? ink : ink3,
                background: i === 0 ? raised : 'transparent',
                borderRadius: 4, fontWeight: 500,
              }}>{t}</div>
            ))}
          </div>
        </div>
        <div style={{ borderTop: `1px solid ${border}` }}>
          <div style={{
            display: 'grid',
            gridTemplateColumns: '44px 1fr 1fr 1fr 1.1fr',
            padding: '8px 0',
            fontSize: 10, fontWeight: 600, letterSpacing: '0.08em',
            textTransform: 'uppercase', color: ink3,
            borderBottom: `1px solid ${border}`,
          }}>
            <div>#</div>
            <div style={{ textAlign: 'right' }}>Pmt</div>
            <div style={{ textAlign: 'right' }}>Prin</div>
            <div style={{ textAlign: 'right' }}>Int</div>
            <div style={{ textAlign: 'right' }}>Balance</div>
          </div>
          {rows.map((r, i) => (
            <div key={i} style={{
              display: 'grid',
              gridTemplateColumns: '44px 1fr 1fr 1fr 1.1fr',
              padding: '8px 0',
              fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums',
              fontSize: 12, color: ink,
              borderBottom: i < rows.length - 1 ? `1px solid ${border}` : '0',
            }}>
              <div style={{ color: ink3 }}>{r.n}</div>
              <div style={{ textAlign: 'right' }}>{r.pay}</div>
              <div style={{ textAlign: 'right' }}>{r.p}</div>
              <div style={{ textAlign: 'right', color: ink2 }}>{r.i}</div>
              <div style={{ textAlign: 'right' }}>{r.bal}</div>
            </div>
          ))}
        </div>
        <div style={{ fontSize: 11, color: ink3, marginTop: 8, fontStyle: 'italic' }}>
          Showing 8 of 360 payments. Tap to expand full schedule.
        </div>
      </div>

      <div style={{ height: 120 }} />

      {/* Bottom action dock */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '10px 16px 30px',
        background: dark ? 'rgba(23,22,15,0.88)' : 'rgba(250,249,245,0.9)',
        backdropFilter: 'blur(20px) saturate(180%)',
        borderTop: `1px solid ${border}`,
        display: 'flex', gap: 8,
      }}>
        <div style={{
          flex: 1, padding: '12px 0', textAlign: 'center',
          border: `1px solid ${border}`, borderRadius: 10,
          fontSize: 14, fontWeight: 500, color: ink,
          background: raised,
        }}>Narrate</div>
        <div style={{
          flex: 1, padding: '12px 0', textAlign: 'center',
          border: `1px solid ${border}`, borderRadius: 10,
          fontSize: 14, fontWeight: 500, color: ink,
          background: raised,
        }}>Save</div>
        <div style={{
          flex: 1.2, padding: '12px 0', textAlign: 'center',
          background: accent, color: dark ? '#0B0A04' : '#FAF9F5',
          borderRadius: 10, fontSize: 14, fontWeight: 600,
        }}>Share as PDF</div>
      </div>
    </div>
  );
}

Object.assign(window, { AmortizationScreen });
