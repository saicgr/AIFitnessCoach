#!/usr/bin/env node
/**
 * "Make today's post" — renders every spec for a day into per-platform folders:
 *
 *   docs/planning/marketing/content/<date>/
 *     specs/*.json
 *     instagram/  carousel-<slug>/ (4:5)  reel-<slug>/ (reel.mp4 + IG caption)
 *     tiktok/     carousel-<slug>/ (9:16) reel-<slug>/ (reel.mp4 + TikTok caption)
 *
 * Carousels render at BOTH aspects (IG 4:5, TikTok Photo Mode 9:16). The reel
 * MP4 is the same 9:16 master for both platforms (no watermark), copied into
 * each folder with that platform's caption. Nothing is auto-posted.
 *
 * Usage:
 *   node make-day.mjs [<date>]            # scans specs for that date (or latest)
 *   node make-day.mjs --spec <path>       # one spec
 */

import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import fs from 'node:fs';
import { REPO_ROOT } from './lib/brand.mjs';
import { writePlatformCaption } from './lib/captions.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CAROUSEL = path.join(__dirname, 'render-carousel.mjs');
const VIDEO = path.join(__dirname, 'assemble-video.mjs');

function arg(flag) {
  const i = process.argv.indexOf(flag);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : null;
}

function contentDir(date, ...rest) {
  return path.join(REPO_ROOT, 'docs/planning/marketing/content', date, ...rest);
}

function run(script, args) {
  execFileSync('node', [script, ...args], { stdio: 'inherit' });
}

async function renderSpec(specPath) {
  const spec = JSON.parse(fs.readFileSync(specPath, 'utf8'));
  const kind = Array.isArray(spec.slides) ? 'carousel' : Array.isArray(spec.segments) ? 'video' : null;
  if (!kind) {
    console.warn(`[make-day] skip ${path.basename(specPath)} — neither slides[] nor segments[]`);
    return;
  }
  const slug = (spec.slug || path.basename(specPath, '.json')).replace(/^(carousel|reel)-/, '');
  const date = spec.date || 'undated';

  if (kind === 'carousel') {
    console.log(`\n[make-day] carousel ${slug} → IG 4:5 + TikTok 9:16`);
    run(CAROUSEL, [specPath, '--platform', 'ig', '--force']);
    run(CAROUSEL, [specPath, '--platform', 'tiktok', '--force']);
  } else {
    console.log(`\n[make-day] reel ${slug} → render once, mirror to both platforms`);
    run(VIDEO, [specPath, '--platform', 'ig']); // renders instagram/reel-<slug>/reel.mp4 + IG caption
    // Mirror the same 9:16 master to the TikTok folder with the TikTok caption.
    const igDir = contentDir(date, 'instagram', `reel-${slug}`);
    const ttDir = contentDir(date, 'tiktok', `reel-${slug}`);
    fs.mkdirSync(ttDir, { recursive: true });
    for (const f of ['reel.mp4', 'RECORD-THIS.md']) {
      const src = path.join(igDir, f);
      if (fs.existsSync(src)) fs.copyFileSync(src, path.join(ttDir, f));
    }
    await writePlatformCaption(ttDir, spec, 'tiktok');
    console.log(`[make-day] mirrored reel → ${ttDir}`);
  }
}

async function main() {
  const one = arg('--spec');
  let specs;
  if (one) {
    specs = [path.resolve(process.cwd(), one)];
  } else {
    let date = process.argv[2] && !process.argv[2].startsWith('--') ? process.argv[2] : null;
    if (!date) {
      const base = path.join(REPO_ROOT, 'docs/planning/marketing/content');
      const dates = fs.existsSync(base)
        ? fs.readdirSync(base).filter((d) => /^\d{4}-\d{2}-\d{2}$/.test(d)).sort()
        : [];
      date = dates[dates.length - 1];
      if (!date) {
        console.error('[make-day] no date given and no content/<date> dirs found');
        process.exit(1);
      }
      console.log(`[make-day] no date given — using latest: ${date}`);
    }
    const specDir = contentDir(date, 'specs');
    // Back-compat: older runs kept specs under instagram/specs.
    const legacy = contentDir(date, 'instagram', 'specs');
    const dir = fs.existsSync(specDir) ? specDir : fs.existsSync(legacy) ? legacy : null;
    if (!dir) {
      console.error(`[make-day] no specs/ dir for ${date}`);
      process.exit(1);
    }
    specs = fs.readdirSync(dir).filter((f) => f.endsWith('.json')).map((f) => path.join(dir, f));
    if (!specs.length) {
      console.error(`[make-day] no specs in ${dir}`);
      process.exit(1);
    }
  }
  for (const s of specs) await renderSpec(s);
  console.log(`\n[make-day] done — review the instagram/ and tiktok/ folders, then upload.`);
}

main().catch((e) => {
  console.error('[make-day]', e.message || e);
  process.exit(1);
});
