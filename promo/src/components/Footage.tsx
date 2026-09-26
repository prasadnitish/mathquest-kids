import React from 'react';
import {AbsoluteFill, OffthreadVideo, Sequence, interpolate, staticFile, useCurrentFrame, useVideoConfig, Easing} from 'remotion';
import footageIndex from '../footage.json';
import {fonts} from '../brand';

export type DeviceKind = 'iphone-standard' | 'ipad-standard';

type SceneFootage = {
  file: string;
  duration: number;
  width: number;
  height: number;
  marks: Record<string, number>;
  taps: Array<[number, number, number]>;
};

const index = footageIndex as unknown as Record<string, Record<string, SceneFootage>>;

// A tap is logged just before XCUITest sends it; the touch lands a moment later.
const TAP_LAG = 0.15;

export function sceneFootage(device: DeviceKind, scene: string): SceneFootage | undefined {
  return index[device]?.[scene];
}

/** Seconds into the scene's video where `mark` happened, or undefined. */
export function markTime(device: DeviceKind, scene: string, mark: string): number | undefined {
  return sceneFootage(device, scene)?.marks[mark];
}

/** A zoom onto part of the screen: from `from` to `to` (clip frames), centered on x, y (fractions). */
export type Focus = {from: number; to: number; scale: number; x: number; y: number};

export type ClipProps = {
  device: DeviceKind;
  scene: string;
  mark: string;
  /** Seconds after the mark to start (negative starts before it). */
  offset?: number;
  rate?: number;
  focus?: Focus[];
  taps?: boolean;
};

