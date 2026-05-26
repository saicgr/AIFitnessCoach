# Zealova — Unified Immediate Tasks

**Merged + reconciled with deep codebase audit on 2026-05-26.** Many items previously listed as TODO turned out to be shipped — moved out. Partials reframed with the actual remaining scope.

- `next_update/youtube_audit_files/2.txt` — 8 Fitbit Air + Google Health Coach reviewer transcripts.
- `next_update/youtube_audit_files/1.txt` — Sherman Share + Dave Does Fitness + Bevel 3.0 + Google Premium ad + RJ Fitbit Air.
- `next_update/fitbit_air_response.md` — strategic positioning + P0/P1/P2 sequence (deleted post-merge).

**Scope:** Software/AI only. Hardware excluded.

**Tag legend — primary type + surface + AI flag:**

- **[URGENT]** — **must ship/verify before first Apple App Store submission**. Top of file.
- **[NEW]** / **[CHANGE]** / **[MKT]** / **[RESEARCH]** — primary type
- **· AI** — LLM/ML/Gemini-driven behaviour is core
- **· UI** — frontend-only (Flutter) surface
- **· BACKEND** — backend-only (FastAPI / cron / migration); the change rides an existing UI surface
- **· UI+BACKEND** — both halves required
- **· DATA** — data audit / DB migration / content-only
- **· DOCS** — markdown/docs/marketing-copy only
- **· VERIFY** — confirm-already-shipped task (no new code expected; just check it works end-to-end on a fresh install)
- **· OPS** — operational / App Store Connect / config task (no app code)

When a task is BACKEND-only, an inline `*(surface: existing X)*` note names which existing UI carries the result so it's clear users still see it.

---

## URGENT — From YouTube analysis (must ship before first Apple submission)

General App Store submission checklist lives in **`next_update/apple_submission_urgent.md`** (account deletion, Sign in with Apple, privacy/ToS URLs, Info.plist strings, Restore Purchases, screenshots, App Privacy questionnaire, crash + completeness checks, etc.). The items below are the YouTube-audit-derived subset — each one closes a failure mode that reviewers (DC Rainmaker, Quantified Scientist, Sherman Share) explicitly called out in Google Health Coach. Shipping these means a first-day Zealova user won't hit the same embarrassing AI behaviour Google got slammed for.

### AI safety + first-impression quality

These items were originally in the broader TODO list but are pulled here as URGENT because each one closes a failure mode that reviewers (DC Rainmaker, Quantified Scientist, Sherman Share) explicitly called out in Google Health Coach. Shipping these means a first-day user won't hit the same embarrassing AI behaviour competitors got slammed for.

- [ ] **[URGENT · AI · BACKEND] Sustainability guardrail on extreme goal requests** *(surface: existing AI Coach chat reply)* — when user asks "lose 30 lbs in a month" or "200 lb in a year," coach must redirect to sustainable target with a "here's why" one-liner. Apple guideline 1.4.1 risk: AI that compliantly generates a crash-diet plan is a rejection vector for health apps. Add to coach system prompt. _Promoted to URGENT 2026-05-26._
- [ ] **[URGENT · AI · BACKEND] Hard guardrail: never auto-switch units (kg ↔ lb)** *(surface: existing AI Coach chat reply)* — Google Coach silently logged 121 lb bicep curls because it auto-converted from kg (reviewer caught it). Zealova must never change units without explicit user confirmation. Failure = wrong-data-in-user's-log on Day 1 = 1-star review fodder. _Promoted to URGENT 2026-05-26._
- [ ] **[URGENT · AI · BACKEND] Unit confirmation echo on every set-logging chat turn** *(surface: existing chat reply)* — chat agent always echoes "I logged 3 sets of squats at 100 **lb**" with unit explicit. Same risk class as the kg/lb guardrail above. Verifies user intent before persisting any logged set from voice / chat. _Promoted to URGENT 2026-05-26._
- [ ] **[URGENT · AI · BACKEND] Hallucination tone-down: drop sarcasm-flagged turns after 48h** *(surface: existing chat — same UI, less recurring weirdness)* — DC Rainmaker's "queso and rosé recovery joke" got re-referenced for 10+ days in Google Coach. Coach context summarizer drops sarcasm-flagged turns after 48h so a one-off mention doesn't keep getting referenced. Prevents the most-shared "AI slop" failure mode at launch. _Promoted to URGENT 2026-05-26._
- [ ] **[URGENT · UI] Calibration-period messaging during first 7 days** — "Coach is learning you — first {N} days" banner with what's getting calibrated (resting HR, HRV, sleep pattern). Sets first-week expectations so users don't churn at Day 3 thinking the AI is dumb. Every reviewer mentioned the 7-day calibration as a pain point in Google Health — solving it upfront protects Day-1 → Day-7 retention. _Promoted to URGENT 2026-05-26._

### Pre-launch metadata + marketing positioning (from YouTube analysis)

