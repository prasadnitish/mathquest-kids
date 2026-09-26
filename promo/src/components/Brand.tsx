import React from 'react';
import {AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {brand, fonts} from '../brand';

/** The icon's purple-to-blue sky, slowly shifting, with math symbols drifting up. */
export const Backdrop: React.FC<{from?: string; to?: string; symbols?: boolean}> = ({
  from = brand.purple,
  to = brand.blue,
  symbols = true,
}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const angle = 135 + Math.sin(frame / 90) * 12;
  const glyphs = ['+', '−', '×', '=', '3', '7', '½', '5', '+', '9', '÷', '2'];
  return (
    <AbsoluteFill style={{background: `linear-gradient(${angle}deg, ${from}, ${to})`, overflow: 'hidden'}}>
      <AbsoluteFill
        style={{
          background: `radial-gradient(circle at ${50 + Math.sin(frame / 70) * 10}% 45%, rgba(255,255,255,0.28), transparent 55%)`,
        }}
      />
      {symbols &&
        glyphs.map((glyph, i) => {
          const speed = 0.6 + ((i * 37) % 10) / 10;
          const x = ((i * 173) % 100) / 100;
          const y = 1.1 - (((frame * speed) / height + (i * 0.37) % 1) % 1.25);
          return (
            <div
              key={i}
              style={{
                position: 'absolute',
                left: x * width,
                top: y * height,
                fontFamily: fonts.display,
                fontWeight: 900,
                fontSize: Math.min(width, height) * (0.05 + ((i * 29) % 7) / 100),
                color: 'rgba(255,255,255,0.13)',
                transform: `rotate(${Math.sin((frame + i * 20) / 40) * 15}deg)`,
              }}
            >
              {glyph}
            </div>
          );
        })}
    </AbsoluteFill>
  );
};

/** A glossy rounded tile like the K-5 tiles on the app icon. */
export const Tile: React.FC<{label: string; color: string; size: number; style?: React.CSSProperties}> = ({
  label,
  color,
  size,
  style,
}) => (
  <div
    style={{
      width: size,
      height: size,
      borderRadius: size * 0.22,
      background: `linear-gradient(160deg, rgba(255,255,255,0.35), rgba(255,255,255,0) 45%), ${color}`,
      boxShadow: `0 ${size * 0.08}px 0 rgba(0,0,0,0.18), 0 ${size * 0.14}px ${size * 0.2}px rgba(20,10,60,0.25), inset 0 -${size * 0.06}px 0 rgba(0,0,0,0.12)`,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: fonts.display,
      fontWeight: 900,
      fontSize: size * 0.62,
      color: 'white',
      textShadow: `0 ${size * 0.03}px 0 rgba(0,0,0,0.18)`,
      ...style,
    }}
  >
    {label}
  </div>
);

/** K 1 2 3 4 5 dropping in one after another with a bounce. */
export const TileRow: React.FC<{size: number; delay?: number; stagger?: number; gap?: number}> = ({
  size,
  delay = 0,
  stagger = 5,
  gap = 0.25,
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const labels = ['K', '1', '2', '3', '4', '5'];
  return (
    <div style={{display: 'flex', gap: size * gap}}>
      {labels.map((label, i) => {
        const t = spring({frame: frame - delay - i * stagger, fps, config: {damping: 9, stiffness: 140, mass: 0.7}});
        const wobble = Math.sin((frame - i * 7) / 12) * 3 * Math.min(1, t);
        return (
          <Tile
            key={label}
            label={label}
            color={brand.tiles[label]}
            size={size}
            style={{
              transform: `translateY(${interpolate(t, [0, 1], [-size * 3, 0])}px) rotate(${(i % 2 ? 1 : -1) * 6 + wobble}deg)`,
              opacity: t > 0.01 ? 1 : 0,
            }}
          />
        );
      })}
    </div>
  );
};

/** Words that pop in one at a time. */
export const PopText: React.FC<{
  text: string;
  size: number;
  delay?: number;
  stagger?: number;
  color?: string;
  weight?: number;
  align?: 'left' | 'center';
  shadow?: boolean;
  maxWidth?: number;
}> = ({text, size, delay = 0, stagger = 3, color = 'white', weight = 900, align = 'center', shadow = true, maxWidth}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const words = text.split(' ');
  return (
    <div
      style={{
        display: 'flex',
        flexWrap: 'wrap',
        justifyContent: align === 'center' ? 'center' : 'flex-start',
        columnGap: size * 0.28,
        rowGap: size * 0.05,
        maxWidth,
        fontFamily: fonts.display,
        fontWeight: weight,
        fontSize: size,
        lineHeight: 1.08,
        color,
        textShadow: shadow ? `0 ${size * 0.05}px ${size * 0.12}px rgba(30,10,80,0.35)` : undefined,
      }}
    >
      {words.map((word, i) => {
        const t = spring({frame: frame - delay - i * stagger, fps, config: {damping: 11, stiffness: 170}});
        return (
          <span
            key={i}
            style={{
              display: 'inline-block',
              transform: `translateY(${(1 - t) * size * 0.5}px) scale(${interpolate(t, [0, 1], [0.6, 1])})`,
              opacity: Math.min(1, t * 1.5),
            }}
          >
            {word}
          </span>
        );
      })}
    </div>
  );
};

/** A bold caption pill that bounces in. */
export const Caption: React.FC<{
  text: string;
  size: number;
  delay?: number;
  color?: string;
  background?: string;
  emoji?: string;
  out?: number;
}> = ({text, size, delay = 0, color = brand.ink, background = 'white', emoji, out}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = spring({frame: frame - delay, fps, config: {damping: 12, stiffness: 180}});
  const leave = out === undefined ? 0 : spring({frame: frame - out, fps, config: {damping: 20, stiffness: 200}});
  const scale = interpolate(t, [0, 1], [0.5, 1]) * (1 - leave * 0.4);
  return (
    <div
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: size * 0.4,
        padding: `${size * 0.42}px ${size * 0.8}px`,
        borderRadius: size * 2,
        background,
        color,
        fontFamily: fonts.display,
        fontWeight: 900,
        fontSize: size,
        lineHeight: 1.1,
        boxShadow: `0 ${size * 0.25}px ${size * 0.6}px rgba(25,10,70,0.28)`,
        transform: `scale(${scale}) rotate(${(1 - t) * -4}deg)`,
        opacity: Math.min(1, t * 1.6) * (1 - leave),
      }}
    >
      {emoji ? <span>{emoji}</span> : null}
      <span>{text}</span>
    </div>
  );
};

