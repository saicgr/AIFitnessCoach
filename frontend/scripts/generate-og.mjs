#!/usr/bin/env node
/**
 * Build-time per-tool OG image generator.
 *
 * Renders one 1200x630 PNG per free-tool into public/og/tools/<slug>.png so
 * each tool page has a correct share preview. Before this, every tool
 * hardcoded the Google Health comparison card — sharing a TDEE result showed
 * an unrelated image and looked broken.
 *
 * Reuses the Puppeteer that prerender.mjs already depends on (no new deps).
 * Same local-vs-Vercel-CI Chrome split as prerender.mjs.
 *
 * Idempotent: skips a slug whose PNG already exists unless --force is passed,
 * so incremental builds only render newly added tools.
 */

import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs/promises';

const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const OG_DIR = path.join(ROOT, 'public/og');
const OUT_DIR = path.join(OG_DIR, 'tools');
const GLOSSARY_OUT_DIR = path.join(OG_DIR, 'glossary');
const FORCE = process.argv.includes('--force');

// Anton (the brand display face) inlined as base64 so Puppeteer's
// setContent page can use it without any network/file fetch.
let antonFontFace = '';
try {
  const woff2 = await fs.readFile(
    path.join(ROOT, 'node_modules/@fontsource/anton/files/anton-latin-400-normal.woff2'),
  );
  antonFontFace = `@font-face { font-family:'Anton'; src:url(data:font/woff2;base64,${woff2.toString('base64')}) format('woff2'); }`;
} catch {
  // Falls back to the condensed system stack below.
}

// The real app icon (orange Z), inlined for the card's brand chip so share
// cards match the Play Store listing exactly.
let appIconDataUri = '';
try {
  const icon = await fs.readFile(path.join(ROOT, 'public/zealova-logo.png'));
  appIconDataUri = `data:image/png;base64,${icon.toString('base64')}`;
} catch {
  // Chip falls back to the lettered div.
}

// Glossary share cards — public/og/glossary/<slug>.png, referenced by
// GlossaryShell's og:image meta.
const GLOSSARY_CARDS = [
  { slug: '1rm', term: 'One-Rep Max (1RM)' },
  { slug: 'tdee', term: 'TDEE' },
  { slug: 'bmr', term: 'BMR' },
  { slug: 'macros', term: 'Macros' },
  { slug: 'progressive-overload', term: 'Progressive Overload' },
  { slug: 'rir-rpe', term: 'RIR & RPE' },
  { slug: 'deload', term: 'Deload' },
  { slug: 'cut-bulk', term: 'Cutting & Bulking' },
  { slug: 'mesocycle', term: 'Mesocycle' },
  { slug: 'wilks-score', term: 'Wilks Score' },
  { slug: 'body-fat-percentage', term: 'Body Fat Percentage' },
  { slug: 'sleep-cycles', term: 'Sleep Cycles' },
  { slug: 'intermittent-fasting', term: 'Intermittent Fasting' },
  { slug: 'vo2-max', term: 'VO2 Max' },
  { slug: 'zone-2-cardio', term: 'Zone 2 Cardio' },
];

// Static (non-tool) marketing pages that need their own 1200x630 share card.
// Rendered to public/og/<slug>.png. Add an entry + reference it from the
// page's og:image meta tag.
const STATIC_CARDS = [
  {
    slug: 'home',
    kicker: 'AI workout + meal coach',
    title: 'Your AI coach. Every rep. Every meal.',
    tagline:
      'Personalized training plans, real-time coaching mid-set, photo food logging, and a restaurant menu scanner. Live on Google Play.',
    footLeft: '7-day free trial · no credit card',
    footRight: 'zealova.com',
  },
  {
    slug: 'roadmap',
    kicker: 'Product Roadmap',
    title: 'Vote on what we build next',
    tagline:
      "See what's shipped, what's in progress, and what's up for debate — then vote on the features you want most.",
    footLeft: 'Live roadmap · one-tap voting',
    footRight: 'zealova.com/roadmap',
  },
];