- [ ] **[URGENT · DOCS] App Store + Play Store description + keyword updates** — add "Fitbit Air alternative" + "Google Health Coach alternative" + "Claude fitness app" + "ChatGPT fitness coach" + "MyFitnessPal AI" + "AI fitness coach" to keywords. Apple 2.3.7 (metadata accuracy): every description claim must match the actual build. Submission-blocking if mismatched. _Promoted to URGENT 2026-05-26._
- [ ] **[URGENT · UI] Plan-portability badge ("Yours forever, even after trial")** — sharpest wedge vs Fitbit per audits. If the comparison landing page + the App Store description claim "your plan is yours forever," the app must visibly show the badge on paywall + trial-end + workout cards. Apple 2.3.1 prohibits claims the build doesn't deliver. _Promoted to URGENT 2026-05-26._

---

## AI Coach — conversation, memory, multimodal

- [ ] **[NEW · AI · UI+BACKEND] Coach memory + explicit "forget" command** — chat_history persists but no structured user-facts table for semantic recall ("I have a knee injury", "I drink coffee at 3pm") across sessions. Add `user_facts` table + langgraph memory module + "forget X" / "stop reminding me" intent handler. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] Cite sources in coach answers** — Gemini grounding may return citations; surface them inline Perplexity-style in chat bubbles. No source UI exists today in `chat_message_bubble.dart`. _Added 2026-05-26._
- [ ] **[CHANGE · AI · BACKEND] Sustainability guardrail on extreme goal requests** *(surface: existing AI Coach chat reply)* — `adherence_tracking_service.py` references extreme goals but no explicit "lose 30 lbs in a month → redirect to sustainable target" prompt guardrail. Add to coach system prompt. _Added 2026-05-26._
- [ ] **[NEW · AI · BACKEND] Hard guardrail: never auto-switch units (kg ↔ lb)** *(surface: existing AI Coach chat reply)* — Zealova must never change units without explicit user confirmation. _Added 2026-05-26._
- [ ] **[NEW · BACKEND] Wire weather into coach system prompt context** *(surface: existing AI Coach chat reply)* — coach state at `coach_agent/state.py:47` pulls sleep/recovery but not weather; add a weather fetch + inject into Gemini coach prompts so reply includes "today is 30°C, drink electrolytes." _Added 2026-05-26._
- [ ] **[CHANGE · BACKEND] Use food-photo EXIF timestamp, not upload time** *(surface: existing food log entry timestamp)* — read EXIF `DateTimeOriginal` from incoming images in `vision_service.py` and let user confirm vs override. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] Specialized training-plan agent for race goals** — race context exists in `cardio_context` but no dedicated `RunPlanAgent`; add agent with running-coach domain primitives (long-run progression, taper, pace zones, fueling). **New UI:** race-anchored plan visualization in `weekly_plan_screen.dart` showing multi-week timeline + taper indicator + race-day countdown. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] Goal-anchored multi-month training plan generator** — `weekly_plans.py` generates per-week; no endpoint takes `(race_type, race_date)` → 12-16 week block structure. Add endpoint emitting multi-block periodized plan persisted across weeks. _Added 2026-05-26._
- [ ] **[CHANGE · AI · BACKEND] Mid-training goal conversation — wire plan reflow** *(surface: existing AI Coach chat)* — `custom_goal_service.generate_keywords_for_goal()` exists + `/custom_goals` update endpoints exist; missing piece is the plan-reflow trigger when goal changes mid-program. Connect goal-change event → `holistic_plan_service.regenerate_from_week()`. _Added 2026-05-26._
- [ ] **[NEW · BACKEND] Week-over-week plan progression cron** *(surface: existing weekly_plan_screen renders new week automatically; push notif when next week's plan is ready)* — no auto-continuation today; add cron creating next week's plan from rolling history + anchored race goal. _Added 2026-05-26._
- [ ] **[CHANGE · AI · BACKEND] Readiness-based plan recalibration — close the loop** *(surface: existing weekly_plan_screen + chat insight when adjustments fire)* — `progression_settings.auto_deload_enabled` exists + Hooper Index in `test_readiness_service.py`; missing piece is end-to-end "low readiness 3 days → deload upcoming week + push notification with why." _Added 2026-05-26._
- [ ] **[CHANGE · AI · BACKEND] Feedback-driven plan evolution — close the loop** *(surface: existing weekly_plan_screen + chat)* — `smart_weights.py` + `crud_completion.populate_performance_logs()` exist; missing piece is `rpe_feedback_loop` that closes RPE → next-week difficulty. _Added 2026-05-26._
- [ ] **[CHANGE · UI] Specialist-handoff cue visible in chat** — 7 langgraph agents (coach / nutrition / hydration / injury / cycle / workout / plan) route silently; surface handoff ("routing to injury specialist") as a pill animation with per-agent accent color. _Added 2026-05-26._
- [ ] **[CHANGE · UI] Add live-transcribe preview to voice mic button** — voice mic shipped (`voice_message_widget.dart`); add live STT preview while user speaks. _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] Daily journaling — structured input fields** — `journal_screen.dart` aggregates workouts/meals/photos read-only; hydration log exists in nutrition models; add unified daily inputs (caffeine mg, mood 1-5, perceived energy 1-5, hydration notes) the coach reads as 7-day context. _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] Inline charts/graphs in coach replies** — when user asks "how did I do this week," coach renders a chart inline in chat bubble. New `action_data` type `render_chart` with payload `{metric, range, chart_type}`; chat_screen.dart receives + renders compact chart card. _Added 2026-05-26._
- [ ] **[CHANGE · UI+BACKEND] Coach auto-share workout/meal summary card** — share tools exist (`share_tools.py`); auto-offer CTA in coach reply post-summary missing. Wire "Share this" inline action after coach summary message. _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] "Training Wheels" beginner mode for first 30 days** — flip *Beginner*. Hides advanced tiles + replaces dense weekly-target language with plain-English. Auto-graduates after 30 days. _Added 2026-05-26._
- [ ] **[NEW · AI · BACKEND] Adaptive language simplifier** *(surface: existing AI Coach chat — same UI, simpler words)* — system-prompt reads `user.session_count + workout_log_count + age` and dynamically downshifts coach vocabulary every turn. No manual toggle. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] "Mira" women's-health coach persona** — flip *Women (TTC/postpartum/perimenopause)*. Dedicated persona in `langgraph_agents/coach_agent/` with cycle-phase + relaxin-aware injury awareness + postpartum + perimenopause + PCOS context. Selectable in coach picker. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] Morning AI insight + nightly journal prompt as daily ritual** — flip *Working adult*. Two recurring touchpoints (morning push at wake-time + 30 min, nightly journal at sleep_time - 60 min); creates habit beat that doesn't depend on workouts. _Added 2026-05-26._
- [ ] **[NEW · UI] Onboarding demo of chat-driven plan edit** — flip *Fitbod migrant*. Interactive onboarding slide where user types "swap leg day" and sees Zealova actually do it. _Added 2026-05-26._

