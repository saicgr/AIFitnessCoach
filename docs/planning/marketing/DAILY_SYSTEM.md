# Zealova Daily Marketing System

**The one-page operating manual.** You (Sai, solo founder) are posting **2×/day on Instagram, TikTok, X, and Reddit**, starting 2026-07-12. This file is the whole system: what to post, when, and how to generate it in one command. Read this once; after that you live in the Daily Pack + the checklist.

**Zealova is one lane of a larger schedule.** You're running marketing across multiple products (ByteShards, Zealova, Mediaphile). The top-level time-slot allocation across all of them lives in `~/founder-marketing/SCHEDULE.md` — this file owns Zealova's tactical detail (which feature, which hook, which audio); that one owns when Zealova's slot happens relative to everything else.

---

## The model (why this is sustainable and the last attempt wasn't)

"2×/day × 4 platforms" is **not** 8 unique posts a day — that's the burnout trap that killed posting on 2026-05-22. Instead:

> **One idea → produced once → repurposed natively across platforms. The video is the only thing that needs recording; every word of copy is generated for you.**

- **The hard 20% (only you can do it):** record short faceless screen-recordings of Zealova (no camera, no face). You do this in a **weekend batch** — record ~12 reusable clips ONCE (`reels/broll-library.md`), then draw from them for weeks. Add a few fresh clips each weekend.
- **The easy 80% (generated for you):** every caption, hook, hashtag set, trending-audio pick, X post, and Reddit comment. You paste and post.
- **The night carousel is now 100% auto** (added 2026-07): the render engine (`frontend/scripts/instagram/`) outputs **finished** 1080×1350 IG + 1080×1920 TikTok slides — no CapCut, no design. Only the morning video needs your recorded footage.