const isVercelBuild = process.cwd().startsWith('/vercel');
let puppeteer;
let chromiumExecutablePath = null;
let chromiumArgs = ['--no-sandbox', '--disable-setuid-sandbox'];
if (isVercelBuild) {
  puppeteer = require('puppeteer-core');
  const chromium = require('@sparticuz/chromium').default || require('@sparticuz/chromium');
  chromiumExecutablePath = await chromium.executablePath();
  chromiumArgs = chromium.args;
} else {
  puppeteer = require('puppeteer');
}

async function parseRegistry() {
  const src = await fs.readFile(
    path.join(ROOT, 'src/components/tools/calcRegistry.ts'),
    'utf8',
  );
  const tools = [];
  const slugRe = /slug:\s*'([^']+)'/g;
  let m;
  while ((m = slugRe.exec(src)) !== null) {
    const slug = m[1];
    const window = src.slice(m.index, m.index + 900);
    const nameM = window.match(/name:\s*'([^']*(?:\\'[^']*)*)'/);
    const descM = window.match(/description:\s*'([^']*(?:\\'[^']*)*)'/);
    tools.push({
      slug,
      name: nameM ? nameM[1].replace(/\\'/g, "'") : slug,
      description: descM ? descM[1].replace(/\\'/g, "'") : '',
    });
  }
  return tools;
}

function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

// Generic 1200x630 brand card ("dark kinetic volt" identity). Used for
// tool cards, glossary cards, and static-page cards.
function cardHtml({ kicker, title, tagline, footLeft, footRight }) {
  return `<!DOCTYPE html><html><head><meta charset="utf-8"><style>
  ${antonFontFace}
  * { margin:0; padding:0; box-sizing:border-box; }
  html,body { width:1200px; height:630px; }
  body {
    display:flex; flex-direction:column; justify-content:space-between;
    padding:72px;
    background:
      radial-gradient(80% 60% at 100% 0%, rgba(255,122,0,0.14), transparent 60%),
      radial-gradient(60% 50% at 0% 100%, rgba(150,60,0,0.12), transparent 65%),
      #050505;
    color:#fff;
    font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
  }
  .brand { display:flex; align-items:center; gap:14px; font-size:28px;
    font-family:'Anton','Arial Narrow',sans-serif; text-transform:uppercase;
    letter-spacing:1px; }
  .logo {
    width:42px; height:42px; border-radius:12px; background:#FF7A00;
    display:flex; align-items:center; justify-content:center;
    color:#050505; font-weight:900; font-size:26px;
    font-family:'Anton','Arial Narrow',sans-serif;
    overflow:hidden;
  }
  .logo img { width:100%; height:100%; object-fit:cover; }
  .kicker { font-size:22px; font-weight:600; color:#FF7A00;
    text-transform:uppercase; letter-spacing:4px; margin-bottom:18px; }
  .title { font-size:88px; line-height:0.98; text-transform:uppercase;
    font-family:'Anton','Arial Narrow',sans-serif; font-weight:400;
    letter-spacing:0; max-width:1056px; }
  .tagline { margin-top:24px; font-size:27px; color:#a1a1aa;
    line-height:1.4; max-width:1000px; }
  .foot { display:flex; align-items:center; justify-content:space-between;
    font-size:22px; color:#a1a1aa; }
  .accent { color:#FF7A00; font-weight:700; }
  </style></head><body>
    <div class="brand"><div class="logo">${appIconDataUri ? `<img src="${appIconDataUri}" alt="">` : 'Z'}</div><span>Zealova</span></div>
    <div>
      <div class="kicker">${esc(kicker)}</div>
      <div class="title">${esc(title)}</div>
      ${tagline ? `<div class="tagline">${esc(tagline)}</div>` : ''}
    </div>
    <div class="foot">
      <span class="accent">${esc(footLeft)}</span>
      <span>${esc(footRight)}</span>
    </div>
  </body></html>`;
}

