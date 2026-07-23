/**
 * Zealova Reel — transparent overlay templates.
 *
 * The video assembler renders one of these per segment to a transparent PNG
 * (1080×1920) and composites it over the scaled b-roll / app-demo clip with
 * ffmpeg. Rendering overlays in HTML (instead of ffmpeg drawtext) keeps the
 * exact brand look — Anton/Barlow, the Exposr-style news bar, big stroked
 * caption words — with zero font-file wrangling.
 *
 * Segment overlay spec:
 *   {
 *     headline?: string,      // bottom "HEADLINE:" news bar (hijack framing)
 *     caption?: string,       // big centered stroked word ("INTACT", "PEROXIDE")
 *     captionAccent?: 'white'|'green'|'red',
 *     captionY?: number,      // 0..1 vertical position of caption (default 0.5)
 *     label?: string,         // small top-left kicker chip (e.g. "SCANNED 3")
 *     brand?: boolean         // show the Zealova chip bottom-right
 *   }
 */

import { BRAND, FONT, VIDEO, fontFacesCss, logoDataUri } from './brand.mjs';

// Universal safe zone (works on BOTH TikTok + IG Reels): keep text/CTAs inside a
// ~900×1400 centered box, out of the platform UI. Numbers are px from each edge
// in the 1080×1920 frame (2026 safe-zone guidance).
export const SAFE = { top: 240, bottom: 470, side: 60, right: 150 };

const esc = (s) =>
  String(s ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');

function captionColor(a) {
  if (a === 'green') return BRAND.accent;
  if (a === 'red') return BRAND.bad;
  return '#ffffff';
}

// Big centered stroked caption word — white fill, heavy black outline.
function captionBlock(seg) {
  if (!seg.caption) return '';
  const top = `${Math.round((seg.captionY ?? 0.5) * 100)}%`;
  const col = captionColor(seg.captionAccent);
  return `<div style="position:absolute;left:0;right:0;top:${top};transform:translateY(-50%);
    text-align:center;padding:0 80px;">
    <span style="display:inline;font-family:${FONT.condensed};font-weight:700;text-transform:uppercase;
      font-size:120px;line-height:1.0;letter-spacing:2px;color:${col};
      -webkit-text-stroke:14px #000;paint-order:stroke fill;
      text-shadow:0 6px 24px rgba(0,0,0,0.6);">${esc(seg.caption)}</span>
  </div>`;
}

// Exposr-style news bar: "HEADLINE:" chip + red tick + the headline. Sits above
// the platform UI (bottom safe margin), styled as a floating lower-third card.
function newsBar(seg) {
  if (!seg.headline) return '';
  return `<div style="position:absolute;left:${SAFE.side}px;right:${SAFE.side}px;bottom:${SAFE.bottom}px;
    background:#0a0a0a;border-radius:14px;padding:36px 40px 40px;box-shadow:0 20px 50px rgba(0,0,0,0.5);">
    <div style="display:inline-flex;align-items:center;background:#fff;padding:10px 22px;
      border-radius:4px;margin-bottom:24px;position:relative;">
      <span style="position:absolute;left:-14px;top:0;bottom:0;width:8px;background:${BRAND.bad};border-radius:3px;"></span>
      <span style="font-family:${FONT.condensed};font-weight:700;text-transform:uppercase;letter-spacing:2px;
        font-size:38px;color:#0a0a0a;">Headline:</span>
    </div>
    <div style="display:flex;align-items:stretch;gap:20px;">
      <div style="width:8px;background:${BRAND.bad};border-radius:3px;flex:0 0 auto;"></div>
      <div style="font-family:${FONT.body};font-weight:800;color:#fff;font-size:58px;line-height:1.08;">${esc(
        seg.headline,
      )}</div>
    </div>
  </div>`;
}

function labelChip(seg) {
  if (!seg.label) return '';
  // A pill background keeps the label legible over an app screen that has its
  // own header text, instead of raw stroked type colliding with it.
  const y = seg.labelY != null ? `${Math.round(seg.labelY * 100)}%` : `${SAFE.top}px`;
  return `<div style="position:absolute;top:${y};left:0;right:0;text-align:center;">
    <span style="display:inline-block;background:rgba(8,8,8,0.62);padding:16px 40px;border-radius:999px;
      backdrop-filter:blur(2px);font-family:${FONT.condensed};font-weight:700;text-transform:uppercase;
      letter-spacing:3px;font-size:60px;color:#fff;box-shadow:0 8px 28px rgba(0,0,0,0.4);">${esc(seg.label)}</span>
  </div>`;
}

function brandMark(seg) {
  if (!seg.brand) return '';
  const logo = logoDataUri();
  return `<div style="position:absolute;bottom:${seg.headline ? SAFE.bottom + 250 : SAFE.bottom}px;right:${SAFE.right}px;display:flex;
    align-items:center;gap:12px;background:rgba(0,0,0,0.42);padding:12px 20px 12px 12px;border-radius:999px;">
    <div style="width:52px;height:52px;border-radius:50%;overflow:hidden;background:#fff;">
      ${logo ? `<img src="${logo}" style="width:100%;height:100%;object-fit:cover"/>` : ''}
    </div>
    <span style="font-family:${FONT.condensed};font-weight:700;text-transform:uppercase;letter-spacing:1px;
      font-size:30px;color:#fff;">${esc(BRAND.appName)}</span>
  </div>`;
}

export function videoOverlayHtml(seg) {
  return `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${fontFacesCss()}
    *{margin:0;padding:0;box-sizing:border-box;}
    html,body{width:${VIDEO.width}px;height:${VIDEO.height}px;background:transparent;}
    .stage{position:relative;width:${VIDEO.width}px;height:${VIDEO.height}px;}
  </style></head><body><div class="stage">
    ${labelChip(seg)}
    ${captionBlock(seg)}
    ${brandMark(seg)}
    ${newsBar(seg)}
  </div></body></html>`;
}
