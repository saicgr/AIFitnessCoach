# Zealova Instagram content engine

Turns a content **spec** (JSON) into finished, post-ready assets — a 1080×1350
carousel (PNG slides) and a 1080×1920 Reel (MP4) — rendered on-brand with real
app screenshots. Modeled on the Exposr daily grammar (shock hook → comparison
scorecards → app-proof → CTA for carousels; b-roll hijack → captioned explainer
→ app-demo for video), in Zealova's App-Store look.

**Nothing is auto-posted.** The engine produces files in a dated folder; you
review and upload manually.

## The daily flow

Primary: run **`/social-today`** — reads the schedule in
`docs/planning/marketing/DAILY_SYSTEM.md` (the Mon–Sun feature rotation), delegates
authoring to the `social-content` agent (a morning reel + a night carousel,
platform-native captions), and renders everything for review. Ad-hoc: just ask
("make a reel about X").

Under the hood:

1. **Author** the day's specs (the Claude step): pick the feature + mode, research a
   hook, write the copy + screenshots + per-segment voiceover, and write JSON specs to
   `docs/planning/marketing/content/<date>/specs/`.
2. **Render** everything:
   ```bash
   cd frontend
   npm run ig:day 2026-07-19      # renders every spec for that date
   # or a single spec:
   npm run ig:carousel -- ../docs/.../specs/menu-scan.json --force
   npm run ig:video    -- ../docs/.../specs/menu-reel.json
   ```
3. **Review + upload** each folder — slides / `reel.mp4` plus `ig-caption.txt` and
   `tiktok-caption.txt` (native per platform).

## Cross-platform (2026 research)

Never post the same file to both platforms — IG suppresses cross-posted /
watermarked content. The engine renders ONE clean unwatermarked master and emits
**separate IG + TikTok captions** (IG: short + trending audio; TikTok:
keyword-rich + original audio). Video overlays stay inside the **900×1400
universal safe zone** (`SAFE` in `lib/video-overlays.mjs`) so on-screen text
survives both platforms' UI. Full rules: `docs/planning/marketing/DAILY_SYSTEM.md`.

## Content pillars (rotation)

| Pillar key | Angle | Flagship screenshots |
|---|---|---|
| `menu-scan` | Food exposé — scan a menu/product, grade it, show the better pick | `menu-scan-result`, `fridge-scan` |
| `form` | "You're doing it wrong" → AI form score | `form-check-pushup` |
| `workout` | The AI moat — plan reveal, strength score, guided sets | `strength-score`, `active-workout-set`, `coach-chat`, `schedule-programs` |
| `nutrition` | Macro/logging comparisons | `coach-chat`, `imports-ai` |

Lead with `menu-scan` (most viral, direct Exposr analog + our per-dish
inflammation score differentiator). Keep the tone **honest myth-busting**, never
fear-mongering — health claims are a liability surface.

## Carousel spec

```jsonc
{
  "slug": "menu-scan-dinner-split",
  "pillar": "menu-scan",
  "date": "2026-07-19",
  "slides": [ /* 5–8 slides, see types below */ ],
  "caption": "…",                 // post caption
  "firstComment": "Comment \"scan\" …",  // pinned first comment (the growth loop)
  "hashtags": ["#nutritioncoach", "…"]   // 3–6 niche tags
}
```

Headline highlight markers: `[[word]]` → accent (green), `{{word}}` → red.

### Slide types = content MODES (`lib/slides.mjs`)

Through-line: *everything gets a score, and we reveal it — food AND training.*
Text slides (`hook`/`stat`/`cta`/`appProof`) auto-get a background photo from the
app's `shareable_backgrounds` by pillar; the data slides
(`score`/`subscores`/`insight`/`timeline`/`radar`/`cards`/`heatmap`) are
self-styled dark performance-dashboard visuals — leave them without an `image`.

- **`hook`** — swipe-stopper. `{ image?(bg photo/key), badge?, kicker?, headline, accent?:"green"|"red" }`
- **`compare`** (Comparison) — bad vs good columns. `{ title?, bad:{name,subtitle?,score,grade,image?,bullets:[{label,value}]}, good:{…} }`
- **`score`** (Reveal) — big glowing score ring. `{ kicker?, score, grade?, headline?, foot? }`
- **`subscores`** — metric bars. `{ title?, metrics:[{label,value,max?}], foot? }`
- **`insight`** — "the app caught something". `{ kicker?, headline, detail?, stat?{value,label}, screenshot? }`
- **`timeline`** — stages over time (fasting clock). `{ title?, stages:[{time?,name,note?,highlight?}] }`
- **`radar`** — n-axis profile. `{ title?, axes:[{label,value}], foot? }`
- **`cards`** — ranked/tier grid w/ images (program covers). `{ title?, items:[{label,image?,tag?}], foot? }`
- **`beforeAfter`** — two panels. `{ title?, before:{image,label?}, after:{image,label?}, foot? }`
- **`heatmap`** — consistency grid. `{ title?, weeks?, data?[0-4], foot? }`
- **`stat`** — one big number/claim. `{ kicker?, big, headline?, foot?, image? }`
- **`appProof`** — real app screen in a phone frame. `{ image?(bg), headline, sub?, screenshot(key/path) }`
- **`cta`** — the closer. `{ image?(bg), headline, sub?, screenshot?(key/path), comment?("scan") }`

