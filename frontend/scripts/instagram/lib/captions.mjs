/**
 * Per-platform caption writer.
 *
 * Research (2026): never post the same file+caption to IG and TikTok — IG
 * suppresses cross-posted/watermarked content and wants trending audio + short
 * captions; TikTok wants original audio + keyword-rich captions. So a spec can
 * carry platform-native captions and we emit one text file per platform.
 *
 * Spec fields (all optional; falls back gracefully):
 *   caption, firstComment, hashtags            // shared fallback
 *   captions: {
 *     instagram: { caption, firstComment?, hashtags?, audio? },
 *     tiktok:    { caption, hashtags?, audio? }
 *   }
 * `audio` is a human note (e.g. "trending sound: <name>" for IG, "original
 * audio / voiceover" for TikTok) written at the top of the file as a reminder.
 */

import path from 'node:path';
import fs from 'node:fs/promises';

function block(c, fallback) {
  const caption = (c?.caption ?? fallback.caption ?? '').trim();
  const hashtags = (c?.hashtags ?? fallback.hashtags ?? []).join(' ');
  const firstComment = (c?.firstComment ?? fallback.firstComment ?? '').trim();
  const audio = c?.audio ? `🎵 AUDIO: ${c.audio}\n\n` : '';
  const parts = [audio + caption, '', hashtags];
  if (firstComment) parts.push('', '— pinned first comment —', firstComment);
  return parts.join('\n').replace(/\n{3,}/g, '\n\n').trim() + '\n';
}

// Write a single caption.txt for ONE platform ('instagram' | 'tiktok'), used when
// output is split into per-platform folders.
export async function writePlatformCaption(outDir, spec, platform) {
  const fallback = { caption: spec.caption, firstComment: spec.firstComment, hashtags: spec.hashtags };
  const c = (spec.captions || {})[platform] || {};
  await fs.writeFile(path.join(outDir, 'caption.txt'), block(c, fallback));
  const fc = c.firstComment ?? (platform === 'instagram' ? spec.firstComment : null);
  if (fc) await fs.writeFile(path.join(outDir, 'first-comment.txt'), String(fc).trim() + '\n');
}

export async function writeCaptions(outDir, spec) {
  const fallback = { caption: spec.caption, firstComment: spec.firstComment, hashtags: spec.hashtags };
  const c = spec.captions || {};
  // Always write a generic caption.txt (fallback / single-platform use).
  await fs.writeFile(path.join(outDir, 'caption.txt'), block(c.instagram || c.tiktok || {}, fallback));
  if (c.instagram) await fs.writeFile(path.join(outDir, 'ig-caption.txt'), block(c.instagram, fallback));
  if (c.tiktok) await fs.writeFile(path.join(outDir, 'tiktok-caption.txt'), block(c.tiktok, fallback));
  if (spec.firstComment && !c.instagram) {
    await fs.writeFile(path.join(outDir, 'first-comment.txt'), spec.firstComment.trim() + '\n');
  }
}
