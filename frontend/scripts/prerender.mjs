#!/usr/bin/env node
/**
 * Post-build static-site generation (SSG) for the Zealova marketing SPA.
 *
 * Why a Puppeteer-based crawler (instead of vite-react-ssg / vite-plugin-ssr):
 *  - Zero refactor of main.tsx (which has auth + fetch side effects that
 *    don't play nicely with a Node SSR entry point).
 *  - Works transparently with React 19 + React Router v7 — no new APIs.
 *  - We only need pre-rendered HTML for LLM/SEO crawlers; React still
 *    hydrates over the markup, so client navigation is unaffected.
 *
 * Flow:
 *  1. `vite build` has already produced `dist/`.
 *  2. We serve `dist/` over a local sirv server with SPA fallback.
 *  3. For each route in ROUTES, we navigate Puppeteer, wait for content,
 *     and write the resulting HTML to `dist/<route>/index.html`.
 *  4. `dist/index.html` (the SPA shell) is preserved for un-pre-rendered
 *     routes that fall through Vercel's rewrite.
 */

import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs/promises';
import http from 'node:http';

const require = createRequire(import.meta.url);
const sirv = require('sirv');

// Vercel's build container is missing system libs that Puppeteer's bundled
// Chrome needs (libnspr4.so etc). On CI we use @sparticuz/chromium, which
// ships a statically-linked Chrome compatible with Amazon Linux 2 / Vercel
// Fluid Compute. Local runs use the regular puppeteer install (faster,
// full-feature). The split is driven by the presence of /vercel in cwd.
// Only flip to sparticuz on the actual Vercel CI build container (path
// /vercel/path0/...). Running `vercel build` locally on macOS also sets
// VERCEL=1 but sparticuz ships a Linux-only binary that ENOEXECs on Darwin.
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

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const DIST = path.join(ROOT, 'dist');

// ---------------------------------------------------------------------------
// Route list — pulled from src/components/tools/calcRegistry.ts at build time.
// We parse the source file rather than import it, so this script has no
// TypeScript dependency.
// ---------------------------------------------------------------------------

async function getToolSlugs() {
  const src = await fs.readFile(
    path.join(ROOT, 'src/components/tools/calcRegistry.ts'),
    'utf8'
  );
  // Match lines like `    slug: 'foo-bar',`
  const slugs = [];
  const re = /^\s*slug:\s*'([^']+)'/gm;
  let m;
  while ((m = re.exec(src)) !== null) slugs.push(m[1]);
  return slugs;
}

async function buildRouteList() {
  const tools = await getToolSlugs();
  const staticRoutes = [
    '/',
    '/features',
    '/pricing',
    '/about',
    '/faq',
    '/contact',
    '/privacy',
    '/terms',
    '/refunds',
    '/health-disclaimer',
    '/architecture',
    '/changelog',
    '/roadmap',
    '/waitlist',
    '/vs/google-health',
    '/vs/bevel',
    '/blog',
    '/free-tools',
    '/glossary',
    '/glossary/1rm',
    '/glossary/tdee',
    '/glossary/bmr',
    '/glossary/macros',
    '/glossary/progressive-overload',
    '/glossary/rir-rpe',
    '/glossary/deload',
    '/glossary/cut-bulk',
    '/glossary/mesocycle',
    '/glossary/wilks-score',
    '/glossary/body-fat-percentage',
    '/glossary/sleep-cycles',
    '/glossary/intermittent-fasting',
    '/glossary/vo2-max',
    '/glossary/zone-2-cardio',
    '/best-ai-fitness-apps-2026',
    '/best-calorie-tracker-apps-2026',
    '/best-workout-generator-apps-2026',
    '/best-fitbit-alternatives-2026',
    '/best-myfitnesspal-alternatives-2026',
    '/free-tools/how-to-get-jacked',
    '/free-tools/how-to-get-ripped',
    '/free-tools/how-to-cut-without-losing-muscle',
    '/free-tools/alcohol-impact-calculator',
    '/free-tools/ai-physique-analyzer',
    '/free-tools/ai-form-check',
    '/free-tools/workout-log-exporter',
    '/free-tools/workout-plan-builder',
    '/free-tools/calorie-deficit-tracker',
    '/free-tools/supplement-stack-analyzer',
  ];
  const toolRoutes = tools.map((s) => `/free-tools/${s}`);
  return [...staticRoutes, ...toolRoutes];
}

// ---------------------------------------------------------------------------
// Static file server (sirv) with SPA fallback. We need the SPA fallback so
// any in-page resource lookup works while Puppeteer renders.
// ---------------------------------------------------------------------------

