#!/usr/bin/env node
/**
 * Zealova Instagram / TikTok Reel assembler.
 *
 * Reads a video spec JSON and assembles a 1080×1920 (9:16) MP4:
 *   b-roll / app-demo clips (or stills with a slow Ken-Burns push) → scaled +
 *   cropped to fill → a brand overlay per segment (Exposr-style news bar + big
 *   stroked caption) → per-segment VOICEOVER (macOS `say`, synced) → optional
 *   music bed.
 *
 * Overlays render in HTML via Puppeteer (transparent PNG) then composite in
 * ffmpeg. Voiceover uses the free macOS `say` voice by default (no key); set
 * `audio` to a pre-made mp3 (e.g. ElevenLabs) to override with a single track.
 *
 * Usage:
 *   node assemble-video.mjs <spec.json> [--out <dir>] [--keep]
 *
 * Spec shape:
 *   {
 *     "slug":"ramen-flame", "date":"2026-07-19", "pillar":"menu-scan",
 *     "voice":"Samantha", "rate":180,        // say voice + wpm (optional defaults)
 *     "segments":[
 *       { "clip":"path.mp4", "kind":"video", "start":0, "duration":4,
 *         "headline":"Ramen can't dissolve under flame", "caption":"INTACT",
 *         "vo":"Watch what happens when you set instant ramen on fire." },
 *       { "clip":"menu-scan-result", "kind":"still", "duration":4,
 *         "label":"SCANNED", "brand":true,
 *         "vo":"Zealova scanned it in three seconds and flagged eleven additives." }
 *     ],
 *     "music":"bed.mp3",   // OPTIONAL music bed (ducked under the voice)
 *     "audio":"vo.mp3",    // OPTIONAL single voiceover track (overrides per-segment `vo`)
 *     "caption":"…", "hashtags":["#…"]
 *   }
 *
 * A segment's on-screen time = max(its `duration`, its voiceover length) so the
 * narration is never cut off.
 */

import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import fs from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { VIDEO, REPO_ROOT, resolveShot } from './lib/brand.mjs';
import { videoOverlayHtml } from './lib/video-overlays.mjs';
import { writePlatformCaption } from './lib/captions.mjs';

const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

function arg(flag) {
  const i = process.argv.indexOf(flag);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : null;
}
const KEEP = process.argv.includes('--keep');
const FPS = 30;

const abs = (p) => {
  const r = resolveShot(p);
  return path.isAbsolute(r) ? r : path.join(REPO_ROOT, r);
};

function ff(args) {
  execFileSync('ffmpeg', ['-y', '-hide_banner', '-loglevel', 'error', ...args], { stdio: ['ignore', 'pipe', 'pipe'] });
}
function probeDur(file) {
  const out = execFileSync('ffprobe', [
    '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', file,
  ]);
  return Number(String(out).trim()) || 0;
}

// macOS `say` → aiff, returns duration. Falls back to null if `say` is absent.
function sayVoiceover(text, { voice, rate }, outAiff) {
  const args = [];
  if (voice) args.push('-v', voice);
  if (rate) args.push('-r', String(rate));
  args.push('-o', outAiff, text);
  try {
    execFileSync('say', args, { stdio: ['ignore', 'pipe', 'pipe'] });
    return probeDur(outAiff);
  } catch {
    return null; // no `say` (non-mac) — segment stays silent
  }
}

async function renderOverlays(segments, tmpDir) {
  const puppeteer = require('puppeteer');
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox', '--disable-setuid-sandbox'] });
  const page = await browser.newPage();
  await page.setViewport({ width: VIDEO.width, height: VIDEO.height, deviceScaleFactor: 1 });
  const files = [];
  for (let i = 0; i < segments.length; i++) {
    const out = path.join(tmpDir, `ovl-${i}.png`);
    await page.setContent(videoOverlayHtml(segments[i]), { waitUntil: 'load' });
    await page.evaluate(() => (document.fonts ? document.fonts.ready : null));
    await page.screenshot({ path: out, type: 'png', omitBackground: true });
    files.push(out);
  }
  await browser.close();
  return files;
}

// The universal placeholder for a not-yet-recorded video clip.
const STOCK_FALLBACK = path.join(REPO_ROOT, '6388436-uhd_3840_2160_25fps.mp4');

