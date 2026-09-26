import React from 'react';
import {AbsoluteFill, Audio, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {BAR, brand, duckedVolume, fonts} from '../brand';
import {Backdrop, Caption, Mascot, PopText, TileWipe, Wordmark} from '../components/Brand';
import {Clip, Device} from '../components/Footage';
import {SlipScene, slipVoiceFrame} from '../components/SlipScene';

// 32 seconds, square, for the LinkedIn feed: the column-by-column feature on its own.
export const ON_PAPER_FRAMES = 16 * BAR;
const S = {hook: 0, abcd: BAR, reveal: 2 * BAR, paper: 3 * BAR, trade: 10 * BAR, end: 13 * BAR};
const PHONE = 'iphone-standard' as const;

export const OnPaper: React.FC = () => {
  const voice = slipVoiceFrame(PHONE, PAPER_FRAMES);
  const voiceAt = voice === undefined ? undefined : S.paper + voice;
  return (
  <AbsoluteFill style={{background: brand.cream}}>
    <Sequence from={S.hook} durationInFrames={S.abcd - S.hook}>
      <Hook />
    </Sequence>
    <Sequence from={S.abcd} durationInFrames={S.reveal - S.abcd}>
      <MultipleChoice />
    </Sequence>
    <Sequence from={S.reveal} durationInFrames={S.paper - S.reveal}>
      <Reveal />
    </Sequence>
    <Sequence from={S.paper} durationInFrames={S.trade - S.paper}>
      <Paper />
    </Sequence>
    <Sequence from={S.trade} durationInFrames={S.end - S.trade}>
      <Trade />
    </Sequence>
    <Sequence from={S.end}>
      <End />
    </Sequence>
    {[S.reveal, S.end].map((at) => (
      <Sequence key={at} from={at - 10} durationInFrames={22}>
        <Wipe frames={22} />
        <Audio src={staticFile('audio/sfx-whoosh.wav')} volume={0.5} />
      </Sequence>
    ))}
    <Audio src={staticFile('audio/music-paper.wav')} volume={duckedVolume(0.8, voiceAt)} />
  </AbsoluteFill>
  );
};

const Wipe: React.FC<{frames: number}> = ({frames}) => {
  const frame = useCurrentFrame();
  return <TileWipe progress={frame / frames} />;
};

/** Notebook grid paper with a red margin line. */
const GridPaper: React.FC = () => (
  <AbsoluteFill
    style={{
      background: brand.cream,
      backgroundImage:
        'linear-gradient(rgba(70,120,220,0.16) 2px, transparent 2px), linear-gradient(90deg, rgba(70,120,220,0.16) 2px, transparent 2px)',
      backgroundSize: '54px 54px',
    }}
  >
    <div style={{position: 'absolute', left: 120, top: 0, bottom: 0, width: 4, background: 'rgba(230,80,90,0.45)'}} />
  </AbsoluteFill>
);

/** A sum written on paper, digit by digit, with the carried 1. */
const PaperSum: React.FC<{delay: number}> = ({delay}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const cell = 108;
  const show = (at: number) => spring({frame: frame - delay - at, fps, config: {damping: 12, stiffness: 200}});
  const digit = (text: string, at: number, color = brand.ink, size = 96) => {
    const t = show(at);
    return (
      <div
        style={{
          width: cell,
          height: cell,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontFamily: fonts.display,
          fontWeight: 900,
          fontSize: size,
          color,
          opacity: t,
          transform: `scale(${interpolate(t, [0, 1], [1.6, 1])}) rotate(${(1 - t) * -8}deg)`,
        }}
      >
        {text}
      </div>
    );
  };
  const line = show(14);
  return (
    <div style={{display: 'flex', flexDirection: 'column', alignItems: 'flex-end'}}>
      <div style={{display: 'flex'}}>{digit('', 0)}{digit('1', 26, '#e8742a', 56)}{digit('', 0)}</div>
      <div style={{display: 'flex'}}>{digit('', 0)}{digit('4', 0)}{digit('7', 3)}</div>
      <div style={{display: 'flex'}}>{digit('+', 8)}{digit('3', 6)}{digit('6', 9)}</div>
      <div style={{width: cell * 3, height: 8, borderRadius: 4, background: brand.ink, transform: `scaleX(${line})`, transformOrigin: 'right'}} />
      <div style={{display: 'flex'}}>{digit('', 0)}{digit('8', 34, '#2e7d4f')}{digit('3', 20, '#2e7d4f')}</div>
    </div>
  );
};

const Hook: React.FC = () => (
  <AbsoluteFill>
    <GridPaper />
    <AbsoluteFill style={{flexDirection: 'column', alignItems: 'center', paddingTop: 90, gap: 40}}>
      <PopText text="On paper, kids work math one column at a time." size={66} color={brand.ink} shadow={false} maxWidth={900} delay={2} />
      <PaperSum delay={16} />
    </AbsoluteFill>
  </AbsoluteFill>
);

const MultipleChoice: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const strike = spring({frame: frame - 34, fps, config: {damping: 14, stiffness: 160}});
  return (
    <AbsoluteFill>
      <GridPaper />
      <AbsoluteFill style={{flexDirection: 'column', alignItems: 'center', paddingTop: 110, gap: 80}}>
        <PopText text="Most apps just ask them to pick A, B, C or D." size={66} color={brand.ink} shadow={false} maxWidth={900} delay={2} />
        <div style={{position: 'relative', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 28}}>
          {['A  73', 'B  83', 'C  713', 'D  93'].map((label, i) => (
            <div key={label} style={{transform: `scale(${spring({frame: frame - 10 - i * 4, fps, config: {damping: 12}})})`}}>
              <div
                style={{
                  width: 330,
                  padding: '26px 0',
                  borderRadius: 26,
                  background: 'white',
                  boxShadow: '0 10px 24px rgba(30,20,80,0.15)',
                  fontFamily: fonts.display,
                  fontWeight: 900,
                  fontSize: 58,
                  color: '#7a76a0',
                  textAlign: 'center',
                  whiteSpace: 'pre',
                }}
              >
                {label}
              </div>
            </div>
          ))}
          <div
            style={{
              position: 'absolute',
              left: -40,
              right: -40,
              top: '50%',
              height: 18,
              borderRadius: 9,
              background: '#e5484d',
              transform: `rotate(-12deg) scaleX(${strike})`,
              transformOrigin: 'left',
            }}
          />
        </div>
      </AbsoluteFill>
      <Sequence from={34} durationInFrames={10}>
        <Audio src={staticFile('audio/sfx-pop.wav')} volume={0.5} />
      </Sequence>
    </AbsoluteFill>
  );
};