## AI extras — explainability, time-management, proactive coaching

- [ ] **[NEW · AI · UI+BACKEND] "Explain my data" coach mode** — user asks "why is my HRV down" / "what's making my sleep worse"; coach pulls actual data (last 14 days HRV + sleep + nutrition + workout + caffeine), correlates, surfaces top 2 likely factors with citations. _Added 2026-05-26._
- [ ] **[NEW · AI · BACKEND] AI rest-day determiner** *(surface: morning push + existing chat + workout card flips to "rest" state)* — based on cumulative training load + sleep + RPE trend + HRV vs baseline, coach proactively suggests today as rest with a one-line rationale; user can accept or override. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI travel / vacation auto-adapter** — when GPS detects user in new timezone / country for 2+ days, coach asks "you traveling?" and offers a travel-mode plan (bodyweight / hotel-gym / walking-focused) + adjusts notifications. **New UI:** "Travel mode active" badge on Home + travel-card variant in active plan view. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI grocery list generator from weekly meal plan** — `grocery_list` model + `grocery_list_items` table exist but no UI integration; build the Sunday push + tappable list (share-to-Notes / WhatsApp / iMessage). _Added 2026-05-26._
- [ ] **[NEW · AI · BACKEND] AI smart hydration prompts** *(surface: existing push + existing hydration tile)* — pulls today's temperature + planned workout duration + body weight to compute target oz/L; nudges at user-local 11 AM / 3 PM if intake is trailing. _Added 2026-05-26._
- [ ] **[NEW · AI · BACKEND] AI conversation starter on quiet days** *(surface: existing chat + push)* — when user hasn't opened the app in 48+ hrs AND no logged data, coach asks a real question that invites a reply, not a tap. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI smart auto-pause detection in active workout** — when phone detects zero motion for 5+ min mid-workout, prompt: "Done for now, or are you mid-set?" Avoids stale-session problem. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI menstrual-symptom predictor + auto-soften workouts** — cycle agent + cycle-phase TDEE adjustment shipped; missing piece is explicit workout-softening 2 days before predicted period start (reduce volume 15%, swap high-RPE compound for hypertrophy variant) + "softened — predicted cycle" badge on affected workout card. _Added 2026-05-26._
- [ ] **[NEW · AI · BACKEND] AI vacation mode auto-detector** *(surface: push prompt + existing vacation-mode toggle in Settings)* — no logs for 4+ days + GPS away from home for 3+ days → auto-suggest vacation mode with one-tap confirm. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI menu sort/filter** — menu scan extracts food items; add sort-by-macros (low-carb, high-protein) and filter chips on the scan result view. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI cuisine-aware meal suggestion** — recipes/meals respect user's cuisine preference (Indian, Mediterranean, Asian). Add `cuisine_preference` field to nutrition prefs + filter meal-gen + recipe library. _Added 2026-05-26._
- [ ] **[NEW · AI · UI] AI rest-timer voice cues** — TTS during rest periods ("60 seconds left, breathe deep, next set 8 reps"). _Added 2026-05-26._
- [ ] **[CHANGE · AI · BACKEND] AI proactive injury awareness — detect repeated pain pattern** *(surface: existing chat + workout card warning)* — injury history + injury agent exist; missing piece is pattern detector that flags "user logged pain at this exercise 3+ times → swap in safer variant proactively." _Added 2026-05-26._
- [ ] **[CHANGE · AI · UI+BACKEND] AI sleep-aware morning insight — surface in UI** *(backend partially shipped)* — `sleep_aware_nutrition.py` already drives TDEE adjustments from prior night's sleep; missing piece is the morning push + Home insight card surfacing "your TDEE held today because you slept 5.2 hrs." _Added 2026-05-26._