/** Plays a scene's recording from a mark, with a ripple wherever the test tapped. */
export const Clip: React.FC<ClipProps> = ({device, scene, mark, offset = 0, rate = 1, focus = [], taps = true}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const footage = sceneFootage(device, scene);
  const at = footage?.marks[mark];
  if (!footage || at === undefined) {
    return <Placeholder label={`${device} · ${scene} · ${mark}`} />;
  }
  const start = Math.max(0, at + offset);
  const sourceTime = start + (frame / fps) * rate;

  // Zoom: ease between focus keyframes; outside them, full frame.
  let scale = 1;
  let cx = 0.5;
  let cy = 0.5;
  for (const f of focus) {
    const ramp = 10;
    const inT = interpolate(frame, [f.from, f.from + ramp], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.inOut(Easing.cubic)});
    const outT = interpolate(frame, [f.to - ramp, f.to], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.inOut(Easing.cubic)});
    const t = Math.min(inT, outT);
    if (t > 0) {
      scale = 1 + (f.scale - 1) * t;
      cx = 0.5 + (f.x - 0.5) * t;
      cy = 0.5 + (f.y - 0.5) * t;
    }
  }
  // Keep the zoomed frame inside the screen.
  const half = 0.5 / scale;
  cx = Math.min(1 - half, Math.max(half, cx));
  cy = Math.min(1 - half, Math.max(half, cy));

  return (
    <AbsoluteFill style={{overflow: 'hidden', background: 'black'}}>
      <AbsoluteFill
        style={{
          transformOrigin: '0 0',
          transform: `translate(${(0.5 - cx * scale) * 100}%, ${(0.5 - cy * scale) * 100}%) scale(${scale})`,
        }}
      >
        <OffthreadVideo
          src={staticFile(footage.file)}
          trimBefore={Math.round(start * fps)}
          playbackRate={rate}
          muted
          style={{width: '100%', height: '100%', objectFit: 'cover'}}
        />
        {taps &&
          footage.taps.map(([x, y, t], i) => {
            const local = ((t + TAP_LAG - sourceTime) * fps) / rate;
            // local is how many frames until the tap; show it for 14 frames after.
            const age = -local;
            if (age < -2 || age > 14) {
              return null;
            }
            return <Ripple key={i} x={x} y={y} age={age} />;
          })}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const Ripple: React.FC<{x: number; y: number; age: number}> = ({x, y, age}) => {
  const {width} = useVideoConfig();
  const size = width * 0.05;
  const press = interpolate(age, [-2, 0, 4, 14], [0, 1, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const ring = interpolate(age, [0, 14], [0.5, 1.8], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const ringOpacity = interpolate(age, [0, 14], [0.8, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <div style={{position: 'absolute', left: `${x * 100}%`, top: `${y * 100}%`, width: 0, height: 0}}>
      <div
        style={{
          position: 'absolute',
          width: size,
          height: size,
          left: -size / 2,
          top: -size / 2,
          borderRadius: '50%',
          background: 'rgba(255,255,255,0.55)',
          border: '3px solid rgba(90,70,200,0.55)',
          opacity: press,
          transform: `scale(${0.8 + press * 0.2})`,
        }}
      />
      <div
        style={{
          position: 'absolute',
          width: size,
          height: size,
          left: -size / 2,
          top: -size / 2,
          borderRadius: '50%',
          border: '4px solid rgba(255,255,255,0.9)',
          opacity: ringOpacity,
          transform: `scale(${ring})`,
        }}
      />
    </div>
  );
};

const Placeholder: React.FC<{label: string}> = ({label}) => (
  <AbsoluteFill
    style={{
      background: 'linear-gradient(160deg, #e9e4ff, #cfe0ff)',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: fonts.body,
      fontWeight: 700,
      color: '#4a3fa0',
      fontSize: 22,
      textAlign: 'center',
      padding: 20,
    }}
  >
    {label}
  </AbsoluteFill>
);

/** A phone or tablet around a clip. `height` sets the size; the screen keeps the footage's shape. */
export const Device: React.FC<{
  kind: DeviceKind;
  height: number;
  children: React.ReactNode;
  tilt?: number;
  style?: React.CSSProperties;
}> = ({kind, height, children, tilt = 0, style}) => {
  const phone = kind === 'iphone-standard';
  // Screen shapes: iPhone 17 portrait, iPad (A16) landscape.
  const aspect = phone ? 1206 / 2622 : 2360 / 1640;
  const bezel = phone ? height * 0.018 : height * 0.03;
  const screenH = height - bezel * 2;
  const screenW = screenH * aspect;
  const radius = phone ? screenW * 0.14 : screenH * 0.045;
  return (
    <div
      style={{
        width: screenW + bezel * 2,
        height,
        padding: bezel,
        borderRadius: radius + bezel,
        background: 'linear-gradient(145deg, #3a3a44, #0d0d12 40%, #24242c)',
        boxShadow: `0 ${height * 0.04}px ${height * 0.08}px rgba(15,5,50,0.45), inset 0 0 0 ${Math.max(2, bezel * 0.18)}px rgba(255,255,255,0.08)`,
        transform: `perspective(2400px) rotateY(${tilt}deg)`,
        ...style,
      }}
    >
      <div style={{position: 'relative', width: screenW, height: screenH, borderRadius: radius, overflow: 'hidden', background: 'black'}}>
        {children}
        {phone ? (
          <div
            style={{
              position: 'absolute',
              top: screenH * 0.013,
              left: '50%',
              width: screenW * 0.3,
              height: screenH * 0.017,
              marginLeft: -screenW * 0.15,
              borderRadius: screenH,
              background: 'black',
            }}
          />
        ) : null}
      </div>
    </div>
  );
};

/**
 * Where a clip starts in its video and how its source times map to frames of the clip,
 * so captions and sounds can land on the moments the test logged.
 */
export function clipTiming(device: DeviceKind, scene: string, mark: string, offset = 0, rate = 1, fps = 30) {
  const footage = sceneFootage(device, scene);
  const at = footage?.marks[mark];
  const start = at === undefined ? undefined : Math.max(0, at + offset);
  const frameOf = (sourceTime: number | undefined) =>
    start === undefined || sourceTime === undefined ? undefined : Math.round(((sourceTime - start) / rate) * fps);
  const tapFrames = (from: number, to: number) =>
    (footage?.taps ?? [])
      .map(([, , t]) => frameOf(t + TAP_LAG))
      .filter((f): f is number => f !== undefined && f >= from && f < to);
  const tapsBetween = (fromSource: number, toSource: number) =>
    (footage?.taps ?? []).filter(([, , t]) => t >= fromSource && t <= toSource);
  return {found: start !== undefined, start: start ?? 0, frameOf, tapFrames, tapsBetween, marks: footage?.marks ?? {}};
}

/** A moment to show at normal speed: from `before` seconds before `at` to `after` seconds after. */
export type Moment = {at: number; before?: number; after?: number};

type Segment = {from: number; frames: number; start: number; rate: number};

/**
 * A speed-ramped timeline through a recording: each moment plays at `rate`, and the waits
 * between them (the test pausing for the app to settle) run at `fastRate`. The screen is
 * still during those waits, so the speed-up doesn't show; it just keeps the edit moving.
 */
export function rampTimeline(moments: Moment[], {rate = 1, fastRate = 5, fps = 30, holdTo = 0} = {}) {
  const windows = moments
    .map((m) => ({start: m.at - (m.before ?? 0.4), end: m.at + (m.after ?? 0.9)}))
    .sort((a, b) => a.start - b.start);
  const merged: Array<{start: number; end: number}> = [];
  for (const w of windows) {
    const last = merged[merged.length - 1];
    if (last && w.start <= last.end + 0.25) {
      last.end = Math.max(last.end, w.end);
    } else {
      merged.push({...w});
    }
  }
  const segments: Segment[] = [];
  let frame = 0;
  const push = (start: number, end: number, r: number) => {
    const frames = Math.max(1, Math.round(((end - start) / r) * fps));
    segments.push({from: frame, frames, start, rate: r});
    frame += frames;
  };
  merged.forEach((w, i) => {
    push(w.start, w.end, rate);
    const next = merged[i + 1];
    if (next && next.start > w.end) {
      push(w.end, next.start, fastRate);
    }
  });
  // Hold the last moment (a crawl, since a video can't play at rate 0) out to `holdTo` frames.
  const last = merged[merged.length - 1];
  if (last && holdTo > frame) {
    const crawl = 0.02;
    segments.push({from: frame, frames: holdTo - frame, start: last.end, rate: crawl});
    frame = holdTo;
  }
  const frameOf = (sourceTime: number) => {
    for (const s of segments) {
      const end = s.start + (s.frames / fps) * s.rate;
      if (sourceTime >= s.start && sourceTime <= end) {
        return s.from + Math.round(((sourceTime - s.start) / s.rate) * fps);
      }
    }
    return sourceTime < (segments[0]?.start ?? 0) ? 0 : frame;
  };
  return {segments, totalFrames: frame, frameOf};
}

/** Plays a scene through a ramped timeline (see rampTimeline). */
export const RampedClip: React.FC<{device: DeviceKind; scene: string; segments: Segment[]}> = ({device, scene, segments}) => {
  if (!sceneFootage(device, scene) || segments.length === 0) {
    return <Placeholder label={`${device} · ${scene}`} />;
  }
  return (
    <AbsoluteFill style={{background: 'black'}}>
      {segments.map((segment, i) => (
        <Sequence key={i} from={segment.from} durationInFrames={segment.frames}>
          <SegmentClip device={device} scene={scene} start={segment.start} rate={segment.rate} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};

/** A zoom onto part of the screen for whatever it wraps (see Focus). */
export const Zoom: React.FC<{focus: Focus[]; children: React.ReactNode}> = ({focus, children}) => {
  const frame = useCurrentFrame();
  let scale = 1;
  let cx = 0.5;
  let cy = 0.5;
  for (const f of focus) {
    const ramp = 10;
    const inT = interpolate(frame, [f.from, f.from + ramp], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.inOut(Easing.cubic)});
    const outT = interpolate(frame, [f.to - ramp, f.to], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.inOut(Easing.cubic)});
    const t = Math.min(inT, outT);
    if (t > 0) {
      scale = 1 + (f.scale - 1) * t;
      cx = 0.5 + (f.x - 0.5) * t;
      cy = 0.5 + (f.y - 0.5) * t;
    }
  }
  const half = 0.5 / scale;
  cx = Math.min(1 - half, Math.max(half, cx));
  cy = Math.min(1 - half, Math.max(half, cy));
  return (
    <AbsoluteFill style={{overflow: 'hidden'}}>
      <AbsoluteFill style={{transformOrigin: '0 0', transform: `translate(${(0.5 - cx * scale) * 100}%, ${(0.5 - cy * scale) * 100}%) scale(${scale})`}}>
        {children}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

/** The video from `start` seconds at `rate`, with tap ripples. */
const SegmentClip: React.FC<{device: DeviceKind; scene: string; start: number; rate: number}> = ({device, scene, start, rate}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const footage = sceneFootage(device, scene)!;
  const sourceTime = start + (frame / fps) * rate;
  return (
    <AbsoluteFill style={{background: 'black'}}>
      <OffthreadVideo
        src={staticFile(footage.file)}
        trimBefore={Math.round(start * fps)}
        playbackRate={rate}
        muted
        style={{width: '100%', height: '100%', objectFit: 'cover'}}
      />
      {footage.taps.map(([x, y, t], i) => {
        const age = ((sourceTime - t - TAP_LAG) * fps) / Math.max(1, rate);
        if (age < -2 || age > 14) {
          return null;
        }
        return <Ripple key={i} x={x} y={y} age={age} />;
      })}
    </AbsoluteFill>
  );
};
