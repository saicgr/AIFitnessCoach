# Zealova — Improvements Needed

---

## 🚨 LEGAL / COMPLIANCE RISK (Top Priority — Ship Before Anything Else)

*Findings verified in code. These are not UX nits — they create GDPR / HIPAA / consumer-protection exposure and reputational risk. Fix before scaling user acquisition.*

### False Privacy Claims in Consent & Settings UI
*The single highest-risk finding: in-app copy directly contradicts the actual behavior AND the legal privacy policy.*

- [x] **`ai_consent_screen.dart:167-198` claims "Data is anonymized before AI processing" + "AI never sees photos" + "no data retention"** — all three are **false**. `backend/api/v1/chat.py:109-120` sends full `user_message` + `user_id` + `ai_response` to Gemini and stores raw exchange in `chat_history`. `vision_service.py` uploads food photos AND form videos to Gemini Vision. The privacy_policy.html section 3 actually states the opposite. **Legal team audit required; rewrite consent copy to match reality.** _(2026-04-21: rewrote all four bullets — now describes models, encryption, 12-month retention, no-sale/no-ads/no-training-on-data.)_
- [x] **`ai_data_usage_screen.dart:139` repeats the same false claims** — remove or rewrite _(2026-04-21: rewrote all four sections; header renamed to "How Your Data Is Used".)_
- [x] **Onboarding consent must match the privacy policy verbatim or be replaced** — the contradiction itself is a GDPR Art. 7(2) violation (consent must be informed) _(2026-04-21: consent copy + policy §3 now both describe Vertex AI ZDR, model routing, and 12mo retention identically.)_

### Placebo Consent Toggles (GDPR Art. 7(4) Dark-Pattern Risk)
- [x] **"AI Data Processing" toggle in Settings is a placebo.** `ai_privacy_section.dart:9` defines `_kAIProcessingKey = 'ai_data_processing_enabled'` and writes to SharedPreferences — grep confirmed that key is **never read by any other file**. Toggling off still hits Gemini identically. Either enforce it (block backend chat calls when off) or remove the toggle entirely. **Do not ship a fake consent control.** _(2026-04-21: removed SharedPrefs key; new column `user_ai_settings.ai_data_processing_enabled` via migration `1962`; `services/consent_guard.require_ai_processing_consent()` now fires in both `/chat/send` and `/chat/send-stream` before any model call.)_
- [x] **`save_chat_history` field in `user_ai_settings` is stored but never checked** before `db.create_chat_message(chat_data)` at `backend/api/v1/chat.py:119`. Another placebo control. Enforce server-side or remove. _(2026-04-21: `should_save_chat_history()` gate added; skips `_save_chat_to_db` background task when off. New UI toggle in Privacy & Data section.)_

### GDPR Art. 20 (Portability) Violation — Incomplete Data Export
- [x] **`backend/services/data_export.py` exports only 8 tables:** profile, body_metrics, workouts, workout_logs, exercise_sets, strength_records, achievements, streaks _(2026-04-21: bumped to EXPORT_VERSION 2.0.)_
- [x] **Missing from export:** chat_history, food_logs, progress_photos (raw files + URLs), nutrition_summaries, user_ai_settings, injuries, habits, personal_goals, measurements, hormonal_health logs, kegel logs, cardio logs, custom_exercises. **Ship a complete export before any EU user files a DSAR.** _(2026-04-21: added `_PORTABILITY_TABLES` with 16 tables; extended CSV/JSON/Excel/Parquet paths; added README.txt companion.)_
- [x] **No "email my data" flow outside the logged-in app** — a user who's been locked out has no way to exercise Art. 20 rights _(2026-04-21: built public `/api/v1/dsar/` flow — HTML form + POST /request + GET /verify. Email-ownership proof via hashed one-time token (24h TTL), S3-signed download URL (7d TTL), background fulfillment, audit row in new `dsar_requests` table (migration 1963, applied). Supports export / access / delete request types; rate-limited 5/hour per IP + one open request per email. Privacy policy §9 now surfaces the URL as a first-class option.)_

### Undisclosed Sub-Processors (GDPR Art. 28)
- [x] **PostHog is hardcoded in `AndroidManifest.xml:84-87`** pointing at `us.i.posthog.com` — US data transfer. Not disclosed in privacy policy section 5. Add to sub-processor list OR remove. Also publish SCCs (Standard Contractual Clauses) for the US data transfer per GDPR Ch. V. _(2026-04-21: added to §5 table with location disclosure; SCC language added below the table.)_
- [x] **Sentry (error tracking) is in `pubspec.yaml` but not disclosed** as a sub-processor. Same issue. _(2026-04-21: disclosed in §5.)_
- [x] **Firebase Crashlytics captures stack traces** that may include user data — not disclosed as retaining user data _(2026-04-21: disclosed in §5 with 90-day retention line in §7.)_

### Gemini API Training-Data Exposure
- [x] **`backend/core/gemini_client.py:66-82` falls back from Vertex AI → developer Gemini API** when `GCP_PROJECT_ID` isn't set. Developer API may use prompts for model improvement unless explicitly opted out. **Force Vertex AI (zero-data-retention config) for all production traffic**, or document the opt-out clearly in privacy policy. _(2026-04-21: `get_genai_client()` raises in production without Vertex config; `allow_gemini_dev_api_in_prod` escape hatch defaults False.)_
- [x] **Privacy policy never says "Google does not train on your data"** or references Vertex AI ZDR guarantee — the single most important question for privacy-conscious users _(2026-04-21: §3 now has an explicit "Zero Data Retention" bullet citing Vertex AI.)_

### Privacy Policy Foundational Gaps
- [x] **No legal entity name** in privacy policy contact section (section 15) — just email addresses _(2026-04-21: added "Zealova, Inc. (Delaware corporation)" — verify against actual registration.)_
- [x] **No registered business address** _(2026-04-21: added Wilmington DE address placeholder — verify.)_
- [x] **No DPO name/contact** — GDPR Art. 37 requires this for processors handling health data _(2026-04-21: §10 + §15 now list `dpo@zealova.com`.)_
- [x] **No UK/EU representative** — GDPR Art. 27 requires this for non-EU controllers processing EU user data _(2026-04-21: §10 adds EU (`eu-rep@zealova.com`) + UK (`uk-rep@zealova.com`) representatives.)_
- [x] **Two different support domains** in policy: `privacy@zealova.com` vs `support@zealova.com` — suspicious, inconsistent, needs reconciliation _(2026-04-21: consolidated to `support@zealova.com`. Note 2026-04-25: fitwiz.app belongs to a different company — never use it.)_
- [x] **"12-month chat retention" promise in section 7 is not implemented** — zero grep matches in backend for retention/archive/cleanup/cron touching `chat_history`. Either build the retention cron or rewrite the promise. _(2026-04-21: new `api/v1/retention_cron.py` with `POST /api/v1/retention/cron`; prunes chat_history >365d, push_nudge_log >90d, media_jobs >30d. Same external-scheduler pattern as `push_nudge_cron`.)_

### Health Data Special Category (GDPR Art. 9 / HIPAA)
- [x] **Weight, heart rate, sleep, menstrual/hormonal data are special category under GDPR Art. 9 and PHI under HIPAA** — privacy policy section 4 mentions Health Connect/HealthKit but never uses the words "special category," "Art. 9 explicit consent," or "HIPAA BAA with subprocessors" _(2026-04-21: added new §4.1 "Special Category (Art. 9) Health Data — Explicit Consent".)_
- [x] **Standard Gemini API terms do NOT include a HIPAA BAA** (only specific Vertex AI configs do) — if US users log health data, this may be a material misrepresentation _(2026-04-21: §4.1 now states Zealova is not a HIPAA-covered entity and instructs users not to submit PHI; paired with Vertex ZDR routing enforcement.)_
- [x] **Add explicit Art. 9 consent gate** for health data processing during onboarding, separate from general ToS acceptance _(2026-04-21: new `user_ai_settings.health_data_consent` column + timestamp; `HealthConnectScreen._handleConnect` stamps consent before OS permission prompt; `activity.py` sync endpoints return 403 without it.)_

### Consent Screen Bug (Blocks Data Sale Opt-Out)
- [x] **`sendDataToCoach` variable may be read before initialization** in consent flow (verify in `ai_consent_screen.dart`) — any unhandled consent state is a risk _(2026-04-21: audited — no `sendDataToCoach` identifier exists anywhere in the repo; likely referred to a prior branch. Current `_onConfirmed()` only touches initialized `aiConsentProvider` and `healthDisclaimerProvider`.)_

---

## Deprecated / Orphaned Code Already Built (Wire Up or Remove)

*Multiple agents surfaced the same pattern: significant features exist as backend services or UI widgets that are never reached by real user flows. These are the highest ROI improvements — the code is done, just not plumbed.*