## Video spec

```jsonc
{
  "slug": "menu-macros-hijack",
  "pillar": "menu-scan",
  "date": "2026-07-19",
  "voice": "Samantha", "rate": 178,   // macOS `say` voice + wpm (defaults)
  "segments": [
    { "clip": "path.mp4", "kind": "video", "start": 0, "duration": 4,
      "headline": "You can't read a menu's macros.",   // Exposr "HEADLINE:" bar
      "caption": "GUESSING", "captionAccent": "white", "captionY": 0.4,
      "vo": "Two dishes on the same menu — you can't tell which wrecks your goal." },
    { "clip": "menu-scan-result", "kind": "still", "duration": 4,
      "label": "SCANNED", "brand": true,
      "vo": "Zealova scanned it in three seconds and ranked every dish." }
  ],
  "music": "bed.mp3",    // OPTIONAL music bed (ducked under the voice)
  "audio": "vo.mp3",     // OPTIONAL single external voice track (overrides per-segment vo)
  "captions": { "instagram": {…}, "tiktok": {…} }   // native per platform (see below)
}
```

- `kind:"video"` uses `start`/`duration` of a clip; `kind:"still"` holds an image
  (screenshot key or path) with a slow **Ken-Burns push** for `duration`s.
- `clip` accepts a screenshot-library **key** or a repo-relative path.
- **Voiceover is baked automatically** from each segment's `vo` via the free macOS
  `say` voice (no key). A segment's on-screen time = max(`duration`, narration
  length) so lines never clip. Better voice later: install a Premium voice in
  System Settings → Accessibility → Spoken Content, set `"voice"`; or drop an
  ElevenLabs mp3 in `audio` to override the whole track.
- Music bed via `music` is ducked under the voice.

## Captions (per platform)

Both carousel and video specs take a `captions` object so each platform gets a
native caption (`lib/captions.mjs` writes `ig-caption.txt` + `tiktok-caption.txt`):

```jsonc
"captions": {
  "instagram": { "caption": "<short, hook-first, <120 char>", "firstComment": "Comment \"scan\" …",
                 "hashtags": ["#…"], "audio": "trending sound suggestion" },
  "tiktok":    { "caption": "<keyword-rich / SEO, hook-first>", "hashtags": ["#…"],
                 "audio": "original audio / the voiceover" }
}
```

A flat `caption`/`firstComment`/`hashtags` still works as a fallback (writes
`caption.txt`).

## Screenshots

Real app screens the renderers embed live in
`docs/planning/marketing/screenshots/` (keys resolved via `manifest.json`). See
that folder's README to add/refresh a shot. This is the still counterpart to the
video B-roll library (`docs/planning/marketing/reels/broll-library.md`).

## Brand

Tokens in `lib/brand.mjs`. The whole system re-skins from one token: set
`BRAND.accent` (default Zealova green `#12B24B`; the website's volt-orange
`#FF7A00` is `BRAND.orange`). Fonts (Anton + Barlow Condensed) and the logo are
inlined from the frontend's `node_modules`/`public` — no new deps beyond the
Puppeteer the OG generator already uses, plus system `ffmpeg` for video.

## Guardrails

Copy must honor `.claude/agents/marketing/_ZEALOVA_FACTS.md` (banned phrases:
"replaces your trainer", "guaranteed results", medical/HIPAA claims, and the
§2G reliability-hold feature list) and `_OUTPUT_STANDARD.md` voice (no
em-dashes/scare-quotes). Never bake an unverifiable claim into a slide image.

## Files

```
frontend/scripts/instagram/
  render-carousel.mjs   # spec → PNG slides
  assemble-video.mjs    # spec → MP4 (ffmpeg)
  make-day.mjs          # render every spec for a date
  lib/
    brand.mjs           # palette, fonts, logo, screenshot-key resolver
    slides.mjs          # carousel slide HTML templates
    video-overlays.mjs  # transparent Reel overlay templates
```
