#!/usr/bin/env node
// Conditional prerender wrapper.
//
// Vercel cloud builds run on a 2-core / 8 GB container that OOMs partway
// through our 99-route Puppeteer crawl, and `puppeteer` ships a Chrome
// missing libnspr4.so. So on Vercel CI we deploy SPA + edge functions only;
// SSG HTML lands via `vercel deploy --prebuilt` from a local build.
//
// Skip-condition: when cwd is under /vercel (the Vercel build container).

import { spawn } from 'node:child_process';

const isVercelCloud = process.cwd().startsWith('/vercel');

if (isVercelCloud) {
  console.log('[prerender-if-local] Skipping SSG on Vercel cloud build (use `vercel build && vercel deploy --prebuilt` from local).');
  process.exit(0);
}

const child = spawn('node', ['scripts/prerender.mjs'], { stdio: 'inherit' });
child.on('exit', (code) => process.exit(code ?? 1));