## Workouts — imported sessions, training load, derived metrics

- [ ] **[NEW · UI+BACKEND] Imported-workout confirmation loop** — equipment-import confirmation banner exists (`import_equipment_result_sheet.dart`) but workout-session imports from HealthKit/HC have no confirmation surface; add the "Did you go for a run at 7:32 PM? Confirm / Edit / Not me" banner on next foreground + per-user classifier from confirmation stream. _Added 2026-05-26._
- [ ] **[NEW · AI · BACKEND] Activity refinement learning loop** *(surface: future imported sessions auto-label correctly; no new UI)* — train per-user classifier on the confirmation stream above. _Added 2026-05-26._
- [ ] **[CHANGE · BACKEND] Adaptive weekly training-load target — wire 4-week history** *(surface: existing weekly plan card)* — `mesocycle_state` exists with phase/deload flag; missing piece is target re-derivation from rolling 4-week history. _Added 2026-05-26._
- [ ] **[NEW · BACKEND] Zealova proprietary composite training-load score** *(surface: existing trends + new Recovery/Training-Load composite tile task below)* — Fitbit TRIMP metrics tracked (`training_load_acute`, `training_load_chronic`, `training_load_acwr`); design Zealova-native composite combining elevated HR + perceived exertion + completed-session volume so we're not just surfacing Fitbit's score. _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] Concrete weekly targets in plan ("X load, Y strength sessions")** — `weekly_personal_goals` table exists; plan output JSON returns prose, not structured numbers. Wire structured numbers + progress-bar UI on Home. _Added 2026-05-26._
- [ ] **[CHANGE · UI+BACKEND] Drift-backed offline workout save queue** — workout `/complete` enqueues to a memory queue on failure (`workout_flow_mixin.dart`); upgrade memory queue → Drift queue so saves survive process death and drain on reconnect. _Added 2026-05-26._
- [ ] **[CHANGE · UI] Add live route map to in-progress workout screen** — HR chart + zone bar already render mid-workout; route map for outdoor activities is missing — add it so cyclists / runners see their track in real time. _Added 2026-05-26._
- [ ] **[NEW · UI] Strava-style workout summary shareable template** — current workout summary template is Apple Watch–style; add a Strava-aesthetic variant (route map + split splits + bold metric stack + accent gradient) + a Strava-style nutrition-day template. _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] Recovery / Training-Load composite dashboard tile** — `recovery_score7d` field exists in DB but no unified Home tile pairing it with the proprietary training-load composite. Add Home overlay above existing 4-pillar grid. _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] Biological age weekly metric** — deterministic formula from RHR + HRV + sleep + activity + BMI, Monday cron + share template. NO LLM. _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] TrainingPeaks-style PMC / CTL / ATL chart** — Chronic Training Load (42-day exp avg) + Acute (7-day) + Training Stress Balance (CTL − ATL). Currently zero matches for `ctl`/`atl`/`tsb`. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI race-pace predictor** — PMC + last 8 weeks of pace/HR + race distance → finishing time + confidence interval. Updates weekly; pushes when prediction shifts ≥3 min. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI taper plan generator** — given race date + peak weekly volume, auto-merge a 2-3 week taper into the active plan. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI race-day fueling plan generator** — distance + duration + climate + body weight → personalized carb/electrolyte schedule (60-90g carbs/hr, sodium estimate). _Added 2026-05-26._

## Sleep

- [ ] **[CHANGE · UI] Surface "sound sleep / interruptions / restlessness" sub-metric bars** — `health_service_ui.dart` already reads `SLEEP_DEEP/LIGHT/REM/AWAKE` from HealthKit/HC; missing piece is the UI rendering 3 sub-metric range bars vs normal range on the Sleep tab. _Added 2026-05-26._

## Nutrition depth

