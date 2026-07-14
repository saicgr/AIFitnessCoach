# Zealova B-roll library — weekend recording session

**Purpose:** record this ONCE (weekend of 2026-07-11/12), reuse for weeks of daily posts. This is the raw-capture source library the daily generator (see `shot-lists.md` Week 1 entry) draws clip IDs from. Clean captures only — no audio, no on-screen text, no captions baked in. All text/audio/pacing gets added per-platform at edit time so the SAME clip can become a raw TikTok cut and a polished IG cut without being a duplicate export.

---

### 📊 Current trends — researched live 2026-07-11

**Platform / channel trends (last 7 days):**
- [https://www.ramd.am/blog/trends-tiktok](https://www.ramd.am/blog/trends-tiktok) — July 2026's dominant TikTok format ("Inspiration Sound" trend) is literally an app-demo shape: uplifting audio + short text like "you finally found a healthier you thanks to [app]" or "how it feels to simplify my savings with [app]." This is a screen-record-plus-text format, which is exactly what a B-roll library feeds.
- [https://newengen.com/insights/july-tiktok-trends/](https://newengen.com/insights/july-tiktok-trends/) — Second dominant format ("No Pen or Paper," set to a Beyoncé sound) is "something that usually feels complicated becomes surprisingly easy — wait, that's it?" That's a screen-record-of-a-single-flow shape (photo in, answer out) — matches food photo logging and menu scan perfectly.
- [https://buffer.com/resources/trending-audio-instagram/](https://buffer.com/resources/trending-audio-instagram/) — IG's top trending audio this month leans transformation/reveal ("Sunny" by Boney M & R3HAB paired with a "wipe the camera" transition). Reveal-shaped edits need a clean BEFORE state and a clean AFTER state as two distinct shots — B-roll must capture both halves of each flow separately, not just the end state.

**Fitness industry trends (last 7-30 days):**
- [https://athletechnews.com/future-pulls-the-plug-on-ai-personal-training-commits-to-human-coaches/](https://athletechnews.com/future-pulls-the-plug-on-ai-personal-training-commits-to-human-coaches/) — Future just walked back AI coaching in favor of human coaches. AI-generated programming is currently a live, contested claim in the category — B-roll must show the plan actually being generated and adapting, not just a static screen, to make the AI claim credible on camera.
- [https://www.techbuzz.ai/articles/myfitnesspal-acquires-teen-built-viral-app-cal-ai](https://www.techbuzz.ai/articles/myfitnesspal-acquires-teen-built-viral-app-cal-ai) — Cal AI (now MFP-owned) built its entire virality on ONE flow: photo in, calories out. That single-flow clarity is why food photo logging leads this library — it's the most-proven screen-record shape in the whole category right now.

### 🎯 Why these matter

- July's dominant TikTok format IS a screen-record-plus-text shape → B-roll must be clean, uncluttered captures with nothing baked in, so the trending text format can be laid over ANY clip later without re-shooting.
- "Wait, that's it?" reveal trend needs a distinct before/after → every flow-based clip below is written as a BEFORE state (2-3s) + AFTER/result state (the hold), not just one screen.
- Cal AI's single-flow virality → food photo logging gets 2 of the 12 slots (single-plate AND multi-image buffet mode) since it's the most trend-proven shape to capture well.
- Future's AI-coaching credibility fight → the workout-generation clips (B5, B6) must show the PLAN CONTENT (real exercise names, sets, reps) on screen long enough to read, not just a loading spinner or a generic dashboard.

### 📝 What I'm generating

- 12 reusable raw B-roll clips, 2 each covering the 6 core Zealova features per `_ZEALOVA_FACTS.md` §2B (food photo logging, menu scan, AI workout generation, multi-agent coach chat, trends & correlations, intermittent fasting) — because those are the features confirmed both code-verified AND user-confirmed reliable, and the ones the current trend formats reward (single clear flow, readable result screen).
- Exact tap paths + hold timings for each, so recording is mechanical, not creative-decision-making, this weekend.
- A staging checklist (photos to pre-load, an active fast to start in advance, sample data needed) since several clips need setup BEFORE you hit record.
- A file-naming + folder convention so `shot-lists.md` can reference clip IDs unambiguously for months.

### 🎯 Zealova grounding check
- Features referenced (from `_ZEALOVA_FACTS.md` §2B): food photo logging (multi-image), menu scan, AI workout plan generation, multi-agent chat coach, trends & correlations, intermittent fasting
- Pricing claims: none in this file (raw B-roll only, no captions)
- Wedges used: none directly (raw capture), reserved for the daily posts in `shot-lists.md`
- Banned phrases avoided: n/a — no text in these clips ✅

---

## Recording setup (do this before Clip 1)

**Device:** iOS Simulator (iPhone 15 Pro, 393×852pt, 3x retina) is the default for ALL 12 clips. Reason: no status-bar notification noise, no Android system-bar flicker, cleanest possible source file — same reasoning as the existing press-demo-clip precedent in this file's neighbor doc. Export/crop to 1080×1920 (9:16). If you only have time to record on the Android emulator or a physical device, that's fine too — just turn on Do Not Disturb first and hide the status bar/notification shade in every take. Flag per-clip below only where it matters.

**Screen recording settings:** iOS Simulator → File-menu screen recording, or QuickTime "New Screen Recording" pointed at the Simulator window. Record at full resolution, no cursor overlay. Trim in post — over-record by 2-3 seconds on each end rather than starting/stopping exactly on action.

**Pre-load BEFORE you start (staging):**
- **3 clean food photos** in the Simulator's Photos app: one single-plate meal (grilled chicken + rice + veg reads clearly), one buffet-style spread for the multi-image clip (5-8 distinct dishes visible), one more single-plate for backup/reshoot.
- **1 restaurant menu photo**: screenshot a real chain's menu page (Chipotle, Sweetgreen, Cava — anything with visible prices and dish names), crop clean, import to Simulator Photos.
- **An account with populated history** for the Trends clips — at least 2-3 weeks of logged weight, workouts, and sleep/nutrition data so the correlation chart actually shows a visible line, not a flat/empty state. Use your own account if it already has this; otherwise the QA reviewer demo-health seed account works (per `project_emulator_health_sample_data.md`).
- **A fast started 12-16 hours before you record** the fasting clips — you want the ring showing Fat Burning or Ketosis stage (the visually interesting mid-fast state), not Fed/just-started. Start it Saturday morning if recording Saturday night, or Friday night if recording Saturday.
- **Do Not Disturb ON** for the whole session — one notification banner mid-recording ruins the take.

**File naming:** save each take as `broll-<clipID>-<YYYY-MM-DD>-take<N>.mov` (e.g. `broll-B1-2026-07-11-take2.mov`) into `docs/planning/marketing/reels/broll-raw/` (gitignored — these are large binary files, don't commit them; the shot-lists reference the clip ID, not a repo path).

---

## The 12 clips

### B1 — Food photo logging (single plate)
**Feature:** food image logging, auto/plate mode
**Nav path:** Nutrition tab → tap the camera/log button → choose "Take Photo" or pick the pre-loaded single-plate photo from the library → hold on the AI analysis result screen (items + calories + macros per item) → tap to log/confirm.
**Target length:** 10-15s
**Must be visible on screen:** the BEFORE (empty photo picker, 1-2s) then the AFTER (analysis result showing at least 2-3 named food items with individual calorie counts, held 5-6s so it's readable at 1x speed, then the confirm tap).
**Device:** iOS Simulator. No Android-specific behavior to capture.

### B2 — Food photo logging (multi-image buffet mode)
**Feature:** food image logging, buffet mode (up to 10 photos)
**Nav path:** Nutrition tab → camera/log button → switch analysis mode to "Buffet" → select 4-6 of the pre-loaded buffet-spread photos → hold on the AI analysis result screen showing the combined breakdown across all dishes.
**Target length:** 10-15s
**Must be visible on screen:** the multi-select photo picker with several thumbnails checked (2-3s, proves "more than one photo"), then the combined result screen listing multiple dishes with per-dish macros (6-7s hold).
**Device:** iOS Simulator.

### B3 — Menu scan (restaurant menu → dishes)
**Feature:** menu scan
**Nav path:** Nutrition tab → camera/log button → analysis mode "Menu" → select the pre-loaded menu photo → hold on the result screen listing dishes with calorie/macro estimates per dish.
**Target length:** 10-15s
**Must be visible on screen:** the raw menu photo for 1-2s (so viewers recognize "that's a menu"), then the result screen with 3-5 dish names + calorie counts held 6-8s, readable.
**Device:** iOS Simulator.

### B4 — Menu scan (dish detail + log)
**Feature:** menu scan, second half of the flow
**Nav path:** From the B3 result screen, tap one specific dish to open its macro breakdown detail → tap "Log."
**Target length:** 5-8s
**Must be visible on screen:** the single-dish detail card (protein/carbs/fat breakdown, 3-4s) then the log confirmation.
**Device:** iOS Simulator.

### B5 — AI workout plan generation (the monthly plan reveal)
**Feature:** AI workout plan generation
**Nav path:** Workouts tab → scroll to reveal the current AI-generated monthly plan structure (days of week, muscle groups, session names).
**Target length:** 8-12s
**Must be visible on screen:** a continuous scroll through at least 5-6 days of the plan, slow enough (roughly 1 day per second) that named workouts/muscle groups are legible frame-by-frame — this is the shot that proves "AI-generated," not generic.
**Device:** iOS Simulator.

### B6 — AI workout plan generation (session detail + progression)
**Feature:** AI workout plan generation, second half
**Nav path:** From B5, tap into one day's workout → hold on the workout detail screen (exercise names, sets, reps) → tap one exercise to show its detail card (form cue, muscle group).
**Target length:** 8-12s
**Must be visible on screen:** at least 4 named exercises with sets/reps clearly readable (4-5s), then the single-exercise detail card (3-4s).
**Device:** iOS Simulator.

### B7 — Multi-agent coach chat (nutrition question routed correctly)
**Feature:** multi-agent chat coach
**Nav path (CONFIRMED 2026-07-11):** Tap the **Coach** tab (center bottom-nav tab — the nav is now Home · Workout · Coach · Nutrition · You after the June redesign; coach chat is its own tab, no FAB) → type a nutrition-flavored question (e.g. "what should I eat before a workout") → hold on the response as it streams in, showing a nutrition-specific, specific answer (not generic).
**Target length:** 10-15s
**Must be visible on screen:** the typed question (2s), then the streaming/typing response building out (5-8s), then the completed answer held 2-3s so it's readable.
**Device:** iOS Simulator.

### B8 — Multi-agent coach chat (workout modification / injury-aware swap)
**Feature:** multi-agent chat coach, between-workout modification (per `_ZEALOVA_FACTS.md` §2B this is between-workout chat, not mid-session — do not stage this as if it's live during an active workout)
**Nav path (CONFIRMED 2026-07-11):** Coach tab → type "swap squats for hip pain" (or similar injury-flavored ask) → hold as the agent responds with a specific alternative exercise and reasoning.
**Target length:** 8-12s
**Must be visible on screen:** the typed prompt, then a response naming a SPECIFIC swapped exercise (not "consult a doctor" boilerplate) held long enough to read.
**Device:** iOS Simulator.

### B9 — Trends & correlations (two-metric overlay + AI insight)
**Feature:** Custom Trends analytics
**Nav path (CONFIRMED 2026-07-11):** Home tab → tap a ring segment on the Today Score card (Train / Nourish / Move) → on the Pillar Detail screen tap the **"Custom Trends"** button (tune icon) → select two metrics to overlay (e.g. sleep hours + workout volume, or weight + calories) → hold on the overlaid chart → scroll to the AI-generated trend insight text below it.
**Target length:** 10-15s
**Must be visible on screen:** the two-line overlaid chart with a visible correlation shape (needs the pre-populated history from setup) held 5-6s, then the AI insight sentence held 3-4s, long enough to read once.
**Device:** iOS Simulator.

### B10 — Trends & correlations (metric picker scroll)
**Feature:** Custom Trends analytics, second half
**Nav path:** From the Trends screen, open the metric picker/selector and scroll through the list of trackable metrics.
**Target length:** 6-10s
**Must be visible on screen:** a continuous scroll showing a wide variety of metric names (weight, macros, water, steps, sleep, mood, glucose, fasting hours, strength) — the breadth is the point, so don't stop scrolling too early.
**Device:** iOS Simulator.

### B11 — Intermittent fasting (live metabolic-stage ring)
**Feature:** Intermittent Fasting tracker
**Nav path (CONFIRMED 2026-07-11):** Home tab → tap the **Fasting tile / hero fasting card** (opens `/fasting`, the redesigned tracker) → hold on the live metabolic-stage ring showing current stage (should read Fat Burning or Ketosis per the pre-fast staging above) → tap into Body Status to show the stage-journey view.
**Target length:** 8-12s
**Must be visible on screen:** the ring itself with the current stage name legible (4-5s), then the stage-journey view showing the full Fed → Deep Autophagy progression (4-5s).
**Device:** iOS Simulator.

### B12 — Intermittent fasting (start-a-fast flow + Fasting Guide)
**Feature:** Intermittent Fasting tracker, second half
**Nav path (CONFIRMED 2026-07-11):** Home tab → Fasting tile (`/fasting`) → tap to start a new fast → select a protocol (16:8 reads clearest on screen) → confirm start → separately, open the built-in Fasting Guide educational timeline and scroll partway. (Alternate entry points: Nutrition tab → Daily → Fasting panel, or the "+" quick-log sheet → Fasting.)
**Target length:** 8-12s
**Must be visible on screen:** the protocol picker with at least 3 named protocols visible (14:10, 16:8, 18:6 etc, 3-4s), the start confirmation, then a scroll through the Fasting Guide timeline (4-5s).
**Device:** iOS Simulator.

---

## After recording — quick QA before you call the weekend session done

- [ ] All 12 clips exist as separate files, correctly named
- [ ] Every clip has a clean BEFORE and a readable, held AFTER/result state — nothing is just a loading spinner
- [ ] No notification banners, no low-battery warnings, no keyboard-autocomplete bar visible in any take
- [ ] Text on every result screen (food items, exercise names, chat responses, metric names) is legible when paused — zoom in on your monitor and check, not just glance
- [ ] Food/menu photos read as real meals, not placeholder/stock-looking images
- [ ] Trends chart (B9) shows an actual visible line/correlation, not a flat or near-empty chart
- [ ] Fasting ring (B11) shows Fat Burning or Ketosis stage, not Fed
- [ ] Files copied out of the Simulator temp location into `docs/planning/marketing/reels/broll-raw/` so they survive a Simulator reset

Once this checklist passes, the library is ready — `shot-lists.md`'s Week 1 entry (below) references these clip IDs directly.
