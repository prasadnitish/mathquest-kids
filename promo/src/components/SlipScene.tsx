import React from 'react';
import {AbsoluteFill, Audio, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {brand} from '../brand';
import {Backdrop, Caption} from './Brand';
import {Device, DeviceKind, RampedClip, Zoom} from './Footage';
import {slipStory} from './slipStory';

const TAP_SOUND_LAG = 0.2;

/**
 * The forgotten carry, told with captions: the device on the left, steps on the right.
 * Captions, tap sounds, the zoom and the app's "You kept trying and solved it!" land on the
 * moments the capture test logged.
 */
export const SlipScene: React.FC<{
  device: DeviceKind;
  frames: number;
  deviceHeight: number;
  deviceLeft: number;
  deviceTop: number;
  captionsLeft: number;
  captionsTop: number;
  captionsWidth: number;
  captionSize: number;
  title?: React.ReactNode;
}> = ({device, frames, deviceHeight, deviceLeft, deviceTop, captionsLeft, captionsTop, captionsWidth, captionSize, title}) => {
  const story = slipStory(device, frames);
  const at = (t: number) => (story ? story.frameOf(t) : 0);
  const coaching = story ? at(story.coaching) : 150;
  const success = story ? at(story.taps.submit) + 12 : 300;
  return (
    <AbsoluteFill>
      <Backdrop from="#ffb86b" to="#ff6fae" />
      <div style={{position: 'absolute', left: deviceLeft, top: deviceTop}}>
        <Device kind={device} height={deviceHeight}>
          {story ? (
            <Zoom focus={[{from: at(story.taps.wrongSubmit) - 4, to: at(story.taps.fixDigit) + 30, scale: 1.45, x: story.zoom.x, y: story.zoom.y + 0.04}]}>
              <RampedClip device={device} scene="testSceneColumnAddition" segments={story.segments} />
            </Zoom>
          ) : (
            <RampedClip device={device} scene="testSceneColumnAddition" segments={[]} />
          )}
        </Device>
        <Sequence from={success} layout="none">
          <SuccessBurst size={deviceHeight * 0.3} />
        </Sequence>
      </div>
      <div
        style={{
          position: 'absolute',
          left: captionsLeft,
          top: captionsTop,
          width: captionsWidth,
          display: 'flex',
          flexDirection: 'column',
          gap: captionSize * 0.6,
          alignItems: 'flex-start',
        }}
      >
        {title}
        <Caption text="Ones first" size={captionSize} delay={story ? at(story.taps.ones) : 20} emoji="✏️" />
        <Caption text="Then the tens" size={captionSize} delay={story ? at(story.taps.tens) : 50} emoji="➡️" />
        <Caption text="Forgot the carried 1?" size={captionSize} delay={story ? at(story.taps.wrongSubmit) : 90} emoji="🤔" />
        <Caption text="It shows exactly where" size={captionSize} delay={coaching} background="#ffe3e3" color="#b3261e" emoji="🔍" />
        <Caption text="Carry the 1, fix the tens" size={captionSize} delay={story ? at(story.taps.carry) : 200} emoji="🛠️" />
        <Caption text="Solved!" size={captionSize * 1.25} delay={success} background={brand.sprout} color="white" emoji="🎉" />
      </div>
      {story?.tapTimes
        .map((t) => story.frameOf(t + TAP_SOUND_LAG))
        .filter((f) => f > 0 && f < frames)
        .map((f, i) => (
          <Sequence key={i} from={f} durationInFrames={8}>
            <Audio src={staticFile('audio/sfx-tap.wav')} volume={0.35} />
          </Sequence>
        ))}
      <Sequence from={success} durationInFrames={60}>
        <Audio src={staticFile('audio/sfx-ding.wav')} volume={0.5} />
      </Sequence>
      <Sequence from={success + 8} durationInFrames={90}>
        <Audio src={staticFile('app/voice/voice-kept-trying.mp3')} volume={1} />
      </Sequence>
    </AbsoluteFill>
  );
};

/** When the app's voice line starts in a SlipScene, for ducking the music under it. */
export function slipVoiceFrame(device: DeviceKind, frames: number) {
  const story = slipStory(device, frames);
  return story ? story.frameOf(story.taps.submit) + 12 + 8 : undefined;
}

/** A green check that pops over the device, with confetti in the K-5 tile colors. */
const SuccessBurst: React.FC<{size: number}> = ({size}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const pop = spring({frame, fps, config: {damping: 9, stiffness: 180}});
  const colors = Object.values(brand.tiles);
  return (
    <div style={{position: 'absolute', left: '50%', top: '42%', width: 0, height: 0}}>
      {Array.from({length: 18}).map((_, i) => {
        const angle = (i / 18) * Math.PI * 2 + (i % 3) * 0.2;
        const distance = interpolate(frame, [0, 24], [0, size * (1.1 + (i % 4) * 0.18)], {extrapolateRight: 'clamp'});
        const fall = interpolate(frame, [10, 60], [0, size * 0.5], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
        const fade = interpolate(frame, [30, 60], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
        const piece = size * 0.09;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: Math.cos(angle) * distance - piece / 2,
              top: Math.sin(angle) * distance + fall - piece / 2,
              width: piece,
              height: piece * (i % 2 ? 1 : 0.55),
              borderRadius: piece * 0.2,
              background: colors[i % colors.length],
              opacity: fade,
              transform: `rotate(${frame * (8 + i) + i * 40}deg)`,
            }}
          />
        );
      })}
      <div
        style={{
          position: 'absolute',
          left: -size / 2,
          top: -size / 2,
          width: size,
          height: size,
          borderRadius: size / 2,
          background: brand.sprout,
          border: `${size * 0.06}px solid white`,
          boxShadow: '0 18px 40px rgba(20,60,10,0.35)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: 'white',
          fontSize: size * 0.6,
          fontWeight: 900,
          transform: `scale(${interpolate(pop, [0, 1], [0.2, 1])})`,
          opacity: interpolate(frame, [0, 3, 50, 60], [0, 1, 1, 0], {extrapolateRight: 'clamp'}),
        }}
      >
        ✓
      </div>
    </div>
  );
};
