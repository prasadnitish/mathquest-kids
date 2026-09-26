import {continueRender, delayRender, staticFile} from 'remotion';

// Colors from the app icon: a purple-to-blue sky and the rainbow K-5 tiles.
export const brand = {
  purple: '#8b6cf6',
  violet: '#6d5ce8',
  blue: '#5b8def',
  ink: '#1f1a3d',
  cream: '#fff8ec',
  sprout: '#4fbf3a',
  tiles: {
    K: '#e2498a',
    '1': '#f0512f',
    '2': '#f7a21b',
    '3': '#4fb840',
    '4': '#2f7fea',
    '5': '#8a4fe0',
  } as Record<string, string>,
};

export type ThemeKey = 'candyland' | 'axolotl' | 'rainbowUnicorn' | 'starsSpace' | 'superhero' | 'turboCars';

// The app's six themes: name, colors (from AppTheme.swift), painted background and a mascot.
export const themes: Record<ThemeKey, {name: string; primary: string; accent: string; background: string; mascot: string}> = {
  candyland: {name: 'Candyland', primary: '#db4791', accent: '#ffc45c', background: 'CandylandBackgroundV2', mascot: 'CandyBenny'},
  axolotl: {name: 'Axolotl Lagoon', primary: '#298aa1', accent: '#ff94b8', background: 'AxolotlBackground', mascot: 'ReefCoral'},
  rainbowUnicorn: {name: 'Rainbow Unicorn', primary: '#8f57e0', accent: '#f782b3', background: 'RainbowUnicornBackground', mascot: 'UnicornSparkle'},
  starsSpace: {name: 'Stars and Space', primary: '#404dbd', accent: '#7ae6f0', background: 'StarsSpaceBackgroundV2', mascot: 'SpaceLuna'},
  superhero: {name: 'Superhero City', primary: '#cc2e2e', accent: '#3380e6', background: 'SuperheroBackground', mascot: 'HeroCaptainCalc'},
  turboCars: {name: 'Turbo Cars', primary: '#d16b0d', accent: '#33bf4d', background: 'TurboCarsBackground', mascot: 'TurboRevRacer'},
};

export const themeOrder: ThemeKey[] = ['candyland', 'axolotl', 'rainbowUnicorn', 'starsSpace', 'superhero', 'turboCars'];

export const fonts = {
  display: "'Nunito', 'DM Sans', sans-serif",
  body: "'DM Sans', 'Nunito', sans-serif",
};

// Load the app's own fonts before any frame renders.
const fontFaces: Array<[string, string, string]> = [
  ['Nunito', 'Nunito-Black.ttf', '900'],
  ['Nunito', 'Nunito-ExtraBold.ttf', '800'],
  ['Nunito', 'Nunito-Bold.ttf', '700'],
  ['DM Sans', 'DMSans-Bold.ttf', '700'],
  ['DM Sans', 'DMSans-Medium.ttf', '500'],
];

if (typeof document !== 'undefined' && typeof FontFace !== 'undefined') {
  const handle = delayRender('Loading fonts');
  Promise.all(
    fontFaces.map(([family, file, weight]) =>
      new FontFace(family, `url(${staticFile(`app/fonts/${file}`)})`, {weight}).load().then((face) => {
        document.fonts.add(face);
      }),
    ),
  )
    .then(() => continueRender(handle))
    .catch((error) => {
      console.error(error);
      continueRender(handle);
    });
}

export const FPS = 30;
// The music runs at 120 BPM: a beat is 15 frames and a bar 60.
export const BEAT = 15;
export const BAR = 60;

/** Music volume that dips under a voice clip starting at `voiceAt` (frames), so the voice reads clearly. */
export function duckedVolume(base: number, voiceAt: number | undefined, voiceFrames = 75) {
  return (frame: number) => {
    if (voiceAt === undefined) {
      return base;
    }
    const into = frame - voiceAt;
    if (into < -8 || into > voiceFrames + 8) {
      return base;
    }
    const dip = into < 0 ? (into + 8) / 8 : into > voiceFrames ? 1 - (into - voiceFrames) / 8 : 1;
    return base * (1 - 0.6 * dip);
  };
}