function glossaryCard(entry) {
  return cardHtml({
    kicker: 'Fitness Glossary',
    title: `What is ${entry.term}?`,
    tagline: 'Definition, formula, and how to use it in your training.',
    footLeft: 'Plain-English fitness science',
    footRight: 'zealova.com/glossary',
  });
}

function toolCard(tool) {
  // One-line tagline: first sentence of the description, trimmed.
  const tagline = (tool.description || '').split(/\.\s/)[0].slice(0, 120);
  return cardHtml({
    kicker: 'Free tool',
    title: tool.name,
    tagline,
    footLeft: 'Free. No sign-up. Nothing leaves your device.',
    footRight: 'zealova.com/free-tools',
  });
}

async function main() {
  const tools = await parseRegistry();
  await fs.mkdir(OUT_DIR, { recursive: true });
  await fs.mkdir(GLOSSARY_OUT_DIR, { recursive: true });

  const exists = async (p) => {
    try {
      await fs.access(p);
      return true;
    } catch {
      return false;
    }
  };

  // Tool cards still needing a PNG.
  const pendingTools = [];
  for (const t of tools) {
    if (FORCE || !(await exists(path.join(OUT_DIR, `${t.slug}.png`)))) {
      pendingTools.push(t);
    }
  }

  // Static-page cards still needing a PNG.
  const pendingStatic = [];
  for (const c of STATIC_CARDS) {
    if (FORCE || !(await exists(path.join(OG_DIR, `${c.slug}.png`)))) {
      pendingStatic.push(c);
    }
  }

  // Glossary cards still needing a PNG.
  const pendingGlossary = [];
  for (const g of GLOSSARY_CARDS) {
    if (FORCE || !(await exists(path.join(GLOSSARY_OUT_DIR, `${g.slug}.png`)))) {
      pendingGlossary.push(g);
    }
  }

  if (pendingTools.length === 0 && pendingStatic.length === 0 && pendingGlossary.length === 0) {
    console.log(
      `[og] all ${tools.length} tool + ${GLOSSARY_CARDS.length} glossary + ${STATIC_CARDS.length} static cards already present, nothing to render`,
    );
    return;
  }

  console.log(
    `[og] rendering ${pendingTools.length} tool + ${pendingGlossary.length} glossary + ${pendingStatic.length} static OG card(s)...`,
  );
  const browser = await puppeteer.launch({
    headless: 'new',
    args: chromiumArgs,
    ...(chromiumExecutablePath ? { executablePath: chromiumExecutablePath } : {}),
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 1200, height: 630, deviceScaleFactor: 1 });
  const clip = { x: 0, y: 0, width: 1200, height: 630 };

  let ok = 0;
  for (const t of pendingTools) {
    try {
      await page.setContent(toolCard(t), { waitUntil: 'load' });
      await page.screenshot({ path: path.join(OUT_DIR, `${t.slug}.png`), type: 'png', clip });
      ok++;
    } catch (err) {
      console.error(`[og] FAIL tool ${t.slug}: ${err.message}`);
    }
  }
  for (const g of pendingGlossary) {
    try {
      await page.setContent(glossaryCard(g), { waitUntil: 'load' });
      await page.screenshot({ path: path.join(GLOSSARY_OUT_DIR, `${g.slug}.png`), type: 'png', clip });
      ok++;
    } catch (err) {
      console.error(`[og] FAIL glossary ${g.slug}: ${err.message}`);
    }
  }
  for (const c of pendingStatic) {
    try {
      await page.setContent(cardHtml(c), { waitUntil: 'load' });
      await page.screenshot({ path: path.join(OG_DIR, `${c.slug}.png`), type: 'png', clip });
      ok++;
    } catch (err) {
      console.error(`[og] FAIL static ${c.slug}: ${err.message}`);
    }
  }

  await browser.close();
  console.log(`[og] done. ${ok}/${pendingTools.length + pendingGlossary.length + pendingStatic.length} cards rendered.`);
}

main().catch((err) => {
  console.error('[og] generation failed:', err);
  process.exit(1);
});