- [ ] **[NEW · UI+BACKEND] Barcode scan for food logging** — no `mobile_scanner` integration; add barcode scan as third option in food-log compose; wire to `food_nutrition_overrides` by UPC/EAN. _Added 2026-05-26._
- [ ] **[NEW · DATA · UI] Micronutrient depth + opt-in detailed micro view** — `nutrition.py:fiber_g` only field today; backfill Vitamin D, B12, magnesium, potassium, iron, omega-3 columns on `food_nutrition_overrides`; add "Detailed micros" expandable section on food log detail. _Added 2026-05-26._
- [ ] **[CHANGE · DATA] US/EU global food DB depth audit** — food_curation pipeline ingests USDA + OpenFoodFacts + INDB + CNF; row count by region unknown. Audit US + EU parity so "Trader Joe's chicken tikka masala bowl" hits a real match. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI nutrient-gap detector + meal suggester** — weekly cron analyzes 7-day food logs vs RDA per micro; when gap > 30%, coach surfaces 3 cuisine-aware meal suggestions. Depends on micros backfill above. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI weekly nutrition recap with cited cause-and-effect** — Sunday push connecting nutrition + sleep + HRV: "Your sleep was 7% worse on the 3 days you ate dinner after 9pm." Connects existing logs via langgraph state. _Added 2026-05-26._

## Home dashboard / IA

- [ ] **[NEW · UI] Long-press chart to pinpoint exact hour/minute value** — no `onLongPress` handlers on trend chart widgets today; add scrubbing with timestamp + value popover. _Added 2026-05-26._
- [ ] **[CHANGE · UI] Add explicit 6-month + 1-year range buttons to trend charts** — current is `7d / 30d / 90d / all`; add `6m` + `1y` for finer mid-range zoom. _Added 2026-05-26._

## Data sources & multi-device

- [ ] **[NEW · UI+BACKEND] Per-metric source picker + reorderable priority list** — Settings → Data Sources matrix with conflict-resolution dropdown (highest / average / most recent). _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] View-sources affordance on every metric tile** — tap any chart → "view sources" lists every app/device contributing to the displayed number. _Added 2026-05-26._
- [ ] **[NEW · BACKEND] Intelligent duplicate detection on overlapping sessions** *(surface: existing workouts list shows one row instead of two)* — when two devices log the same run within ±5 min, hide the lower-priority source's session. _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] Backfill historical health data on signup** — onboarding offer to import 3 months of Apple Health + full Health Connect history. _Added 2026-05-26._
- [ ] **[CHANGE · UI+BACKEND] Expand Apple Health write-back coverage** — `health_export_service.dart` writes workouts + active energy + distance; expand to sleep, HRV, weight, water, fasting. **New UI:** per-metric write-back toggles in Settings → Connected Apps. _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] CGM (Dexcom / Libre) integration via HealthKit + HC** — no `HKQuantityTypeIdentifierBloodGlucose` binding today; new Nutrition tab card overlaying glucose curve on meal timestamps + Coach context. _Added 2026-05-26._
- [ ] **[CHANGE · DOCS] Add Bevel / Sonar / freddy.coach / Polar MCP / Coros MCP + Fitbit Air + Google Health Coach to competitor matrix** — extend `_ZEALOVA_FACTS.md` §4. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI smart source-conflict resolver** — AI picks most reliable source on conflict + surfaces reasoning behind View Sources. Layer on top of deterministic picker. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI workout auto-categorizer for imported sessions** — infers muscle groups + likely exercises from HR pattern + duration + DOW; surfaces "Was this push day?" inline confirm. _Added 2026-05-26._

## Accessibility / persona-specific UX

- [ ] **[CHANGE · UI+BACKEND] Senior accessibility mode — extend beyond settings screen to home/onboarding flows** — `senior_fitness_screen.dart` Settings shipped (Recovery Multiplier, Joint-Friendly, Balance, Reduced Impact, Extended Warmup); missing are dedicated `senior_home_screen.dart` + `senior_onboarding_screen.dart` flows + age-aware onboarding prompt. _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] "Minimum Mode" for analog / non-tech users** — `workout_ui_mode: 'easy' | 'simple' | 'advanced'` exists in user model but no Minimum-Mode single-daily-card view. Add Settings → Display → Minimum Mode toggle. _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] Low-impact / mobility / fall-risk workout templates** — Kegel `KegelFocusArea.postpartum` + `hormonal_health.dart` exist but no chair-yoga / standing-balance / walking-interval template bank. Add `WorkoutKind.low_impact`, `WorkoutKind.mobility`, `WorkoutKind.balance` to workout-gen + curated templates. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI postpartum return-to-exercise pacer** — `KegelFocusArea.postpartum` + `HormoneGoal.perimenopauseSupport` enums exist but no programming engine. Build: birth type + weeks postpartum + diastasis answers + pelvic-floor PT clearance → week-by-week reintroduction. NO LLM safety classification. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] AI perimenopause symptom-pattern learner** — `HormoneGoal.perimenopauseSupport` exists as goal label; no pattern learner. Build per-user model surfacing correlations between cycle phase / hot flashes / sleep / workout difficulty / mood. _Added 2026-05-26._
- [ ] **[NEW · AI · BACKEND] AI cultural-context awareness in nudges + recommendations** *(surface: existing push + chat — same UI, culturally-aware content)* — coach reads `user.country + preferred_locale`, avoids workouts during Ramadan fasts, suggests Suhoor hydration, recognizes regional food names. _Added 2026-05-26._

