// Renders every video to out/<name>.mp4 plus a poster frame (out/<name>-poster.jpg).
// Usage: npm run render [-- Overview OnPaper Parents]
import {bundle} from '@remotion/bundler';
import {renderMedia, renderStill, selectComposition} from '@remotion/renderer';
import path from 'node:path';
import fs from 'node:fs';

const outputs = {
  Overview: {file: 'sprout-math-overview-16x9', poster: 110},
  OnPaper: {file: 'sprout-math-like-on-paper-1x1', poster: 60},
  Parents: {file: 'sprout-math-for-parents-1x1', poster: 700},
};
const wanted = process.argv.slice(2).length ? process.argv.slice(2) : Object.keys(outputs);
// Chromium's headless shell; override with REMOTION_BROWSER if yours lives elsewhere.
const browserExecutable =
  process.env.REMOTION_BROWSER ??
  (fs.existsSync('/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell')
    ? '/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell'
    : null);

const serveUrl = await bundle({entryPoint: path.resolve('src/index.ts')});
fs.mkdirSync('out', {recursive: true});

for (const id of wanted) {
  const {file, poster} = outputs[id];
  const composition = await selectComposition({serveUrl, id, browserExecutable});
  console.log(`Rendering ${id} (${composition.width}x${composition.height}, ${composition.durationInFrames / composition.fps}s)`);
  await renderMedia({
    composition,
    serveUrl,
    codec: 'h264',
    crf: 18,
    audioCodec: 'aac',
    audioBitrate: '192k',
    pixelFormat: 'yuv420p',
    colorSpace: 'bt709',
    outputLocation: `out/${file}.mp4`,
    browserExecutable,
    concurrency: Number(process.env.CONCURRENCY ?? 4),
    onProgress: ({progress}) => process.stdout.write(`\r  ${Math.round(progress * 100)}%`),
  });
  process.stdout.write('\n');
  await renderStill({composition, serveUrl, frame: poster, output: `out/${file}-poster.jpg`, imageFormat: 'jpeg', jpegQuality: 90, browserExecutable});
  console.log(`  -> out/${file}.mp4`);
}
