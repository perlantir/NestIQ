// TCA.jsx — Total Cost Analysis (Calc 04)
// Compare 2-4 loan scenarios over 5/7/10/15/30 year horizons.
// Editorial heatmap-ish table + stacked bars.

function TCAScreen({ dark = false }) {
  const bg = dark ? '#17160F' : '#FAF9F5';
  const raised = dark ? '#1E1D15' : '#FFFFFE';
  const ink = dark ? '#F2EFE2' : '#17160F';
  const ink2 = dark ? '#B4B0A0' : '#4A4840';
  const ink3 = dark ? '#7C7869' : '#85816F';
  const border = dark ? '#2A281F' : '#E5E1D5';
  const accent = dark ? '#4F9E7D' : '#1F4D3F';
  const accentTint = dark ? '#22322C' : '#DFE6E0';
  const gain = dark ? '#6FB28D' : '#2D6A4E';
  const grid = dark ? '#26241C' : '#ECE8DC';

  const scenarios = [
    { id: 'A', name: 'Conv 30', c: '#1F4D3F', rate: '6.750', pts: '0.00', piti: '3284', best: false },
    { id: 'B', name: 'Conv 15', c: '#264B6A', rate: '5.875', pts: '0.00', piti: '4612', best: false },
    { id: 'C', name: 'FHA 30',  c: '#6A3F5A', rate: '6.375', pts: '0.50', piti: '3198', best: false },
    { id: 'D', name: 'Buydown', c: '#73522A', rate: '4.750', pts: '2.75', piti: '2955', best: true },
  ];

  // Total cost matrix — scenarios × horizons (in $k)
  const horizons = [5, 7, 10, 15, 30];
  const matrix = [
    { A: 238, B: 289, C: 241, D: 211 },
    { A: 326, B: 378, C: 330, D: 295 },
    { A: 456, B: 495, C: 461, D: 428 },
    { A: 661, B: 629, C: 670, D: 642, w: 'B' },
    { A: 1181, B: 1104, C: 1198, D: 1168, w: 'B' },
  ];

  return (
    <div style={{ background: bg, minHeight: '100%', color: ink, fontFamily: 'var(--font-sans)' }}>
      <div style={{ height: 59 }} />
      <div style={{ display: 'flex', alignItems: 'center', padding: '6px 16px 10px', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', color: accent, fontSize: 16, fontWeight: 500 }}>
          <svg width="10" height="16" viewBox="0 0 10 16" style={{ marginRight: 4 }}><path d="M8 2L2 8l6 6" stroke={accent} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
          Home
        </div>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>04 · Total cost</div>
        <div style={{ width: 28 }} />
      </div>

      {/* Borrower */}
      <div style={{ padding: '8px 20px 16px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3, marginBottom: 4 }}>Borrower</div>
        <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.015em' }}>Alonzo Garcia-Reyes</div>
        <div style={{ fontSize: 12.5, color: ink2, marginTop: 3, fontFamily: 'var(--font-mono)' }}>Purchase · $548,000 · 20% down</div>
      </div>

      {/* Scenarios legend */}
      <div style={{ padding: '0 20px 14px', display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        {scenarios.map(s => (
          <div key={s.id} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '5px 9px', border: `1px solid ${s.best ? accent : border}`, borderRadius: 999, background: s.best ? accentTint : 'transparent' }}>
            <div style={{ width: 7, height: 7, borderRadius: 1, background: s.c }}/>
            <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: ink2, letterSpacing: '0.02em' }}>{s.id} · {s.name}</div>
          </div>
        ))}
      </div>

      {/* Scenario spec grid */}
      <div style={{ padding: '0 20px 20px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 0, border: `1px solid ${border}`, borderRadius: 8, overflow: 'hidden', background: raised }}>
          {scenarios.map((s, i) => (
            <div key={s.id} style={{
              padding: '10px 8px',
              borderRight: i < 3 ? `1px solid ${border}` : '0',
              background: s.best ? accentTint : 'transparent',
            }}>
              <div style={{ fontSize: 9.5, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: s.c }}>{s.id}</div>
              <div style={{ fontSize: 15, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, marginTop: 2 }}>{s.rate}<span style={{ fontSize: 9, color: ink3 }}>%</span></div>
              <div style={{ fontSize: 10.5, color: ink3, fontFamily: 'var(--font-mono)', marginTop: 1 }}>pts {s.pts}</div>
              <div style={{ fontSize: 12, fontFamily: 'var(--font-mono)', marginTop: 4, color: ink }}>${s.piti}/mo</div>
            </div>
          ))}
        </div>
      </div>

      {/* Matrix */}
      <div style={{ padding: '0 20px 8px' }}>
        <div style={{ fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em', marginBottom: 2 }}>Total cost · by horizon</div>
        <div style={{ fontSize: 12, color: ink2, marginBottom: 12 }}>Principal + interest + points. Winner highlighted per row.</div>

        <div style={{ borderTop: `1px solid ${border}` }}>
          {/* header */}
          <div style={{ display: 'grid', gridTemplateColumns: '52px repeat(4, 1fr)', padding: '7px 0', borderBottom: `1px solid ${border}` }}>
            <div/>
            {scenarios.map(s => (
              <div key={s.id} style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: s.c, textAlign: 'right' }}>{s.id}</div>
            ))}
          </div>
          {matrix.map((row, i) => {
            const vals = ['A','B','C','D'].map(k => row[k]);
            const winner = ['A','B','C','D'].reduce((a, b) => row[b] < row[a] ? b : a, 'A');
            return (
              <div key={i} style={{ display: 'grid', gridTemplateColumns: '52px repeat(4, 1fr)', padding: '10px 0', borderBottom: `1px solid ${border}`, alignItems: 'center' }}>
                <div style={{ fontSize: 11, fontWeight: 500, color: ink2, fontFamily: 'var(--font-mono)' }}>{horizons[i]}-yr</div>
                {['A','B','C','D'].map(k => {
                  const v = row[k];
                  const isW = k === winner;
                  return (
                    <div key={k} style={{ textAlign: 'right', fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontSize: 12.5, fontWeight: isW ? 600 : 500, color: isW ? gain : ink }}>
                      ${v}<span style={{ color: ink3, fontSize: 9.5 }}>k</span>
                    </div>
                  );
                })}
              </div>
            );
          })}
        </div>
      </div>

      {/* Stacked bar — at 10-yr horizon */}
      <div style={{ padding: '22px 20px 0' }}>
        <div style={{ fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em', marginBottom: 2 }}>Breakdown · 10-yr horizon</div>
        <div style={{ fontSize: 12, color: ink2, marginBottom: 14 }}>P&amp;I · points · tax &amp; ins.</div>
        {scenarios.map(s => {
          const pi = { A: 310, B: 362, C: 318, D: 286 }[s.id];
          const pts = { A: 0, B: 0, C: 2.7, D: 15.1 }[s.id];
          const ti = 146;
          const total = pi + pts + ti;
          const W = 322;
          return (
            <div key={s.id} style={{ marginBottom: 14 }}>
              <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 5 }}>
                <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: s.c, letterSpacing: '0.04em', fontWeight: 600 }}>{s.id} · {s.name}</div>
                <div style={{ fontSize: 12, fontFamily: 'var(--font-mono)', fontWeight: 500 }}>${total.toFixed(0)}k</div>
              </div>
              <div style={{ display: 'flex', height: 10, borderRadius: 2, overflow: 'hidden', background: grid }}>
                <div style={{ width: (pi/total)*W, height: '100%', background: s.c }}/>
                <div style={{ width: (pts/total)*W, height: '100%', background: s.c, opacity: 0.55 }}/>
                <div style={{ width: (ti/total)*W, height: '100%', background: s.c, opacity: 0.25 }}/>
              </div>
            </div>
          );
        })}
        <div style={{ display: 'flex', gap: 14, fontSize: 10, color: ink3, fontFamily: 'var(--font-mono)', marginTop: 4 }}>
          <span><span style={{ display: 'inline-block', width: 8, height: 8, background: ink2, marginRight: 4, borderRadius: 1 }}/>P&amp;I</span>
          <span><span style={{ display: 'inline-block', width: 8, height: 8, background: ink2, opacity: 0.55, marginRight: 4, borderRadius: 1 }}/>Points</span>
          <span><span style={{ display: 'inline-block', width: 8, height: 8, background: ink2, opacity: 0.25, marginRight: 4, borderRadius: 1 }}/>Tax &amp; ins</span>
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
        <div style={{ flex: 1, padding: '12px 0', textAlign: 'center', border: `1px solid ${border}`, borderRadius: 10, fontSize: 14, fontWeight: 500, background: raised }}>Add scenario</div>
        <div style={{ flex: 1.2, padding: '12px 0', textAlign: 'center', background: accent, color: dark ? '#0B0A04' : '#FAF9F5', borderRadius: 10, fontSize: 14, fontWeight: 600 }}>Share as PDF</div>
      </div>
    </div>
  );
}

Object.assign(window, { TCAScreen });