// Decide what footage a segment actually renders with:
//  - the real clip if it exists on disk
//  - else its `fallback` (a screenshot key / image) rendered as a Ken-Burns still
//  - else the stock clip, else a solid brand-ink card
// and report whether the real clip is still MISSING (→ goes in RECORD-THIS.md).
function resolveFootage(seg) {
  if (seg.kind === 'still') return { useKind: 'still', useClip: abs(seg.clip), missing: null };
  const cAbs = abs(seg.clip);
  if (existsSync(cAbs)) return { useKind: 'video', useClip: cAbs, missing: null };
  // A video segment whose recording doesn't exist yet.
  const missing = { saveAs: seg.clip, shot: seg.shot || '', caption: seg.caption || '', headline: seg.headline || '' };
  if (seg.fallback) {
    const fAbs = abs(seg.fallback);
    if (existsSync(fAbs)) return { useKind: 'still', useClip: fAbs, missing };
  }
  if (existsSync(STOCK_FALLBACK)) return { useKind: 'video', useClip: STOCK_FALLBACK, missing };
  return { useKind: 'color', useClip: null, missing };
}

// Build one segment as a fully-muxed A/V clip (h264 + aac) of `segDur` seconds.
function buildSegment(seg, useKind, useClip, overlay, voAiff, segDur, tmpDir, idx) {
  const v = path.join(tmpDir, `v-${idx}.mp4`);
  const a = path.join(tmpDir, `a-${idx}.m4a`);
  const out = path.join(tmpDir, `seg-${String(idx).padStart(2, '0')}.mp4`);
  const enc = ['-c:v', 'libx264', '-preset', 'veryfast', '-crf', '20', '-pix_fmt', 'yuv420p', '-t', String(segDur)];

  // --- video (with overlay) ---
  if (useKind === 'still') {
    const frames = Math.max(2, Math.round(segDur * FPS));
    const inc = (0.16 / frames).toFixed(6); // slow Ken-Burns push to ~1.16x
    const chain =
      `[0:v]scale=1296:2304:force_original_aspect_ratio=increase,crop=1296:2304,` +
      `zoompan=z='min(zoom+${inc},1.16)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=${frames}:s=${VIDEO.width}x${VIDEO.height}:fps=${FPS},` +
      `setsar=1[bg];[bg][1:v]overlay=0:0,format=yuv420p[v]`;
    ff(['-loop', '1', '-t', String(segDur), '-i', useClip, '-i', overlay, '-filter_complex', chain, '-map', '[v]', '-an', ...enc, v]);
  } else if (useKind === 'color') {
    const chain = `[0:v][1:v]overlay=0:0,format=yuv420p[v]`;
    ff(['-f', 'lavfi', '-t', String(segDur), '-i', `color=c=0x141210:s=${VIDEO.width}x${VIDEO.height}:r=${FPS}`, '-i', overlay, '-filter_complex', chain, '-map', '[v]', '-an', ...enc, v]);
  } else {
    const chain =
      `[0:v]scale=${VIDEO.width}:${VIDEO.height}:force_original_aspect_ratio=increase,` +
      `crop=${VIDEO.width}:${VIDEO.height},fps=${FPS},setsar=1[bg];[bg][1:v]overlay=0:0,format=yuv420p[v]`;
    ff(['-ss', String(seg.start || 0), '-t', String(segDur), '-i', useClip, '-i', overlay, '-filter_complex', chain, '-map', '[v]', '-an', ...enc, v]);
  }

  // --- audio (voiceover padded to segDur, or silence) ---
  if (voAiff) {
    ff(['-i', voAiff, '-af', 'apad', '-t', String(segDur), '-ar', '44100', '-ac', '2', '-c:a', 'aac', '-b:a', '192k', a]);
  } else {
    ff(['-f', 'lavfi', '-t', String(segDur), '-i', 'anullsrc=r=44100:cl=stereo', '-c:a', 'aac', '-b:a', '192k', a]);
  }

  // --- mux ---
  ff(['-i', v, '-i', a, '-map', '0:v:0', '-map', '1:a:0', '-c', 'copy', '-shortest', out]);
  return out;
}

