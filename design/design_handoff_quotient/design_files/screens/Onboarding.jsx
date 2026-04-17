// Onboarding.jsx — 6-step tour, teaches the 5 calculators + ends with profile setup.

function OnboardingStep({ step, dark = false }) {
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
  const grid = dark ? '#26241C' : '#ECE8DC';

  // Visuals per step — typographic demos, no illustration
  const Demo = () => {
    if (step === 1) {
      // Amortization mini: hero number + balance curve
      return (
        <div style={{ width: '100%', background: raised, border: `1px solid ${border}`, borderRadius: 12, padding: 18, marginTop: 14 }}>
          <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>Monthly PITI</div>
          <div style={{ display: 'flex', alignItems: 'baseline', marginTop: 4, gap: 2 }}>
            <span style={{ fontSize: 12, color: ink3, fontFamily: 'var(--font-mono)' }}>$</span>
            <span style={{ fontSize: 38, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, letterSpacing: '-0.02em', lineHeight: 1 }}>3,284</span>
          </div>
          <svg width="100%" height="80" viewBox="0 0 300 80" preserveAspectRatio="none" style={{ marginTop: 14 }}>
            <path d="M10 72 L60 60 L110 45 L160 30 L210 18 L260 10 L290 6 L290 78 L10 78 Z" fill={accent} opacity="0.18"/>
            <path d="M10 72 L60 60 L110 45 L160 30 L210 18 L260 10 L290 6" stroke={accent} strokeWidth="1.5" fill="none"/>
          </svg>
          <div style={{ fontSize: 10.5, color: ink3, fontFamily: 'var(--font-mono)', marginTop: 8, textAlign: 'right' }}>Payoff · 2056</div>
        </div>
      );
    }
    if (step === 2) {
      // Income qual: two dials
      return (
        <div style={{ width: '100%', background: raised, border: `1px solid ${border}`, borderRadius: 12, padding: 20, marginTop: 14, display: 'flex', justifyContent: 'space-around' }}>
          {[{l:'Front',v:24.2,lim:28,c:accent},{l:'Back',v:38.1,lim:43,c:accent}].map((d,i) => {
            const size=88, r=size/2-5, cx=size/2, cy=size/2, circ=2*Math.PI*r;
            return (
              <div key={i} style={{ textAlign: 'center' }}>
                <svg width={size} height={size}>
                  <circle cx={cx} cy={cy} r={r} fill="none" stroke={grid} strokeWidth="5"/>
                  <circle cx={cx} cy={cy} r={r} fill="none" stroke={d.c} strokeWidth="5" strokeLinecap="round" transform={`rotate(-90 ${cx} ${cy})`} strokeDasharray={`${circ * d.v/(d.lim*1.4)} ${circ}`}/>
                  <text x={cx} y={cy+2} textAnchor="middle" fontSize="17" fontFamily="var(--font-mono)" fontWeight="500" fill={ink}>{d.v}</text>
                  <text x={cx} y={cy+15} textAnchor="middle" fontSize="8.5" fill={ink3} fontFamily="var(--font-mono)">% · lim {d.lim}</text>
                </svg>
                <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: ink3, marginTop: 4 }}>{d.l}</div>
              </div>
            );
          })}
        </div>
      );
    }
    if (step === 3) {
      // Refi: break-even line
      return (
        <div style={{ width: '100%', background: raised, border: `1px solid ${border}`, borderRadius: 12, padding: 18, marginTop: 14 }}>
          <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>Cumulative savings</div>
          <svg width="100%" height="110" viewBox="0 0 300 110" preserveAspectRatio="none" style={{ marginTop: 10 }}>
            <line x1="0" x2="300" y1="60" y2="60" stroke={ink3} strokeWidth="1" strokeDasharray="3 3" opacity="0.5"/>
            <path d="M10 92 L60 82 L110 72 L140 60 L180 42 L240 18 L290 2" stroke={accent} strokeWidth="1.75" fill="none"/>
            <line x1="140" x2="140" y1="0" y2="110" stroke={accent} strokeWidth="1" strokeDasharray="2 2" opacity="0.6"/>
            <circle cx="140" cy="60" r="4" fill={bg} stroke={accent} strokeWidth="1.75"/>
            <text x="145" y="52" fontSize="10" fontFamily="var(--font-mono)" fill={accent} fontWeight="600">24 mo</text>
          </svg>
          <div style={{ fontSize: 11, color: ink2, marginTop: 4, fontFamily: 'var(--font-mono)' }}>break-even · month 24</div>
        </div>
      );
    }
    if (step === 4) {
      // TCA: table peek
      return (
        <div style={{ width: '100%', background: raised, border: `1px solid ${border}`, borderRadius: 12, padding: 14, marginTop: 14 }}>
          <div style={{ display: 'grid', gridTemplateColumns: '40px repeat(4,1fr)', padding: '6px 0', borderBottom: `1px solid ${border}` }}>
            <div/>
            {[['A',accent],['B','#264B6A'],['C','#6A3F5A'],['D','#73522A']].map(([id,c]) => <div key={id} style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: c, textAlign: 'right' }}>{id}</div>)}
          </div>
          {[[5,238,289,241,211],[10,456,495,461,428],[30,1181,1104,1198,1168]].map(r => {
            const min = Math.min(...r.slice(1));
            return (
              <div key={r[0]} style={{ display: 'grid', gridTemplateColumns: '40px repeat(4,1fr)', padding: '8px 0', borderBottom: `1px solid ${border}`, alignItems: 'center' }}>
                <div style={{ fontSize: 10.5, fontFamily: 'var(--font-mono)', color: ink2 }}>{r[0]}-yr</div>
                {r.slice(1).map((v,i) => (
                  <div key={i} style={{ textAlign: 'right', fontFamily: 'var(--font-mono)', fontSize: 11.5, fontWeight: v === min ? 600 : 500, color: v === min ? gain : ink }}>${v}k</div>
                ))}
              </div>
            );
          })}
        </div>
      );
    }
    if (step === 5) {
      // HELOC: blended rate bar
      return (
        <div style={{ width: '100%', background: raised, border: `1px solid ${border}`, borderRadius: 12, padding: 18, marginTop: 14 }}>
          <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: ink3 }}>Blended rate</div>
          <div style={{ display: 'flex', alignItems: 'baseline', marginTop: 4, gap: 2 }}>
            <span style={{ fontSize: 38, fontFamily: 'var(--font-mono)', fontVariantNumeric: 'tabular-nums', fontWeight: 500, letterSpacing: '-0.02em' }}>4.85</span>
            <span style={{ fontSize: 14, color: ink3, fontFamily: 'var(--font-mono)' }}>%</span>
            <span style={{ fontSize: 11, color: ink3, fontFamily: 'var(--font-mono)', marginLeft: 10 }}>vs refi 6.125%</span>
          </div>
          <div style={{ marginTop: 14, height: 10, borderRadius: 2, overflow: 'hidden', display: 'flex', background: grid }}>
            <div style={{ width: '80%', background: accent }}/>
            <div style={{ width: '20%', background: '#264B6A' }}/>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontSize: 10, fontFamily: 'var(--font-mono)', color: ink3 }}>
            <span>1st · 3.125%</span>
            <span>HELOC · 8.75%</span>
          </div>
        </div>
      );
    }
    // step 0 — welcome: wordmark composition
    return (
      <div style={{ width: '100%', background: raised, border: `1px solid ${border}`, borderRadius: 12, padding: '36px 20px', marginTop: 14, textAlign: 'center' }}>
        <div style={{ fontFamily: 'var(--font-serif)', fontSize: 72, fontWeight: 400, letterSpacing: '-0.02em', color: ink, lineHeight: 1 }}>Q</div>
        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.14em', textTransform: 'uppercase', color: ink3, marginTop: 10 }}>Quotient</div>
        <div style={{ fontSize: 10, color: ink3, marginTop: 4, fontFamily: 'var(--font-mono)', letterSpacing: '0.06em' }}>v 1.2.4</div>
      </div>
    );
  };

  const content = [
    {
      eyebrow: 'Welcome',
      title: 'Quotient.',
      body: 'Five calculators, built for loan officers who care about how the numbers read on paper. Swipe to see what\'s inside.',
    },
    {
      eyebrow: '01 · Amortization',
      title: 'The schedule, settled.',
      body: 'Enter loan, taxes, and insurance. See the PITI, the balance curve, every row of the schedule. Extra principal and recast built in.',
    },
    {
      eyebrow: '02 · Income qualification',
      title: 'Max loan, fast.',
      body: 'Front- and back-end DTI against agency limits. Tells you not just the number — but why the number.',
    },
    {
      eyebrow: '03 · Refinance comparison',
      title: 'Break-even, not broad strokes.',
      body: 'Three refi options against the current loan. Monthly savings, lifetime delta, NPV at a discount rate you choose.',
    },
    {
      eyebrow: '04 · Total cost analysis',
      title: 'Two to four scenarios, side by side.',
      body: 'Compare 30-yr vs 15-yr vs buydown across 5, 7, 10, 15, and 30-year horizons. Winner highlighted per row.',
    },
    {
      eyebrow: '05 · HELOC vs refinance',
      title: 'When keeping the first mortgage wins.',
      body: 'Blended rate math, a stress path for rate shocks, and a plain-English verdict at the bottom.',
    },
  ][step];

  return (
    <div style={{ background: bg, minHeight: '100%', color: ink, fontFamily: 'var(--font-sans)', display: 'flex', flexDirection: 'column' }}>
      <div style={{ height: 59 }} />

      {/* Progress + skip */}
      <div style={{ display: 'flex', alignItems: 'center', padding: '6px 20px 0', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', gap: 4 }}>
          {[0,1,2,3,4,5].map(i => (
            <div key={i} style={{ width: 22, height: 3, borderRadius: 2, background: i <= step ? accent : border }}/>
          ))}
        </div>
        <div style={{ fontSize: 12.5, color: ink3, fontWeight: 500 }}>Skip</div>
      </div>

      {/* Body */}
      <div style={{ padding: '26px 20px 16px', flex: 1 }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: accent }}>{content.eyebrow}</div>
        <div style={{ fontFamily: 'var(--font-serif)', fontSize: 32, fontWeight: 400, letterSpacing: '-0.02em', marginTop: 6, color: ink, lineHeight: 1.15 }}>{content.title}</div>
        <div style={{ fontSize: 14.5, color: ink2, marginTop: 10, lineHeight: 1.55, maxWidth: 330, textWrap: 'pretty' }}>{content.body}</div>

        <Demo/>
      </div>

      <div style={{ height: 100 }} />

      {/* CTA */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '10px 16px 30px',
        background: dark ? 'rgba(23,22,15,0.88)' : 'rgba(250,249,245,0.9)',
        backdropFilter: 'blur(20px) saturate(180%)',
        borderTop: `1px solid ${border}`,
        display: 'flex', gap: 8, alignItems: 'center',
      }}>
        <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: ink3, letterSpacing: '0.04em', paddingLeft: 6 }}>{step + 1} / 6</div>
        <div style={{ flex: 1 }}/>
        <div style={{ padding: '12px 28px', background: accent, color: dark ? '#0B0A04' : '#FAF9F5', borderRadius: 10, fontSize: 14, fontWeight: 600 }}>
          {step === 5 ? 'Get started' : 'Continue'}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { OnboardingStep });
