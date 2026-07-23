/**
 * Zealova Instagram carousel — slide HTML templates.
 *
 * Each exported builder returns a full standalone HTML document (so the
 * renderer just calls page.setContent → screenshot). Every slide is
 * 1080×1350. Layouts are modeled on the proven Exposr carousel grammar
 * (shock hook → side-by-side comparison scorecards → app-proof → CTA) but
 * rendered in Zealova's App-Store brand.
 *
 * Slide spec shapes are documented in ../specs/README-spec.md and validated
 * loosely at render time (missing optional fields degrade gracefully).
 */

import { BRAND, FONT, CAROUSEL, fontFacesCss, logoDataUri, imageDataUri } from './brand.mjs';

// Canvas size is mutable so one template set renders both IG 4:5 (1080×1350) and
// TikTok Photo Mode 9:16 (1080×1920). The renderer calls setCanvas() first.
let CANVAS = { width: CAROUSEL.width, height: CAROUSEL.height };
export function setCanvas(size) {
  CANVAS = { width: size.width, height: size.height };
}

const esc = (s) =>
  String(s ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');

// Inline highlights inside a headline: [[word]] -> the slide accent,
// {{word}} -> the "bad" red. Lets one line show a green win and a red loss.
const hl = (s, color) =>
  esc(s)
    .replace(/\[\[(.+?)\]\]/g, `<span style="color:${color}">$1</span>`)
    .replace(/\{\{(.+?)\}\}/g, `<span style="color:${BRAND.bad}">$1</span>`);

// ---------------------------------------------------------------------------
// Shared components
// ---------------------------------------------------------------------------

// The circular apple-style watermark Exposr uses — here the Zealova mark.
function brandChip({ size = 74, ring = true } = {}) {
  const logo = logoDataUri();
  const inner = logo
    ? `<img src="${logo}" alt="" style="width:100%;height:100%;object-fit:cover"/>`
    : `<span style="font-family:${FONT.display};font-size:${size * 0.42}px;color:${BRAND.dark}">Z</span>`;
  return `<div style="width:${size}px;height:${size}px;border-radius:50%;overflow:hidden;
    background:#fff;display:flex;align-items:center;justify-content:center;
    ${ring ? `box-shadow:0 0 0 3px rgba(0,0,0,0.06),0 6px 20px rgba(0,0,0,0.18)` : ''};">${inner}</div>`;
}

// A small pill: label + handle, bottom-of-slide branding.
function handleRow({ dark = false } = {}) {
  const col = dark ? BRAND.darkSoft : BRAND.muted;
  return `<div style="display:flex;align-items:center;gap:12px;justify-content:center;
    font-family:${FONT.condensed};font-weight:600;letter-spacing:2px;text-transform:uppercase;
    font-size:26px;color:${col};">
      ${brandChip({ size: 46, ring: false })}
      <span>${esc(BRAND.appName)} · ${esc(BRAND.handle)}</span>
    </div>`;
}

function scoreColor(score) {
  if (score >= 65) return BRAND.good;
  if (score >= 40) return '#E0A200';
  return BRAND.bad;
}

// SVG score ring (matches the app's /100 result ring).
function scoreRing(score, { size = 132, stroke = 12 } = {}) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const pct = Math.max(0, Math.min(100, Number(score) || 0)) / 100;
  const col = scoreColor(score);
  return `<svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
    <circle cx="${size / 2}" cy="${size / 2}" r="${r}" fill="none" stroke="${col}22" stroke-width="${stroke}"/>
    <circle cx="${size / 2}" cy="${size / 2}" r="${r}" fill="none" stroke="${col}" stroke-width="${stroke}"
      stroke-linecap="round" stroke-dasharray="${c}" stroke-dashoffset="${c * (1 - pct)}"
      transform="rotate(-90 ${size / 2} ${size / 2})"/>
    <text x="50%" y="50%" text-anchor="middle" dominant-baseline="central"
      font-family="${FONT.display}" font-size="${size * 0.34}px" fill="${col}">${Math.round(score)}</text>
    <text x="50%" y="${size * 0.66}" text-anchor="middle"
      font-family="${FONT.body}" font-weight="700" font-size="${size * 0.11}px" fill="${BRAND.muted}">/100</text>
  </svg>`;
}