async function main() {
  const specPath = process.argv[2];
  if (!specPath || specPath.startsWith('--')) {
    console.error('Usage: node assemble-video.mjs <spec.json> [--out <dir>] [--keep]');
    process.exit(1);
  }
  const specAbs = path.isAbsolute(specPath) ? specPath : path.resolve(process.cwd(), specPath);
  const spec = JSON.parse(await fs.readFile(specAbs, 'utf8'));
  if (!Array.isArray(spec.segments) || !spec.segments.length) throw new Error('Spec has no segments[]');

  const slug = (spec.slug || path.basename(specAbs, '.json')).replace(/^reel-/, '');
  const date = spec.date || 'undated';
  const platform = (arg('--platform', 'ig') || 'ig').toLowerCase();
  const platformDir = platform === 'tiktok' ? 'tiktok' : 'instagram';
  const captionKey = platform === 'tiktok' ? 'tiktok' : 'instagram';
  const outDir = arg('--out')
    ? path.resolve(process.cwd(), arg('--out'))
    : path.join(REPO_ROOT, 'docs/planning/marketing/content', date, platformDir, `reel-${slug}`);
  await fs.mkdir(outDir, { recursive: true });
  const tmpDir = path.join(outDir, '.work');
  await fs.mkdir(tmpDir, { recursive: true });

  await writePlatformCaption(outDir, spec, captionKey);

  const voiceOpts = { voice: spec.voice || 'Samantha', rate: spec.rate || 180 };
  const singleTrack = !!spec.audio; // one external voice track overrides per-segment vo

  console.log(`[reel] rendering ${spec.segments.length} overlays...`);
  const overlays = await renderOverlays(spec.segments, tmpDir);

  const segFiles = [];
  const missingShots = [];
  for (let i = 0; i < spec.segments.length; i++) {
    const seg = spec.segments[i];
    let voAiff = null;
    let voDur = 0;
    if (!singleTrack && seg.vo) {
      voAiff = path.join(tmpDir, `vo-${i}.aiff`);
      voDur = sayVoiceover(seg.vo, voiceOpts, voAiff) || 0;
      if (!voDur) voAiff = null;
    }
    // Segment time = max(requested duration, narration length + a breath).
    const segDur = Math.max(Number(seg.duration || 0), voDur ? voDur + 0.45 : 0, 2.2);
    const { useKind, useClip, missing } = resolveFootage(seg);
    if (missing) missingShots.push({ ...missing, idx: i + 1, dur: segDur });
    console.log(
      `[reel] segment ${i + 1}/${spec.segments.length} (${useKind}${missing ? ' PLACEHOLDER' : ''}, ${segDur.toFixed(1)}s${voAiff ? ', vo' : ''})`,
    );
    segFiles.push(buildSegment(seg, useKind, useClip, overlays[i], voAiff, segDur, tmpDir, i));
  }

  // If any real footage is missing, write a shot list the founder can film to.
  if (missingShots.length) {
    const relSpec = path.relative(path.join(REPO_ROOT, 'frontend'), specAbs);
    const lines = [
      `# 🎥 Record these clips — ${slug}`,
      '',
      `${missingShots.length} clip(s) are placeholders. Film them, save each with the EXACT name below, then re-render:`,
      '',
      '```bash',
      `cd frontend && npm run ig:video -- ${relSpec}`,
      '```',
      '',
      'Tip: film the app on one phone using a SECOND phone (hand + screen visible) for the app-demo shots — that reads as authentic, not a screenshot.',
      '',
    ];
    for (const m of missingShots) {
      lines.push(`## Clip ${m.idx} — save as \`${m.saveAs}\`  (~${Math.round(m.dur)}s)`);
      lines.push(m.shot || '_(no shot note in spec)_');
      if (m.headline) lines.push(`- On-screen headline: "${m.headline}"`);
      if (m.caption) lines.push(`- On-screen caption word: "${m.caption}"`);
      lines.push('');
    }
    await fs.writeFile(path.join(outDir, 'RECORD-THIS.md'), lines.join('\n'));
    console.log(`[reel] ⚠ ${missingShots.length} placeholder clip(s) — see RECORD-THIS.md`);
  }

  // Concat (all segments share codec/params → stream copy).
  const listFile = path.join(tmpDir, 'concat.txt');
  await fs.writeFile(listFile, segFiles.map((f) => `file '${f.replace(/'/g, "'\\''")}'`).join('\n') + '\n');
  const joined = path.join(tmpDir, 'joined.mp4');
  ff(['-f', 'concat', '-safe', '0', '-i', listFile, '-c', 'copy', joined]);

  const finalFile = path.join(outDir, 'reel.mp4');

  // Optional: an external single voiceover track (e.g. ElevenLabs) replaces the audio.
  let stage = joined;
  if (singleTrack) {
    const withVoice = path.join(tmpDir, 'with-voice.mp4');
    ff(['-i', joined, '-i', abs(spec.audio), '-map', '0:v', '-map', '1:a', '-c:v', 'copy', '-c:a', 'aac', '-b:a', '192k', '-shortest', withVoice]);
    stage = withVoice;
  }

  // Optional: music bed ducked under the existing audio.
  if (spec.music && existsSync(abs(spec.music))) {
    ff([
      '-i', stage, '-i', abs(spec.music),
      '-filter_complex', '[1:a]volume=0.22[m];[0:a][m]amix=inputs=2:duration=first:dropout_transition=0[a]',
      '-map', '0:v', '-map', '[a]', '-c:v', 'copy', '-c:a', 'aac', '-b:a', '192k', finalFile,
    ]);
  } else {
    ff(['-i', stage, '-c', 'copy', finalFile]);
  }

  if (!KEEP) await fs.rm(tmpDir, { recursive: true, force: true });
  const { size } = await fs.stat(finalFile);
  console.log(`\n[reel] done → ${finalFile} (${(size / 1e6).toFixed(1)} MB, ${probeDur(finalFile).toFixed(1)}s)`);
}

main().catch((err) => {
  console.error('[reel] assembly failed:', err.message || err);
  process.exit(1);
});