Your only daily job: **upload in the morning, upload at night, and handle comments** (you said you'll take care of engagement). Everything else is pre-written in the Daily Pack.

---

## Your format decision (recommended for you)

**Faceless app-demo videos.** Screen-recording of one Zealova feature in action + on-screen text + a trending sound. Fastest to make, no camera, and it's the proven format for app growth (Cal AI built its user base on exactly this). No talking head required, no build-in-public — just the app.

---

## The daily two-slot rhythm

| Slot | Time (your local, CST) | What goes out | Where |
|---|---|---|---|
| **☀️ Morning** | 7–9 AM | That day's **feature-demo video** | IG Reel + TikTok + X (clip) |
| **🌙 Night** | 6–8 PM | An **auto-rendered carousel** on the same/adjacent feature (any of the 13 modes) | TikTok Photo Mode daily + IG feed the strong days |
| **Always-on (do in downtime)** | anytime | 1 genuine Reddit value comment | Reddit |

That's your "2×/day everywhere": **one video + one carousel** upload + one Reddit touch you slot in whenever. (The carousel needs no footage — it renders finished, so the night slot is basically free.)

---

## Weekly feature rotation (so it's never repetitive)

Each day has **one feature focus**. The morning video demos it; the night video is a complementary angle on the same or adjacent feature.

| Day | ☀️ Morning video (feature demo) | 🌙 Night carousel (mode → CONTENT-ANGLES.md) |
|---|---|---|
| **Mon** | 🍽️ Food photo logging (strongest AI feature) | **Comparison** — "this meal vs that, scored" |
| **Tue** | 🏋️ AI workout generation (the headline) | **Cards** — "a program for your exact life" |
| **Wed** | 📸 Menu scan (eating-out differentiator) | **Comparison / Reveal** — "82 vs 24" or a single food's inflammation score |
| **Thu** | 💬 Multi-agent coach chat | **Insight** — "the coach caught something" (correlation / plateau) |
| **Fri** | ⏱️ Intermittent fasting tracker | **Timeline** — the hour-by-hour fasting clock |
| **Sat** | 📈 Trends & correlations (progress) | **Reveal / Radar** — strength score / fitness radar · + **Reddit self-promo** (allowed subs) |
| **Sun** | 🎯 Best-of / recap feature | **Heatmap / Wrapped** — consistency streak · + **batch-record next week's clips** |

Lead with food logging + menu scan + workout generation — per `_ZEALOVA_FACTS.md §2B` these are the most-tested, most-marketable features. Never claim anything in the `§5` banned list ("replaces your trainer," "guaranteed results," etc.).

---

## How to generate each day's content (the one command)

Every morning (or the night before), open Claude Code and type:

```
/social-today
```

That builds **today's two posts as FINISHED files** (no CapCut, no Canva):
- **☀️ Morning video** → an assembled reel (uses your recorded b-roll; if a clip
  isn't recorded yet it renders with a placeholder + writes a `RECORD-THIS.md` shot list).
- **🌙 Night carousel** → rendered slides in the right mode for today's feature.
Both come out **native for IG and TikTok** (`content/<date>/instagram/` + `tiktok/`),
each with its own caption. It runs live research every time (trending audio, a
defensible hook) and rotates via `ROTATION-LOG.md` so nothing repeats.

Variants:
- `/social-today` → today
- `/social-today 2026-07-21` → a specific date
- Ad-hoc, just ask: "make a reel about the fasting clock", "an insight carousel about the sleep-vs-bench thing"

After you post, log it:
- `log this posted Reel` (reels-producer logs to `reels/posted-log.md`)
- `Reddit posted, log it`

*(Legacy: `/daily-content` still exists for the older copy-only/Reddit pack — `/social-today` supersedes it for the IG/TikTok visual content.)*

---

## The daily checklist (print this / pin it)

**☀️ Morning (5–10 min):**
1. Open today's pack: `docs/planning/marketing/daily/<today>.md` → **MORNING** block.
2. Grab the named B-roll clip. Drop it into CapCut/Instagram, add the on-screen text + the trending audio listed.
3. Post to **IG Reels** (paste IG caption + hashtags) → then **TikTok** (paste the *distinct* TikTok caption) → then **X** (paste the X text).

**🌙 Night (5–10 min):**
1. Same pack → **NIGHT** block. Grab that clip, add text + audio.
2. Post IG → TikTok → X.
3. Drop the day's **Reddit value comment** on the linked thread (from the pack).
4. Spend 5 min replying to any comments/DMs from the morning post (your job — the algorithm rewards fast replies).

**🗓️ Sunday (30–45 min, batch):**
1. Record next week's fresh clips from `reels/broll-library.md` (+ any new feature clips).
2. Run `/daily-content week` to generate all 7 days at once.

---

## One-time setup (do before Day 1)

1. **Record the B-roll library** — `docs/planning/marketing/reels/broll-library.md` (~12 clips, ~30 min total). This is your reusable footage; everything draws from it.
2. Confirm bios/link across IG, TikTok, X point to `zealova.com` (or the Play Store link).
3. Install **CapCut** (free) for adding on-screen text + trending audio to clips.

---

## Where everything lives

| What | Path |
|---|---|
| **Rendered posts (finished, per platform)** | `docs/planning/marketing/content/<date>/{instagram,tiktok}/` |
| **Render engine (carousel + video code)** | `frontend/scripts/instagram/` (+ README) |
| **Content-angle catalog (features → modes)** | `docs/planning/marketing/content/CONTENT-ANGLES.md` |
| **Rotation ledger (no-repeat)** | `docs/planning/marketing/content/ROTATION-LOG.md` |
| **Screenshot library (real app screens)** | `docs/planning/marketing/screenshots/` |
| **Authoring agent** | `.claude/agents/marketing/community/social-content.md` |
| Reusable B-roll shot list | `docs/planning/marketing/reels/broll-library.md` |
| Reel shot lists + weekly plan | `docs/planning/marketing/reels/shot-lists.md` |
| Reddit threads + comment drafts | `docs/planning/marketing/reddit/posts.md` |
| Sub promo rules | `docs/planning/marketing/reddit/sub-rules.md` |
| Posted log (what went live) | `docs/planning/marketing/posted-log.md` · `reels/posted-log.md` |
| Canonical facts (features/pricing/voice) | `.claude/agents/marketing/_ZEALOVA_FACTS.md` |

---

**Golden rule:** consistency beats perfection. A B-minus post every day beats an A-plus post once a month. The last attempt stopped because it aimed for perfect. This system aims for *daily* — the pack does the thinking, you just hit post.
