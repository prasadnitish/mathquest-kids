import {DeviceKind, Moment, rampTimeline, sceneFootage} from './Footage';

/**
 * The forgotten-carry story from the column addition scene, as a speed-ramped timeline that
 * fits `targetFrames`: ones digit, the tens written without the carry, submit, the red
 * coaching note (held so it can be read), the carry marked, the tens fixed, submit, success.
 * Frame numbers for captions and sounds come from `frameOf` on the logged moments.
 */
export function slipStory(device: DeviceKind, targetFrames: number, fps = 30) {
  const footage = sceneFootage(device, 'testSceneColumnAddition');
  const marks = footage?.marks ?? {};
  const start = marks['slip-start'];
  const coaching = marks['slip-coaching'];
  const fixed = marks['slip-fixed'];
  if (!footage || start === undefined || coaching === undefined || fixed === undefined) {
    return undefined;
  }
  const tapTimes = footage.taps.map(([, , t]) => t);
  const between = (a: number, b: number) => tapTimes.filter((t) => t > a && t < b);
  const [ones, tens, wrongSubmit] = between(start, coaching);
  const [carry, tensBox, fixDigit] = between(coaching, fixed);
  const submit = tapTimes.find((t) => t > fixed);
  if ([ones, tens, wrongSubmit, carry, tensBox, fixDigit, submit].some((t) => t === undefined)) {
    return undefined;
  }
  const moments: Moment[] = [
    {at: ones!, before: 0.9, after: 0.9},
    {at: tens!, before: 0.3, after: 0.9},
    {at: wrongSubmit!, before: 0.3, after: 0.5},
    {at: coaching, before: 0.2, after: 2.8},
    {at: carry!, before: 0.4, after: 0.9},
    {at: tensBox!, before: 0.3, after: 0.7},
    {at: fixDigit!, before: 0.3, after: 0.9},
    // Just the tap: the app moves on to the next question soon after, so the edit holds here.
    {at: submit!, before: 0.3, after: 0.7},
  ];
  // Slow enough to follow, fast enough to fit: try speeds until the story fits the slot.
  // Leave about two seconds after the last tap for the success moment, held on the solved sum.
  const successFrames = 2 * fps;
  let rate = 1;
  for (rate of [1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.65, 1.8, 2]) {
    if (rampTimeline(moments, {rate, fastRate: 6, fps}).totalFrames <= targetFrames - successFrames) {
      break;
    }
  }
  const timeline = rampTimeline(moments, {rate, fastRate: 6, fps, holdTo: targetFrames});
  const taps = {ones: ones!, tens: tens!, wrongSubmit: wrongSubmit!, carry: carry!, tensBox: tensBox!, fixDigit: fixDigit!, submit: submit!};
  // Zoom on the sum: between the carry box and the tens answer box.
  const carryTap = footage.taps.find(([, , t]) => t === carry);
  const boxTap = footage.taps.find(([, , t]) => t === tensBox);
  const zoom = carryTap && boxTap ? {x: (carryTap[0] + boxTap[0]) / 2, y: (carryTap[1] + boxTap[1]) / 2} : {x: 0.5, y: 0.4};
  return {...timeline, coaching, taps, zoom, tapTimes};
}
