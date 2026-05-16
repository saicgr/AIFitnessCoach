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
const FORCE = process.argv.includes('--force');

// Static (non-tool) marketing pages that need their own 1200x630 share card.
// Rendered to public/og/<slug>.png. Add an entry + reference it from the
// page's og:image meta tag.
const STATIC_CARDS = [
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

// Generic 1200x630 brand card. Used for both tool cards and static-page cards.
function cardHtml({ kicker, title, tagline, footLeft, footRight }) {
  return `<!DOCTYPE html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html,body { width:1200px; height:630px; }
  body {
    display:flex; flex-direction:column; justify-content:space-between;
    padding:72px;
    background:linear-gradient(135deg,#052e16 0%,#09090b 62%);
    color:#fff;
    font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
  }
  .brand { display:flex; align-items:center; gap:14px; font-size:26px; font-weight:700; }
  .logo {
    width:42px; height:42px; border-radius:12px; background:#10b981;
    display:flex; align-items:center; justify-content:center;
    color:#052e16; font-weight:900; font-size:26px;
  }
  .kicker { font-size:22px; font-weight:600; color:#34d399;
    text-transform:uppercase; letter-spacing:3px; margin-bottom:18px; }
  .title { font-size:72px; font-weight:900; line-height:1.05;
    letter-spacing:-2px; max-width:1056px; }
  .tagline { margin-top:22px; font-size:27px; color:#a1a1aa;
    line-height:1.4; max-width:1000px; }
  .foot { display:flex; align-items:center; justify-content:space-between;
    font-size:22px; color:#a1a1aa; }
  .accent { color:#34d399; font-weight:700; }
  </style></head><body>
    <div class="brand"><div class="logo">Z</div><span>Zealova</span></div>
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

  if (pendingTools.length === 0 && pendingStatic.length === 0) {
    console.log(
      `[og] all ${tools.length} tool + ${STATIC_CARDS.length} static cards already present, nothing to render`,
    );
    return;
  }

  console.log(
    `[og] rendering ${pendingTools.length} tool + ${pendingStatic.length} static OG card(s)...`,
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
  console.log(`[og] done. ${ok}/${pendingTools.length + pendingStatic.length} cards rendered.`);
}

main().catch((err) => {
  console.error('[og] generation failed:', err);
  process.exit(1);
});