function startServer(port) {
  return new Promise((resolve, reject) => {
    const serve = sirv(DIST, { single: true, dev: false, etag: true });
    const server = http.createServer((req, res) => serve(req, res));
    server.listen(port, '127.0.0.1', (err) => {
      if (err) return reject(err);
      resolve(server);
    });
    server.on('error', reject);
  });
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const routes = await buildRouteList();
  console.log(`[ssg] Pre-rendering ${routes.length} routes...`);

  // Preserve the pristine Vite-built SPA shell BEFORE we overwrite
  // dist/index.html with the prerendered homepage. Vercel rewrites
  // dynamic routes (/home, /workout/:id, etc.) to this file so users
  // hitting those URLs get an empty shell that hydrates cleanly —
  // not the homepage's hero copy flashing first.
  const shellSrc = path.join(DIST, 'index.html');
  const shellDst = path.join(DIST, '__spa_shell.html');
  await fs.copyFile(shellSrc, shellDst);

  const port = 4321;
  const server = await startServer(port);
  const baseUrl = `http://127.0.0.1:${port}`;

  const browser = await puppeteer.launch({
    headless: 'new',
    args: chromiumArgs,
    ...(chromiumExecutablePath ? { executablePath: chromiumExecutablePath } : {}),
  });

  let ok = 0;
  let failed = 0;
  let homepageHtml = null;

  // Render a single route. Returns true on success, false on failure.
  // Caller may retry failed routes with a longer wait timeout — early
  // routes sometimes time out while Vite's lazy-loaded page chunks warm
  // up the disk cache.
  async function renderRoute(route, waitTimeout) {
    // Fresh incognito browser context per route. We tried reusing a single
    // page (Supabase websocket detached the frame) and creating new pages
    // off the default context (Chrome accumulated 60+ renderer processes
    // and hung). An isolated context tears down ALL associated renderer
    // processes on close, keeping memory + handle counts flat.
    const context = await browser.createBrowserContext();
    const page = await context.newPage();
    page.on('pageerror', () => {});
    page.on('console', () => {});

    // Block off-origin network (Supabase realtime, Google Fonts, etc.) so
    // the page doesn't hang on `networkidle`. Same-origin assets load.
    await page.setRequestInterception(true);
    page.on('request', (req) => {
      const url = req.url();
      if (url.startsWith(baseUrl)) {
        if (url.includes('/session-reset.json')) {
          return req.respond({ status: 404, body: '' });
        }
        return req.continue();
      }
      return req.abort();
    });

    try {
      await page.goto(`${baseUrl}${route}`, {
        waitUntil: 'load',
        timeout: 30000,
      });

      // Wait for React to render content into #root.
      await page.waitForFunction(
        () => {
          const root = document.getElementById('root');
          return root && root.children.length > 0;
        },
        { timeout: waitTimeout }
      );

      // Small settle delay so animations / lazy components paint.
      await new Promise((r) => setTimeout(r, 300));

      const html = await page.evaluate(
        () => '<!DOCTYPE html>' + document.documentElement.outerHTML
      );

      // CRITICAL: never write to dist/index.html during the run. sirv serves
      // it as the SPA fallback for EVERY non-existent path, and once it
      // contains prerendered React content, React's createRoot on subsequent
      // routes hits "Target container is not a DOM element" / error #299
      // (rendering halts and #root stays empty). We stash the homepage
      // prerender to a buffer and write it last, after the server stops.
      if (route === '/') {
        homepageHtml = html;
      } else {
        const outDir = path.join(DIST, route.replace(/^\//, ''));
        await fs.mkdir(outDir, { recursive: true });
        await fs.writeFile(path.join(outDir, 'index.html'), html);
      }

      console.log(`[ssg] OK  ${route}`);
      return true;
    } catch (err) {
      console.error(`[ssg] FAIL ${route}: ${err.message}`);
      return false;
    } finally {
      try { await page.close(); } catch { /* ignore */ }
      try { await context.close(); } catch { /* ignore */ }
    }
  }

  try {
    const failedRoutes = [];
    for (const route of routes) {
      const success = await renderRoute(route, 15000);
      if (success) ok++; else failedRoutes.push(route);
    }
    // Retry pass with a 45s wait — covers first-hit chunk warm-up timeouts.
    if (failedRoutes.length) {
      console.log(`[ssg] Retrying ${failedRoutes.length} failed routes...`);
      for (const route of failedRoutes) {
        const success = await renderRoute(route, 45000);
        if (success) ok++; else failed++;
      }
    }
  } finally {
    await browser.close();
    server.close();
  }

  // Write the homepage prerender AFTER the local server has been torn down
  // so it doesn't pollute the SPA fallback served during the run.
  if (homepageHtml) {
    await fs.writeFile(path.join(DIST, 'index.html'), homepageHtml);
  }

  console.log(`[ssg] Done. ${ok} succeeded, ${failed} failed.`);
  if (failed > 0) process.exitCode = 1;
}

main().catch((err) => {
  console.error('[ssg] Fatal:', err);
  process.exit(1);
});