/** A mascot from the app popping in, then bobbing. */
export const Mascot: React.FC<{name: string; size: number; delay?: number; flip?: boolean; style?: React.CSSProperties}> = ({
  name,
  size,
  delay = 0,
  flip = false,
  style,
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = spring({frame: frame - delay, fps, config: {damping: 8, stiffness: 120}});
  const bob = Math.sin((frame - delay) / 9) * size * 0.02 * t;
  return (
    <Img
      src={staticFile(`app/characters/${name}.png`)}
      style={{
        width: size,
        height: size,
        objectFit: 'contain',
        transform: `translateY(${(1 - t) * size * 0.6 + bob}px) scale(${interpolate(t, [0, 1], [0.3, 1])}) scaleX(${flip ? -1 : 1}) rotate(${(1 - t) * 20}deg)`,
        opacity: t > 0.02 ? 1 : 0,
        filter: 'drop-shadow(0 18px 24px rgba(20,10,60,0.3))',
        ...style,
      }}
    />
  );
};

/** The app icon and name. */
export const Wordmark: React.FC<{size: number; delay?: number; color?: string}> = ({size, delay = 0, color = 'white'}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = spring({frame: frame - delay, fps, config: {damping: 10, stiffness: 130}});
  return (
    <div style={{display: 'flex', alignItems: 'center', gap: size * 0.3, transform: `scale(${interpolate(t, [0, 1], [0.7, 1])})`, opacity: t}}>
      <Img
        src={staticFile('app/icon.png')}
        style={{width: size * 1.25, height: size * 1.25, borderRadius: size * 0.3, boxShadow: '0 16px 40px rgba(20,10,60,0.35)'}}
      />
      <div style={{fontFamily: fonts.display, fontWeight: 900, fontSize: size, color, letterSpacing: -size * 0.01, textShadow: '0 6px 18px rgba(30,10,80,0.35)'}}>
        Sprout Math
      </div>
    </div>
  );
};

/** A number that counts up, with a label, on a tile. */
export const StatTile: React.FC<{
  value: number;
  prefix?: string;
  suffix?: string;
  label: string;
  color: string;
  size: number;
  delay?: number;
  text?: string;
}> = ({value, prefix = '', suffix = '', label, color, size, delay = 0, text}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = spring({frame: frame - delay, fps, config: {damping: 10, stiffness: 140}});
  const count = interpolate(frame - delay, [0, 24], [0, value], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const shown = text ?? `${prefix}${Math.round(count).toLocaleString('en-US')}${suffix}`;
  return (
    <div
      style={{
        width: size,
        padding: `${size * 0.12}px ${size * 0.08}px`,
        borderRadius: size * 0.16,
        background: `linear-gradient(160deg, rgba(255,255,255,0.3), rgba(255,255,255,0) 50%), ${color}`,
        boxShadow: `0 ${size * 0.05}px 0 rgba(0,0,0,0.18), 0 ${size * 0.1}px ${size * 0.2}px rgba(20,10,60,0.25)`,
        color: 'white',
        textAlign: 'center',
        transform: `translateY(${(1 - t) * size * 0.8}px) scale(${interpolate(t, [0, 1], [0.6, 1])})`,
        opacity: t > 0.02 ? 1 : 0,
      }}
    >
      <div style={{fontFamily: fonts.display, fontWeight: 900, fontSize: size * 0.3, lineHeight: 1}}>{shown}</div>
      <div style={{fontFamily: fonts.body, fontWeight: 700, fontSize: size * 0.1, marginTop: size * 0.05, lineHeight: 1.15}}>{label}</div>
    </div>
  );
};

/** A sweep of colored tiles across the frame, covering a cut. `progress` 0..1. */
export const TileWipe: React.FC<{progress: number}> = ({progress}) => {
  const {width, height} = useVideoConfig();
  const colors = Object.values(brand.tiles);
  const columns = 6;
  const w = width / columns;
  return (
    <AbsoluteFill style={{pointerEvents: 'none'}}>
      {colors.map((color, i) => {
        const local = interpolate(progress, [i * 0.06, 0.5 + i * 0.06], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
        const leave = interpolate(progress, [0.5 + i * 0.03, 1], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
        const y = interpolate(local, [0, 1], [-height * 1.1, 0]) + leave * height * 1.1;
        return (
          <div
            key={i}
            style={{position: 'absolute', left: i * w - 1, top: y, width: w + 2, height, background: color, borderRadius: w * 0.2}}
          />
        );
      })}
    </AbsoluteFill>
  );
};