// Auto-fit the big stat/number so a long string (a name cluster, a phrase) can't
// overflow the slide the way a short number wouldn't. Length is measured without
// the [[ ]] / {{ }} highlight markers.
function bigFontSize(s) {
  const n = String(s || '').replace(/\[\[|\]\]|\{\{|\}\}/g, '').length;
  if (n <= 3) return 280;
  if (n <= 5) return 208;
  if (n <= 8) return 150;
  if (n <= 12) return 112;
  if (n <= 18) return 82;
  if (n <= 26) return 62;
  return 48;
}

function gradePill(grade) {
  const g = String(grade || '').toLowerCase();
  let bg = BRAND.badSoft,
    fg = BRAND.bad;
  if (g.includes('good') || g.includes('excellent')) {
    bg = BRAND.goodSoft;
    fg = BRAND.good;
  } else if (g.includes('ok') || g.includes('fair')) {
    bg = '#F6ECCF';
    fg = '#9A7400';
  }
  return `<span style="display:inline-block;padding:6px 16px;border-radius:999px;background:${bg};
    color:${fg};font-family:${FONT.condensed};font-weight:700;font-size:24px;text-transform:uppercase;
    letter-spacing:1px;">${esc(grade)}</span>`;
}

// The little app scorecard used at the top of a comparison column.
function miniScoreCard({ name, subtitle, score, grade }) {
  return `<div style="background:#fff;border-radius:22px;padding:22px 24px;display:flex;
    align-items:center;justify-content:space-between;gap:16px;box-shadow:0 8px 24px rgba(0,0,0,0.06);">
    <div style="min-width:0;">
      <div style="font-family:${FONT.body};font-weight:800;font-size:30px;line-height:1.12;color:${BRAND.ink};
        display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;">${esc(name)}</div>
      ${subtitle ? `<div style="font-size:22px;color:${BRAND.muted};margin-top:4px;">${esc(subtitle)}</div>` : ''}
      <div style="margin-top:14px;">${gradePill(grade)}</div>
    </div>
    ${scoreRing(score, { size: 104, stroke: 10 })}
  </div>`;
}

// A red/green attribute row (the heart of a comparison).
function bulletRow(item, side) {
  const dot = side === 'good' ? BRAND.good : BRAND.bad;
  const valCol = side === 'good' ? BRAND.good : BRAND.bad;
  return `<div style="display:flex;align-items:flex-start;gap:14px;padding:20px 4px;">
    <span style="flex:0 0 auto;width:18px;height:18px;border-radius:50%;background:${dot};margin-top:7px;"></span>
    <div style="font-size:30px;line-height:1.25;color:${BRAND.ink};">
      <span style="font-weight:800;">${esc(item.label)}</span>
      ${item.value ? ` · <span style="color:${valCol};font-weight:700;">${esc(item.value)}</span>` : ''}
    </div>
  </div>`;
}

// Phone mockup wrapping a real app screenshot.
function phoneFrame(screenshotPath, { width = 470 } = {}) {
  const uri = imageDataUri(screenshotPath);
  const inner = uri
    ? `<img src="${uri}" alt="" style="width:100%;display:block;"/>`
    : `<div style="width:100%;aspect-ratio:9/19.5;background:#111;display:flex;align-items:center;
        justify-content:center;color:#555;font-family:${FONT.condensed};font-size:28px;">screenshot missing</div>`;
  return `<div style="width:${width}px;border-radius:52px;background:#0b0b0b;padding:12px;
    box-shadow:0 40px 80px rgba(0,0,0,0.45),0 0 0 2px rgba(255,255,255,0.06) inset;">
    <div style="border-radius:42px;overflow:hidden;background:#000;">${inner}</div>
  </div>`;
}

function doc(inner, { bg } = {}) {
  return `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${fontFacesCss()}
    *{margin:0;padding:0;box-sizing:border-box;-webkit-font-smoothing:antialiased;}
    html,body{width:${CANVAS.width}px;height:${CANVAS.height}px;overflow:hidden;}
    body{font-family:${FONT.body};color:${BRAND.ink};}
    .stage{position:relative;width:${CANVAS.width}px;height:${CANVAS.height}px;background:${bg};overflow:hidden;}
  </style></head><body><div class="stage">${inner}</div></body></html>`;
}

// ---------------------------------------------------------------------------
// Slide builders
// ---------------------------------------------------------------------------

/**
 * HOOK — the swipe-stopping opener. Photo background (optional) with a dark
 * scrim + a huge Anton headline, an optional corner emblem, and the brand chip.
 * spec: { type:'hook', image?, badge?(emoji/img path), kicker?, headline, accent?('green'|'red') }
 */
