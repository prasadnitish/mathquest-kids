import React from 'react';
import {AbsoluteFill, Audio, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {BAR, brand, fonts} from '../brand';
import {Backdrop, Caption, Mascot, PopText, StatTile, TileWipe, Wordmark} from '../components/Brand';
import {Clip, Device} from '../components/Footage';

// 36 seconds, square: what parents get, and why they can trust it.
export const PARENTS_FRAMES = 18 * BAR;
const S = {hook: 0, gate: 2 * BAR, dashboard: 4 * BAR, curriculum: 11 * BAR, trust: 14 * BAR, end: 16 * BAR};
const PHONE = 'iphone-standard' as const;

// Real standards from the app's lesson plans (MathQuestKids/Content/lesson-plans-k5.json).
const STANDARDS: Array<[string, string]> = [
  ['K.CC.B.5', 'Count and match'],
  ['K.OA.A.3', 'Make 10'],
  ['1.NBT.B.2', 'Teen place value'],
  ['1.OA.C.6', 'Subtract within 20'],
  ['2.NBT.B.7', 'Regrouping'],
  ['2.MD.C.8', 'Time and money'],
  ['3.OA.A.1', 'Multiplication'],
  ['3.NF.A.1', 'Unit fractions'],
  ['4.NBT.B.5', 'Multi-digit ×'],
  ['4.G.A.3', 'Symmetry'],
  ['5.NF.A.1', 'Unlike fractions'],
  ['5.MD.C.5', 'Volume'],
];

export const Parents: React.FC = () => (
  <AbsoluteFill style={{background: '#1d2135'}}>
    <Sequence from={S.hook} durationInFrames={S.gate - S.hook}>
      <Hook />
    </Sequence>
    <Sequence from={S.gate} durationInFrames={S.dashboard - S.gate}>
      <Gate />
    </Sequence>
    <Sequence from={S.dashboard} durationInFrames={S.curriculum - S.dashboard}>
      <Dashboard />
    </Sequence>
    <Sequence from={S.curriculum} durationInFrames={S.trust - S.curriculum}>
      <Curriculum />
    </Sequence>
    <Sequence from={S.trust} durationInFrames={S.end - S.trust}>
      <Trust />
    </Sequence>
    <Sequence from={S.end}>
      <End />
    </Sequence>
    {[S.gate, S.curriculum].map((at) => (
      <Sequence key={at} from={at - 10} durationInFrames={22}>
        <Wipe frames={22} />
        <Audio src={staticFile('audio/sfx-whoosh.wav')} volume={0.5} />
      </Sequence>
    ))}
    <Audio src={staticFile('audio/music-parents.wav')} volume={0.75} />
  </AbsoluteFill>
);

const Wipe: React.FC<{frames: number}> = ({frames}) => {
  const frame = useCurrentFrame();
  return <TileWipe progress={frame / frames} />;
};

const Slate: React.FC = () => <AbsoluteFill style={{background: 'linear-gradient(145deg, #1d2135, #362a58)'}} />;

const Hook: React.FC = () => (
  <AbsoluteFill>
    <Backdrop />
    <AbsoluteFill style={{alignItems: 'center', paddingTop: 120, flexDirection: 'column', gap: 30}}>
      <PopText text="What did they actually learn today?" size={80} delay={4} maxWidth={900} />
    </AbsoluteFill>
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'flex-end'}}>
      <Mascot name="HeroCaptainCalc" size={520} delay={14} style={{marginBottom: -40}} />
    </AbsoluteFill>
  </AbsoluteFill>
);

const PhoneLeft: React.FC<{scene: string; mark: string; offset: number; rate: number}> = (props) => (
  <div style={{position: 'absolute', left: 50, top: 40}}>
    <Device kind={PHONE} height={1000}>
      <Clip device={PHONE} {...props} />
    </Device>
  </div>
);

const Gate: React.FC = () => (
  <AbsoluteFill>
    <Slate />
    <PhoneLeft scene="testSceneParentDashboard" mark="parent-gate" offset={0} rate={1.2} />
    <div style={{position: 'absolute', left: 560, top: 140, width: 470, display: 'flex', flexDirection: 'column', gap: 30, alignItems: 'flex-start'}}>
      <PopText text="A grown-up zone" size={64} align="left" delay={4} maxWidth={470} />
      <Caption text="Behind a parent PIN" size={40} delay={20} emoji="🔒" />
      <Caption text="Kids can't change settings" size={36} delay={44} emoji="🙅" />
    </div>
  </AbsoluteFill>
);

