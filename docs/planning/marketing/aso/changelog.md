# Zealova ASO Changelog

One entry per shipped listing change. Append entries below — do not overwrite.

---

## 2026-05-18 — Add Intermittent Fasting + Trends to Play Store and App Store descriptions

- **Store(s):** Both (Google Play full description + App Store description)
- **Asset(s) changed:** Play full description, Play short description, App Store description, App Store promotional text, App Store keywords, App Store "What's New" copy
- **Before (Play full description):** Led with "Your workouts and diet finally talk to each other." Covered workouts, meal logging, form check, AI coach, progress tracking, batch cooking. No mention of fasting or analytics trends. ~3,970 chars.
- **After (Play full description):** Opens with "Your workouts, meals, and fasts — finally in one place." Adds full INTERMITTENT FASTING section (protocols, metabolic-stage ring, Body Status view, hydration + mood check-ins, pause/resume, Live Activity, Fasting Guide) and full TRENDS AND CORRELATIONS section (100+ metrics, any-two overlay, AI insights, event overlays). Removed the FORM CHECK section (moves to §2G per facts file — not yet reliability-validated for marketing) and EXERCISE PREFERENCES section (condensed for space). Final: 3,833 chars.
- **Before (Play short description):** "AI coach that builds your workouts & tracks meals — type, snap, or scan." (72 chars)
- **After (Play short description):** "AI coach for workouts, meals & fasting — type, snap, scan, or fast." (67 chars)
- **Before (App Store description):** Led with workouts + meals. Included a brief "▶ FASTING TIMER + STREAKS" section (two lines, referenced 16:8/18:6/OMAD only). Included "▶ SENIOR-AWARE MODE" (deprecated feature — should not have been in listing). ~3,380 chars.
- **After (App Store description):** Full "▶ INTERMITTENT FASTING" section (seven bullet points covering all protocols, metabolic stages, Body Status, hydration check-ins, pause/resume, Live Activity, Fasting Guide). Full "▶ TRENDS AND CORRELATIONS" section. Removed SENIOR-AWARE MODE (deprecated per `_ZEALOVA_FACTS.md` §2E). Removed free-tier breakdown (was stale — Zealova is subscription only with 7-day trial). Updated "WORKS WITH" to mention Live Activity for fasts, not just workouts. 3,416 chars.
- **Before (App Store promo text):** "New: Snap any meal — our vision AI logs calories and macros instantly. Plus injury-aware workouts, adaptive TDEE, and a coach that actually answers back." (152 chars)
- **After (App Store promo text):** "New: Fasting tracker with live metabolic-stage ring. Plus custom Trends for 100+ metrics. Snap meals, build workouts, track it all in one app." (142 chars)
- **Before (App Store keywords):** "fitness,workout,gym,AI,coach,meal,nutrition,calorie,macro,trainer,plan,strength,cardio,health" (99 chars)
- **After (App Store keywords):** "fitness,workout,AI,coach,meal,nutrition,calorie,macro,fasting,fast,strength,plan,tracker,health" (95 chars) — added "fasting" and "fast" (high-intent terms for the new feature); removed "gym", "trainer", "cardio" (lower-volume, overlapping with name/subtitle)
- **Hypothesis:** Fasting is a high-search-volume category in Health & Fitness on both stores. Adding it to the description and keywords should capture users searching for IF-specific apps (16:8, OMAD, intermittent fasting timer) who would otherwise find Zero, Life Fasting, or Fastic instead of Zealova. Estimated new keyword surface: 4-6 fasting-intent queries now indexable. Secondary: Trends section differentiates Zealova from one-dimensional trackers on the "analytics" intent queries.
- **Measurement:** Install conversion rate (listing-page-view to install) — measure 4 weeks from the date the listing goes live in each store. Also track keyword ranking for "intermittent fasting", "fasting timer", "16:8 fasting" in App Store and Play Store — check at 2-week and 4-week marks via AppFollow or AppTweak (or manual search-rank check).
- **Audit reference:** Refresh run 2026-05-18 — no prior audit file existed; this is the first changelog entry.
- **Status:** DRAFTED 2026-05-18 — awaiting paste into App Store Connect and Play Console by founder. NOT yet live.

