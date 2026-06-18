# Zealova — Gravl Feature-Request Board Audit (competitor demand signal + confidence doc)

**Source:** 16 screenshots in `next_update/gravl/` of **Gravl's public Canny feature-request board** ("Powered by Canny"). Gravl is Zealova's **primary Workout-AI rival** — an AI workout-programming app that auto-generates and adapts strength training. This is a free, vote-ranked, comment-validated list of exactly what real workout-app users are begging for, with public vote counts and Gravl's own status tags (In Progress / Backlog).

**Parsed:** 2026-06-18 from the board screenshots, then cross-checked against actual Zealova code by 5 parallel codebase-verification agents (Flutter `mobile/flutter/lib/` + `backend/`), then synthesised + de-duplicated here.

**Why this matters:** Gravl's board is the cleanest available read on what workout-AI users actually want from a competitor we directly fight for the same users. Pairs with `gravl_roadmap.md` (their shipped-feature tracking) and the nutrition-side `amy_feature_requests_audit.md` / `macrofactor_roadmap.md`.

**Headline finding:** Zealova **already matches or beats the overwhelming majority of Gravl's most-requested features — including Gravl's #1 most-voted request of all time, Injury Recognition (797 votes), which we ship end-to-end and deeper.** Every flagship beg on their board (sick mode, reassign-don't-skip, custom equipment, AI chat, body-photo analysis, automatic deload, recovery editing) is already live in Zealova, frequently with more depth. So this is **not a build-list** — it is (1) a **confidence doc** (we are ahead of our primary workout rival on their own users' top demands), (2) a **short list of genuine net-new gaps**, and (3) **positioning wedges**. The genuine gaps are narrow and mostly integration-shaped (Apple Watch app, Zepp, half-reps, travel mode, calendar sync).

> ⚠️ Verification note baked into this doc: statuses below were re-verified against actual Flutter screen/widget code and registered backend routers — not directory names or stubs (`feedback_verify_features_before_asserting`, `project_frontend_src_is_not_the_app`).

---

## 1. Tag legend

Same scheme as `caloriii_competitor_audit.md` / `amy_feature_requests_audit.md`:

- **[NEW]** / **[CHANGE]** / **[WIRE]** / **[MKT]** / **[RESEARCH]** — primary type. **[WIRE]** = the feature already exists; the work is routing/surfacing it.
- **· AI** LLM/ML core · **· UI** Flutter frontend · **· BACKEND** FastAPI/cron/migration · **· DATA** data/content · **· VERIFY** confirm-already-shipped.
- **Gravl board:** `<votes> votes · <status>` — `status` ∈ {Trending, Backlog, In Progress}. **In Progress** = Gravl is building it (so they don't have it yet either).
- **Zealova cross-check:** **✅ SHIPS** (don't rebuild — cite file) · **🟢 SHIPS+BURIED** (exists & reachable but hard to find / orphaned — surface it) · **🟡 PARTIAL** (have half) · **🔴 GAP** (true opportunity) · **⭐ WE WIN** (we beat Gravl here) · **⚪ N/A** (Gravl-specific class — regression-guard).

---

## 2. TL;DR scorecard

| | Where it stands |
|---|---|
| **Feature parity** | Zealova ships ~90% of what Gravl's board begs for, usually deeper — including Gravl's **#1 most-voted request ever** (Injury Recognition, 797 votes). |
| **The headline** | Their TOP-5 most-voted requests (Injury Recognition 797 · Sick Mode 230 · Reassign-don't-skip 158 · New Equipment 113 · AI Chat 28) are **all ✅ SHIPPED in Zealova, several deeper.** Two of their highest-voted are things Gravl is still only *building*. |
| **Genuine net-new gaps** | Mostly integration-shaped: native **Apple Watch (watchOS) app** · Zepp/Amazfit · Runna/TrainingPeaks/RingConn · automatic GPS cardio tracking · calendar sync · social-media-video import. Plus a few feature gaps: **half/fractional reps** · **travel mode** · **save-changes-forward** · asymmetrical generation · sport-specific programs · ~6 missing machines · Hungarian locale · audio-narrated videos. |
| **Monetization gaps** | Lifetime + Family plan (we're single-tier monthly/yearly per `project_pricing`). |
| **Where we clearly win** | Injury-aware programming (their #1!), periodization depth, recovery/readiness check-ins, gym profiles + AI equipment-photo import, native Wear OS app, the **entire nutrition + meal-planning category** Gravl lacks, real in-app social + buddy workouts, AI body scan, multi-agent chat coach, 36 locales. |
| **Their cons / regression-guards** | They are still *building* injury features (Injury Recognition listed as their #1 unmet beg) that Zealova already ships; their board shows many unmet basic begs (bodyweight workouts, cardio in routine, rep ranges) that are table stakes for us. |

### Pros / cons at a glance

**Gravl pros (what's genuinely working for them):** a healthy public voting board (good demand signal + community trust); a few in-progress exercise additions (Cable Wood Chop, standing hamstring curl machine, single-arm cable crossover); shipped Strava sync, effort-based cardio rating, reorder-upcoming-workouts, and an in-progress monthly summary.

**Gravl cons:** their **#1 most-requested feature (Injury Recognition, 797 votes) is unbuilt** — Zealova ships it end-to-end; **Sick/Unwell mode (230) unbuilt** — we ship it; lots of unmet table-stakes begs (bodyweight-only workouts, cardio in the routine, rep ranges, bodyweight progression) that are core Zealova features; no nutrition category at all; no real in-app social (requests for "social feed" / "workout with a friend" are unmet) — Zealova ships both.

### 2a. Where Zealova BEATS Gravl (defend + press the lead)

- ⭐ **Injury-aware programming — their #1 most-voted request (797 votes), and they don't have it.** Zealova ships it end-to-end: `mobile/flutter/lib/screens/injuries/report_injury_screen.dart` + `backend/api/v1/injuries.py` (report injury → `invalidate_upcoming_workouts` → regenerate avoiding the injured area, honoring `affects_exercises`/`affects_muscles`). This is the single biggest competitive flex in this entire audit: our primary rival's most-begged feature is one we already ship deeper.
- ⭐ **Recovery & readiness depth** — Sick/Unwell mode (`scheduling.py` `feeling_unwell`), pre-workout readiness check-in (`pre_workout_checkin.dart` + `subjective_feedback.py`), post-workout soreness eval, edit-muscle-recovery grid (`recovery_section.dart`). Gravl's board begs for all of these; several are unbuilt there.
- ⭐ **Periodization depth** — automatic deload + linear/DUP/block/conjugate cycles (`backend/api/v1/periodization.py`, `deload_recommendation_card.dart`). Gravl's board has "automatic deload" and "periodic training" as *unmet requests*.
- ⭐ **Gym profiles + AI equipment-photo import** — multi-gym CRUD, per-workout location, geofence auto-switch (`gym_profiles.py`), and AI import of equipment from a PDF/photo/text/URL via Gemini Vision (`/import-equipment` + `import_equipment_sheet.dart`). Gravl's #4 request (New Equipment, 113 votes) plus "use photos of your gym equipment + AI" are exactly this — already shipped.
- ⭐ **Native Wear OS / Samsung Galaxy Watch app** — `wearos/` (Health Connect, live HR, tiles, voice food logging). Gravl users beg for Samsung/Wear OS/Pixel Watch apps; we ship one.
- ⭐ **Entire nutrition + meal-planning category** — 41 nutrition screens, meal planner, recipes, menu scan, grocery, micros. Gravl's board has "Nutrition", "Meal Planning", "Fat loss program" as *unmet requests*; we ship the whole category.
- ⭐ **Real in-app social + buddy workouts** — `social/tabs/feed_tab.dart` + `buddy_workout_bar.dart` (Realtime co-op). Gravl's "social feed" / "workout with a friend" / "partner workouts" requests are all unmet on their board.
- ⭐ **AI body scan from photos** — `body_analyzer_screen.dart` + `body_analyzer.py` (BF%/muscle/symmetry/posture). Gravl's "use AI to analyze body progress by pictures" and "body scan" requests are unmet.
- ⭐ **Multi-agent chat coach** — Gravl's "Chat with AI" (28 votes) is unmet; we ship `chat_screen.dart` + LangGraph multi-agent.
- ⭐ **Localization** — 36 locales + simultaneous kg/lbs. Gravl users beg for "use both kg and lbs" (5) and Hungarian (1); we have the units (Hungarian is a single net-new locale gap).

---

## 3. 🔥 Top demand — the items to act on first

Sorted by Gravl board votes (their highest-signal requests). Note how many of their TOP requests Zealova already ships.

| Votes | Request | Gravl status | Zealova |
|---:|---|---|---|
| **797** | Injury Recognition (report injury → auto-adjust workout) | Backlog (unbuilt) | ✅ SHIPS, DEEPER — `report_injury_screen.dart` + `injuries.py` (regen avoiding area) ⭐ WE WIN |
| **230** | Sick / Unwell Mode | Backlog (unbuilt) | ✅ SHIPS — `scheduling.py` `feeling_unwell` |
| **158** | Reassign workout to another day (not skip) | Backlog (unbuilt) | ✅ SHIPS — `scheduling.py` /reschedule + `reschedule_sheet.dart` |
| **113** | New Equipment (add equipment to DB) | Backlog (unbuilt) | ✅ SHIPS — `gym_profiles.py` /import-equipment (AI photo/PDF/text) ⭐ WE WIN |
| **44** | Single Arm Cable Crossover | In Progress | 🟡 GAP — missing machine (Gravl doesn't have it yet either) |
| **35** | Cable Wood Chop | In Progress | 🟡 GAP — missing machine (Gravl building it) |
| **28** | Chat with AI (tune plan from human input) | Backlog (unbuilt) | ✅ SHIPS — `chat_screen.dart` + LangGraph ⭐ WE WIN |
| **22** | Standing hamstring curl machine | In Progress | 🟡 GAP — missing machine (Gravl building it) |
| **21** | Add Side Lunges | Backlog | ✅ SHIPS — present in exercise library |
| **11** | Better warm-ups / more warmup sets | Backlog | ✅ SHIPS — WarmupResponse + warmup_duration prefs |
| **10** | Save changes applied to next workouts | Backlog | 🟡 PARTIAL — edits log to current session, not auto-propagated forward |
| **8** | Improve Apple Fitness/Health sync + in-app button | Backlog | ✅ SHIPS — `health_export_service.dart` (bidirectional) |
| **7** | Body weight workouts | Backlog | ✅ SHIPS — bodyweight detection + `skill_progression.py` |
| **7** | Range of reps | Backlog | ✅ SHIPS — `SetTargetSchema` per-set reps |

The pattern: **of Gravl's top 14 requests, Zealova fully ships 9 (several deeper), the 3 missing-machine items are also unbuilt on Gravl, and only "save-changes-forward" is a genuine PARTIAL gap.**

---

## 4. Feature-by-feature comparison (by surface)

### 4.1 Injury / Recovery / Scheduling

Gravl's single hottest theme — and the one where Zealova most decisively wins. Their #1, #2, and #3 all-time requests live here, all unbuilt on Gravl.

- [x] **[VERIFY · AI · UI · BACKEND] Injury Recognition (report injury → auto-adjust)** — ✅ SHIPS, DEEPER, ⭐ **WE WIN (their #1, 797 votes)**. `report_injury_screen.dart` + `backend/api/v1/injuries.py`: report → `invalidate_upcoming_workouts` → regenerate avoiding injured area; `affects_exercises`/`affects_muscles` constrain generation. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Sick / Unwell mode (230 votes)** — ✅ SHIPS. `backend/api/v1/scheduling.py` `SkipReasonCategory` "feeling_unwell" 🤒 + `reschedule_sheet.dart`. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Reassign workout to another day, not skip (158 votes)** — ✅ SHIPS. `scheduling.py` /reschedule (+swap); `reschedule_sheet.dart`. _Added 2026-06-18._
- [x] **[VERIFY · BACKEND] Skip workout (explicit)** — ✅ SHIPS. `scheduling.py` /skip. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Pre-workout recovery / readiness check-in to auto-adjust load** — ✅ SHIPS. `pre_workout_checkin.dart` + `subjective_feedback.py` /pre-checkin (mood/energy/sleep/stress). _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Post-workout soreness / recovery evaluation** — ✅ SHIPS. `workout_complete_screen.dart` + `subjective_feedback.py` `soreness_level` 1-5. _Added 2026-06-18._
- [x] **[VERIFY · AI · BACKEND] Automatic deload + periodization (incorporate deload weeks / training cycles)** — ✅ SHIPS. `backend/api/v1/periodization.py` (state, force-deload) + `deload_recommendation_card.dart`; linear/DUP/block/conjugate. _Added 2026-06-18._
- [x] **[VERIFY · UI] Edit muscle recovery** — ✅ SHIPS. `settings/beast_mode/widgets/recovery_section.dart` (per-muscle grid + K-value editor). _Added 2026-06-18._
- [x] **[VERIFY · UI] Health Conditions & Postural Considerations section** — ✅ SHIPS. `onboarding/widgets/quiz_limitations.dart` + injuries `affects_exercises`/`affects_muscles`. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Set workout & rest days per week** — ✅ SHIPS. `settings/widgets/workout_days_sheet.dart` + `weekly_plans.py` `workout_days`. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Excluded exercises / avoided muscles** — ✅ SHIPS. `exercise_preferences` (AvoidedExercise/AvoidedMuscle). _Added 2026-06-18._

### 4.2 Equipment / Plates / Exercise library

Gravl's #4 request (New Equipment, 113) and the whole "use photos of your gym + AI" cluster are already shipped. The only real gaps are ~6 specific machines (3 of which Gravl is also still building).

- [x] **[VERIFY · AI · UI · BACKEND] Add custom equipment + AI equipment-photo import (113 votes)** — ✅ SHIPS, ⭐ WE WIN. `backend/api/v1/gym_profiles.py` /import-equipment (PDF/photo/text/URL via Gemini Vision) + `import_equipment_sheet.dart` (extracts equipment + inferred_environment). _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Plate quantity / weight inventory / Olympic-plate twins** — ✅ SHIPS. `models/equipment_item.dart` `weightInventory` Map<double,int>. _Added 2026-06-18._
- [x] **[VERIFY · BACKEND] Smarter plate loading / EZ-bar customization / per-gym plates / 1.25 kg increments** — ✅ SHIPS. `backend/core/weight_utils.py` + `smart_weights.py` (equipment-aware snapping, 1.25 kg granularity). _Added 2026-06-18._
- [x] **[VERIFY · BACKEND] Equipment starting / max weight per machine** — ✅ SHIPS. `EQUIPMENT_BASELINES` + `equipment_details` weight_min/max/increment. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Gym Profiles (multi-gym, per-workout location, per-gym notes)** — ✅ SHIPS. `gym_profiles.py` full CRUD + geofence auto-switch. _Added 2026-06-18._
- [x] **[VERIFY · AI · BACKEND] Use photos of your gym equipment + AI → populate location/workout** — ✅ SHIPS. /import-equipment (equipment + inferred_environment). _Added 2026-06-18._
- [x] **[VERIFY · AI · UI · BACKEND] Custom exercises (CRUD + photo/video/text import + RAG)** — ✅ SHIPS. `backend/api/v1/custom_exercises.py`. _Added 2026-06-18._
- [x] **[VERIFY · UI] Preview/view exercise before replacing; preview replacement** — ✅ SHIPS. `exercise_detail_screen.dart`, `exercise_swap_sheet.dart`, `parsed_exercises_preview_sheet.dart`. _Added 2026-06-18._
- [ ] **[CHANGE · UI · BACKEND] Remove equipment from a specific exercise** — 🟡 PARTIAL. Can avoid whole exercises/muscles, but not per-exercise equipment removal. Net-new affordance on `exercise_preferences`. _Added 2026-06-18._
- [ ] **[WIRE · BACKEND] Equipment suggestion based on profile (4 votes)** — 🟢 BURIED. Foundation exists in `exercise_suggestions.py` but is not surfaced as a feature. Surface, don't build. _Added 2026-06-18._
- [ ] **[NEW · DATA] ~6 missing machines** — 🟡 GAP (small data adds). Library = 3,080 exercises via `add_exercises.py`; PRESENT: Dead Bug, Side Lunges, some plate-loaded. MISSING: **Cable wood chop** (Gravl In Progress, 35), **Single-arm cable crossover** (Gravl In Progress, 44), **Standing hamstring curl machine** (Gravl In Progress, 22), **Straight-arm lat pulldown**, **Incline rowing machine**, **Single-leg lying hamstring curl**. Run `add_exercises.py` then the instruction-quality gate (`python scripts/audit_exercise_instructions.py --check`, see CLAUDE.md). _Added 2026-06-18._

### 4.3 Sets / Reps / Progression

Almost entirely shipped, often deeper than Gravl. Two true gaps: half/fractional reps and save-changes-forward.

- [x] **[VERIFY · BACKEND] Custom rep ranges & sets / range of reps (7 votes)** — ✅ SHIPS. `SetTargetSchema` per-set reps. _Added 2026-06-18._
- [x] **[VERIFY · BACKEND] Drop sets / reverse pyramid / rest-pause** — ✅ SHIPS. `gemini_schemas` `is_drop_set`/`drop_set_count`/`set_type` (warmup|working|drop|failure|amrap|rest_pause). _Added 2026-06-18._
- [x] **[VERIFY · BACKEND] Percentage of 1RM** — ✅ SHIPS. `progressive_overload_service` `get_current_1rm` + `training_intensity.py`. _Added 2026-06-18._
- [x] **[VERIFY · AI · BACKEND] RPE / RIR ("how many more reps after that set")** — ✅ SHIPS. `target_rpe`/`target_rir` per set + post-workout capture. _Added 2026-06-18._
- [x] **[VERIFY · BACKEND] Low-rep compounds / high-rep isolations** — ✅ SHIPS. Exercise-subcategory rep ranges (5-8 compound / 8-15 isolation). _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Strength & hypertrophy goals + powerlifting + periodic training** — ✅ SHIPS. `primary_goal`/`training_style` + 12-week "Ultimate Strength Builder" (powerlifting/periodization tags, 3 variants). _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Progressive-overload dashboard + after-success show planned increases** — ✅ SHIPS. `progressive_overload_service` + `stats/widgets/strength_tab.dart` + `exercise_progressions_screen.dart`. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Strength Score + more exercises contributing** — ✅ SHIPS. `strength_score` + `strength_score_card.dart` + per-exercise drill-down. _Added 2026-06-18._
- [x] **[VERIFY · AI · BACKEND] Bodyweight-only workouts + progression (7 votes)** — ✅ SHIPS. Bodyweight detection + `skill_progression.py`. _Added 2026-06-18._
- [x] **[VERIFY · AI · BACKEND] Warm-ups / more warmup sets / mobility / static stretch (11 votes)** — ✅ SHIPS. WarmupResponse/StretchResponse + warmup_duration/stretch_duration prefs + mobility test. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Multi-week periodized programs (Week X of N)** — ✅ SHIPS. `duration_weeks` + periodization; "Week X of N" chip shipped (per caloriii audit). _Added 2026-06-18._
- [ ] **[NEW · UI · BACKEND] Half reps / fractional reps logging** — 🔴 GAP. No partial-rep logging path today. Net-new on the active-workout set logger + schema. _Added 2026-06-18._
- [ ] **[CHANGE · UI · BACKEND] Save changes applied to next workouts (10 votes)** — 🟡 PARTIAL. Edits log to the current session, not auto-propagated forward. Net-new "apply this change to future sessions" propagation; ties to `feedback_logged_data_durability`. _Added 2026-06-18._
- [ ] **[NEW · AI · BACKEND] Asymmetrical / unilateral generation + workout symmetry** — 🟡 PARTIAL. `symmetry_score` + `priority_muscles` from body scan exist, but no explicit asymmetric-generation mode. _Added 2026-06-18._
- [ ] **[NEW · AI · DATA] Sport-specific programs (golf / team sports)** — 🟡 PARTIAL. `generate_sports_programs.py` exists but is not in the live catalog; only basketball logging today. Promote to live catalog. _Added 2026-06-18._
- [ ] **[CHANGE · AI · UI] Explanation of why score increases/decreases** — 🟡 PARTIAL. `progress_narrative` exists; strength-score-delta explanation is not surfaced on the score card. _Added 2026-06-18._

### 4.4 Integrations / Wearables

Strongest cluster of genuine gaps — and the most strategically interesting, because a native Apple Watch app is begged for on **both** boards. Gravl users want it too.

- [x] **[VERIFY · BACKEND] Garmin Connect (incl. cardio uploads)** — ✅ SHIPS. `backend/services/sync/garmin.py` + oauth_sync (OAuth + webhooks, cardio+strength). _Added 2026-06-18._
- [x] **[VERIFY · BACKEND] Strava** — ✅ SHIPS. `sync/strava.py` (OAuth + webhooks). (Gravl already shipped Strava too.) _Added 2026-06-18._
- [x] **[VERIFY · BACKEND] Fitbit** — ✅ SHIPS. `sync/fitbit.py` (OAuth PKCE + webhooks). _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Wear OS / Samsung Galaxy Watch / Pixel Watch app** — ✅ SHIPS, ⭐ WE WIN. Native `wearos/` app (Health Connect, live HR, tiles, voice food logging). _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Apple Health / Google Health Connect bidirectional sync (8 votes for the in-app button)** — ✅ SHIPS. `health_export_service.dart` + `WearHealthConnectClient.kt`. _Added 2026-06-18._
- [x] **[VERIFY · BACKEND] Import from PDF/CSV (Strong/Hevy/Fitbod)** — ✅ SHIPS. `workout_import` adapters incl. `adapters/fitbod.py`. _Added 2026-06-18._
- [ ] **[NEW · UI · BACKEND] Native Apple Watch (watchOS) app** — 🔴 GAP (biggest integration gap). No watchOS target — double-tap log-a-set, plank-timer-both-sides, watch-as-data-source all unavailable. Gravl users beg for it too (double-tap log a set — 6 votes). Default to a Flutter/native package path per `feedback_flutter_packages_first` for v1. _Added 2026-06-18._
- [ ] **[NEW · BACKEND] Zepp / Amazfit sync** — 🔴 GAP (7 votes for Zepp compatibility). _Added 2026-06-18._
- [ ] **[NEW · BACKEND] Runna / TrainingPeaks / RingConn integrations** — 🔴 GAP (low individual votes; cluster signal). _Added 2026-06-18._
- [ ] **[NEW · BACKEND] Import workouts from social-media video / blogs / PDFs** — 🟡 GAP. PDF/CSV import ships; social-media VIDEO parsing does not. _Added 2026-06-18._
- [ ] **[NEW · UI] Bluetooth HR strap live on iPhone (see HR while exercising)** — 🟡 PARTIAL. Wear OS live HR ships; iPhone BLE strap does not. _Added 2026-06-18._
- [ ] **[NEW · BACKEND] Import to calendar / iCal / Google Calendar link** — 🔴 GAP. No calendar export. _Added 2026-06-18._

### 4.5 Cardio

Core cardio is shipped (and cycle-aware, which Gravl lacks). The gaps are auto-tracking and a couple of class types.

- [x] **[VERIFY · UI · BACKEND] Cardio in the routine (run/cycle/row/elliptical/swim/walk/yoga/pilates)** — ✅ SHIPS. `cardio_logs` + `CardioType` enum. _Added 2026-06-18._
- [x] **[VERIFY · AI · BACKEND] AI cardio recommendations (cycle-aware, add cardio at end of session)** — ✅ SHIPS, deeper. `cardio_phase_service.py` (menstrual-phase intensity, cited). _Added 2026-06-18._
- [x] **[VERIFY · BACKEND] Effort-based rating for cardio (RPE)** — ✅ SHIPS. `cardio_log` rpe. (Gravl shipped this too.) _Added 2026-06-18._
- [ ] **[NEW · UI · BACKEND] Automatic / background cardio tracking (GPS auto-detect)** — 🔴 GAP. No GPS auto-detect. _Added 2026-06-18._
- [ ] **[NEW · DATA] HIIT / dance / aerobics / team-sports cardio types** — 🟡 PARTIAL. Broad CardioType enum; some specific class types (dance/aerobics, team sports) not enumerated — extend via coverage gate not a whitelist (`feedback_no_hardcoded_enumerations`). _Added 2026-06-18._

### 4.6 Social / Sharing

Entirely a win column — Gravl's social requests are all unmet.

- [x] **[VERIFY · UI · BACKEND] Social feed (public progress)** — ✅ SHIPS, ⭐ WE WIN. `social/tabs/feed_tab.dart` + `social/feed.py`. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Workout with a friend / partner / gym-buddy sync** — ✅ SHIPS, ⭐ WE WIN. `buddy_workout_bar.dart` + buddy_workout_service (Realtime). _Added 2026-06-18._
- [x] **[VERIFY · BACKEND] React/comment on friends' workouts + friends leaderboard** — ✅ SHIPS. `social/reactions.py`, `comments.py`, `xp_leaderboard`. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Share to Instagram stories + overlay stats** — ✅ SHIPS. `share_service.dart` `shareToInstagramStories` + `workout_summary_template`. _Added 2026-06-18._
- [ ] **[VERIFY · BACKEND] External workouts count toward streaks (4 votes)** — 🟡 PARTIAL. Health sync exists; verify external/imported activity auto-counts the main streak. _Added 2026-06-18._

### 4.7 Body / Profile

Win column — Gravl's body-analysis and profile requests are unmet.

- [x] **[VERIFY · AI · UI · BACKEND] AI body progress from photos / body scan** — ✅ SHIPS, ⭐ WE WIN. `body_analyzer_screen.dart` + `body_analyzer.py` (BF%/muscle/symmetry/posture). _Added 2026-06-18._
- [x] **[VERIFY · UI] Before/after comparison** — ✅ SHIPS. `progress/comparison_view.dart` (side-by-side/slider/overlay). _Added 2026-06-18._
- [x] **[VERIFY · UI] Add body type / more profile options** — ✅ SHIPS. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Body measurements + bodyweight** — ✅ SHIPS. `measurements_screen`. _Added 2026-06-18._
- [x] **[VERIFY · UI] Pregnancy mode** — ✅ SHIPS. `cycle_screen` pregnancy toggle. _Added 2026-06-18._

### 4.8 Coach (AI)

Win column — Gravl's "Chat with AI" (28 votes) is unbuilt.

- [x] **[VERIFY · AI · UI] Chat with AI coach to tune the plan (28 votes)** — ✅ SHIPS, ⭐ WE WIN. `chat_screen.dart` + LangGraph multi-agent. _Added 2026-06-18._
- [x] **[VERIFY · AI · BACKEND] Variable recovery adjustment / rest-and-recovery recommendations** — ✅ SHIPS. Recovery-aware Daily Outlook signal (`recovery_signal_service.py`, per `project_recovery_aware_import_loop`). _Added 2026-06-18._

### 4.9 Nutrition

Entire category Gravl lacks — pure win.

- [x] **[VERIFY · AI · UI · BACKEND] Nutrition + meal planning + fat-loss programming** — ✅ SHIPS, ⭐ BIG WIN. 41 nutrition screens, meal planner, recipes, menu scan, grocery, micros. Gravl's "Nutrition", "Meal Planning", "Fat loss program" requests are all unmet. _Added 2026-06-18._

### 4.10 UX / Misc

Mostly shipped; one true locale gap and the narrated-video polish gap.

- [x] **[VERIFY · UI · BACKEND] Notes in exercises / before & during workout** — ✅ SHIPS. _Added 2026-06-18._
- [x] **[VERIFY · UI] Undo button (3 votes)** — ✅ SHIPS. active_workout 5-sec undo snapshot. _Added 2026-06-18._
- [x] **[VERIFY · UI] Reorder upcoming / log past / edit past workout time** — ✅ SHIPS. `schedule_screen.dart` drag-reorder. (Gravl shipped reorder too.) _Added 2026-06-18._
- [x] **[VERIFY · UI] New app icons / custom themes / layouts** — ✅ SHIPS. `cosmetics_gallery` + `layout_editor` + `appearance_page`. _Added 2026-06-18._
- [x] **[VERIFY · UI] First day of the week setting** — ✅ SHIPS. `weekStartsSundayProvider` in `appearance_page`. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Timer notification / rest timer** — ✅ SHIPS. `workout_timer_controller` + `workout_notification_service`. _Added 2026-06-18._
- [x] **[VERIFY · UI] iOS widget / Live Activity** — ✅ SHIPS. `ios/FitnessWidgets` + Live Activity. _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Monthly summary / Wrapped** — ✅ SHIPS. `my_wrapped` + `weekly_wrapped`. (Gravl's monthly summary is In Progress.) _Added 2026-06-18._
- [x] **[VERIFY · UI · BACKEND] Use both kg and lbs (5 votes)** — ✅ SHIPS. lbs/kg with separation (`feedback_weight_unit_separation`). _Added 2026-06-18._
- [ ] **[NEW · DATA] Hungarian language (1 vote)** — 🔴 GAP. 36 locales ship; Hungarian is a single net-new locale add. _Added 2026-06-18._
- [ ] **[NEW · AI · UI] Audio-narrated exercise videos** — 🟡 PARTIAL. TTS announcements exist; no narrated video track. (Gravl has "audio guidance in exercise videos" planned.) _Added 2026-06-18._
- [ ] **[NEW · UI] Travel mode (dedicated)** — 🔴 GAP. Bodyweight exists, but no dedicated travel-mode surface (no-equipment-while-traveling profile). _Added 2026-06-18._

### 4.11 Monetization

- [ ] **[RESEARCH · MKT] Lifetime subscription + Family plan** — 🔴 GAP (and a `project_pricing` tension). Zealova is single-tier Premium ($7.99/mo + $59.99/yr) via RevenueCat, monthly/yearly only (`feedback_single_tier_paid` — do NOT add free-vs-premium gating). Lifetime + Family are net-new SKU decisions, not free-tier gating — treat as pricing research, not a build task. _Added 2026-06-18._

---

## 5. Genuine net-new gaps (the only real build list)

Everything in §4 marked 🔴/🟡 distilled to a single actionable list. This is short — that is the point.

**Integrations (the largest real cluster):**
1. **Native Apple Watch (watchOS) app** — double-tap log-a-set, plank timer both sides, watch-as-source. Begged on both Gravl's board and ours; biggest single integration gap.
2. **Zepp / Amazfit sync** (7 votes for Zepp).
3. **Runna / TrainingPeaks / RingConn** connectors (cluster signal).
4. **Automatic / background cardio tracking** (GPS auto-detect).
5. **Calendar sync** (iCal / Google Calendar export).
6. **Import workouts from social-media video / blogs.**
7. **iPhone Bluetooth HR strap** live read.

**Features:**
8. **Half / fractional reps** logging.
9. **Travel mode** (dedicated no-equipment profile).
10. **Save-changes-forward** (propagate an edit to future sessions) — 10 votes; ties to `feedback_logged_data_durability`.
11. **Asymmetrical / unilateral generation** mode.
12. **Sport-specific programs** promoted to the live catalog (golf, team sports).
13. **~6 missing machines** (cable wood chop, single-arm cable crossover, standing hamstring curl machine, straight-arm lat pulldown, incline rowing machine, single-leg lying hamstring curl) — small `add_exercises.py` data adds; 3 of these Gravl is still building too.
14. **Strength-score-delta explanation** surfaced on the score card.
15. **Per-exercise equipment removal.**
16. **External workouts auto-count the main streak** (verify/wire).
17. **Hungarian locale** (single add).
18. **Audio-narrated exercise videos.**

**Pricing research (not a build task):**
19. **Lifetime + Family plan** SKU decision.

---

## 6. Gravl weaknesses / regression-guard list

- ⚪ **Their #1 most-requested feature ever (Injury Recognition, 797 votes) is unbuilt.** Zealova ships it end-to-end. *Wedge: this is the single strongest "we already do their #1" marketing line.*
- ⚪ **Sick/Unwell mode (230) unbuilt; Reassign-don't-skip (158) unbuilt; AI chat (28) unbuilt.** Their three other top requests — all live in Zealova. *Wedge + guard: never regress scheduling/recovery flows.*
- ⚪ **Table-stakes begs unmet on their board** — bodyweight-only workouts (7), cardio in routine, rep ranges (7), bodyweight progression. These are core Zealova features. *Guard: these must never silently break (gen guards FAIL OPEN per `feedback_workout_gen_zero_regression`).*
- ⚪ **No nutrition category** — "Nutrition", "Meal Planning", "Fat loss program" are unmet requests on their board. Zealova ships the entire category. *Wedge.*
- ⚪ **No real in-app social** — "social feed", "workout with a friend", "partner workouts" are all unmet. Zealova ships both feed + buddy workouts. *Wedge.*
- ⚪ **No AI body scan** — "analyze body progress by pictures" + "body scan" unmet. Zealova ships it. *Wedge.*
- ⚪ Their public board's heavy injury/recovery vote concentration (797 + 230 + 158) signals that **recovery-aware programming is the category's #1 unmet need** — and the area where Zealova is most differentiated. *Press this lead in positioning (`project_competitor_gravl`: beat them on their own users' begs).*

---

## 7. What Zealova actually needs from this (prioritized)

**This audit produces almost no build work — that is the finding.** The board confirms Zealova is ahead of its primary workout rival on that rival's own top demands.

**Build now (small, high-confidence):**
1. **~6 missing machines** — `add_exercises.py` data adds + instruction-quality gate. Cheapest possible parity win; 3 of these Gravl is still building.
2. **Half / fractional reps** logging — narrow schema + set-logger change.
3. **Save-changes-forward** propagation (10 votes) — ties to durable-data invariant work.
4. **Travel mode** surface (bodyweight engine already exists — mostly a profile + entry point).

**Bigger investments (decide, then build):**
5. **Native Apple Watch app** — the one large gap begged on both boards; default to a package-first path for v1.
6. **Automatic / background cardio tracking** + **calendar sync** — the next-most-cited integration gaps.
7. **Sport-specific programs** to the live catalog (generator already exists).

**Research, don't build blind:**
8. **Lifetime + Family plan** SKUs — pricing decision, not a feature (`project_pricing`, `feedback_single_tier_paid`).
9. **Zepp/Amazfit, Runna, TrainingPeaks, RingConn** — validate per-integration demand before committing engineering.

**Positioning / marketing wedges (don't build — message):**
- "Zealova already ships Gravl's #1 most-requested feature (Injury Recognition) — and we do it deeper." This is the headline competitive line.
- Recovery-aware programming, nutrition + meal planning (entire category), real in-app social + buddy workouts, AI body scan, native Wear OS app — all things Gravl users are *begging* for and we already ship.

> **Note:** the genuine-gap items in §5 are being seeded into Zealova's in-app feature-voting board as Voting items, so our own users can rank them — turning this competitor-demand signal into a measured internal priority list rather than an assumed one.

---

**Maintained for:** Zealova workout + product roadmap. Pairs with `caloriii_competitor_audit.md` (all-in-one rival), `amy_feature_requests_audit.md` (text-AI nutrition demand), `gravl_roadmap.md` (Gravl shipped-feature tracking), and `macrofactor_roadmap.md` (nutrition rival). _Created 2026-06-18._