const Dashboard: React.FC = () => {
  const captions: Array<[string, string, number]> = [
    ['Day streaks', '🔥', 20],
    ['Skills by math domain', '📊', 90],
    ['Where they need help', '🎯', 170],
    ['Every quest, logged', '🗓️', 250],
  ];
  return (
    <AbsoluteFill>
      <Slate />
      <PhoneLeft scene="testSceneParentDashboard" mark="dashboard" offset={-0.3} rate={0.95} />
      <div style={{position: 'absolute', left: 560, top: 100, width: 470, display: 'flex', flexDirection: 'column', gap: 30, alignItems: 'flex-start'}}>
        <PopText text="Progress you can see" size={64} align="left" delay={4} maxWidth={470} />
        {captions.map(([text, emoji, delay]) => (
          <Caption key={text} text={text} size={40} delay={delay} emoji={emoji} />
        ))}
        <div style={{fontFamily: fonts.body, fontWeight: 500, fontSize: 24, color: 'rgba(255,255,255,0.6)', marginTop: 10}}>
          Sample profile shown
        </div>
      </div>
    </AbsoluteFill>
  );
};

const Curriculum: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <AbsoluteFill>
      <Backdrop />
      <AbsoluteFill style={{alignItems: 'center', paddingTop: 70, flexDirection: 'column', gap: 40}}>
        <PopText text="Built on Common Core, K–5" size={70} delay={2} maxWidth={960} />
        <div style={{display: 'flex', flexWrap: 'wrap', justifyContent: 'center', gap: 14, width: 980}}>
          {STANDARDS.map(([code, title], i) => {
            const t = spring({frame: frame - 12 - i * 3, fps, config: {damping: 12, stiffness: 180}});
            const color = Object.values(brand.tiles)[Math.min(5, Number(code[0]) || 0)];
            return (
              <div
                key={code}
                style={{
                  padding: '12px 18px',
                  borderRadius: 18,
                  background: 'white',
                  boxShadow: '0 8px 18px rgba(20,10,60,0.18)',
                  transform: `scale(${interpolate(t, [0, 1], [0.4, 1])})`,
                  opacity: t,
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                }}
              >
                <span style={{fontFamily: fonts.display, fontWeight: 900, fontSize: 30, color}}>{code}</span>
                <span style={{fontFamily: fonts.body, fontWeight: 500, fontSize: 20, color: '#4a4466'}}>{title}</span>
              </div>
            );
          })}
        </div>
        <div style={{display: 'flex', gap: 26, marginTop: 10}}>
          <StatTile value={65} label="standards mapped" color={brand.tiles['4']} size={290} delay={50} />
          <StatTile value={3000} suffix="+" label="questions" color={brand.tiles['2']} size={290} delay={56} />
          <StatTile value={49} label="lesson plans" color={brand.tiles['3']} size={290} delay={62} />
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const Trust: React.FC = () => {
  const items: Array<[string, string, string]> = [
    ['No ads', '🚫', brand.tiles.K],
    ['No accounts', '👤', brand.tiles['2']],
    ['No tracking', '🙈', brand.tiles['3']],
    ['Works offline', '✈️', brand.tiles['4']],
  ];
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <AbsoluteFill>
      <Slate />
      <AbsoluteFill style={{alignItems: 'center', paddingTop: 90, flexDirection: 'column', gap: 60}}>
        <PopText text="Safe by design" size={76} delay={2} />
        <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 30}}>
          {items.map(([text, emoji, color], i) => {
            const t = spring({frame: frame - 8 - i * 6, fps, config: {damping: 10, stiffness: 160}});
            return (
              <div
                key={text}
                style={{
                  width: 420,
                  height: 230,
                  borderRadius: 40,
                  background: `linear-gradient(160deg, rgba(255,255,255,0.3), rgba(255,255,255,0) 50%), ${color}`,
                  boxShadow: '0 12px 0 rgba(0,0,0,0.2)',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 10,
                  transform: `scale(${interpolate(t, [0, 1], [0.4, 1])}) rotate(${(1 - t) * (i % 2 ? 8 : -8)}deg)`,
                  opacity: t,
                }}
              >
                <span style={{fontSize: 84}}>{emoji}</span>
                <span style={{fontFamily: fonts.display, fontWeight: 900, fontSize: 50, color: 'white'}}>{text}</span>
              </div>
            );
          })}
        </div>
      </AbsoluteFill>
      {[8, 14, 20, 26].map((f) => (
        <Sequence key={f} from={f} durationInFrames={10}>
          <Audio src={staticFile('audio/sfx-pop.wav')} volume={0.4} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};

const End: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const cta = spring({frame: frame - 30, fps, config: {damping: 10, stiffness: 150}});
  return (
    <AbsoluteFill>
      <Backdrop />
      <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 44}}>
        <Wordmark size={96} delay={2} />
        <PopText text="K–5 math practice kids love and parents trust." size={52} delay={12} maxWidth={900} weight={800} />
        <div
          style={{
            padding: '18px 40px',
            borderRadius: 50,
            background: brand.ink,
            color: 'white',
            fontFamily: fonts.display,
            fontWeight: 900,
            fontSize: 44,
            transform: `scale(${interpolate(cta, [0, 1], [0.6, 1])})`,
            opacity: cta,
          }}
        >
          Join the beta · sproutmath.app
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
