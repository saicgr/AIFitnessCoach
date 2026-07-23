---
description: Generate today's 2 posts — a morning reel + a night carousel — rendered and native for Instagram + TikTok, off the DAILY_SYSTEM weekly rotation. Review and upload.
---

# /social-today — "social content today"

One command → today's two finished posts (☀️ morning **reel** + 🌙 night **carousel**),
rendered to files with native IG + TikTok captions, ready to review and upload.
Nothing is auto-posted.

The schedule is your existing **`docs/planning/marketing/DAILY_SYSTEM.md`** (the
generic Mon–Sun feature rotation + 2-slot rhythm) — NOT a separate dated file.
Angle catalog: `docs/planning/marketing/content/CONTENT-ANGLES.md`. Engine:
`frontend/scripts/instagram/README.md`.

## Steps

1. **Today's feature + modes.** Read `DAILY_SYSTEM.md`'s weekly rotation for today's
   weekday → the **morning video feature** and the **night carousel mode**. (Sat/Sun
   also carry the Reddit self-promo / batch-record notes — surface those.)

2. **Author both specs** — spawn the `social-content` agent **twice in parallel**:
   - **Morning reel** — the day's feature demo. Every video segment gets a `shot`
     (film instruction) + `fallback` (screenshot key) + a recordings-path `clip`, so
     it renders now and auto-writes `RECORD-THIS.md`. Hook in the first ~1s.
   - **Night carousel** — the day's mode from the rotation (Comparison / Cards /
     Insight / Timeline / Reveal / Radar / Heatmap…), pulling the angle from
     `CONTENT-ANGLES.md`.
   Each researches live (trending audio + a defensible hook), honors
   `_ZEALOVA_FACTS` banned phrases, writes valid JSON with `captions.instagram` +
   `captions.tiktok` to `content/<date>/specs/`, and appends to `ROTATION-LOG.md`.
   Spot-check both before rendering.

3. **Render:**
   ```bash
   cd frontend && npm run ig:day <date>
   ```
   → carousel at both aspects (IG 4:5 + TikTok 9:16); reel as one 9:16 master
   mirrored to both. Output: `content/<date>/{instagram,tiktok}/`.

4. **Report** for review — do NOT post:
   - Reel + carousel folder paths, the IG + TikTok captions, the first comment.
   - **Posting plan:** ☀️ post the reel morning (IG Reel + TikTok + X); 🌙 post the
     carousel night (TikTok Photo Mode; IG feed on strong days). IG reel = trending
     audio; TikTok = keep the baked voiceover as original audio.
   - TODOs: any `RECORD-THIS.md` clips to film, `⚠capture` screenshots, or (Sat/Sun)
     the Reddit / batch-record touch.

## Guardrails

Honest myth-busting, never fear-mongering. No em-dashes / scare-quotes / ad-speak.
Never post a watermarked file cross-platform. Every baked-in claim defensible.
Quality bar is non-negotiable — a 7/10 gets reworked, not shipped.