## Privacy + trust

- [ ] **[NEW · UI+BACKEND] Chat history download / export** — Settings → Privacy → Export My AI Chats; `ai_data_usage_screen.dart` is privacy-explainer only, no export today. _Added 2026-05-26._

## Premium / monetization

- [ ] **[RESEARCH] Should we ship a feature-gated free tier?** — code has `free` enum but it's just "not subscribed" state, not a real free tier with limits. MacroFactor + Gravl don't ship free either. Research before building. _Added 2026-05-26._
- [ ] **[CHANGE · UI] Plan-portability guarantee + visible badging** — add "Yours forever, even after trial" badge on paywall + trial-end + every workout. Plan is already portable in code; unmarketed. _Added 2026-05-26._

## Medical / health (lightweight, not FHIR)

- [ ] **[NEW · UI+BACKEND] Health-check setup with user-defined thresholds** — Settings opt-in toggles for high-HR / low-HR / irregular-rhythm alerts; respect existing quiet-hours + vacation mode. _Added 2026-05-26._
- [ ] **[CHANGE · UI+BACKEND] Expand medical info profile beyond allergies** — `nutrition_preferences_screen.dart` has FDA Big 9 allergens + diet flags; backend `health_conditions` JSON array exists. Add medications, conditions, pregnancy status, vaccines, social history as a structured profile the coach reads as context. NOT FHIR-grade. _Added 2026-05-26._
- [ ] **[NEW · AI · UI+BACKEND] Lab/blood-test upload — storage + display only** — PDF upload → Gemini Vision extracts top 8 biomarkers (LDL, HDL, glucose, A1c, vit D, ferritin, testosterone, thyroid). **No diagnostic / treatment language in coach replies** (FDA medical-device boundary). Hard "not medical advice" disclaimer + opt-in consent. _Added 2026-05-26._

## Bug-prevention / quality patterns

- [ ] **[NEW · AI · BACKEND] Unit confirmation echo on every set-logging chat turn** *(surface: existing chat reply)* — workout agent confirmation copy is generic; force echo "I logged 3 sets of squats at 100 **lb**" with unit explicit. _Added 2026-05-26._
- [ ] **[NEW · UI] Calibration-period messaging during first 7 days** — "Coach is learning you — first {N} days" banner with what's getting calibrated (resting HR, HRV, sleep pattern). _Added 2026-05-26._
- [ ] **[CHANGE · BACKEND] Bedtime-aware DND for AI evening summaries** *(surface: existing push pipeline — same surface, smarter timing)* — quiet_hours_start/end exist but are generic windows; gate any AI evening push by `user.sleep_time - 30min` so summaries hold for next morning. _Added 2026-05-26._
- [ ] **[CHANGE · AI · BACKEND] Hallucination tone-down: drop sarcasm-flagged turns** *(surface: existing chat — same UI, less recurring weirdness)* — coach context summarizer drops sarcasm-flagged turns after 48h. _Added 2026-05-26._

## Marketing / positioning (no engineering)

- [ ] **[MKT] Position MCP server as tier-3 wedge** — `/use-with-claude`, `/use-with-chatgpt`, `/use-with-gemini` landing pages + Reddit + HN posts. _Added 2026-05-26._
- [ ] **[MKT] HealthKit write-back as confirmed Google Health gap** — lead `/vs/google-health-coach` page with this row + citation. _Added 2026-05-26._
- [ ] **[MKT] 30s side-by-side video proving concise voice vs Google's verbose coach** — Reel + LinkedIn + IG Reel + YouTube Short. _Added 2026-05-26._
- [ ] **[MKT] Indie founder vs "Google data and ads company"** — lean into "indie founder, no parent-co data merger risk" wedge. _Added 2026-05-26._
- [ ] **[MKT] Comparison + counter landing pages** — `/vs-fitbit-air`, `/for-fitbit-users`, `/for-whoop-users`, `/for-apple-watch-users`. _Added 2026-05-26._
- [ ] **[MKT] Launch-day reactive social posts** — LinkedIn + X + Reddit drafts via `social-post-creator`. _Added 2026-05-26._
- [ ] **[CHANGE · DOCS] App Store + Play Store description + keyword updates** — add "Fitbit Air alternative" + "Google Health Coach alternative" + "Claude fitness app" + "ChatGPT fitness coach" + "MyFitnessPal AI". _Added 2026-05-26._
- [ ] **[MKT] Press one-pager + 30s side-by-side video** — for The Verge / 9to5 / TechCrunch indie-vs-Google angle. _Added 2026-05-26._
- [ ] **[MKT] Founder-voice in-app re-onboarding sweep** — one-time slide for existing users: "Heads up — Google launched Fitbit Air today. Here's how Zealova is different." _Added 2026-05-26._
- [ ] **[NEW · DATA] Gujarati (gu) translation pack** — 9 of 10 target Indian languages shipped; Gujarati is the gap. Run pipeline against `app_en.arb`. _Added 2026-05-26._
- [ ] **[NEW · UI+BACKEND] Religious / cultural fasting calendars** — current fasting infra only models TRE protocols; add Ramadan (with location-based sunrise/sunset), Navratri, Karva Chauth, Christian Lent. Auto-detected from `user.country` + opt-in. _Added 2026-05-26._