- [ ] **`PreWorkoutCheckin` widget (`screens/workout/widgets/pre_workout_checkin.dart`) is invoked nowhere** — grep confirms zero call sites outside its own file. The diabetes pre-workout risk endpoint (`/diabetes/exercise/{user_id}/pre-workout`) exists and returns glucose-gated risk levels; wire the widget to the workout-start flow for diabetic users. **Single highest-ROI feature for T2D retention.**
- [ ] **`backend/services/senior_workout_service.py apply_senior_modifications` is never called** from the workout generation pipeline (zero grep hits in `backend/api/v1/workouts/`). Dead code until plumbed into `generation.py`.
- [ ] **`/mode-selection` route exists but is never navigated to** from any screen. `app_router_pre_auth_routes.dart:531` defines it, no caller reaches it. Kill it or wire it into the age-gated senior flow.
- [ ] **`senior_fitness_screen.dart` is a UI stub** with mocked `Future.delayed` save calls — not wired to the real `/v1/senior-fitness` endpoint
- [ ] **Onboarding `limitations` field never reaches Gemini workout generation.** Grep of `backend/services/gemini/workout_generation_helpers.py` for `limitations` returns zero hits. User flags shoulder pain at onboarding → AI recommends overhead press 2 workouts later. **Critical bug for injured + adaptive-athlete users.**
- [ ] **Wheelchair Fitness program (migration 441) exists** but is not filtered into per-user AI generation — lives as a manual-find pre-built program only. `limitations` field doesn't flow to exercise RAG selection.
- [ ] **`analyze_workout_glucose_impact` endpoint is a stub** — `diabetes_endpoints.py:645-656` returns None/0/0. This is the headline Levels/Nutrisense-competitor feature; finish it.
- [ ] **`Pregnancy Safe` tag is a keyword heuristic** (`library/utils.py:663-669` matches "plank", "twist" → blocks them) — and the tag is only used at library-browse time, NOT in AI workout generation. Pregnant user gets supine crunches on Day 1.
- [ ] **Apartment-friendly / silent workout programs exist as seeded migrations** (1503, 1115, 1117, 1118, 1122) but **no "dorm" or "apartment (quiet hours)" equipment option in onboarding** — so the programs are orphaned
- [ ] **Kegel `KegelFocusArea.postpartum` enum exists** in `mobile/flutter/lib/data/models/kegel.dart:17` + migration `121_hormonal_health_kegel.sql:462-466` — but never auto-enabled when postpartum is flagged (and postpartum isn't captured in onboarding anyway)
- [ ] **Offline mode code (on-device Gemma, Drift local DB, SQLCipher, flutter_gemma package) all still in repo** — but Settings UI toggle removed. Either kill the code or reinstate the UI. Don't leave 20% of the bundle size on 100% of user devices with no user benefit.

---

## Programming & Training Logic

- [ ] **Mesocycle visibility** — expose 4-6 week block view with volume/intensity curves so users see *why* Wednesday is lighter
- [ ] **"Why today" 1-liner** on every workout — e.g. "Push day, slight deload, lower volume because sleep avg dropped 8% this week"
- [ ] **Program-thinking trust signals** — deloads triggered by fatigue/sleep, not fixed calendar
- [ ] **Velocity-based training** — optional RPE/velocity input for advanced users
- [ ] **ACWR fatigue model** — chronic:acute workload ratio to flag overtraining risk
- [ ] **Improve AI-generated workout names** — "Aries Spark Arm Sculpt" (from `intro_phone_3.png`) reads as slop; cap name generation to practitioner-safe patterns

## Exercise Library & Coaching Depth

- [ ] **Replace LLM-generic form cues** with structured cues: primary fault → corrective drill → regression/progression ladder
- [ ] **Tie safety tagging (NSCA/NASM/ACSM research) to on-screen coaching**, not just exercise filtering

## Nutrition

- [ ] **Training-day vs. rest-day macro split** by default
- [ ] **Batch cook leftover tracking** surfaced on plate-log screen (model already exists)
- [ ] **Refeed / diet-break logic** for cutters — scheduled high-carb days + planned maintenance breaks

## Retention Anti-Patterns to Fix

- [ ] **Rest-day home redesign** — show mobility, NEAT target, recovery score, tomorrow's preview (no dead-screen)
- [ ] **Streak fragility** — replace hard streaks with consistency scores + forgiveness windows
- [ ] **Lifecycle email tone** — guilt-free, schedule-aware copy (already in memory feedback)
- [ ] **Coach voice continuity** — enforce single persona across push, email, chat

## Retention Levers, Ranked

1. [ ] **Weekly review ritual (Sunday Wrapped push)** — 90-sec AI summary: volume, PRs, sleep correlation, next-week preview; $0 cost, highest-ROI lever in Strong/Hevy/Whoop
2. [ ] **Progression legibility** — every exercise shows last 3 sessions + next target
3. [ ] **Coach continuity** — single persona voice across all touchpoints
4. [ ] **One-tap "adjust today"** — sore / tired / short on time → workout adapts in place; surface on active-workout screen, not buried in chat
5. [ ] **CSV export of every log** — practitioners trust apps that let data leave
6. [ ] **Progress hub consolidation** — merge trophies/achievements/rewards/XP/skills into one tab for discoverability (tighten, don't delete)

---

## Obese Beginner Track

*Persona: 240+ lb, sedentary 4+ years, joint pain, no gym experience, borderline comorbidities (prediabetes/hypertension/sleep apnea). High-risk churn persona — 60% drop by Day 30 industry-wide. These items close that gap.*

### Onboarding & First-Run
- [ ] **Obese-beginner onboarding track** — separate flow from general "beginner": chair-based progressions, wall/incline push-ups, 5-10 min sessions Week 1, no jumping/impact exercises
- [ ] **Defer the scale** — first weigh-in optional with "I'd rather wait" option (no guilt); use tape measurements or progress photos as alternative baselines
- [ ] **Jargon-free mode** — toggle replaces "RIR 2" with "2 reps in the tank"; hides "mesocycle," "split," "periodization"; inline tooltips on every jargon term
- [ ] **Medical flag handling** — if user enters hypertension, diabetes, or BMI >35, gentle nudge for doctor clearance + disclaimer on high-intensity workouts

### Programming for Zero-Baseline
- [ ] **True zero-baseline progressions** — chair squats before bodyweight squats, wall push-ups before knee push-ups, seated rows before standing; injury screen should filter exercises, not just suggest swaps
- [ ] **Joint-aware exercise swaps** — bad knees auto-swaps squats → sit-to-stand, lunges → low step-ups, running → walking/water walking
- [ ] **Chair/bed exercise library** — for days user physically can't stand for 10 min
- [ ] **"I'm in pain" button mid-workout** — one tap, swap to joint-friendly alternative, no judgment
- [ ] **"How do you feel today?" pre-workout check** — adapts session based on energy/pain; some days a 10-min walk is the win
- [ ] **Hydration and walking as "real" workouts** — log 10-min walk as a W, not an asterisk; dopamine matters more than rigor

### Nutrition for the Obese Beginner
- [ ] **Calorie ramp, not cliff** — Week 1: -200 cal deficit, Week 4: -500; show ramp visually so user doesn't feel starved day one
- [ ] **Grocery-list meal plans** — 5 recipes for the week + shopping list; decision fatigue drives users back to DoorDash
- [ ] **No "clean eating" shame language** — swap "junk food," "cheat meal," "bad foods" → neutral framing

### UX & Tone
- [ ] **"Just Today" minimal home mode** — hide achievements/challenges/discover until Week 3; show only today's workout, food target, water
- [ ] **Body-neutral copy audit** — no "burn that belly fat," "shred," "torch"; use "feel stronger," "move more freely," "build energy"
- [ ] **Progress photos with privacy-first UX** — local-only storage option, blurred by default in UI, unlocked on tap
- [ ] **Hide leaderboards/social for obese-beginner track** — comparison triggers spiral and churn for this persona
- [ ] **Start-line celebration** — Day 1 completing a 5-min chair workout celebrated as big as a 225 lb bench PR; calibrate gamification to user level

### Non-Scale Retention Hooks
- [ ] **Non-scale victories dashboard** — "walked 2,000 more steps than last week," "slept 7+ hrs 4 nights," "resting HR dropped 3 bpm" — not just weight
- [ ] **Weight-plateau empathy** — when scale stalls 2+ weeks (it will), coach proactively messages "this is normal, here's why" — not silence
- [ ] **Day 3 + Day 7 re-engagement** — highest beginner drop-off points; warm push notification, not guilt
- [ ] **Plateau prediction + pre-emptive message** — AI anticipates the stall and messages *before* user gets discouraged

### The Four Churn Moments to Engineer For
1. **Day 3** — "I can't do the workout, it's too hard" → zero-baseline progressions + "I'm in pain" button
2. **Day 7** — "I weighed myself, no change, I quit" → non-scale victories dashboard + deferred scale + plateau empathy
3. **Day 14** — "I ate a pizza, broke my streak, shame-quit" → streak forgiveness windows + body-neutral copy
4. **Day 21** — "Too many screens, I got lost" → Just Today minimal mode + consolidated Progress hub

---

## Power-User / Competitive Defection (Grounded Against Screenshots + Code)

*Persona: active Hevy + MFP + Strava + Gravl user. Review based on `intro_phone_1.png` through `intro_phone_7.png` + `paywall_pricing_screen.dart` + `discover_screen.dart` + `library/tabs/`. Pricing: 7-day free trial → $49.99/yr ($4.17/mo) with $39.99 fallback popup.*

### Conversion Blocker Per App

*The single thing that keeps a power user locked to each specialist. Fix this for each app = unlock that defection segment.*

#### vs. Hevy — Blocker: **Data moat + logging muscle memory**
- [ ] **Hevy CSV import tool** — 400+ workouts of PRs, notes, custom routines; without import, users won't seed Zealova and churn before the AI gets smart
- [ ] **Routine templates that re-run untouched** — verify user can build a 5×5 template and run it for 12 weeks *without* AI overriding progression; this is Hevy's stickiest feature
- [ ] **Per-exercise PR dashboard** — every lift, every rep-range PR, all-time history, chartable; Hevy's celebration engine is cult-level
- [ ] **Apple Watch auto-set detection** — Hevy's Watch companion is why lifters don't put their phone down
- [ ] **Public CSV/API export** — reciprocate what Hevy gives so users trust they can leave

#### vs. MyFitnessPal — Blocker: **14M food DB + 20 years of barcode data**
- [ ] **MFP CSV / XML import** — custom foods, recipes, meal templates from years of logging; this is the single biggest blocker
- [ ] **Food DB size published + coverage commitment** — users won't switch if "food not found" happens in Week 1
- [ ] **Barcode scanner benchmark (95%+ on 50 random pantry items)** — MFP's is industry standard; parity or don't bother
- [ ] **Recipe URL importer** — paste any blog/NYT/Serious Eats URL → ingredients + macros via Gemini; eliminates manual recipe rebuild
- [ ] **Top-100 US restaurant chain macro coverage** — Chipotle/Chick-fil-A/Starbucks/Subway verified; refreshed quarterly

#### vs. Strava — Blocker: **GPS, segments, social network of 100M**
- [ ] **Do NOT try to replace Strava** — losing fight; wrong scope
- [ ] **Strava activity read-only import via Apple Health / OAuth** — AI coach sees runs/rides without Zealova replacing the activity itself
- [ ] **Basic GPS walk/run logging** — puts Zealova in the conversation for hybrid athletes without competing head-on
- [ ] **Garmin Connect IQ read-only integration** — cardio athletes live on these devices; even passive reads matter

#### vs. Gravl — Blocker: **300+ trainer videos + Strength Score + $440K/mo social proof**
- [ ] **Gravl export/import** — lose strength history, lose the switch
- [ ] **Single headline Zealova Score (composite)** — one number to chase across strength + cardio + nutrition + recovery; harder for Gravl to copy than their Strength Score was for others
- [ ] **Demonstrable AI quality advantage** — cross-domain insight Gravl can't produce (e.g., "squat regressed 5% because protein -20g + sleep -1hr") proven weekly
- [ ] **Revenue / runway transparency page** — Gravl publishes $440K/mo; trust capital for Zealova to match
- [ ] **Budget-aware video parity** — user-generated clips + creator partnerships + curated YouTube embeds (see section below)

#### vs. MacroFactor (Nutrition) — Blocker: **Stronger By Science brand + science-backed algorithm + curated DB**
*MacroFactor nutrition: $11.99/mo / $71.99/yr. Built by Greg Nuckols / Eric Trexler PhD (Stronger By Science) + 5 co-owners. Adaptive TDEE with EMA smoothing, confidence intervals, metabolic adaptation detection. Curated food DB prioritizes accuracy over MFP's size.*
- [ ] **MacroFactor nutrition export import** — diet history + custom foods + meal patterns; higher-accuracy data than MFP, so worth its own importer
- [ ] **Surface the adaptive TDEE math in-UI** — Zealova's `adaptive_tdee_service.py` already has EMA smoothing + confidence intervals + metabolic adaptation detection (MacroFactor-parity backend); need to show users WHY the target changed this week, with a confidence band visible on the check-in sheet. Trust is built by transparency, not hiding the algorithm.
- [ ] **Food DB accuracy claim** — MacroFactor wins on curation, not size; Zealova needs a verified-entry track (community-flagged vs. verified foods, visible in UI)
- [ ] **Science-credibility moat response** — SBS has Nuckols/Trexler; Zealova has no equivalent named expert. Consider a science advisory board + cite sources inline on recommendations (NSCA/NASM/ACSM research already in backend per `feedback_no_llm_for_safety_classification.md`)
- [ ] **Nutrition ↔ Workout cross-sync story** — MacroFactor requires two separate apps to sync body weight / metrics / progress photos; Zealova does this in one app — **lead with this advantage in marketing** (simpler UX, lower cognitive load, single subscription)

#### vs. MacroFactor Workouts — Blocker: **Jeff Nippard co-ownership + 638 3-angle video demos + 900+ exercise tracker + SBS algorithm quality**
*MacroFactor Workouts: launched Jan 2026. Separate app from nutrition. Five co-owners including Jeff Nippard (equity stake, NOT just endorsement) + Greg Nuckols + Cory Davis + Rebecca Kekelishvili + Lyndsey Nuckols. 900+ exercises tracked, 638 with 3-angle Jeff Nippard video demos + detailed technique notes. Auto-progression via progressive overload. Smart algorithm adapts program week-to-week based on performance + fatigue. Imports Jeff Nippard's 6 most recent programs at launch.*
- [ ] **MacroFactor Workouts import** — lifting history, templates, PRs; same data-moat pattern as Hevy but with SBS-tier users
- [ ] **Exercise library count commitment** — publish Zealova's count + trajectory; MacroFactor Workouts at 900, Fitbod at 1,600 — this is becoming a visible number in the category
- [ ] **Jeff-Nippard-tier creator partnership** — Nippard has equity, not just sponsorship. Zealova needs a flagship creator with either equity or long-term exclusive deal. Being Nippard-adjacent without Nippard himself (e.g., other SBS-affiliated names, or a PhD-credentialed coach) is enough at this stage.
- [ ] **Program import marketplace** — MacroFactor Workouts imports Nippard's pre-built programs as a moat; Zealova could import *any* PDF/URL workout program via Gemini parsing — **turn AI into a program universalizer**, not just generator
- [ ] **Week-to-week program adaptation based on performance + fatigue** — verify Zealova's progression adjusts based on logged RIR + completion rate + rest-day count (partially in `progressive_overload` per memory, but unclear if it adjusts *programs* or just *next session*)
- [ ] **3-angle movement reference** — can't match 638 Nippard demos, but tap-to-see-reference-lifter (user records own best rep) + user-generated form library (vision-AI-scored) + curated YouTube embeds get most of the value at $0

#### vs. Fitbod — Blocker: **400M data points + 1,600 exercise library + Strength Score per muscle group + 264K reviews at 4.82★**
*Fitbod $15.99/mo / $95.99/yr. Recovery Intelligence (fatigue-aware muscle rotation), Capability Recommender (auto-picks weight/reps), equipment flexibility built-in, massive social proof (264K reviews).*
- [ ] **Exercise library depth benchmark** — Fitbod has 1,600+ movements; publish Zealova's count + commit to growth
- [ ] **Strength Score per muscle group (0–100+)** — Fitbod's moat; Zealova Score (composite) already suggested vs. Gravl, but should also decompose into per-muscle subscores
- [ ] **Recovery Intelligence / muscle fatigue model** — track muscle-level fatigue, auto-rotate fresh muscles into workouts; this is Fitbod's retention mechanic
- [ ] **Capability recommender** — auto-suggest weight/reps for an exercise based on past performance + current fatigue (Fitbod has this, Zealova's progression_selector exists but may be simpler)
- [ ] **Travel mode / equipment-switch** — user travels, gym has no squat rack, one tap regenerates today's workout for available equipment; Fitbod makes this frictionless
- [ ] **Review count as social proof** — Fitbod 264K reviews, MacroFactor ~50K; Zealova needs active review acquisition strategy post-paywall conversion
- [ ] **Fitbod import (via CSV or manual workout history)** — data moat lock, same pattern as Hevy

---

### Bugs / Polish Gaps Visible in Screenshots
- [ ] **`[ACTIVE WORKOUT CONTEXT]` block leaking to user** (`intro_phone_1.png`) — cyan debug-style context frame visible in chat UI; should be hidden from the user, only sent to the LLM
- [ ] **AI workout naming quality** — "Aries Spark Arm Sculpt" (`intro_phone_3.png`) reads as LLM slop; constrain to professional/descriptive patterns
- [ ] **First rep weight ergonomics** — set 2 shows "70.0" (two decimals); round to 70 unless user entered a decimal

### Cross-Cutting Competitive Gaps (Not Tied to a Single App)
- [ ] **Apple Health two-way sync** — read weight / HR / sleep; write workouts / steps (gateway to every wearable ecosystem)
- [ ] **Full export parity** — CSV/JSON/photos/AI chat logs; reciprocate what we ask users to hand over
- [ ] **Data sovereignty page** — revenue transparency, runway, AI training-data policy, GDPR/CCPA data-request flow
- [ ] **Community / routine marketplace** — user-submitted templates with quality scores (Hevy won this years ago)

### Web Dashboard — Decision: Skip (For Now)
**Not needed as a conversion blocker.** Evidence:
- **Fitbod** (264K reviews, industry-leading) — mobile-only, no web dashboard
- **MacroFactor** (science-darling, $11.99/mo) — mobile-only, no web dashboard
- **Gravl** ($440K/mo, 1M+ downloads) — mobile-only
- Only Hevy + MFP + Strava have real web apps, and they use them primarily for CSV export + long-form data review
- **Cheaper alternative**: email-based export ("email me my last 90 days as CSV") solves 80% of power-user web use cases at <5% of the engineering cost
- Revisit web dashboard if Zealova exceeds 500K paying users and power-user segment explicitly requests it

### Features Zealova Has Planned That Close Competitor Gaps
*User confirmed these are in the pipeline — do NOT add as new improvement items:*
- **AI form check** — already working per memory (UC3), further investment continues; closes Fitbod + MacroFactor Workouts + Gravl video-demo gap
- **Notes** — exercise notes feature planned
- **Recipe import** — closes MFP + MacroFactor nutrition-onboarding gap significantly

### Features Already Shipped That Close Competitor Gaps (Verified in Code)
*These were previously listed as gaps but verified as shipped — noting only for competitive framing, not as TODOs:*
- **MacroFactor-style adaptive TDEE** — `backend/services/adaptive_tdee_service.py` has EMA smoothing + confidence intervals + metabolic adaptation detection; `mobile/.../weekly_checkin_sheet.dart` surfaces it. **Parity with MacroFactor's core algorithm.** Open question is UX transparency (see MacroFactor section) not whether the math exists.
- **Nutrition ↔ Workout cross-sync** — Zealova unifies what MacroFactor splits across two apps

### AI Quality Investments (Highest ROI Per $0 Spent)
- [ ] **Injury memory across sessions** — if user flagged shoulder pain at onboarding, the AI should not recommend overhead press 2 workouts later
- [ ] **AI audit trail** — "why did you recommend this?" button on every AI suggestion
- [ ] **Consistency harness** — batch-test the same prompt 10× on build; flag variance above threshold
- [ ] **Hallucination guard** — exercise recommendations must validate against the exercise library before rendering
- [ ] **Reduce LLM-generic cues** — "keep your core tight" on every exercise signals lazy output; either tie cues to movement-specific fault libraries or don't show

### Budget-Aware Video Alternatives (No Production Shoot Needed)
- [ ] **User-generated form video library** — top-ranked user clips become reference demos (your vision AI already scores them)
- [ ] **Creator partnership program** — 10 fitness creators × 10 videos each = 100 videos at $0 upfront via free Pro + revenue share
- [ ] **Tap-to-record-personal-reference** — user records their own best rep once, replays inline during future sets
- [ ] **Curated YouTube embeds with attribution** — Jeff Nippard / Squat University / AthleanX for the top 50 movements

### Strategic Position
- **Real wedges to defend:** AI coach with workout context awareness + photo-log food + vision form feedback + multi-agent routing + multi-domain breadth (mood/hydration/diabetes/fasting/hormonal) — no single competitor (Hevy, Gravl, Strava, MFP, MacroFactor, Fitbod) has all five
- **Biggest conversion blocker is import tools**, not missing features — prioritize Hevy + MFP + MacroFactor + Fitbod CSV importers above any new feature work
- **Price advantage** — $49.99/yr is 30% below MacroFactor, 48% below Fitbod, 37% below Strava Premium; lead with value-per-dollar in marketing
- **Credibility gap to close** — MacroFactor has Greg Nuckols / Eric Trexler PhD, Fitbod has 264K reviews, Gravl has $440K/mo revenue transparency, Jeff Nippard endorses MacroFactor Workouts. Zealova needs at least one of: named expert advisor, public revenue, or a single flagship creator partnership

---

## Persona Tracks

*10-persona review (2026-04-19). Each persona was reviewed by an agent that read actual Dart + Python code. File paths cited are verified. "VERIFY:" prefix = agent was unsure; confirm before building.*

---

### Senior (65+) Track
*Margaret, 68, retired teacher, recently widowed, knee pain + moderate hypertension; iPhone user, doctor-recommended exercise, never used a fitness app. NOTE: `senior_home_screen.dart` and `senior_onboarding_screen.dart` are deprecated; propose NEW senior UX, not resurrection.*

#### Onboarding & First-Run
- [ ] Add age-gated mode recommendation in quiz phase 3 (after DOB) that calls `accessibilityProvider.setMode(AccessibilityMode.senior)` — do not route to deprecated `/senior-onboarding`
- [ ] Default unit to imperial when device locale is en-US (`PreAuthQuizData.useMetricUnits = true` currently forces kg/cm for everyone)
- [ ] Add a "Senior quick start" 4-screen path (DOB → limitations+conditions → days/week → equipment) vs. current 11 screens
- [ ] Replace gym-jargon fitness levels with plain-English: "I haven't exercised in years" / "I walk most days" / "I used to lift"
- [ ] Expand `quiz_limitations.dart` with a "Conditions & medications" multi-select: hypertension, heart condition, diabetes, osteoporosis, balance issues / recent fall, dizziness, recent surgery, medications affecting HR
- [ ] Require an explicit PAR-Q+ style affirmation on `health_disclaimer_screen.dart` — 7 standard questions, not a single accept-once tap
- [ ] Plan preview needs senior-appropriate intensity framing (Borg 12-13 "somewhat hard" with explanation, not raw RPE)

#### Accessibility & Visual Design
- [ ] 62+ occurrences of `fontSize: 10/11/12` in `lib/screens/home/widgets/` violate CLAUDE.md 14sp floor; audit project-wide
- [ ] `app.dart:149` feeds raw `a11y.fontScale` into `TextScaler.linear` instead of `effectiveFontScale` — fragile, use `effectiveFontScale`
- [ ] VERIFY which primary CTAs (hero_workout_card, daily_activity_card, set logging) respect `AccessibilitySettings.effectiveButtonHeight` vs. hardcoding 40/44
- [ ] Icon-only buttons need visible text labels in senior mode (back arrows, menu kebabs)
- [ ] No one-handed / reachability mode — top-bar controls unreachable on iPhone Pro Max
- [ ] Contrast audit on `theme_colors.dart` — thin orange strokes on dark LCD may dip below 4.5:1
- [ ] VERIFY `AccessibilitySettings.highContrast` actually swaps theme palettes vs. just setting MediaQuery flag

#### Programming for Senior Physiology
- [ ] Add `balance_training` / `fall_prevention` / `chair_assisted` / `single_leg_stand` / `tai_chi` / `sit_to_stand` / `heel_toe_walk` tags to Chroma exercise metadata — seed 30-50 exercises (Otago, STEADI, NIH Go4Life)
- [ ] Add "Walking + light strength" program archetype (Leslie Sansone / SilverSneakers parity) — walking is primary workout for many seniors
- [ ] Rest-timer default: currently universal, needs senior-adaptive default (90s+) per `senior_workout_service.py`
- [ ] Extend warmup to 8-10 min for senior mode (joint prep, mobility flow)
- [ ] Add "very gradual" option to `quiz_progression_constraints.dart` — senior micro-loading (+1 rep or +1 lb/week) vs. standard +2.5-5 lb

#### Medical & Safety
- [ ] Add `beta_blocker: bool` to user health profile; switch senior cardio prescription to RPE 11-13 (`backend/services/cardio/hr_zones.py` uses pure Tanaka/Karvonen — doesn't handle blunted HR)
- [ ] Add HCP-deference rule to injury_agent + coach prompts: "When user states 'my doctor told me not to X' or 'my PT cleared Y,' treat as authoritative; never contradict"
- [ ] Add STEADI 3-question fall-risk screen to onboarding; positive answer forces balance-priority program
- [ ] Surface Valsalva warning on heavy lifts for hypertensive users ("breathe out during exertion")
- [ ] Add "Feeling off? Stop" panic button on active workout (zero grep hits for `emergency_contact|panic|dizzy`)
- [ ] Surface `medical_disclaimer_screen.dart` at first run, explicitly naming cardiac events, dizziness, fall risk

#### Tone, Community, Retention
- [ ] Gate leaderboards behind opt-in for senior mode, or bucket by age cohort — "65+ this week" instead of global rank #48,912
- [ ] Replace "Don't break your streak!" loss-framing with "You've shown up 12 times this month — that matters" (NIH Go4Life tone) for senior mode
- [ ] Reframe workout duration "45-60 min" → "~30 min session — take breaks whenever you need"
- [ ] Replace RPG-style XP/level-up with "weeks active" / "sessions completed"
- [ ] Suppress "partner in fitness" / couples-challenge copy for users flagging "living alone / recently bereaved"
- [ ] Add peer-age coach persona option in `coach_selection_screen.dart` (currently all young)
- [ ] Pre-charge in-app confirmation at trial day 5 (not just email) — "Your trial ends in 48 hours, $49.99 will be charged"

#### Churn Moments
1. **Day 1** — unreadable 10-12pt stats; auto-apply 1.35× TextScaler on first render for DOB-detected seniors
2. **Day 3** — guilt-tone rest-day notification conflicts with cardiologist-scheduled rest days
3. **Day 7** — silent $49.99 surprise charge (add explicit pre-charge modal)
4. **Day 14** — AI ignores "my doctor said walk only" and prescribes squats (ship HCP-deference system prompt)
5. **Day 21** — leaderboard rank #48,912 triggers opt-out; bucket by age cohort
6. **Day 30** — generic "Coach" voice in renewal email; default senior persona to warm peer-age voice

---

### Gen Z (14-22) Track
*Maya, 19, college sophomore, TikTok-native, broke, shares on IG stories, anxious about money/climate/body, follows Natacha Oceane + Jeff Nippard, skeptical of AI but lives in ChatGPT.*

#### Onboarding & Time-to-First-Value
- [ ] 11-screen pre-auth quiz + 5 more gates = 16 screens before first workout; add "Skip for now" path at screens 7-11
- [ ] **Binary gender + "other" is not 2026-inclusive** — `personal_info_screen.dart:132` requires gender; `calorie_macro_estimator.dart:131` hardcodes male/female BMR math, "other" silently falls into female path. Add non-binary + prefer-not-to-say + pronoun field (they/them, she/they, he/they) with neutral BMR path
- [ ] Add "dorm" and "apartment (quiet hours)" equipment options — apartment-friendly programs ALREADY seeded (migrations 1503, 1115, 1117, 1118, 1122) but orphaned without this option
- [ ] Add "quiet hours" toggle that maps to no-jump/no-drop exercise variants (existing `zero_jump_cardio`, `tippytoe_gains` tags)
- [ ] Student discount path (SheerID / `.edu` verify) — no grep hits for `edu|SheerID|student_discount`; Spotify / Apple / Peloton all have this

#### UI Aesthetics & 2026 Design Language
- [ ] Paywall accent hardcoded to Strava orange `#FC4C02` — use `accentColorProvider` to respect coach accent
- [ ] Unify Wrapped + 23 share templates under per-account aesthetic preset (Clean / Retro / Y2K / Dark Academia / Cottagecore)
- [ ] Add haptic scroll tick (`HapticService.selection()` every 4 items) in `feed_tab.dart`
- [ ] Static home gradients feel 2023; add 60fps animated gradient mesh behind hero card
- [ ] Glass morphism is inconsistent across screens — pick one language (iOS 26 frosted glass)

#### Shareable / Viral Loops
- [ ] Add monthly Wrapped (not just yearly) + Sunday 7pm auto-notification
- [ ] Add `ShareAspectRatio.tiktokCover` (1080×1920 with safe-zone guides) — current options only story/square/portrait
- [ ] Referral share: generate aesthetic card (gym personality + coach + code), not plain text — Gen Z shares objects not codes
- [ ] Make "Share without watermark" a premium perk (if not already)
- [ ] Deep-link "Try my workout" — friend lands on workout preview with Install+Try CTA

#### Mental Health & Body-Neutrality
- [ ] **Audit `backend/scripts/gen_batch_fatloss.py`** — "Extreme Shred", "Wedding Ready Shred", "Peak shred: maximum metabolic stress" / "maximum calorie burn" are ED-risk copy. Rename to "Strength Cut", "Body Recomp Block", "Low-Calorie Phase"
- [ ] "Blast" language in `quick_workout_constants.dart:346-386` — add "Neutral names" toggle
- [ ] Add "Not feeling it — swap for stretch/walk" exit ramp on `mood_workout_pre_start_screen.dart`
- [ ] **VERIFY + ADD: crisis-response trigger** in `langgraph_service.py` — if user mentions "hate my body", "not eating", "want to disappear", route to 988 / Crisis Text Line / BEDA card BEFORE fitness-agent replies. Non-negotiable for 14-22 audience
- [ ] Add "Hide body composition metrics" toggle (Deurenberg body fat % in `calorie_macro_estimator.dart:287-293` is an ED trigger for 1-in-4 women 16-24); default off, suggest during onboarding if goal includes `lose_weight` + age < 22

#### Community & Privacy
- [ ] Add `closeFriends` visibility layer to `create_post_sheet.dart:52` (current options: public / friends / private)
- [ ] Default `leaderboard_visible` to off for users under 22; show friends-who-worked-out-this-week card instead
- [ ] Progress photos default private (good) but add blur-by-default preview requiring long-press; store in app-only directory (not system gallery)
- [ ] Add on-device-only mode for mood/journal data (use Drift without Supabase sync)
- [ ] Add "See my data" JSON dump view — Apple-style transparency

#### Nutrition Realities
- [ ] VERIFY coverage of college staples: Maruchan ramen cup, Pop-Tart, dining hall plate, Starbucks venti iced brown sugar, dorm microwave mac — run a top-50 coverage audit
- [ ] Coach should suggest cheap upgrades: "you logged instant ramen — add an egg + frozen veg for +14g protein"
- [ ] Add "$50/week" or "$75/week" grocery-budget constraint option in meal plans (USDA cost data)

#### Pricing & Access
- [ ] 4-pay annual split ($12.50/mo × 4, no interest) via RevenueCat
- [ ] Add concrete "$0.11/day = 1/40th of a gym membership" framing (Gen Z responds to concrete)
- [ ] Premium-Duo or group plan SKU (friendships drive retention)
- [ ] Conditional 30-day trial extension if user completes 5 workouts in first 7

#### Tone & Voice
- [ ] **Refresh Gen-Z slang dictionary** in `backend/services/langgraph_agents/personality.py:117` — "no cap", "fr fr", "slay", "bussin", "its giving" are 2023-24, already ironic by 2026. Current slang: "delusional", "yap", "aura", "lowkey hard", "chat is this real", "let him cook". Version the dictionary so it ages out gracefully
- [ ] Gender-neutralize "bro"/"dude" in `achievement_prompt_service.dart:334,419`
- [ ] Add meme-recognition layer (don't over-do it; fail-gracefully silence > cringe)
- [ ] VERIFY lifecycle emails match selected coach persona tone (not formal "Hey there" when user picked Hype Danny)

#### Music & Audio
- [ ] Native Spotify / Apple Music Now-Playing controls in workout screen (`audio_session_service.dart:8` already has `mixWithOthers | duckOthers` infra)
- [ ] Recommended playlist per workout type (Spotify public playlist embed, no SDK required for MVP)
- [ ] Audio-only AirPods mode — screen off, audio cues only, volume-button skip

#### Churn Moments
1. **Day 0-1 onboarding fatigue** — 30% drop at screens 7-11; add skip-to-workout path
2. **Day 1 post-first-workout** — mandatory 3-tap post-workout feedback that immediately adjusts next workout
3. **Day 7 trial end** — surface coach-persona-voice recap with social proof + "next week is a deload and you're about to PR" before paywall
4. **Day 14 missed days** — non-guilt "no app guilt here, week 2 is easier than week 1" + 3-day restart plan
5. **Day 30 Wrapped** — monthly mini-Wrapped (5 cards) as repeatable viral hook

---

### Localization / Non-English Speakers Track
*Rohan (Bangalore, 28, Hindi/English), Sofia (São Paulo, 34, Portuguese), Wei (Shanghai, 24, Mandarin). Backend is surprisingly global; frontend is parochial.*

#### Language Support Audit
- [ ] **CRITICAL: Zero localization infrastructure.** No `mobile/flutter/lib/l10n/` directory, no `.arb` files, no `flutter_localizations` in `pubspec.yaml`, no `supportedLocales` or `localizationsDelegates` anywhere. `intl` package used only for DateFormat, not translations. **App is 100% English-only today.** This is a launch-blocker for India/Brazil/China markets
- [ ] No `Locale()` / `Platform.localeName` / `PlatformDispatcher.locale` detection — app cannot even read device language
- [ ] iOS has only `Base.lproj` (English); no Android `values-hi/`, `values-pt/`, `values-zh/` resources
- [ ] App Store / Play Store listings English-only per region — organic discovery dead in non-English stores

#### Unit & Format Localization
- [ ] **Cardio hardcoded to imperial** — `staple_choice_sheet_ui.dart:91` field suffix is literally `'mph'`, params `speed_mph` / `distance_miles`. Sofia running in km/h gets mph regardless of her weight unit setting
- [ ] **Decimal-comma silently fails** — all `double.tryParse` rejects `1,5`. Sofia types `72,5` kg → field reads 0 → weight chart flatlines → she thinks app is broken
- [ ] Dates hardcoded US-format — `DateFormat('MMM d, yyyy')`, `h:mm a` (12-hour) everywhere. Build a locale-aware DateFormat wrapper
- [ ] Three-unit separation (workout/body/increment) defaults identically from one `useMetricUnits` bool — locale-aware defaults needed
- [ ] **No RTL support** — zero `Directionality` / `TextDirection.rtl` branches. Arabic / Hebrew / Urdu users get mirrored layouts

#### Cultural Food DB
- [ ] **Strong backend foundation (credit)** — 200+ country migrations (`1650_overrides_AF_afghanistan.sql` through `1862_overrides_ZW_zimbabwe.sql`) + INDB integration. Good.
- [ ] **But search ranking is not country-aware by default** — `setDefaultCountry()` exists but is user-opt-in; onboarding should auto-set from device locale
- [ ] Add `eggetarian`, `jain` (no onion/garlic/root veg), `pescatarian` nutrition filters (current: only vegan/vegetarian)
- [ ] Add halal / kosher filters for Muslim / Jewish users (zero hits outside Bhutan thali descriptions)
- [ ] VERIFY street-food/hyperlocal brand coverage: Amul, Britannia, Parle-G, Maggi (India); Pão de açúcar, Guaraná Antarctica (Brazil); Master Kong, Wahaha (China)

#### AI Coach Multi-language
- [ ] **Coach only responds in English** — zero prompt directives to mirror user language. Rohan writes in Hindi, Gemini replies in English. Add `{{user_language}}` variable in `personality.py` system prompt
- [ ] Add `preferred_language` / `language_code` column to user model (backend has no place to store "Rohan prefers Hindi")
- [ ] `flutter_tts` during workouts uses `en-US` voice — swap to user's locale during rest-timer countdowns
- [ ] **Food-vision prompts English-only** — Wei photographs 老干妈 chili crisp, classifier outputs English food names, DB search misses match

#### Regional Pricing & Payment
- [ ] **Hardcoded USD fallback strings** throughout `paywall_pricing_screen.dart:82,89,94,106` + `paywall_pricing_screen_part_accent_border_card.dart:625,764,789,817,827,835,874` + `hard_paywall_screen.dart:250`. When RevenueCat offerings fail on flaky networks (common in India), Rohan sees `$49.99` → mentally converts to ₹4,200 → bounces. Remove USD fallbacks; show error state per `feedback_no_silent_fallbacks.md`
- [ ] **"Less than a coffee" daily framing is US-centric** — Indian chai is ₹10; needs locale-aware anchor ("menos que um café", "比一杯咖啡便宜")
- [ ] **No PPP tier** — HealthifyMe charges ₹1,500/yr in India vs. Zealova ₹4,200/yr (3× cheaper). Configure at least 3 RevenueCat tiers (US/EU, LATAM, SEA+India)
- [ ] Trial messaging not translated — "7-day free trial" means nothing to Sofia

#### Local Fitness Culture Integration
- [ ] Yoga catalog already strong (15+ programs) — good for Rohan
- [ ] Tai chi / qigong exist but tagged as "senior" only — Wei (24) won't find qigong through senior filter
- [ ] No capoeira / BJJ / Muay Thai outside one program — add BJJ conditioning as native option for Brazilian users
- [ ] No Ayurveda / dosha-aware nutrition — huge in India (HealthifyMe, Cure.fit)
- [ ] **Exercise names English-only** — Wei searching 卧推 (bench press) gets zero hits. Blocks the entire RAG pipeline for non-English users even if chat were translated
- [ ] VERIFY coach avatars in `assets/images/coaches/` — South Asian / Latin / East Asian representation or all Western?

#### Regional Retention
- [ ] **Meal timing assumes Western schedule** — Indian dinner 9-10pm, not 6pm; "haven't logged dinner" push at 7pm is premature. Per-locale meal-time defaults
- [ ] Notifications + transactional emails English-only — body copy needs translation (name injection works already)
- [ ] WhatsApp integration missing — India runs on WhatsApp (~80% open rate vs ~20% push). Competitors use WhatsApp Business API
- [ ] No family-plan SKU — Indian users buy for whole family
- [ ] No religious-calendar awareness (Ramadan, Navratri, Lent) for meal reminders / macro flags
- [ ] Ethnicity-aware BMR adjustment — Asian populations have 3-5% higher body fat at same BMI; `metrics_calculator.py:156` uses Mifflin-St Jeor without ethnicity input, Wei's TDEE is overestimated

#### Churn Moments
1. **Onboarding weight screen** — Sofia types `72,5` → silent parse fail → thinks app is broken
2. **Paywall with flaky network** — USD fallback renders → Rohan converts mentally → closes app
3. **First AI chat** — Wei writes Chinese, coach replies English → "this app doesn't speak my language"
4. **Cardio logging** — Sofia sees mph / miles after a 5km run → friction compounds → abandons
5. **Barcode scan** — Wei scans Master Kong noodles, `overrides_CN_china.sql` coverage gap → "product not found" → manual entry friction

---

### AI-Skeptical / Privacy-First Track
*David, 42, IT security architect. DuckDuckGo, Signal, ProtonMail. Most legal/compliance issues moved to top section. Remaining UX items below.*

- [ ] **Publish a `.well-known/security.txt`** + responsible disclosure policy (`backend/main.py` routes)
- [ ] Ship bug-bounty program (HackerOne / Intigriti)
- [ ] SOC 2 Type II or ISO 27001 audit within 12 months — competitor comparison: 1Password publishes, Apple Fitness+ publishes crypto whitepaper
- [ ] **"About Us" page with company name, team, founders** — privacy policy has no legal entity; competitors (Gentler Streak, Tangerine) list founder names
- [ ] Document Vertex AI zero-data-retention config explicitly in privacy policy
- [ ] Revenue transparency page (Gravl publishes $440K/mo — this is trust capital)

**Note:** The AI-skeptical persona would be willing to pay for "local-only" mode. Since offline mode UI is removed, there's currently no buyable state for "pay $49.99 and never phone home to Google." If resurrecting is deprioritized, this persona is unreachable.

#### Churn Moments
1. **Reads privacy policy + consent screen** — spots 3 contradictions in 5 min, screenshots, posts Twitter thread. Fix: align consent copy with policy before launch
2. **Runs Charles Proxy on "AI Data Processing" toggle** — confirms placebo. Files GDPR Art. 7(4) complaint
3. **Requests GDPR export → 8-table ZIP** — files DSAR, posts r/privacy thread, 2 years of top Google hits for "Zealova privacy"

---

### Time-Poor Parent Track
*Priya, 34, two kids (3 & 6), marketing manager, husband travels, home-only, postpartum.*

#### Time-Constrained Programming
- [ ] `quiz_days_selector.dart:45-48` tags 45-60 min as "Recommended" — context-aware: tag <30 as recommended when `obstacles: time` or `sleep_quality: poor`
- [ ] Surface "How long do you have?" (15/20/30) chip on Home, not just onboarding — Quick Workout sheet exists but sits behind carousel
- [ ] Add "End early & save progress" button on active workout — currently kids-woke-up = lose streak or don't log

#### Home-First Equipment
- [ ] **Yoga mat missing from equipment grid** despite onboarding copy promising "bodyweight + mat" — 12 chips in `quiz_equipment.dart:115-128` include TRX, medicine ball, cable machine, no mat
- [ ] Don't pre-select pull-up bar under `home_gym` — most garages don't have one
- [ ] Add `low_impact_quiet` / `nap_mode` RAG filter to exclude jumping / stomping / dropped weights (`service.py:746-753` has full/home/bodyweight only)

#### Postpartum
- [ ] **Zero postpartum / pregnancy / DR / pelvic-floor chip in `quiz_limitations.dart`** — Priya has to free-text "Other," AI may not respect for safety-critical programming
- [ ] **Auto-enable `KegelFocusArea.postpartum`** when postpartum flagged — feature exists (`data/models/kegel.dart:17`, migration 121) but buried in settings, never linked from onboarding
- [ ] VERIFY `safety_mode.py` excludes crunches/sit-ups/planks-under-duress for diastasis recti — safety liability issue

#### Household Integration
- [ ] **Google Calendar scope is wrong** — `google_calendar_service.dart:97 pushEvent()` pushes `schedule_items` (meals/appointments), not workouts. `Workout` has no `googleCalendarEventId`
- [ ] **Zero Apple / EventKit support** — iOS parents can't see workouts on Family Sharing calendar (`add_2_calendar` / `device_calendar` packages not in `pubspec.yaml`)
- [ ] Add `premium_yearly_duo` RevenueCat SKU — Peloton's household plan is a real conversion lever; doubles retention
- [ ] **One-tap Silent Mode** on active workout header — mutes all 4 sound categories (`sound_settings_section.dart:33`) + swaps to haptic. Currently nap-killing rest beeps require individual muting
- [ ] Add "family-meal shortcut" in nutrition — log adult portion of kid-plate recipe + save as template ("Mia's mac & cheese – mom portion"); soften `inflammation_tags_section.dart:294` copy for family-meal context

#### Churn Moments
1. **Day 3, 6am, 18min window** — auto-promote quick workout to hero when last 3 starts were quick; collapse conflict dialog to toast
2. **Week 2, nap-time, rest beep wakes toddler** — ship one-tap Silent Mode
3. **Day 21, partner traveled 4 days** — ask at intake "Does your partner travel?"; auto-generate lighter solo-parent week template; renewal email leads with attendance vs. plan, not vs. ideal

---

### Chronic Condition Track
*Tom, 52, T2D + HTN + sleep apnea, CGM-wearer, fears hypoglycemia during workouts. Nina, 29, PCOS + TTC, insulin-resistant.*

**Context:** Diabetes backend is surprisingly deep (~40 endpoints, A1C, TIR, CV, GMI, patterns, pre-workout risk, HealthKit glucose sync). See the orphaned-code section above — `PreWorkoutCheckin` widget exists but never invoked, `analyze_workout_glucose_impact` is a stub.

#### CGM & Device Integration
- [ ] Ship glucose-gated "Start Workout" — call `/diabetes/exercise/{user_id}/pre-workout` on tap; block if `can_exercise=false`, show carb countdown
- [ ] Add CGM trend arrows (↑↑ ↑ → ↓ ↓↓) computed from HealthKit slope over last 15 min — current `BloodGlucoseReading` has no direction
- [ ] Fill `analyze_workout_glucose_impact` stub — correlate workout timestamps with glucose deltas per workout type (the Levels/Nutrisense headline feature)
- [ ] Dexcom Clarity / LibreView deep-link buttons for users without HealthKit bridging

#### Medication-Aware Programming
- [ ] Add general `user_medications` table (current: only diabetes-specific `diabetes_medications`) with RxNorm autocomplete + impact flags (`blunts_hr`, `increases_hypo_risk`, `muscle_side_effects`)
- [ ] Adjust HR zones when `blunts_hr=true` (subtract 20-30 bpm from Tanaka max or use RPE) — `backend/services/cardio/hr_zones.py` is unconditional Tanaka
- [ ] Show RPE 1-10 dial alongside HR on active workout when medication flags warrant
- [ ] Statin myalgia check-in — atorvastatin-flagged users get bilateral muscle pain vs. normal DOMS differentiation

#### Condition-Specific Nutrition
- [ ] **Low-GI tagging** on food corpus — zero grep hits for `glycemic.?index`. Add `estimated_gi` + `glycemic_load` columns
- [ ] **PCOS supplements** (inositol, vitamin D, NAC) — zero `inositol` hits. Add supplements module with evidence citations
- [ ] TTC-aware programming for Nina — `HormoneGoal.improveFertility` enum exists but only adjusts prompt text. Cap HIIT, flag LEA, prioritize strength + walking
- [ ] Carb-counting bolus calculator UI — backend has `carbs_covered`, `carb_ratio`, `correction_factor` but exposed nowhere

#### Medical Ecosystem Handoff
- [ ] **Doctor-ready PDF export** — `reports_hub_screen.dart` is share-to-social only; add `printing` package, generate 2-page PDF (A1C trend, TIR, BP log, medications, weekly minutes, hypo events). This is what makes PCP say "keep using this app" at 3-month follow-up
- [ ] In-app BP log widget + Bluetooth cuff pairing (Omron, Withings via HealthKit) — current BP is onboarding-only (`Onboarding.tsx:340`)
- [ ] Unified medical-complexity gate — ≥2 of {T2D, HTN, apnea, cardiac, BMI≥35} → PCP clearance + single compound disclaimer
- [ ] CPAP / apnea-event integration from HealthKit (iOS 16+ `sleepApneaEvent`) — correlate poor-AHI nights with next-day auto-deload

#### Churn Moments
1. **Morning cardio, glucose 78 trending down** — today nothing happens; ship glucose-gated start FIRST, earns the $49.99 vs. losing to Levels
2. **3-month PCP follow-up** — can't generate PDF → doctor says "interesting app, let's start metformin"
3. **Nina's first month, weight doesn't move (normal for IR women)** — default home screen shows weight/steps/calories, nothing validates her progress → cancel at trial end. Ship PCOS wins dashboard (cycle variance ↓, fasting glucose ↓, energy ↑)

---

### Pregnant / Postpartum Track
*Sarah, 31, 20 weeks T2, OB-cleared. Jen, 33, 3 mo PP, breastfeeding.*

**Major issue:** `Pregnancy Safe` tag is a keyword heuristic (`library/utils.py:663-669`) AND is not used in AI workout generation at all — see orphaned-code section.

#### Onboarding & Safety Gating
- [ ] **No pregnancy / postpartum flag exists anywhere in onboarding.** Add `life_stage` quiz step: not pregnant / trying / pregnant (+ weeks) / postpartum (+ weeks + C-section vs. vaginal vs. VBAC + breastfeeding Y/N)
- [ ] Hard medical-clearance gate — blocking modal requiring "My OB/midwife has cleared me for moderate exercise" with date stamp → `users.medical_clearance` column; re-prompt every trimester. If unchecked, restrict generator to walking + gentle mobility only
- [ ] **ACOG red-flag tripwire** — vaginal bleeding, amniotic leakage, contractions, chest pain, headache, calf pain, decreased fetal movement. Zero references anywhere in `screens/workout/`

#### Trimester-Aware Programming
- [ ] Replace keyword-heuristic `pregnancy_safe` with curated `pregnancy_tier` column per trimester (safe / modify / contraindicated) — NSCA Position Stand + ACOG Committee Opinion 804 citations per `feedback_no_llm_for_safety_classification.md`
- [ ] Supine-position cutoff after T1 (~16-20 weeks) — swap lying exercises for incline 30° / side-lying alternatives
- [ ] Add breathing/Valsalva cue ("exhale on exertion, never hold breath") to every pregnant-user exercise
- [ ] **Add RPE scale entirely** — zero matches for "RPE", "perceived exertion", "talk test" in frontend. ACOG recommends RPE 12-14 or talk test in pregnancy (HR is unreliable due to plasma expansion). Build `PregnancyIntensityGuide` widget

#### Postpartum Return-to-Training
- [ ] Diastasis recti self-screen (3 questions + video demo) — gates loaded core until cleared. Zero grep hits for "coning" / "doming"
- [ ] Week-by-week unlock schedule (wks 0-6: breathing + pelvic tilts; wks 6-8: BW squats + glute bridges; wks 8-12: light resistance + walking; wks 12+: progressive return) — generator has no `weeks_postpartum` input
- [ ] C-section vs. vaginal delivery differentiation — scar mobilization cues, block core flexion before wk 8, 6-week OB hard stop
- [ ] Sleep-deprivation-aware adjustment — "How did you sleep?" 1-tap check; <4h cumulative → auto-regenerate with 30-40% volume reduction

#### Breastfeeding Nutrition
- [ ] **No lactation calorie adjustment anywhere** — zero matches for "breastfeed", "lactat", "+450", "+500". Add `breastfeeding_status` (exclusive / partial / weaning / not BF) → feeds into `calculate_calorie_target` with IOM deltas + 25g protein floor + 1000mg calcium floor
- [ ] Hydration target unadjusted for BF (~16 cups/day vs. baseline ~9)
- [ ] **Fasting is correctly blocked in `fasting_endpoints.py:264` IF "pregnant"/"breastfeeding" appears in `health_conditions` string — but no onboarding step writes those strings.** Gate is functionally dead code. Wire life-stage flag to fasting safety check

#### Churn Moments
1. **Week 1 — supine crunch in generated plan** — Sarah OB-cleared at 20 weeks, has no pregnancy flag option → Reddit post "this app doesn't know I'm pregnant, refunded"
2. **Week 3 postpartum — "You missed 4 workouts" at 6am while cluster-feeding** — guilt tone, uninstall. Fix: suppress streak/shame for weeks 0-12 PP
3. **32 weeks — "Your weight is up 8 lbs, let's get you back on track" banner** — legitimate gestational weight gain flagged as regression. Fix: suppress weight-trend banners when `life_stage=pregnant`; replace with IOM-based expected-range messaging

---

### Adaptive Athlete Track
*James (35, paraplegic, wheelchair), Emma (27, blind, VoiceOver), Marcus (42, above-knee amputee). The most catastrophic finding across all personas: `limitations` field never reaches Gemini (see orphaned-code section).*

#### Accessibility Compliance
- [ ] **Zero `Semantics` wrappers in `mobile/flutter/lib/screens/workout/`** — all 36 files. Emma can't hear set number / target reps / current weight / rest countdown via VoiceOver. Wrap `Text(...)` with `Semantics(label:, liveRegion:)` in `set_row.dart`, `rest_timer_overlay.dart`, `expanded_exercise_card.dart`
- [ ] VERIFY `HapticService.countdownTick(secondsRemaining)` is invoked every second from rest-timer loop (not just on done)
- [ ] Add captions to `video_player` instances — `SubtitleConfiguration` / `ClosedCaptionFile` not present anywhere
- [ ] RIR pill selection state is color-only (cyan border/fill at `set_row_part_rpe_rir_selector_state.dart:432-440`) — add checkmark icon for monochrome vision
- [ ] Add `AccessibilityMode.screen_reader` + `AccessibilityMode.deaf` options with haptic-always, captions-on, announce-set-changes defaults
- [ ] VERIFY RIR pills + limitation chips render ≥44pt tall at default font scale on iPhone SE

#### Adaptive Exercise Library
- [ ] **Onboarding cannot capture permanent disabilities.** Add `mobility_impairment`, `wheelchair_user`, `visual_impairment`, `hearing_impairment`, `missing_limb`, `prosthetic_user` fields — current `quiz_limitations.dart` is joint-only
- [ ] Add `seated`, `wheelchair_accessible`, `one_arm_only`, `standing_required`, `lower_body_free`, `stump_loading_safe` position tags to exercise model
- [ ] Wire migration 441 `Wheelchair Fitness` program to AI generation path (currently orphaned — manual-find only)
- [ ] Add "Upper body 4x/week (adaptive)" + "Push/Pull 3x/week (no legs)" presets in `training_split_screen.dart`
- [ ] Community/social filter for adaptive athletes in `screens/social/`

#### AI Coach Disability-Awareness
- [ ] **LangGraph injury agent frames disability as recoverable** — "clear recovered injuries, track recovery progress." Paraplegics don't recover from paraplegia. Add permanent-adaptation profile (separate from injury log)
- [ ] **`limitations` field absent from Gemini generation prompt** — zero grep hits for `limitations` in `workout_generation_helpers.py`. Paraplegic user gets "Barbell Back Squat" on Day 1
- [ ] `safety_mode.py` activates only at ≥50% injury violation — fallback is too gentle (PT HEP, not progressive upper-body strength). Add middle-tier "adaptive programming mode"
- [ ] Chat coach can't persist "I'm a wheelchair user" as permanent constraint — injury tool treats everything as transient

#### Churn Moments
1. **Day 1 — barbell back squat prescribed to paraplegic** — `limitations` never reaches generator → trial refund
2. **RIR selector with VoiceOver** — Emma can't announce pill values or confirm selection → can't log set
3. **Free-text "above-knee amputee" in "Other"** — Marcus sees running-based conditioning in plan preview → $49.99 buys non-adaptive generator → trial churn

---

### Broke College Student Track
*Jamal, 20, state-school, $400/mo, dining hall, dorm-gym, shares on Instagram, free-forever mindset (Hevy, Strong, MFP free tiers).*

#### Pricing & Access
- [ ] **Free tier is extractive, not a product.** Verified in migrations 268 + 1864 + 1868: 2 AI workouts/mo, 20 chat messages/day, 1 food photo/mo, 3 text-to-calories/mo, 5 form videos/mo, 0 form analysis. Jamal burns 50% of monthly quota Sunday planning his week. Raise AI generation free limit to 4/week (use rule-based path)
- [ ] **No student discount** — grep returns zero hits for `edu|SheerID|student_discount|student_verify|.edu`. RevenueCat + SheerID integration is 1 day of work. Student tier at $24.99/yr or $29.99/yr
- [ ] $39.99 save-offer fires exactly once via `_hasShownDiscount` in `paywall_pricing_screen.dart:479-507` — make a persistent student-verify path
- [ ] Semester pass SKU (`premium_semester_24` = $19.99 for 4 months) aligning with fall/spring rhythm; free over summer when away from gym
- [ ] Subscription pause option (RevenueCat supports it) for winter/summer break vs. hard cancel + re-acquisition at full CAC

#### Dorm-Reality Programming
- [ ] **No `dorm_gym` environment type** in `backend/api/v1/gym_profiles.py:65,644` — current enum is `commercial_gym | home_gym | home | hotel | outdoors`. Dorm gyms are not commercial (50lb DB cap, 1 rack peak-hour, no specialty). Add `dorm_gym` with hard-cap equipment
- [ ] "Gym is packed" one-tap regenerate — constrains to DBs + bodyweight for remaining session
- [ ] Bodyweight-only one-tap "stuck in my room" mode — today requires multi-step toggles
- [ ] Add explicit 20-min and 25-min "Between classes" duration presets

#### Dining Hall / Cheap Food DB
- [ ] **Zero Sodexo / Aramark / Compass / Chartwells coverage** — grep returns zero hits for any of 4 major US university food service providers. These vendors publish daily per-campus menus (Sodexo's "Bite", Aramark's "Nutrislice", Compass's "Dine On Campus"). Integration owns every student on a meal plan
- [ ] VERIFY college-staple coverage: ramen IS in DB (`1890_add_generic_food_overrides.sql:77-80` + `1750_overrides_KR_south_korea.sql`) but could not find Kraft Mac & Cheese (blue box), Hot Pockets, Pop-Tarts, Cheez-Its, Easy Mac, Velveeta Shells, Hamburger Helper. Add "Dorm essentials" category (50 cheapest US grocery SKUs)
- [ ] "Protein on a Budget" curated card (chicken thighs, eggs, whey, tuna, cottage cheese) with $/g protein — zero AI, curated list of ~40 foods

#### Viral Loops & Referrals
- [ ] **REFERRAL REWARDS ARE MERCH, NOT SUBSCRIPTION MONTHS.** Verified at `referral_summary.dart:95-102` + migration `1932_referrals_and_merch_toggle.sql:11-14`: 3 refs = sticker pack, 10 = shaker, 25 = t-shirt, 50 = hoodie, 100 = full kit. **Single highest-leverage change in this entire doc: convert to free-month credit** (1 ref = 1 mo, 3 = 3 mo, 10 = 1 year, 25 = lifetime). Dropbox 2008 playbook. Shaker bottles don't solve his actual problem.
- [ ] **Two-sided referral** — "me and my roommate both get Pro free for a month" vs. current one-sided merch tier. Text-shareable, zero friction, fits IG story
- [ ] Add `Squad` / `Group` / `Crew` entity for 4-person dorm squads with shared streak (BeReal / Strava-club mechanic)
- [ ] TikTok/IG share templates: gym-selfie + PR overlay, before/after collage, lift-of-the-day meme template

#### Churn Moments
1. **Monday week 3 — free tier quota exhausted** — churn; free users should NEVER hit paywall on generating a workout
2. **Thursday 11:45am, 35 min between classes** — generated plan assumes commercial gym with cable machine dorm doesn't have; ship `dorm_gym` profile
3. **Friday trial end, $49.99 surprise** — student-verify path doesn't exist + no pause option → hard cancel, re-acquisition at full CAC

---

### Personal Trainer / B2B Track — Strategic Deferral
*Alex, 38, CSCS, 500-member garage gym + 15 remote clients, currently paying ~$575/mo (Trainerize + TrueCoach).*

#### Strategic Recommendation: **Do NOT enter B2B at this stage.**

Rationale (verified):
1. **Schema debt is enormous** — every table under `backend/api/v1/` is keyed by single `user_id`. Zero `organization_id`, `trainer_id`, `coach_user_id`, `assigned_by` columns. 6-10 engineer-weeks before a single trainer feature ships
2. **B2B support load is categorically different** — gym-owner billing disputes are 15× individual churn. No org admin tools, no audit log, no actor attribution on workout versioning
3. **Moat is weak at $49.99 consumer** — Trainerize has 10+ years of feature depth; fighting a feature war Zealova can't win until consumer has 100K+ paying users
4. **$49.99 cannot support per-seat economics** — Trainerize $5-25/mo/client, TrueCoach ~$200/mo flat. Needs separate `trainer_seats` RevenueCat offering, not exists

#### The ONLY Near-Term B2B Feature Worth Shipping
- [ ] **"Refer a client" affiliate flow** — lets trainer share affiliate link; client gets 1 month free; trainer gets $10 RevenueCat payout per conversion. Zero schema change. Captures 80% of trainer's acquisition-channel value. Defers real B2B decision by 18-24 months.

#### Everything Else — Out of Scope Until Consumer Product Reaches 100K+ Paying Users
- Multi-client data model
- Role system (`account_type` enum)
- Clients tab / invite-by-email
- Trainer-override form-check video review
- Client progress dashboard
- Trainer chat persona
- Workout-plan PDF export (stats-only PDFs exist, not workout plans)
- White-label / co-branded app
- Group workouts / class scheduling

**Files verified:** `backend/api/v1/programs.py` (admin→user assignment exists, not trainer→client), `backend/api/v1/library/branded_programs.py` (global programs), `backend/api/v1/custom_exercises.py` (per-user, not shareable), `backend/api/v1/social/` (peer follow, no trainer-client), `backend/services/form_analysis_service.py` (AI form check pipeline — extensible for trainer overlay later), `data/models/coach_persona.dart` (5 hardcoded personas, `isCustom` flag exists but trainer-as-persona not wired), `data/services/pdf_export_service.dart` (stats PDFs only)

---

## Cross-Persona Patterns

Three structural issues surfaced by multiple personas:

1. **Onboarding quiz collects data that never reaches the AI generator.** `limitations`, `cycle_phase`, `weeks_postpartum`, and medical conditions all captured but absent from `workout_generation_helpers.py` prompt context. The highest-ROI fix: audit the quiz data → Gemini pipeline and plumb every field through.

2. **Huge feature scaffolding orphaned from user flows.** `senior_workout_service.apply_senior_modifications` never invoked. `PreWorkoutCheckin` never called. `/mode-selection` route never reached. Migration 441 Wheelchair program not in RAG. Seeded apartment-friendly programs with no `dorm_gym` option to surface them. **Pattern:** build the infrastructure, forget to wire it.

3. **Consent / privacy UI contradicts actual behavior.** False claims in onboarding consent, placebo toggles in Settings, incomplete GDPR export. **See top section — these are legal compliance, not UX polish.**

---

*All items in scope. Ship incrementally as the product matures. Legal/compliance section at top is ship-before-anything-else.*
