import React from 'react';
import {AbsoluteFill, Audio, Img, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {BAR, brand, duckedVolume, fonts, themeOrder, themes, ThemeKey} from '../brand';
import {Backdrop, Caption, Mascot, PopText, StatTile, TileRow, TileWipe, Wordmark} from '../components/Brand';
import {Clip, Device, RampedClip, Zoom, rampTimeline, stretch} from '../components/Footage';
import {moments} from '../moments';
import {SlipScene, slipVoiceFrame} from '../components/SlipScene';

// 46 seconds: 23 bars of the 120 BPM track. Sections start on bar lines.
export const OVERVIEW_FRAMES = 23 * BAR;
const S = {
  intro: 0,
  themes: 2 * BAR,
  column: 5 * BAR,
  montage: 11 * BAR,
  parents: 14 * BAR,
  stats: 19 * BAR,
  end: 21 * BAR,
};

const IPAD = 'ipad-standard' as const;

export const Overview: React.FC = () => {
  const voice = slipVoiceFrame(IPAD, COLUMN_FRAMES);
  const voiceAt = voice === undefined ? undefined : S.column + voice;
  return (
    <AbsoluteFill style={{background: brand.purple}}>
      <Sequence from={S.intro} durationInFrames={S.themes - S.intro}>
        <Intro />
      </Sequence>
      <Sequence from={S.themes} durationInFrames={S.column - S.themes}>
        <Themes />
      </Sequence>
      <Sequence from={S.column} durationInFrames={S.montage - S.column}>
        <ColumnWork />
      </Sequence>
      <Sequence from={S.montage} durationInFrames={S.parents - S.montage}>
        <Montage />
      </Sequence>
      <Sequence from={S.parents} durationInFrames={S.stats - S.parents}>
        <Parents />
      </Sequence>
      <Sequence from={S.stats} durationInFrames={S.end - S.stats}>
        <Stats />
      </Sequence>
      <Sequence from={S.end}>
        <EndCard />
      </Sequence>

      {[S.column, S.parents, S.stats].map((at) => (
        <Sequence key={at} from={at - 10} durationInFrames={22}>
          <WipeFor frames={22} />
          <Audio src={staticFile('audio/sfx-whoosh.wav')} volume={0.5} />
        </Sequence>
      ))}

      <Audio src={staticFile('audio/music-overview.wav')} volume={duckedVolume(0.8, voiceAt)} />
    </AbsoluteFill>
  );
};

const WipeFor: React.FC<{frames: number}> = ({frames}) => {
  const frame = useCurrentFrame();
  return <TileWipe progress={frame / frames} />;
};

const Intro: React.FC = () => (
  <AbsoluteFill>
    <Backdrop />
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 56}}>
      <TileRow size={140} delay={4} stagger={5} />
      <Wordmark size={112} delay={40} />
      <PopText text="Math practice that feels like play." size={58} delay={62} weight={800} />
    </AbsoluteFill>
    {[0, 1, 2, 3, 4, 5].map((i) => (
      <Sequence key={i} from={6 + i * 5} durationInFrames={10}>
        <Audio src={staticFile('audio/sfx-pop.wav')} volume={0.45} />
      </Sequence>
    ))}
  </AbsoluteFill>
);

const THEME_FRAMES = 30;

