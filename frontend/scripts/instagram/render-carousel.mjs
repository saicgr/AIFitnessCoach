#!/usr/bin/env node
/**
 * Zealova carousel renderer — Instagram 4:5 (1080×1350) or TikTok Photo Mode
 * 9:16 (1080×1920). Renders each slide to a PNG via Puppeteer and writes the
 * platform's caption. Every text slide gets a real background photo (from the
 * app's shareable-background library) so no slide is a flat color.
 *
 * Usage:
 *   node render-carousel.mjs <spec.json> [--platform ig|tiktok] [--out <dir>] [--force] [--scale 2]
 *
 * Default output dir:
 *   docs/planning/marketing/content/<date>/<platform>/carousel-<slug>/
 */

import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs/promises';
import { existsSync, readdirSync } from 'node:fs';
import { REPO_ROOT } from './lib/brand.mjs';
import { renderSlideHtml, setCanvas } from './lib/slides.mjs';
import { writePlatformCaption } from './lib/captions.mjs';

const require = createRequire(import.meta.url);

function arg(flag, def = null) {
  const i = process.argv.indexOf(flag);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : def;
}
const FORCE = process.argv.includes('--force');
const SCALE = Number(arg('--scale', '2'));
const PLATFORM = (arg('--platform', 'ig') || 'ig').toLowerCase(); // ig | tiktok
const SIZE = PLATFORM === 'tiktok' ? { width: 1080, height: 1920 } : { width: 1080, height: 1350 };
const CAPTION_KEY = PLATFORM === 'tiktok' ? 'tiktok' : 'instagram';

// ---- background library (real app shareable backgrounds) -------------------
const BG_ROOT = path.join(REPO_ROOT, 'mobile/flutter/assets/images/shareable_backgrounds');
const BG_CAT = {
  'menu-scan': 'nutrition', nutrition: 'nutrition', fasting: 'nutrition', wellness: 'nutrition',
  programs: 'workout', workout: 'workout', 'workout/ai': 'workout', form: 'workout',
  strength: 'workout', 'gym/travel': 'workout',
};
function bgFilesFor(pillar) {
  const cat = BG_CAT[(pillar || '').toLowerCase()] || 'abstract';
  try {
    return readdirSync(path.join(BG_ROOT, cat))
      .filter((f) => /\.(jpe?g|png|webp)$/i.test(f))
      .sort()
      .map((f) => `mobile/flutter/assets/images/shareable_backgrounds/${cat}/${f}`);
  } catch {
    return [];
  }
}
// Deterministic per-slug offset so the same post always picks the same bgs, but
// different posts vary.
function hash(s) {
  let h = 0;
  for (let i = 0; i < String(s).length; i++) h = (h * 31 + String(s).charCodeAt(i)) | 0;
  return Math.abs(h);
}

// Inject a background image into any text slide that lacks one.
function injectBackgrounds(spec) {
  const files = bgFilesFor(spec.pillar);
  if (!files.length) return;
  const base = hash(spec.slug || '');
  let pick = 0;
  const wants = new Set(['hook', 'stat', 'cta', 'appProof']);
  for (const slide of spec.slides) {
    if (wants.has(slide.type) && !slide.image) {
      slide.image = files[(base + pick) % files.length];
      pick++;
    }
  }
}

async function loadPuppeteer() {
  const isVercel = process.cwd().startsWith('/vercel');
  if (isVercel) {
    const puppeteer = require('puppeteer-core');
    const chromium = require('@sparticuz/chromium').default || require('@sparticuz/chromium');
    return { puppeteer, executablePath: await chromium.executablePath(), args: chromium.args };
  }
  return { puppeteer: require('puppeteer'), executablePath: null, args: ['--no-sandbox', '--disable-setuid-sandbox'] };
}

async function main() {
  const specPath = process.argv[2];
  if (!specPath || specPath.startsWith('--')) {
    console.error('Usage: node render-carousel.mjs <spec.json> [--platform ig|tiktok] [--out <dir>] [--force]');
    process.exit(1);
  }
  const specAbs = path.isAbsolute(specPath) ? specPath : path.resolve(process.cwd(), specPath);
  const spec = JSON.parse(await fs.readFile(specAbs, 'utf8'));
  if (!Array.isArray(spec.slides) || spec.slides.length === 0) throw new Error('Spec has no slides[]');

  injectBackgrounds(spec);
  setCanvas(SIZE);

  const slug = (spec.slug || path.basename(specAbs, '.json')).replace(/^carousel-/, '');
  const date = spec.date || 'undated';
  const platformDir = PLATFORM === 'tiktok' ? 'tiktok' : 'instagram';
  const outDir = arg('--out')
    ? path.resolve(process.cwd(), arg('--out'))
    : path.join(REPO_ROOT, 'docs/planning/marketing/content', date, platformDir, `carousel-${slug}`);
  await fs.mkdir(outDir, { recursive: true });
  await writePlatformCaption(outDir, spec, CAPTION_KEY);

  const { puppeteer, executablePath, args } = await loadPuppeteer();
  const browser = await puppeteer.launch({ headless: 'new', args, ...(executablePath ? { executablePath } : {}) });
  const page = await browser.newPage();
  await page.setViewport({ width: SIZE.width, height: SIZE.height, deviceScaleFactor: SCALE });
  const clip = { x: 0, y: 0, width: SIZE.width, height: SIZE.height };

  let ok = 0;
  const manifest = [];
  for (let i = 0; i < spec.slides.length; i++) {
    const n = String(i + 1).padStart(2, '0');
    const file = path.join(outDir, `slide-${n}.png`);
    try {
      await page.setContent(renderSlideHtml(spec.slides[i]), { waitUntil: 'load' });
      await page.evaluate(() => (document.fonts ? document.fonts.ready : null));
      await page.screenshot({ path: file, type: 'png', clip });
      manifest.push(path.basename(file));
      ok++;
      console.log(`[carousel:${PLATFORM}] slide-${n} (${spec.slides[i].type})`);
    } catch (err) {
      console.error(`[carousel:${PLATFORM}] FAIL slide-${n}: ${err.message}`);
    }
  }

  await browser.close();
  await fs.writeFile(
    path.join(outDir, 'index.json'),
    JSON.stringify({ slug, pillar: spec.pillar, date, platform: PLATFORM, slides: manifest }, null, 2) + '\n',
  );
  console.log(`[carousel:${PLATFORM}] ${ok}/${spec.slides.length} → ${outDir}`);
  if (ok < spec.slides.length) process.exit(1);
}

main().catch((err) => {
  console.error('[carousel] render failed:', err);
  process.exit(1);
});