const Reveal: React.FC = () => (
  <AbsoluteFill>
    <Backdrop />
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 50}}>
      <Wordmark size={84} delay={4} />
      <PopText text="lets them write it out." size={74} delay={16} maxWidth={900} />
    </AbsoluteFill>
  </AbsoluteFill>
);

const PAPER_FRAMES = S.trade - S.paper;

const Paper: React.FC = () => (
  <SlipScene
    device={PHONE}
    frames={PAPER_FRAMES}
    deviceHeight={1000}
    deviceLeft={50}
    deviceTop={40}
    captionsLeft={560}
    captionsTop={70}
    captionsWidth={480}
    captionSize={42}
  />
);

const Trade: React.FC = () => (
  <AbsoluteFill>
    <Backdrop from="#58c7d8" to="#3a7bd5" />
    <div style={{position: 'absolute', left: 50, top: 40}}>
      <Device kind={PHONE} height={1000}>
        <Clip device={PHONE} scene="testSceneColumnSubtraction" mark="trade-start" offset={0.6} rate={1.1} />
      </Device>
    </div>
    <div style={{position: 'absolute', left: 560, top: 110, width: 480, display: 'flex', flexDirection: 'column', gap: 30, alignItems: 'flex-start'}}>
      <PopText text="Subtracting? Same idea." size={60} align="left" delay={2} maxWidth={470} />
      <Caption text="Not enough ones?" size={42} delay={16} emoji="🤔" />
      <Caption text="Trade a ten for 10 ones" size={42} delay={40} emoji="🔁" />
    </div>
    <div style={{position: 'absolute', right: 20, bottom: 0}}>
      <Mascot name="ReefCoral" size={330} delay={20} />
    </div>
  </AbsoluteFill>
);

const End: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const cta = spring({frame: frame - 44, fps, config: {damping: 10, stiffness: 150}});
  return (
    <AbsoluteFill>
      <Backdrop />
      <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 48, padding: 60}}>
        <PopText text="It catches exactly where a child goes wrong." size={70} delay={2} maxWidth={940} />
        <Wordmark size={84} delay={26} />
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
          K–5 · Join the beta · sproutmath.app
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