---

## Already shipped (do not re-implement) — with file:line + screen citations

### Shipped this cycle (2026-05-26)

- [x] **[NEW · UI+BACKEND] Wire PostHog lifecycle events end-to-end** — `posthog_client.py` + chokepoint hooks in `push_nudge_cron._send_nudge` and `email_cron._log_email_sent`; UTM-tagged email URLs via `lifecycle_open_url`; Flutter `app_open_after_gap` + `lifecycle_notification_tapped` + `lifecycle_email_clicked` events.
- [x] **[CHANGE · UI+BACKEND] Route lapsed unsubscribed users to paywall on app open** — `lapsedPaywallGateProvider` 24h suppression + router branch in `_handleAuthRedirect`. Events fire on route + dismiss.

### Shipped pre-2026-05-26 (verified by codebase audit)

**Coach + chat:**
- [x] **[NEW · UI] Voice input mic button in AI Coach chat** — `voice_message_widget.dart` (`VoiceRecorderButton`, long-press + duration). **Screen: Chat screen**.
- [x] **[NEW · UI] Voice-told set logging on active workout** — `voice_set_logging_provider.dart`. **Screen: Active Workout**.
- [x] **[NEW · UI] Photo from gallery + camera in single picker** — `media_picker_helper.dart` offers both in one sheet. **Screen: Chat compose**.
- [x] **[NEW · AI · BACKEND] Photo of gym equipment classifier** — `vision_service.py:815-877` returns `gym_equipment` + `extract_equipment_from_document()` for PDFs.
- [x] **[NEW · AI · UI+BACKEND] Coach offers "log this for me" inline action after food-photo recognition** — `nutrition_tools.py:1236-1269` emits `action_data` with log-it CTA. **Screen: Chat reply → food log screen**.
- [x] **[NEW · AI · BACKEND] Chat-based workout reschedule** — `workout_agent/nodes.py` exposes `reschedule_workout(workout_id, new_date, reason)`. **Surface: AI Coach chat**.
- [x] **[CHANGE · UI] Workout AI summary at top of workout detail page** — `workout_summary_general.dart:67-150` renders `_CoachReviewSection`.
- [x] **[CHANGE · AI · BACKEND] Concise AI voice retrofit** — `personality.py:143` `"concise"` mode.
- [x] **[NEW · UI] Privacy explainer for AI chat data flow** — `ai_data_usage_screen.dart`. **Screen: Settings → AI Data Usage**.
- [x] **[CHANGE · UI] Material 3 expressive theming** — `theme_provider.dart:33,48` `useMaterial3: true`. **Screen: entire app**.
- [x] **[NEW · AI · UI] Contextual quick-reply chips** — `chat_quick_pills.dart` + `chat_quick_action_provider.dart` generate pills dynamically from user state. **Screen: Chat**.
- [x] **[NEW · AI · BACKEND] 7 specialist langgraph agents** — coach + nutrition + hydration + injury + cycle + workout + plan agents all shipped under `langgraph_agents/`. **Surface: AI Coach chat routes between them based on intent**.

**Plan / programming / training intelligence:**
- [x] **[NEW · AI · UI+BACKEND] AI workout shortener** — `/backend/api/v1/workouts/quick.py` + `generate_quick_workout` tool in workout_agent. Chat intent routes "I only have 20 min" → quick generation. **Surface: Quick Workout action + Coach chat**.
- [x] **[NEW · UI+BACKEND] 1RM-based percentage programming + mesocycle / block periodization** — `/backend/api/v1/periodization.py` (mesocycle_state table with week/scheme/deload) + `strength_calculator_service.py` (%1RM) + `percent_1rm_min/max` in programming. **UI: Quick Workout Sheet shows "Mesocycle: [phase] Week X/Y"**.
- [x] **[NEW · BACKEND] AI deload detector** — `plateau_break_orchestrator.py` forces deload via RPE+HRV+sleep monitoring; `progression_settings.auto_deload_enabled`. **Surface: `deload_recommendation_card.dart` + push notif**.
- [x] **[NEW · AI · UI+BACKEND] AI plateau-breaker** — `plateau_break_orchestrator.py:31-51` `PLATEAU_VARIATIONS` map + `suggest_variation()` (barbell bench → incline, deadlift → deficit, etc.). Detects <3% 1RM variance over 4+ sessions, auto-swaps for 4 weeks. **Surface: chat suggestion + workout card**.
- [x] **[CHANGE · BACKEND] Cycle tracking wired into workout-gen prompts** — `/backend/api/v1/workouts/hormonal_utils.py` calls `adjust_workout_for_cycle_phase()` + phase recommendations injected into Gemini prompts. **Surface: workout output adapts; UI badge "phase-adjusted" still missing — kept as TODO above**.
- [x] **[NEW · AI · UI+BACKEND] Video form scoring** — `form_analysis_service.py` with `form_score` 1-10 + pose analysis via Gemini Vision + keyframe extraction. **Screen: `form_check_result_card.dart`**.
- [x] **[NEW · BACKEND] AI gym-equipment-aware workout generation** — `EquipmentResolver` singleton + gym_profile filtering throughout `workout_db.py`. **Surface: workout-gen output filtered to user's equipment**.
- [x] **[NEW · AI · BACKEND] AI dynamic exercise selection (RAG)** — `exercise_rag_service.py` + ChromaDB 768-dim. **Surface: workout generation pulls from RAG**.

