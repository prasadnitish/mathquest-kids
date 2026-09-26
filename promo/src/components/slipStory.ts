import {DeviceKind, Moment, rampTimeline, sceneFootage} from './Footage';
import {moments as anchors, SlipMoments} from '../moments';

// A tap shows on screen about this long after the step log records it (on iPhone, where the
// log and video stay in step).
const VISUAL_LAG = 0.7;

/** The slip's moments as seen in the video: anchored by hand, or from the step log. */
function slipMoments(device: DeviceKind): SlipMoments | undefined {
  const anchored = anchors[device]?.slip;
  if (anchored) {
    return anchored;
  }
  const footage = sceneFootage(device, 'testSceneColumnAddition');
  const marks = footage?.marks ?? {};
  const start = marks['slip-start'];
  const coaching = marks['slip-coaching'];
  const fixed = marks['slip-fixed'];
  if (!footage || start === undefined || coaching === undefined || fixed === undefined) {
    return undefined;
  }
  const taps = footage.taps;
  const between = (a: number, b: number) => taps.filter(([, , t]) => t > a && t < b);
  const first = between(start, coaching).slice(0, 3);
  const second = between(coaching, fixed).slice(0, 3);
  const submit = taps.find(([, , t]) => t > fixed);
  if (first.length < 3 || second.length < 3 || !submit) {
    return undefined;
  }
  const seen = [...first, ...second, submit].map(([, , t]) => t + VISUAL_LAG);
  return {
    ones: seen[0],
    tens: seen[1],
    wrongSubmit: seen[2],
    coaching,
    carry: seen[3],
    tensBox: seen[4],
    fixDigit: seen[5],
    submit: seen[6],
    positions: [...first, ...second, submit].map(([x, y]) => [x, y] as [number, number]),
  };
}

/**
 * The forgotten-carry story from the column addition scene, as a speed-ramped timeline that
 * fits `targetFrames`: ones digit, the tens written without the carry, submit, the red
 * coaching note (held so it can be read), the carry marked, the tens fixed, submit, success.
 * Times are when each thing shows on screen; `frameOf` places captions and sounds.
 */
export function slipStory(device: DeviceKind, targetFrames: number, fps = 30) {
  const m = slipMoments(device);
  if (!m) {
    return undefined;
  }
  const list: Moment[] = [
    {at: m.ones, before: 0.9, after: 0.8},
    {at: m.tens, before: 0.3, after: 0.8},
    {at: m.wrongSubmit, before: 0.3, after: 0.6},
    {at: m.coaching, before: 0.1, after: 2.6},
    {at: m.carry, before: 0.4, after: 0.8},
    {at: m.tensBox, before: 0.3, after: 0.7},
    {at: m.fixDigit, before: 0.3, after: 0.9},
    // The success banner, then the edit holds: the app moves on to the next question soon after.
    {at: m.submit, before: 0.2, after: 1.2},
  ];
  // Slow enough to follow, fast enough to fit: leave about two seconds after the last tap for
  // the success moment, held on the solved sum.
  const successFrames = 2 * fps;
  let rate = 1;
  for (rate of [1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.65, 1.8, 2]) {
    if (rampTimeline(list, {rate, fastRate: 6, fps}).totalFrames <= targetFrames - successFrames) {
      break;
    }
  }
  const timeline = rampTimeline(list, {rate, fastRate: 6, fps, holdTo: targetFrames});
  const touched = [m.ones, m.tens, m.wrongSubmit, m.carry, m.tensBox, m.fixDigit, m.submit];
  // A finger lands a beat before the screen changes.
  const ripples = m.positions.map(([x, y], i) => [x, y, touched[i] - 0.25] as [number, number, number]);
  const carryAt = m.positions[3];
  const boxAt = m.positions[4];
  const zoom = carryAt && boxAt ? {x: (carryAt[0] + boxAt[0]) / 2, y: (carryAt[1] + boxAt[1]) / 2} : {x: 0.5, y: 0.4};
  return {...timeline, moments: m, ripples, zoom, touched};
}