const Themes: React.FC = () => {
  const frame = useCurrentFrame();
  const current = Math.min(themeOrder.length - 1, Math.floor(frame / THEME_FRAMES));
  return (
    <AbsoluteFill>
      {themeOrder.map((theme, i) => (
        <Sequence key={theme} from={i * THEME_FRAMES} durationInFrames={i === themeOrder.length - 1 ? 60 : THEME_FRAMES}>
          <ThemeCut theme={theme} />
          <Audio src={staticFile('audio/sfx-pop.wav')} volume={0.35} />
        </Sequence>
      ))}
      <AbsoluteFill style={{alignItems: 'center', top: 44}}>
        <PopText text="Six worlds to explore" size={76} delay={2} />
      </AbsoluteFill>
      <AbsoluteFill style={{justifyContent: 'flex-end', alignItems: 'center', paddingBottom: 30}}>
        <div style={{display: 'flex', gap: 14}}>
          {themeOrder.map((theme, i) => (
            <div
              key={theme}
              style={{
                width: 18,
                height: 18,
                borderRadius: 9,
                background: i === current ? 'white' : 'rgba(255,255,255,0.4)',
                transform: `scale(${i === current ? 1.25 : 1})`,
              }}
            />
          ))}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const ThemeCut: React.FC<{theme: ThemeKey}> = ({theme}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const info = themes[theme];
  const enter = spring({frame, fps, config: {damping: 14, stiffness: 160}});
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{background: info.primary}}>
        <Img
          src={staticFile(`app/backgrounds/${info.background}.png`)}
          style={{width: '100%', height: '100%', objectFit: 'cover', filter: 'blur(3px) saturate(1.1)', transform: `scale(${1.12 - frame * 0.0015})`}}
        />
        <AbsoluteFill style={{background: `linear-gradient(90deg, ${info.primary}55, transparent 60%)`}} />
      </AbsoluteFill>
      <div style={{position: 'absolute', left: 110, top: 190, transform: `translateX(${(1 - enter) * -80}px)`, opacity: enter}}>
        <Device kind={IPAD} height={760} tilt={6}>
          <RampedClip device={IPAD} scene="testSceneThemes" segments={stretch(moments[IPAD].themes?.[theme] ?? 0, 1.4).segments} />
        </Device>
      </div>
      <div style={{position: 'absolute', right: 90, top: 230, width: 560, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
        <Mascot name={info.mascot} size={430} delay={0} />
        <Caption text={info.name} size={50} delay={3} background={info.primary} color="white" />
      </div>
    </AbsoluteFill>
  );
};

// The forgotten carry: written without it, flagged in red with a note, fixed, solved.
const COLUMN_FRAMES = 6 * BAR;

const ColumnWork: React.FC = () => (
  <SlipScene
    device={IPAD}
    frames={COLUMN_FRAMES}
    deviceHeight={840}
    deviceLeft={70}
    deviceTop={120}
    captionsLeft={1330}
    captionsTop={110}
    captionsWidth={540}
    captionSize={40}
    title={<PopText text="Write it like on paper" size={70} align="left" delay={4} maxWidth={540} />}
  />
);

const Montage: React.FC = () => {
  const ipad = moments[IPAD];
  const teen = ipad.teen;
  const cuts: Array<{theme: ThemeKey; scene: string; timeline: ReturnType<typeof rampTimeline>; ripples?: Array<[number, number, number]>; text: string; emoji: string}> = [
    {
      theme: 'turboCars',
      scene: 'testSceneTeenPlaceValue',
      timeline: teen
        ? rampTimeline(
            [
              {at: teen.bounce, before: 0.2, after: 0.6},
              {at: teen.ten, before: 0.3, after: 0.5},
              {at: teen.one, before: 0.3, after: 0.8},
            ],
            {rate: 1.35, fastRate: 6, holdTo: BAR},
          )
        : stretch(0, 2),
      ripples: teen?.taps,
      text: 'Build numbers from tens and ones',
      emoji: '🧱',
    },
    {
      theme: 'starsSpace',
      scene: 'testSceneSpatial',
      timeline: stretch(ipad.spatial ?? 0, 2, {holdTo: BAR}),
      text: 'Turn, flip and fit shapes',
      emoji: '🔷',
    },
    {
      theme: 'candyland',
      scene: 'testSceneColumnAddition',
      timeline: stretch(ipad.summary ?? 0, 2, {holdTo: BAR}),
      text: 'Rewards to collect',
      emoji: '⭐',
    },
  ];
  return (
    <AbsoluteFill>
      {cuts.map((cut, i) => (
        <Sequence key={cut.scene} from={i * BAR} durationInFrames={BAR}>
          <MontageCut {...cut} />
          <Audio src={staticFile('audio/sfx-pop.wav')} volume={0.35} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};

const MontageCut: React.FC<{
  theme: ThemeKey;
  scene: string;
  timeline: ReturnType<typeof rampTimeline>;
  ripples?: Array<[number, number, number]>;
  text: string;
  emoji: string;
}> = ({theme, scene, timeline, ripples, text, emoji}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const info = themes[theme];
  const enter = spring({frame, fps, config: {damping: 13, stiffness: 170}});
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{background: info.primary}}>
        <Img src={staticFile(`app/backgrounds/${info.background}.png`)} style={{width: '100%', height: '100%', objectFit: 'cover', filter: 'blur(4px)', opacity: 0.85}} />
      </AbsoluteFill>
      <div style={{position: 'absolute', left: 300, top: 70, transform: `scale(${interpolate(enter, [0, 1], [0.85, 1])})`, opacity: enter}}>
        <Device kind={IPAD} height={820}>
          <RampedClip device={IPAD} scene={scene} segments={timeline.segments} ripples={ripples} />
        </Device>
      </div>
      <AbsoluteFill style={{justifyContent: 'flex-end', alignItems: 'center', paddingBottom: 60}}>
        <Caption text={text} size={50} delay={4} emoji={emoji} />
      </AbsoluteFill>
      <div style={{position: 'absolute', right: 40, bottom: 40}}>
        <Mascot name={info.mascot} size={300} delay={6} />
      </div>
    </AbsoluteFill>
  );
};

const Parents: React.FC = () => {
  const gateFrames = BAR;
  const p = moments[IPAD].parent;
  const gate = p
    ? rampTimeline(
        [
          {at: p.pinSheet, before: 0.3, after: 0.9},
          {at: p.pinDone, before: 1.2, after: 0.3},
        ],
        {rate: 1.2, fastRate: 14, holdTo: gateFrames},
      )
    : stretch(0, 2);
  const dashFrames = 4 * BAR;
  const dash = p
    ? rampTimeline(
        [
          {at: p.settings, before: 0.2, after: 0.8},
          {at: p.dashboard, before: 0.3, after: p.footer - p.dashboard + 1.5},
        ],
        {rate: 1.7, fastRate: 14, holdTo: dashFrames},
      )
    : stretch(0, 8);
  const at = (t: number | undefined) => (t === undefined ? 0 : gateFrames + dash.frameOf(t));
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{background: 'linear-gradient(135deg, #1d2135, #33294f)'}} />
      <div style={{position: 'absolute', left: 70, top: 120}}>
        <Device kind={IPAD} height={840}>
          <Sequence from={0} durationInFrames={gateFrames}>
            <Zoom focus={[{from: -20, to: gateFrames + 20, scale: 1.35, x: 0.5, y: 0.45}]}>
              <RampedClip device={IPAD} scene="testSceneParentDashboard" segments={gate.segments} />
            </Zoom>
          </Sequence>
          <Sequence from={gateFrames}>
            {/* The dashboard is a sheet in the middle of the iPad screen; zoom in on it. */}
            <Zoom focus={[{from: -20, to: dashFrames + 20, scale: 1.7, x: 0.5, y: 0.55}]}>
              <RampedClip device={IPAD} scene="testSceneParentDashboard" segments={dash.segments} />
            </Zoom>
          </Sequence>
        </Device>
      </div>
      <div style={{position: 'absolute', left: 1290, top: 120, width: 580, display: 'flex', flexDirection: 'column', gap: 28, alignItems: 'flex-start'}}>
        <PopText text="And for grown-ups" size={68} align="left" delay={2} />
        <Caption text="PIN-protected parent zone" size={36} delay={12} emoji="🔒" />
        <Caption text="Streaks and where to help" size={36} delay={at(p?.dashboard) + 10} emoji="🔥" />
        <Caption text="Skills by math domain" size={36} delay={at(p?.skills)} emoji="📊" />
        <Caption text="Every quest, logged" size={36} delay={at(p?.sessions)} emoji="🗓️" />
      </div>
    </AbsoluteFill>
  );
};

const Stats: React.FC = () => (
  <AbsoluteFill>
    <Backdrop />
    <AbsoluteFill style={{alignItems: 'center', paddingTop: 130, gap: 110, flexDirection: 'column'}}>
      <PopText text="Built on real curriculum" size={84} delay={2} />
      <div style={{display: 'flex', gap: 44}}>
        <StatTile value={0} text="K–5" label="Kindergarten to 5th grade" color={brand.tiles.K} size={360} delay={8} />
        <StatTile value={3000} suffix="+" label="practice questions" color={brand.tiles['2']} size={360} delay={14} />
        <StatTile value={49} label="lesson plans" color={brand.tiles['3']} size={360} delay={20} />
        <StatTile value={0} text="CCSS" label="Common Core aligned" color={brand.tiles['4']} size={360} delay={26} />
      </div>
    </AbsoluteFill>
  </AbsoluteFill>
);

const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const cta = spring({frame: frame - 40, fps, config: {damping: 10, stiffness: 150}});
  return (
    <AbsoluteFill>
      <Backdrop />
      <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 44}}>
        <Wordmark size={120} delay={2} />
        <div style={{display: 'flex', gap: 22}}>
          <Caption text="No ads" size={40} delay={14} emoji="🚫" />
          <Caption text="No accounts" size={40} delay={19} emoji="👤" />
          <Caption text="Works offline" size={40} delay={24} emoji="✈️" />
        </div>
        <div
          style={{
            marginTop: 10,
            padding: '22px 44px',
            borderRadius: 60,
            background: brand.ink,
            color: 'white',
            fontFamily: fonts.display,
            fontWeight: 900,
            fontSize: 50,
            transform: `scale(${interpolate(cta, [0, 1], [0.6, 1])})`,
            opacity: cta,
            boxShadow: '0 16px 40px rgba(20,10,60,0.35)',
          }}
        >
          Join the beta · sproutmath.app
        </div>
      </AbsoluteFill>
      <div style={{position: 'absolute', left: 40, bottom: -20}}>
        <Mascot name="SpaceLuna" size={320} delay={8} />
      </div>
      <div style={{position: 'absolute', right: 40, bottom: -20}}>
        <Mascot name="HeroCaptainCalc" size={320} delay={12} />
      </div>
    </AbsoluteFill>
  );
};
