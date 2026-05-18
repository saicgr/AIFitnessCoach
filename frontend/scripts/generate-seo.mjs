#!/usr/bin/env node
/**
 * Regenerates public/sitemap.xml and the tool-list section of public/llms.txt
 * from the single source of truth (src/components/tools/calcRegistry.ts plus
 * the static route list below).
 *
 * Runs at build time so neither file can drift behind the registry again.
 * The llms.txt prose (intro, pricing, citations, contact) is preserved — only
 * the block between the "## Free tools" heading and the next "## " heading is
 * rewritten.
 */

import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs/promises';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const DOMAIN = 'https://zealova.com';

// Non-tool routes that belong in the sitemap. Tool routes are appended
// automatically from the registry.
const STATIC_ROUTES = [
  { path: '/', priority: '1.0', changefreq: 'weekly' },
  { path: '/features', priority: '0.9', changefreq: 'weekly' },
  { path: '/pricing', priority: '0.9', changefreq: 'weekly' },
  { path: '/free-tools', priority: '0.9', changefreq: 'weekly' },
  { path: '/blog', priority: '0.8', changefreq: 'weekly' },
  { path: '/glossary', priority: '0.7', changefreq: 'monthly' },
  { path: '/faq', priority: '0.6', changefreq: 'monthly' },
  { path: '/about', priority: '0.5', changefreq: 'monthly' },
  { path: '/contact', priority: '0.4', changefreq: 'monthly' },
  { path: '/roadmap', priority: '0.5', changefreq: 'monthly' },
  { path: '/changelog', priority: '0.4', changefreq: 'monthly' },
  { path: '/architecture', priority: '0.4', changefreq: 'monthly' },
  { path: '/waitlist', priority: '0.6', changefreq: 'monthly' },
  { path: '/privacy', priority: '0.3', changefreq: 'yearly' },
  { path: '/terms', priority: '0.3', changefreq: 'yearly' },
  { path: '/refunds', priority: '0.3', changefreq: 'yearly' },
  { path: '/health-disclaimer', priority: '0.3', changefreq: 'yearly' },
  { path: '/vs/google-health', priority: '0.7', changefreq: 'monthly' },
  { path: '/vs/bevel', priority: '0.7', changefreq: 'monthly' },
  { path: '/blog/google-health-coach-hallucination', priority: '0.7', changefreq: 'monthly' },
  { path: '/best-ai-fitness-apps-2026', priority: '0.7', changefreq: 'monthly' },
  { path: '/best-calorie-tracker-apps-2026', priority: '0.7', changefreq: 'monthly' },
  { path: '/best-workout-generator-apps-2026', priority: '0.7', changefreq: 'monthly' },
  { path: '/best-fitbit-alternatives-2026', priority: '0.7', changefreq: 'monthly' },
  { path: '/best-myfitnesspal-alternatives-2026', priority: '0.7', changefreq: 'monthly' },
];

const GLOSSARY_SLUGS = [
  '1rm', 'tdee', 'bmr', 'macros', 'progressive-overload', 'rir-rpe', 'deload',
  'cut-bulk', 'mesocycle', 'wilks-score', 'body-fat-percentage', 'sleep-cycles',
  'intermittent-fasting', 'vo2-max', 'zone-2-cardio',
];

/**
 * Parse calcRegistry.ts. Each entry is an object literal with slug / name /
 * description fields. We grab them with a tolerant regex rather than importing
 * the TS module (this script has no TS toolchain).
 */
async function parseRegistry() {
  const src = await fs.readFile(
    path.join(ROOT, 'src/components/tools/calcRegistry.ts'),
    'utf8',
  );
  const tools = [];
  // Split on `slug:` so each chunk holds one entry's remaining fields.
  const slugRe = /slug:\s*'([^']+)'/g;
  let m;
  while ((m = slugRe.exec(src)) !== null) {
    const slug = m[1];
    // Look ahead a bounded window for this entry's name + description.
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

function escapeXml(s) {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

async function writeSitemap(tools) {
  const today = new Date().toISOString().slice(0, 10);
  const rows = [];

  for (const r of STATIC_ROUTES) {
    rows.push(
      `  <url>\n    <loc>${DOMAIN}${r.path === '/' ? '' : r.path}</loc>\n` +
        `    <lastmod>${today}</lastmod>\n` +
        `    <changefreq>${r.changefreq}</changefreq>\n` +
        `    <priority>${r.priority}</priority>\n  </url>`,
    );
  }
  for (const t of tools) {
    rows.push(
      `  <url>\n    <loc>${DOMAIN}/free-tools/${t.slug}</loc>\n` +
        `    <lastmod>${today}</lastmod>\n` +
        `    <changefreq>monthly</changefreq>\n` +
        `    <priority>0.8</priority>\n  </url>`,
    );
  }
  for (const slug of GLOSSARY_SLUGS) {
    rows.push(
      `  <url>\n    <loc>${DOMAIN}/glossary/${slug}</loc>\n` +
        `    <lastmod>${today}</lastmod>\n` +
        `    <changefreq>monthly</changefreq>\n` +
        `    <priority>0.6</priority>\n  </url>`,
    );
  }

  const xml =
    '<?xml version="1.0" encoding="UTF-8"?>\n' +
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
    rows.join('\n') +
    '\n</urlset>\n';

  await fs.writeFile(path.join(ROOT, 'public/sitemap.xml'), xml);
  return STATIC_ROUTES.length + tools.length + GLOSSARY_SLUGS.length;
}

async function patchLlmsTxt(tools) {
  const file = path.join(ROOT, 'public/llms.txt');
  const txt = await fs.readFile(file, 'utf8');
  const lines = txt.split('\n');

  // Find the "## Free tools" heading and the next "## " heading after it.
  const startIdx = lines.findIndex((l) => /^## Free tools/.test(l));
  if (startIdx === -1) {
    console.warn('[seo] llms.txt: no "## Free tools" heading, skipping patch');
    return 0;
  }
  let endIdx = lines.length;
  for (let i = startIdx + 1; i < lines.length; i++) {
    if (/^## /.test(lines[i])) {
      endIdx = i;
      break;
    }
  }

  const toolLines = tools.map(
    (t) =>
      `- [/free-tools/${t.slug}](${DOMAIN}/free-tools/${t.slug}): ${t.description || t.name}`,
  );

  const block = [
    '## Free tools (no sign-up, no paywall)',
    '',
    `Zealova publishes ${tools.length} free fitness tools and calculators at ` +
      `zealova.com/free-tools. Several are AI-powered (form check, food photo, ` +
      `physique analyzer, workout generator) and rate-limited per IP.`,
    '',
    `- [/free-tools](${DOMAIN}/free-tools): full directory of all ${tools.length} tools`,
    ...toolLines,
    '',
  ];

  const next = [...lines.slice(0, startIdx), ...block, ...lines.slice(endIdx)];
  await fs.writeFile(file, next.join('\n'));
  return tools.length;
}

async function main() {
  const tools = await parseRegistry();
  const sitemapCount = await writeSitemap(tools);
  const llmsCount = await patchLlmsTxt(tools);
  console.log(
    `[seo] sitemap.xml: ${sitemapCount} URLs · llms.txt: ${llmsCount} tools listed`,
  );
}

main().catch((err) => {
  console.error('[seo] generation failed:', err);
  process.exit(1);
});