Files changed:
- `/Users/saichetangrandhe/AIFitnessCoach/PLAY_STORE_LISTING_COPY.md` — source of truth for Play full description (updated)
- `/Users/saichetangrandhe/AIFitnessCoach/APP_STORE_LISTING.md` — source of truth for App Store description (updated)

Stale duplicates (do NOT use as source of truth — they were not updated):
- `/Users/saichetangrandhe/AIFitnessCoach/PLAY_STORE_DESCRIPTION.txt`
- `/Users/saichetangrandhe/AIFitnessCoach/play_store_listing.txt`

---

(Append readout here 30 days post-live:)

- **Readout (due ~2026-06-18):** install conversion rate before → after; keyword rank for "intermittent fasting" / "fasting timer" before → after; verdict: kept / reverted / iterated

---

## 2026-06-29 — Full screenshot deck rebuild (post-signature-v2 reskin + Program Library + Form Check + Menu Scan)

- **Store(s):** Play + App Store (both)
- **Asset(s) changed:** All 8 Play phone screenshots + 10 App Store screenshots (complete rebuild — previous May 2026 deck is one full reskin + 442 feature commits out of date)
- **Before:** May 2026 deck — 8 frames: coach/exercise detail/menu+fridge composite/chat-swap/voice-log/strength/body/shareables. Missing: Program Library, program customizability, AI Form Check, Easy mode active workout, Overload Dashboard. Chat-swap frame (F4 old) violates hard constraint (excluded per founder directive 2026-06-29).
- **After (core-8, Play + App Store):**
  - F1: "Your fitness coach, IN CHAT." — Home redesign (signature-v2 metric deck + timeline). Background: cream `#FAF8F4`.
  - F2: "Real programs. PICK YOURS." — Program Library cinematic carousel with HYROX in hero. Background: deep charcoal `#1A1A2E`.
  - F3: "Built for YOUR gym." — Edit Program sheet (day swap + gym picker + AI-tailor). Background: warm indigo `#3D3A6B`. (Required by founder.)
  - F4: "Film a set. GET COACHED." — AI Form Check critique card with 7.4/10 score + item notes. Background: muted amber `#4A3728`.
  - F5: "Snap the menu. BEST PICK." — Menu scan result with TOP PICK badge + ranked dish list. Background: warm peach `#FBE2C8`. (Required by founder.)
  - F6: "Set by set. YOU'RE READY." — Easy mode active workout (warmup done, rest timer, large weight focal). Background: soft sky `#D6E9F5`.
  - F7: "Just say what YOU ATE." — Chat logging: 3 exchanges (tacos, yoga, run). Background: soft green `#D4ECD7`.
  - F8: "Watch your strength CLIMB." — Overload Dashboard (1RM chart + muscle heatmap + PR badge). Background: steel blue `#2563EB`.
  - App Store F9: "Open fridge. GET RECIPES." — Fridge scan → 3 high-protein recipe cards.
  - App Store F10: "Bring your history. KEEP GOING." — Imports/switcher (MFP, MacroFactor, Cronometer, Apple Health).
- **Hypothesis:** +15-25% listing-page-to-install conversion from: (a) narrative story arc (Problem→Solution→Trust) replacing independent feature enumeration; (b) two required high-visual-wow frames (AI Form Check + Menu Scan) that no competitor in workout AI or nutrition tracking shows together; (c) Program Library differentiator visible in frame 2 (inside the 70% install-decision window — first 3 frames). Fitbod at frame 2 comparison: they show a workout list; Zealova shows a cinematic HYROX carousel with variant selectors. Visually stronger.
- **Measurement:** Install conversion rate (Play Console listing-page views → installs), 4 weeks post-live. Run Play Store Listing Experiment if variant budget allows (test F1 dark background vs cream background). Track at 2-week and 4-week marks.
- **Audit reference:** Screenshot rebuild run 2026-06-29. Draft at `/Users/saichetangrandhe/AIFitnessCoach/next_update/screenshots_2026-06.md`.
- **Status:** DRAFTED 2026-06-29. Awaiting: (1) Sai review and approval of deck; (2) reliability confirmation on AI Form Check (F4) and fridge scan (F9); (3) staging / screen capture; (4) paste into Play Console + App Store Connect.

(Append readout 30 days post-live:)

- **Readout (due ~2026-07-29):** install conversion rate before → after; verdict: kept / reverted / iterated
