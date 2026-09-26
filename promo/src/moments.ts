import type {DeviceKind} from './components/Footage';

/**
 * When things happen in the footage, in seconds into each scene's video, read off the frames.
 *
 * The simulator's recorder drops time while the screen is still (an idle Home Screen, or on
 * iPad a quiet quest screen), so a scene's step log can run up to 20 seconds ahead of its
 * video, by an amount that grows through the scene. These anchors come from looking at the
 * frames themselves (contact sheets at 0.25 to 2 second steps), so the cuts land on what's
 * actually on screen. Taps carry the screen position from the step log.
 */
export type Tap = [x: number, y: number, t: number];

export type SlipMoments = {
  ones: number;
  tens: number;
  wrongSubmit: number;
  coaching: number;
  carry: number;
  tensBox: number;
  fixDigit: number;
  submit: number;
  /** Where each of those taps landed, in the same order (x, y as screen fractions). */
  positions: Array<[number, number]>;
};

export const moments: Record<
  DeviceKind,
  {
    slip?: SlipMoments;
    themes?: Record<string, number>;
    teen?: {bounce: number; ten: number; one: number; taps: Tap[]};
    summary?: number;
    spatial?: number;
    trade?: {trade: number; ones: number; tens: number; submit: number; taps: Tap[]};
    parent?: {home: number; pinSheet: number; pinDone: number; settings: number; dashboard: number; skills: number; sessions: number; footer: number};
  }
> = {
  'ipad-standard': {
    // 47 + 36: the 3, the 7 without the carry, the grey-out and red note, the carried 1,
    // the tens box, the 8, "Great adding!". The next question slides in at 95.5.
    slip: {
      ones: 74.4,
      tens: 76.0,
      wrongSubmit: 79.0,
      coaching: 80.0,
      carry: 85.0,
      tensBox: 89.5,
      fixDigit: 92.0,
      submit: 94.0,
      positions: [
        [0.6186, 0.5268],
        [0.5559, 0.6171],
        [0.5, 0.8936],
        [0.3644, 0.5616],
        [0.3644, 0.8128],
        [0.6186, 0.4585],
        [0.5, 0.8936],
      ],
    },
    // Home in each theme, a moment after it appears (black launch frames come between).
    themes: {candyland: 67.5, axolotl: 91.5, rainbowUnicorn: 115.5, starsSpace: 139.5, superhero: 169.5, turboCars: 193.5},
    // "Show 11 as tens and ones": the big buttons waiting (bouncing), a ten, a one.
    teen: {
      bounce: 46.5,
      ten: 50.8,
      one: 53.8,
      taps: [
        [0.3059, 0.3598, 50.6],
        [0.7653, 0.3598, 53.6],
      ],
    },
    // "Quest Complete" with the reward star.
    summary: 130.4,
    // "Which choice matches the red triangle after it turns 135 degrees?"
    spatial: 49.0,
    // On iPad the parent screens are sheets over Home: the PIN sheet, the on-screen
    // keyboard as the PIN is typed, Parent Settings, then the dashboard scrolling.
    parent: {home: 28.5, pinSheet: 34.0, pinDone: 55.0, settings: 57.5, dashboard: 78.0, skills: 87.5, sessions: 96.5, footer: 103.5},
  },
  'iphone-standard': {
    // The trade in 72 - 45: tens crossed to 6 with 12 ones, the 7, the 2, done.
    trade: {
      trade: 116.9,
      ones: 119.8,
      tens: 121.9,
      submit: 124.9,
      taps: [
        [0.5, 0.2021, 116.6],
        [0.3657, 0.5988, 119.5],
        [0.3657, 0.4687, 121.6],
        [0.5, 0.8842, 124.6],
      ],
    },
    // Home, the PIN sheet, the four dots filled, Parent Settings, then the dashboard: the
    // streak and "needs attention" at the top, skills by domain, recent sessions, the
    // Common Core footer.
    parent: {home: 52.5, pinSheet: 57.0, pinDone: 85.5, settings: 88.5, dashboard: 104.0, skills: 110.0, sessions: 114.0, footer: 124.0},
  },
};