export function hookSlide(spec) {
  const accent = spec.accent === 'red' ? BRAND.bad : BRAND.accent;
  const bgImg = imageDataUri(spec.image);
  const emblem = spec.badge
    ? (imageDataUri(spec.badge)
        ? `<img src="${imageDataUri(spec.badge)}" style="width:100%;height:100%;object-fit:cover;border-radius:50%"/>`
        : `<span style="font-size:96px;line-height:150px;">${esc(spec.badge)}</span>`)
    : '';
  return doc(
    `
    ${bgImg ? `<img src="${bgImg}" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover;"/>` : ''}
    <div style="position:absolute;inset:0;background:${
      bgImg
        ? 'linear-gradient(180deg,rgba(0,0,0,0.35) 0%,rgba(0,0,0,0.15) 40%,rgba(0,0,0,0.82) 100%)'
        : BRAND.dark
    };"></div>
    ${
      emblem
        ? `<div style="position:absolute;top:64px;left:64px;width:150px;height:150px;border-radius:50%;
            background:#fff;display:flex;align-items:center;justify-content:center;overflow:hidden;
            box-shadow:0 10px 30px rgba(0,0,0,0.35);border:5px solid #fff;">${emblem}</div>`
        : ''
    }
    <div style="position:absolute;left:0;right:0;bottom:0;padding:70px 64px 64px;">
      ${
        spec.kicker
          ? `<div style="font-family:${FONT.condensed};font-weight:700;text-transform:uppercase;
              letter-spacing:5px;font-size:30px;color:${accent};margin-bottom:20px;">${esc(spec.kicker)}</div>`
          : ''
      }
      <div style="display:flex;align-items:center;gap:24px;margin-bottom:34px;">
        <div style="flex:1;height:2px;background:rgba(255,255,255,0.35);"></div>
        ${brandChip({ size: 70 })}
        <div style="flex:1;height:2px;background:rgba(255,255,255,0.35);"></div>
      </div>
      <div style="font-family:${FONT.display};color:#fff;text-transform:uppercase;
        font-size:96px;line-height:0.98;letter-spacing:0.5px;text-align:center;">
        ${hl(spec.headline, accent)}
      </div>
    </div>`,
    { bg: BRAND.dark },
  );
}

/**
 * COMPARE — the proof: bad column vs good column, each a mini score card,
 * product image, and red/green attribute bullets. Modeled on Exposr slides 2-5.
 * spec: { type:'compare', title?, bad:{name,subtitle?,score,grade,image?,bullets:[{label,value}]},
 *         good:{...same} }
 */
export function compareSlide(spec) {
  const col = (data, side) => {
    const img = imageDataUri(data.image);
    return `<div style="flex:1;display:flex;flex-direction:column;gap:22px;min-width:0;">
      ${miniScoreCard(data)}
      ${
        img
          ? `<div style="height:300px;display:flex;align-items:center;justify-content:center;">
              <img src="${img}" style="max-width:100%;max-height:100%;object-fit:contain;
                filter:drop-shadow(0 14px 26px rgba(0,0,0,0.16));"/></div>`
          : ''
      }
      <div style="border-top:2px solid ${BRAND.panelLine};padding-top:6px;">
        ${(data.bullets || [])
          .slice(0, 3)
          .map((b) => bulletRow(b, side))
          .join(`<div style="height:1px;background:${BRAND.panelLine};"></div>`)}
      </div>
    </div>`;
  };
  return doc(
    `
    <div style="position:absolute;inset:0;padding:56px 52px;display:flex;flex-direction:column;">
      ${
        spec.title
          ? `<div style="font-family:${FONT.condensed};font-weight:700;text-transform:uppercase;
              letter-spacing:3px;font-size:34px;color:${BRAND.ink};text-align:center;margin-bottom:34px;">
              ${hl(spec.title, BRAND.accent)}</div>`
          : ''
      }
      <div style="flex:1;display:flex;gap:40px;">
        ${col(spec.bad, 'bad')}
        ${col(spec.good, 'good')}
      </div>
    </div>`,
    { bg: BRAND.panel },
  );
}

/**
 * APPPROOF — a real app screenshot in a phone frame with a headline. The
 * "here's the actual app" payoff frame.
 * spec: { type:'appProof', image(bg?), headline, sub?, screenshot(path) }
 */
export function appProofSlide(spec) {
  const bgImg = imageDataUri(spec.image);
  return doc(
    `
    ${bgImg ? `<img src="${bgImg}" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover;"/>` : ''}
    <div style="position:absolute;inset:0;background:${
      bgImg ? 'linear-gradient(180deg,rgba(0,0,0,0.78) 0%,rgba(0,0,0,0.45) 100%)' : BRAND.dark
    };"></div>
    <div style="position:absolute;inset:0;padding:72px 64px;display:flex;flex-direction:column;">
      <div style="font-family:${FONT.display};color:#fff;text-transform:uppercase;font-size:82px;line-height:0.98;">
        ${hl(spec.headline, BRAND.accent)}</div>
      ${
        spec.sub
          ? `<div style="font-size:33px;line-height:1.35;color:#e9e9e9;margin-top:22px;max-width:900px;">${hl(
              spec.sub,
              BRAND.accent,
            )}</div>`
          : ''
      }
      <div style="flex:1;display:flex;align-items:flex-end;justify-content:center;">
        ${phoneFrame(spec.screenshot, { width: 452 })}
      </div>
    </div>`,
    { bg: BRAND.dark },
  );
}

/**
 * STAT — a single bold claim/number slide on cream. Good for a mid-carousel
 * "the one number" beat.
 * spec: { type:'stat', kicker?, big, headline?, foot? }
 */
export function statSlide(spec) {
  const bgImg = imageDataUri(spec.image);
  const onDark = !!bgImg;
  const bigCol = onDark ? '#fff' : BRAND.ink;
  const headCol = onDark ? '#fff' : BRAND.ink;
  const footCol = onDark ? '#e4e4e4' : BRAND.inkSoft;
  return doc(
    `
    ${bgImg ? `<img src="${bgImg}" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover;"/>` : ''}
    ${
      bgImg
        ? `<div style="position:absolute;inset:0;background:linear-gradient(180deg,rgba(0,0,0,0.55) 0%,rgba(0,0,0,0.35) 45%,rgba(0,0,0,0.8) 100%);"></div>`
        : ''
    }
    <div style="position:absolute;inset:0;padding:80px 72px;display:flex;flex-direction:column;justify-content:center;gap:24px;">
      ${
        spec.kicker
          ? `<div style="font-family:${FONT.condensed};font-weight:700;text-transform:uppercase;
              letter-spacing:5px;font-size:32px;color:${BRAND.accent};">${esc(spec.kicker)}</div>`
          : ''
      }
      <div style="font-family:${FONT.display};font-size:${bigFontSize(spec.big)}px;line-height:0.9;color:${bigCol};
        text-transform:uppercase;word-break:break-word;${onDark ? 'text-shadow:0 4px 24px rgba(0,0,0,0.5);' : ''}">${hl(spec.big, BRAND.bad)}</div>
      ${
        spec.headline
          ? `<div style="font-family:${FONT.display};text-transform:uppercase;font-size:70px;line-height:1.0;color:${headCol};">${hl(
              spec.headline,
              BRAND.accent,
            )}</div>`
          : ''
      }
      ${spec.foot ? `<div style="font-size:32px;color:${footCol};line-height:1.4;max-width:880px;">${esc(spec.foot)}</div>` : ''}
    </div>
    <div style="position:absolute;bottom:56px;left:0;right:0;">${handleRow({ dark: onDark })}</div>`,
    { bg: onDark ? BRAND.dark : BRAND.canvas },
  );
}

/**
 * CTA — the closer. Dark, phone screenshot, "comment 'app'" style call.
 * spec: { type:'cta', image(bg?), headline, sub?, screenshot?, comment?('app') }
 */
export function ctaSlide(spec) {
  const bgImg = imageDataUri(spec.image);
  return doc(
    `
    ${bgImg ? `<img src="${bgImg}" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover;"/>` : ''}
    <div style="position:absolute;inset:0;background:${
      bgImg ? 'linear-gradient(180deg,rgba(0,0,0,0.72) 0%,rgba(0,0,0,0.4) 55%,rgba(0,0,0,0.85) 100%)' : BRAND.dark
    };"></div>
    <div style="position:absolute;inset:0;padding:76px 64px;display:flex;flex-direction:column;">
      <div style="font-family:${FONT.display};color:#fff;text-transform:uppercase;font-size:92px;line-height:0.96;">
        ${hl(spec.headline, BRAND.accent)}</div>
      ${
        spec.sub
          ? `<div style="font-size:36px;line-height:1.35;color:#eaeaea;margin-top:24px;max-width:920px;">${hl(
              spec.sub,
              BRAND.accent,
            )}</div>`
          : ''
      }
      <div style="flex:1;display:flex;align-items:center;justify-content:center;">
        ${spec.screenshot ? phoneFrame(spec.screenshot, { width: 440 }) : ''}
      </div>
      ${
        spec.comment
          ? `<div style="display:flex;justify-content:center;margin-bottom:14px;">
              <span style="background:${BRAND.accent};color:#062611;font-family:${FONT.condensed};font-weight:700;
                text-transform:uppercase;letter-spacing:1px;font-size:36px;padding:18px 40px;border-radius:999px;">
                Comment "${esc(spec.comment)}"</span></div>`
          : ''
      }
      ${handleRow({ dark: true })}
    </div>`,
    { bg: BRAND.dark },
  );
}

// A big glowing score ring — Zealova's "reveal" hero visual (its scorecard).
function bigRing(score, { size = 520, stroke = 34 } = {}) {
  const col = scoreColor(score);
  return `<div style="filter:drop-shadow(0 0 60px ${col}aa) drop-shadow(0 0 14px ${col});">
    ${scoreRing(score, { size, stroke })}</div>`;
}

// Dark stage with a green performance-dashboard glow.
function darkGlow() {
  return `<div style="position:absolute;inset:0;background:
    radial-gradient(70% 55% at 50% 42%, ${BRAND.accent}22, transparent 62%),
    radial-gradient(90% 60% at 50% 120%, rgba(18,178,75,0.14), transparent 60%),
    ${BRAND.dark};"></div>`;
}

