/**
 * Zealova Instagram content engine — brand tokens + asset loaders.
 *
 * The carousel/video renderers import this so every slide is on-brand without
 * any network fetch: fonts + logo are inlined as base64 data URIs (same trick
 * generate-og.mjs uses for the website OG cards).
 *
 * Design language: the App Store creative look (cohesive with the real app
 * screenshots we embed) — warm cream canvas, near-black Anton headlines, a
 * confident Zealova green accent, and Exposr-style red/green comparison chrome.
 * The web brand's volt-orange is available as an alternate accent (BRAND.orange)
 * so a single token swap re-skins everything if we ever want the website look.
 */

import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';

const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// frontend/ root — lib is at frontend/scripts/instagram/lib
export const FRONTEND_ROOT = path.resolve(__dirname, '../../..');
export const REPO_ROOT = path.resolve(FRONTEND_ROOT, '..');

// ---------------------------------------------------------------------------
// Palette — tweak `accent` to re-skin the whole system.
// ---------------------------------------------------------------------------
export const BRAND = {
  accent: '#12B24B', // Zealova app green (the accent the audience sees in-app)
  accentDark: '#0C8C39',
  accentSoft: '#DCEFE1', // light-green pill background
  ink: '#161310', // near-black headline / body text on cream
  inkSoft: '#5C574F', // muted body text on cream
  canvas: '#F0EDE7', // warm cream (App Store background)
  panel: '#E8EAED', // light gray comparison panel (Exposr style)
  panelLine: '#D6D9DE', // hairline divider on panels
  dark: '#0A0A0A', // dark slide background (hook / cta over photo)
  darkSoft: '#B7B3AC', // muted text on dark
  bad: '#D6453F', // "bad ingredient / junk" red
  badSoft: '#F6DEDC',
  good: '#249B49', // "clean / good" green (comparison bullets)
  goodSoft: '#DBEFE0',
  muted: '#8C877E',
  orange: '#FF7A00', // web brand — alternate accent
  appName: 'Zealova',
  handle: '@getzealova',
  domain: 'zealova.com',
};

// ---------------------------------------------------------------------------
// Fonts — inlined @font-face blocks (Anton display + Barlow Condensed).
// ---------------------------------------------------------------------------
function fontFace(family, relPath, weight = 400, style = 'normal') {
  try {
    const buf = fs.readFileSync(path.join(FRONTEND_ROOT, relPath));
    return `@font-face{font-family:'${family}';font-weight:${weight};font-style:${style};src:url(data:font/woff2;base64,${buf.toString(
      'base64',
    )}) format('woff2');}`;
  } catch {
    return ''; // falls back to the system stack declared in cssReset()
  }
}

export function fontFacesCss() {
  return [
    fontFace('Anton', 'node_modules/@fontsource/anton/files/anton-latin-400-normal.woff2', 400),
    fontFace(
      'Barlow Condensed',
      'node_modules/@fontsource/barlow-condensed/files/barlow-condensed-latin-400-normal.woff2',
      400,
    ),
    fontFace(
      'Barlow Condensed',
      'node_modules/@fontsource/barlow-condensed/files/barlow-condensed-latin-600-normal.woff2',
      600,
    ),
    fontFace(
      'Barlow Condensed',
      'node_modules/@fontsource/barlow-condensed/files/barlow-condensed-latin-700-normal.woff2',
      700,
    ),
  ].join('\n');
}

// Font stacks to reference in slide CSS.
export const FONT = {
  display: "'Anton','Arial Narrow',sans-serif", // big hook caps
  condensed: "'Barlow Condensed','Oswald','Arial Narrow',sans-serif", // labels / bullets
  body: "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif",
};

// ---------------------------------------------------------------------------
// Logo — the Zealova mark, inlined as a data URI for the brand chip.
// ---------------------------------------------------------------------------
let _logoDataUri = null;
export function logoDataUri() {
  if (_logoDataUri !== null) return _logoDataUri;
  for (const rel of ['public/zealova-logo.png', 'public/email/zealova-logo-88.png']) {
    try {
      const buf = fs.readFileSync(path.join(FRONTEND_ROOT, rel));
      _logoDataUri = `data:image/png;base64,${buf.toString('base64')}`;
      return _logoDataUri;
    } catch {
      /* try next */
    }
  }
  _logoDataUri = '';
  return _logoDataUri;
}

// Screenshot library manifest — lets specs reference a stable key
// (e.g. "menu-scan-result") instead of a raw path.
let _manifest = null;
function shotManifest() {
  if (_manifest) return _manifest;
  try {
    _manifest = JSON.parse(
      fs.readFileSync(path.join(REPO_ROOT, 'docs/planning/marketing/screenshots/manifest.json'), 'utf8'),
    );
  } catch {
    _manifest = { shots: {} };
  }
  return _manifest;
}

// Resolve a manifest key to its repo-relative file; pass paths through unchanged.
export function resolveShot(keyOrPath) {
  if (!keyOrPath) return '';
  const m = shotManifest();
  if (m.shots && m.shots[keyOrPath]) return m.shots[keyOrPath].file;
  return keyOrPath;
}

// Read an arbitrary image (screenshot library asset) as a data URI. Accepts a
// manifest key, an absolute path, or a path relative to the repo root. '' if missing.
export function imageDataUri(p) {
  if (!p) return '';
  p = resolveShot(p);
  const abs = path.isAbsolute(p) ? p : path.join(REPO_ROOT, p);
  try {
    const buf = fs.readFileSync(abs);
    const ext = path.extname(abs).slice(1).toLowerCase();
    const mime = ext === 'jpg' ? 'jpeg' : ext === 'svg' ? 'svg+xml' : ext;
    return `data:image/${mime};base64,${buf.toString('base64')}`;
  } catch {
    return '';
  }
}

// ---------------------------------------------------------------------------
// Canvas geometry.
// ---------------------------------------------------------------------------
export const CAROUSEL = { width: 1080, height: 1350 }; // IG portrait 4:5
export const VIDEO = { width: 1080, height: 1920 }; // 9:16 reel

// Shared CSS reset + font-face for every slide's <head>.
export function cssReset() {
  return `${fontFacesCss()}
  *{margin:0;padding:0;box-sizing:border-box;-webkit-font-smoothing:antialiased;text-rendering:geometricPrecision;}
  html,body{width:${CAROUSEL.width}px;height:${CAROUSEL.height}px;overflow:hidden;}
  body{font-family:${FONT.body};color:${BRAND.ink};}`;
}
