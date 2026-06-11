#!/usr/bin/env node
/**
 * One-shot screenshot optimizer. Reads public/screenshots/*.png and emits
 * AVIF + WebP variants at 480/768/1080 widths into public/screenshots/opt/.
 *
 * Run manually (NOT part of npm run build — outputs are committed):
 *   node scripts/optimize-images.mjs
 *
 * Consumers render:
 *   <picture>
 *     <source type="image/avif" srcSet=".../opt/name-480.avif 480w, ..." />
 *     <source type="image/webp" srcSet=".../opt/name-480.webp 480w, ..." />
 *     <img src=".../name.png" width={1080} height={2400} loading="lazy" decoding="async" />
 *   </picture>
 */

import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs/promises';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SRC_DIR = path.resolve(__dirname, '../public/screenshots');
const OUT_DIR = path.join(SRC_DIR, 'opt');
const WIDTHS = [480, 768, 1080];

async function main() {
  await fs.mkdir(OUT_DIR, { recursive: true });
  const entries = await fs.readdir(SRC_DIR);
  const pngs = entries.filter((f) => f.endsWith('.png'));
  if (!pngs.length) {
    console.log('[img] No PNGs found in', SRC_DIR);
    return;
  }

  for (const file of pngs) {
    const name = path.basename(file, '.png');
    const input = path.join(SRC_DIR, file);
    const meta = await sharp(input).metadata();

    for (const width of WIDTHS) {
      if (meta.width && width > meta.width) continue;
      const resized = sharp(input).resize({ width });
      const avifOut = path.join(OUT_DIR, `${name}-${width}.avif`);
      const webpOut = path.join(OUT_DIR, `${name}-${width}.webp`);
      await resized.clone().avif({ quality: 55 }).toFile(avifOut);
      await resized.clone().webp({ quality: 78 }).toFile(webpOut);
      const [a, w] = await Promise.all([fs.stat(avifOut), fs.stat(webpOut)]);
      console.log(
        `[img] ${name}-${width}: avif ${(a.size / 1024).toFixed(0)}K, webp ${(w.size / 1024).toFixed(0)}K`
      );
    }
  }
  console.log('[img] Done.');
}

main().catch((err) => {
  console.error('[img] Fatal:', err);
  process.exit(1);
});