/**
 * SCORE — the reveal. A large glowing score ring on dark (Zealova's scorecard).
 * spec: { type:'score', kicker?, score, grade?, headline?, foot? }
 */
export function scoreSlide(spec) {
  const col = scoreColor(spec.score);
  return doc(
    `
    ${darkGlow()}
    <div style="position:absolute;inset:0;padding:80px 64px;display:flex;flex-direction:column;
      align-items:center;justify-content:center;text-align:center;gap:30px;">
      ${
        spec.kicker
          ? `<div style="font-family:${FONT.condensed};font-weight:700;text-transform:uppercase;
              letter-spacing:6px;font-size:34px;color:${BRAND.accent};">${esc(spec.kicker)}</div>`
          : ''
      }
      ${bigRing(spec.score)}
      ${
        spec.grade
          ? `<div style="font-family:${FONT.display};text-transform:uppercase;font-size:76px;color:${col};line-height:1;">${esc(
              spec.grade,
            )}</div>`
          : ''
      }
      ${
        spec.headline
          ? `<div style="font-family:${FONT.display};text-transform:uppercase;font-size:60px;color:#fff;line-height:1.0;">${hl(
              spec.headline,
              BRAND.accent,
            )}</div>`
          : ''
      }
      ${spec.foot ? `<div style="font-size:32px;color:${BRAND.darkSoft};line-height:1.4;max-width:820px;">${esc(spec.foot)}</div>` : ''}
    </div>`,
    { bg: BRAND.dark },
  );
}

/**
 * SUBSCORES — the breakdown, native metric bars on dark.
 * spec: { type:'subscores', title?, metrics:[{label,value,max?}], foot? }
 */
export function subscoresSlide(spec) {
  const rows = (spec.metrics || [])
    .map((m) => {
      const max = m.max || 100;
      const pct = Math.max(4, Math.min(100, (Number(m.value) / max) * 100));
      const col = scoreColor((Number(m.value) / max) * 100);
      return `<div style="margin-bottom:52px;">
        <div style="display:flex;justify-content:space-between;align-items:baseline;margin-bottom:16px;">
          <span style="font-family:${FONT.condensed};font-weight:700;text-transform:uppercase;letter-spacing:2px;
            font-size:46px;color:#fff;">${esc(m.label)}</span>
          <span style="font-family:${FONT.display};font-size:64px;color:${col};">${esc(m.value)}${m.max ? '' : ''}</span>
        </div>
        <div style="height:22px;border-radius:999px;background:#ffffff18;overflow:hidden;">
          <div style="height:100%;width:${pct}%;border-radius:999px;background:${col};
            box-shadow:0 0 24px ${col}aa;"></div>
        </div>
      </div>`;
    })
    .join('');
  return doc(
    `
    ${darkGlow()}
    <div style="position:absolute;inset:0;padding:90px 72px;display:flex;flex-direction:column;justify-content:center;">
      ${
        spec.title
          ? `<div style="font-family:${FONT.display};text-transform:uppercase;font-size:78px;color:#fff;line-height:0.98;margin-bottom:64px;">${hl(
              spec.title,
              BRAND.accent,
            )}</div>`
          : ''
      }
      ${rows}
      ${spec.foot ? `<div style="font-size:34px;color:${BRAND.darkSoft};line-height:1.4;margin-top:20px;">${esc(spec.foot)}</div>` : ''}
    </div>
    <div style="position:absolute;bottom:56px;left:0;right:0;">${handleRow({ dark: true })}</div>`,
    { bg: BRAND.dark },
  );
}

function hashStr(s) {
  let h = 0;
  for (let i = 0; i < String(s).length; i++) h = (h * 31 + String(s).charCodeAt(i)) | 0;
  return Math.abs(h);
}

/**
 * INSIGHT — "the app caught something" (the AI-knows-you moment).
 * spec: { type:'insight', kicker?, headline, detail?, stat?{value,label}, screenshot? }
 */
export function insightSlide(spec) {
  const shot = spec.screenshot ? phoneFrame(spec.screenshot, { width: 300 }) : '';
  const stat = spec.stat
    ? `<div style="display:flex;align-items:center;gap:26px;">
        <span style="font-family:${FONT.display};font-size:130px;color:${BRAND.bad};line-height:0.9;">${esc(spec.stat.value)}</span>
        <span style="font-size:34px;color:${BRAND.darkSoft};line-height:1.25;max-width:520px;">${esc(spec.stat.label)}</span>
      </div>`
    : '';
  return doc(
    `${darkGlow()}
    <div style="position:absolute;inset:0;padding:84px 64px;display:flex;flex-direction:column;justify-content:center;gap:30px;">
      <div style="font-family:${FONT.condensed};font-weight:700;text-transform:uppercase;letter-spacing:5px;
        font-size:32px;color:${BRAND.accent};">${esc(spec.kicker || 'Your coach noticed')}</div>
      <div style="font-family:${FONT.display};text-transform:uppercase;font-size:86px;line-height:0.98;color:#fff;">${hl(
        spec.headline,
        BRAND.accent,
      )}</div>
      ${stat}
      ${spec.detail ? `<div style="font-size:34px;color:${BRAND.darkSoft};line-height:1.4;max-width:900px;">${esc(spec.detail)}</div>` : ''}
      ${shot ? `<div style="display:flex;justify-content:center;margin-top:10px;">${shot}</div>` : ''}
    </div>`,
    { bg: BRAND.dark },
  );
}

/**
 * TIMELINE — vertical stages over time (fasting clock, program phases).
 * spec: { type:'timeline', title?, stages:[{time?,name,note?,highlight?}] }
 */
export function timelineSlide(spec) {
  const arr = spec.stages || [];
  const stages = arr
    .map((s, i) => {
      const on = s.highlight;
      const ring = on ? BRAND.accent : '#ffffff45';
      return `<div style="display:flex;gap:28px;align-items:flex-start;">
        <div style="display:flex;flex-direction:column;align-items:center;flex:0 0 auto;">
          <div style="width:30px;height:30px;border-radius:50%;background:${on ? BRAND.accent : '#0a0a0a'};
            border:5px solid ${ring};${on ? `box-shadow:0 0 26px ${BRAND.accent};` : ''}"></div>
          ${i < arr.length - 1 ? `<div style="width:5px;height:88px;background:#ffffff20;"></div>` : ''}
        </div>
        <div style="padding-bottom:32px;">
          ${s.time ? `<div style="font-family:${FONT.display};font-size:50px;color:${on ? BRAND.accent : '#fff'};line-height:1;">${esc(s.time)}</div>` : ''}
          <div style="font-family:${FONT.condensed};font-weight:700;text-transform:uppercase;letter-spacing:1px;
            font-size:40px;color:#fff;margin-top:6px;">${esc(s.name)}</div>
          ${s.note ? `<div style="font-size:27px;color:${BRAND.darkSoft};margin-top:6px;max-width:640px;">${esc(s.note)}</div>` : ''}
        </div>
      </div>`;
    })
    .join('');
  return doc(
    `${darkGlow()}
    <div style="position:absolute;inset:0;padding:84px 64px;display:flex;flex-direction:column;">
      ${spec.title ? `<div style="font-family:${FONT.display};text-transform:uppercase;font-size:70px;color:#fff;line-height:0.98;margin-bottom:48px;">${hl(spec.title, BRAND.accent)}</div>` : ''}
      <div style="flex:1;">${stages}</div>
    </div>`,
    { bg: BRAND.dark },
  );
}

/**
 * RADAR — n-axis performance radar (fitness index).
 * spec: { type:'radar', title?, axes:[{label,value(0-100)}], foot? }
 */
export function radarSlide(spec) {
  const axes = spec.axes || [];
  const n = Math.max(3, axes.length);
  const cx = 540, cy = 590, R = 330;
  const pt = (i, r) => {
    const a = -Math.PI / 2 + (i * 2 * Math.PI) / n;
    return [cx + r * Math.cos(a), cy + r * Math.sin(a)];
  };
  let grid = '';
  for (const rr of [0.25, 0.5, 0.75, 1]) {
    grid += `<polygon points="${axes.map((_, i) => pt(i, R * rr).join(',')).join(' ')}" fill="none" stroke="#ffffff1a" stroke-width="2"/>`;
  }
  let spokes = '', labels = '';
  axes.forEach((ax, i) => {
    const [x, y] = pt(i, R);
    spokes += `<line x1="${cx}" y1="${cy}" x2="${x}" y2="${y}" stroke="#ffffff1a" stroke-width="2"/>`;
    const [lx, ly] = pt(i, R + 54);
    labels += `<text x="${lx}" y="${ly}" text-anchor="middle" dominant-baseline="middle" font-family="${FONT.condensed}" font-weight="700" font-size="30" fill="#fff">${esc(ax.label)}</text>`;
  });
  const poly = axes.map((ax, i) => pt(i, (R * Math.max(0, Math.min(100, ax.value))) / 100).join(',')).join(' ');
  const dots = axes.map((ax, i) => { const [x, y] = pt(i, (R * ax.value) / 100); return `<circle cx="${x}" cy="${y}" r="9" fill="${BRAND.accent}"/>`; }).join('');
  return doc(
    `${darkGlow()}
    <div style="position:absolute;top:74px;left:0;right:0;text-align:center;font-family:${FONT.display};
      text-transform:uppercase;font-size:64px;color:#fff;padding:0 60px;line-height:1;">${hl(spec.title || '', BRAND.accent)}</div>
    <svg width="1080" height="1180" viewBox="0 0 1080 1180" style="position:absolute;top:120px;left:0;">
      ${grid}${spokes}
      <polygon points="${poly}" fill="${BRAND.accent}55" stroke="${BRAND.accent}" stroke-width="5"/>
      ${dots}${labels}
    </svg>
    ${spec.foot ? `<div style="position:absolute;bottom:70px;left:0;right:0;text-align:center;font-size:32px;color:${BRAND.darkSoft};padding:0 72px;">${esc(spec.foot)}</div>` : ''}`,
    { bg: BRAND.dark },
  );
}

/**
 * CARDS — ranked/tier grid of items with optional images (program covers).
 * spec: { type:'cards', title?, items:[{label,image?,tag?}], foot? }
 */
export function cardsSlide(spec) {
  const items = (spec.items || [])
    .slice(0, 6)
    .map((it) => {
      const img = imageDataUri(it.image);
      return `<div style="background:#ffffff10;border-radius:22px;overflow:hidden;display:flex;flex-direction:column;">
        ${img ? `<div style="height:200px;background:#000;"><img src="${img}" style="width:100%;height:100%;object-fit:cover;"/></div>` : `<div style="height:200px;background:${BRAND.accentDark};"></div>`}
        <div style="padding:16px 20px;">
          ${it.tag ? `<div style="font-family:${FONT.condensed};font-weight:700;text-transform:uppercase;letter-spacing:1px;font-size:22px;color:${BRAND.accent};">${esc(it.tag)}</div>` : ''}
          <div style="font-family:${FONT.body};font-weight:800;font-size:29px;color:#fff;line-height:1.1;">${esc(it.label)}</div>
        </div>
      </div>`;
    })
    .join('');
  return doc(
    `${darkGlow()}
    <div style="position:absolute;inset:0;padding:80px 56px;display:flex;flex-direction:column;">
      ${spec.title ? `<div style="font-family:${FONT.display};text-transform:uppercase;font-size:68px;color:#fff;line-height:0.98;margin-bottom:40px;">${hl(spec.title, BRAND.accent)}</div>` : ''}
      <div style="flex:1;display:grid;grid-template-columns:1fr 1fr;gap:24px;align-content:start;">${items}</div>
      ${spec.foot ? `<div style="font-size:30px;color:${BRAND.darkSoft};margin-top:22px;">${esc(spec.foot)}</div>` : ''}
    </div>`,
    { bg: BRAND.dark },
  );
}

/**
 * BEFORE/AFTER — two panels.
 * spec: { type:'beforeAfter', title?, before:{image,label?}, after:{image,label?}, foot? }
 */
export function beforeAfterSlide(spec) {
  const panel = (d, lab, accent) => {
    const img = imageDataUri(d && d.image);
    return `<div style="flex:1;position:relative;overflow:hidden;">
      ${img ? `<img src="${img}" style="width:100%;height:100%;object-fit:cover;"/>` : `<div style="width:100%;height:100%;background:#141210;"></div>`}
      <div style="position:absolute;bottom:0;left:0;right:0;padding:26px;background:linear-gradient(transparent,rgba(0,0,0,0.82));">
        <span style="font-family:${FONT.display};text-transform:uppercase;font-size:54px;color:${accent ? BRAND.accent : '#fff'};">${esc((d && d.label) || lab)}</span>
      </div></div>`;
  };
  return doc(
    `<div style="position:absolute;inset:0;display:flex;flex-direction:column;">
      ${spec.title ? `<div style="padding:56px 60px 28px;font-family:${FONT.display};text-transform:uppercase;font-size:62px;color:${BRAND.ink};line-height:1;">${hl(spec.title, BRAND.accent)}</div>` : ''}
      <div style="flex:1;display:flex;gap:6px;">${panel(spec.before, 'Before', false)}${panel(spec.after, 'After', true)}</div>
      ${spec.foot ? `<div style="padding:26px 60px;font-size:32px;color:${BRAND.inkSoft};">${esc(spec.foot)}</div>` : ''}
    </div>`,
    { bg: BRAND.canvas },
  );
}

/**
 * HEATMAP — GitHub-style consistency grid (habits / streak).
 * spec: { type:'heatmap', title?, weeks?, data?[0-4], foot? }
 */
export function heatmapSlide(spec) {
  const weeks = spec.weeks || 20, days = 7;
  let data = spec.data;
  if (!Array.isArray(data)) {
    data = [];
    const seed = hashStr(spec.title || 'streak');
    for (let i = 0; i < weeks * days; i++) data.push((seed >> (i % 15)) & 1 ? (i * 7 + seed) % 5 : (i * 3) % 3);
  }
  const cell = 26, gap = 9;
  let cells = '';
  for (let w = 0; w < weeks; w++)
    for (let d = 0; d < days; d++) {
      const v = data[w * days + d] || 0;
      const op = [0.08, 0.32, 0.55, 0.78, 1][Math.min(4, v)];
      cells += `<rect x="${w * (cell + gap)}" y="${d * (cell + gap)}" width="${cell}" height="${cell}" rx="6" fill="${BRAND.accent}" fill-opacity="${op}"/>`;
    }
  const gw = weeks * (cell + gap), gh = days * (cell + gap);
  return doc(
    `${darkGlow()}
    <div style="position:absolute;inset:0;padding:90px 60px;display:flex;flex-direction:column;justify-content:center;gap:52px;">
      ${spec.title ? `<div style="font-family:${FONT.display};text-transform:uppercase;font-size:78px;color:#fff;line-height:0.98;">${hl(spec.title, BRAND.accent)}</div>` : ''}
      <svg width="${gw}" height="${gh}" viewBox="0 0 ${gw} ${gh}" style="max-width:100%;">${cells}</svg>
      ${spec.foot ? `<div style="font-size:34px;color:${BRAND.darkSoft};line-height:1.4;">${esc(spec.foot)}</div>` : ''}
    </div>`,
    { bg: BRAND.dark },
  );
}

// ---------------------------------------------------------------------------
// Dispatcher
// ---------------------------------------------------------------------------
const BUILDERS = {
  hook: hookSlide,
  compare: compareSlide,
  appProof: appProofSlide,
  stat: statSlide,
  cta: ctaSlide,
  score: scoreSlide,
  subscores: subscoresSlide,
  insight: insightSlide,
  timeline: timelineSlide,
  radar: radarSlide,
  cards: cardsSlide,
  beforeAfter: beforeAfterSlide,
  heatmap: heatmapSlide,
};

export function renderSlideHtml(slide) {
  const fn = BUILDERS[slide.type];
  if (!fn) throw new Error(`Unknown slide type: ${slide.type}`);
  return fn(slide);
}

export const SLIDE_TYPES = Object.keys(BUILDERS);