**Workouts UX:**
- [x] **[NEW · UI+BACKEND] Live-activity / lock-screen workout card** — `live_activity_service.dart` (`live_activities` package). **Surface: iOS Dynamic Island + Android persistent notification**.
- [x] **[NEW · BACKEND] Custom heart-rate zone bounds** — `/backend/services/cardio/hr_zones.py` `calculate_hr_zones()` supports custom resting HR + max HR override per zone. (Flutter settings UI to edit may still be partial — verify if zone editing screen exists in user-facing Settings.)
- [x] **[NEW · UI] Workout in-progress HR chart + zone bar** — `post_workout_hr_graph.dart` renders HR chart + stacked time-in-zone bar. (Live route map mid-workout still missing — kept as TODO above.)
- [x] **[NEW · UI] Progress photo timeline / before-after comparison** — `comparison_gallery.dart`, `comparison_view.dart`, `progress_screen.dart` + `photo_before_after_template.dart` + `before_after_plate_doc.dart`. **Screen: Progress → Comparison Gallery**.
- [x] **[NEW · AI · UI+BACKEND] AI exercise substitution from chat** — `workout_mutation_tools.py` swap_exercise + workout_agent routing + `suggest_exercise_substitutes()` endpoint. **Surface: AI Coach chat ("swap deadlift for…")**.

**Nutrition:**
- [x] **[NEW · UI+BACKEND] Recipe URL import** — `/backend/api/v1/nutrition/recipe_imports.py:66` `/recipes/import-url` endpoint with SSE-streamed extraction. **Screen: Recipe import flow**.
- [x] **[NEW · AI · BACKEND] AI portion estimator from food photo** — `vision_service.py` Stage-1 "identify dishes + portion-estimate from a single image" with confidence tiers. **Surface: food-log photo flow**.
- [x] **[NEW · AI · UI+BACKEND] AI nutrition health score per food (0-10)** — `nutrition_db_helpers.py:health_score` + UI 10-dot bar in `Nutrition.tsx:186-200`. **Screen: Nutrition page**.

**Home / IA:**
- [x] **[NEW · UI] Drag-drop reorderable home metric cards** — `home_my_space_screen.dart:122` `ReorderableListView` + `customize_rings_sheet.dart` + `ring_catalog.dart`. **Screen: Home → My Space**.
- [x] **[NEW · UI] Wellness daily check-in** — `wellness_checkin_card.dart` captures sleep quality, energy, muscle soreness, stress, mood. **Screen: Home → Wellness Check-in Card**.
- [x] **[NEW · UI+BACKEND] Timeline / chronological feed on Today tab** — `home_timeline.dart` + `timeline_section.dart` mix workouts/meals/photos chronologically. **Screen: Home → Today tab**.
- [x] **[NEW · UI+BACKEND] iOS + Android home-screen widgets** — `ios/FitnessWidgets/` with 10+ widget types (StatsWidget, MealSuggestionWidget, StreakWidget) + Android `FitnessWidgetReceiver` / `MealSuggestionWidgetReceiver`. **Surface: iOS + Android home/lock screen**.

**Re-engagement + notifications:**
- [x] **[NEW · AI · UI+BACKEND] Proactive daily check-in messages from coach** — `push_nudge_cron.py` 14-tier guilt escalation + meal/streak/habit nudges + `email_cron.py` 21 lifecycle jobs. Writes to `chat_history` + FCM push. **Surface: Chat feed + push**.
- [x] **[NEW · BACKEND] Quiet-hours-aware notification gating** — `push_nudge_cron.py:136-146` `_is_in_quiet_hours()`. **Setting: Settings → Notification Preferences → quiet-hours picker**.

**India / i18n:**
- [x] **[NEW · DATA] India regional food DB** — 601 regional Indian food items across 6 migrations in `food_nutrition_overrides`. Sources: IFCT 2017 + USDA.
- [x] **[NEW · DATA] Indian-language i18n pack (9 of 10 target languages)** — hi, te, ta, kn, ml, mr, bn, pa, or, ur; each `.arb` ~21,513 keys. **Surface: Settings → Language picker (native script)**.
