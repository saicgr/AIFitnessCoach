# File Review 2026-06 — Consolidated Summary

Scope: every first-party source file **>1000 lines** (159 Dart + 109 Python), reviewed by 39 parallel subagents. Per-file detail lives in `batch-00.md` … `batch-38.md`. This is a **read-only review — no code was changed.** (The only repo change made during this session was adding venv globs to `.gitignore`.)

Each finding below cites the batch file to open for the precise `file:line` and fix.

---

## 🔴 Tier 1 — Ship-blocking / security / data-integrity

### A. Broad IDOR (authenticated-but-not-authorized) across the backend
Many endpoints take `user_id`/`profile_id` from path/query/**body** and never compare it to `current_user["id"]`. Because handlers use the **service-role Supabase client (RLS bypassed)**, the API-layer check is the only boundary. Confirmed on:
- `saved_workouts.py` — read/edit/**delete** other users' saved & scheduled workouts; its "ownership check" compares the row to the *client-supplied* `user_id`, not the JWT (batch-14).
- `leaderboard.py` — 4 endpoints leak friend-graph/rank (batch-14).
- `nutrition/food_logging_stream.py::/analyze-text-stream` — the one streaming endpoint missing `verify_user_ownership` that all its siblings have (batch-11).
- `hormonal_health.py`, `metrics.py`, `gym_profiles_endpoints.py`, `progress.py` (reads), `workouts/quick.py::/quick/save`, `scores.py` (strength/PR reads), `trophies.py`, `neat_endpoints.py`, `workout_operations.py`, `data_export.py` (batches 11/13/14/15/16/12/24).
- **Fix pattern already in repo:** `fasting.py` / `exercise_history.py` / most of `quick.py` do `verify_user_ownership(current_user, user_id)` at the top — apply uniformly.

### B. Two auth/privacy gates FAIL OPEN (should fail closed)
- `social_service.dart` `getPrivacySettings`/`canShareActivity` default to **allow** on any network error → a transient error can auto-post a workout/PR the user marked private (batch-27).
- `auth_repository.dart` 401-recovery `restoreSession` has **no `.timeout(ApiConstants.tokenRefreshTimeout)`** — the exact coalesced-latch wedge `project_auth_refresh_timeout` warns about (batch-27).

### C. Forbidden fabricated/mock data shown to users (violates no-mock-data rule)
- `card_doc_renderer.dart` — injects **fake chart/series/radar/heatmap/ring data** when real Shareable data is empty; users can share invented progress graphs (batch-05). **Highest-severity mock-data violation.**
- `progress_share_templates.dart` `_buildCalendarHeat` — seeds `Random()` to light ~N cells in a contribution-graph that does **not** map to real training days (batch-18).
- `edit_targets_sheet.dart` — the "2000/150/200/65" default-macro trap rendered as real targets (batch-06).
- `import_exercise_preview_sheet.dart` — hardcoded "AI confidence 80%" never set from real data (batch-21).
- `vision_service.py` fallback inflammation triggers; `gemini/nutrition.py` regex-recovery fabricates `health_score=5` (batch-23/24).

### D. Data-loss / durability bugs
- `set_logging_mixin.dart` `updateCompletedSet`/`editCompletedSet` — rebuild a fresh `SetLog` on edit, **silently dropping rpe/rir/targetReps/duration/rest/previous/aiInputSource/notes/photo/audio**, then persist the stripped set to the crash-safe checkpoint. Mechanical fix: `existingSet.copyWith(...)` (batch-04).
- `workout_operations.py::log-set` — dedupe/override key is `(user_id, exercise_name, set_number)` with **no `workout_id`**; `override=true` can **DELETE a set belonging to a different workout** (batch-16).
- `food_logs.py::swap_dish_variant` — writes phantom columns `total_protein_g/total_carbs_g/total_fat_g` → PGRST204 **500 on every dish-variant swap** (batch-13).
- Food-log **idempotency bypass / double-log** vectors: `log_meal_sheet_ui_1.dart` regenerates the idempotency key on retry; `menu_analysis_sheet.dart` sends no key and latches "Logged" unconditionally (batch-06). Backend `wellness/events.py` idempotency cache is **per-process in-memory** → double-writes across uvicorn workers (batch-15).

---

## 🟠 Tier 2 — Systemic / high-frequency

### E. Event-loop blocking — the #1 backend perf root cause (`project_perf_pass_2026_06`)
Synchronous supabase-py `.execute()` called directly inside `async def` handlers blocks the entire event loop on every DB round-trip. Found in **nearly every backend file reviewed** (batches 11–16, 23–26). Worst: `push_nudge_cron.py` (~35 blocking per-user jobs), `email_cron.py` (`_get_user_stats` ≈13 blocking queries/user), `coach/daily_insight.py` (14-query serial snapshot), `neat.py`/`hormonal_health.py` (zero offloading), `user_preference_utils.py` (docstring claims `gather()` parallelism but each call blocks → serial). **Fix pattern in-repo:** `food_logging.py` `_run_blocking`/`_foodlog_pool`, `progress.py::/summary` `to_thread`+`gather`, `rag_service.py` `asyncio.to_thread` — apply uniformly.

### F. lbs/kg unit handling is scattered and inconsistent (`feedback_weight_units`)
Ad-hoc `* 0.453592` / `/ 2.20462` literals (and two *different* kg→lb factors, 2.205 vs 2.20462) duplicated across many files instead of funneling through `WeightUtils`. Concrete user-facing bugs:
- `workout_ui_builders_mixin_ui_2.dart:993` voice-confirm snackbar hardcodes "kg" while the very next commit honors `useKg` — contradictory units in one flow (batch-03).
- `quick_workout_sheet` / `easy_active_workout_state` default `_weightUnit='kg'` for a lbs-majority base (batch-04/01).
- `workout_summary_general.dart` `useKg:false` hardcoded; several summary/volume/e1RM banners are kg-only for lbs users (batch-00/02).
- `toggleUnit()` asymmetric snap → double-toggle inflates logged weight (batch-04).

### G. Uncapped 1RM (Epley/Brzycki) math
No rep cap → projected 1RM ~2× inflated on high-rep sets; `strength_calculator_service.py`/`health_insights_engine.py` **divide-by-zero at reps=37 and go negative beyond**, now reachable via the new bodyweight-proxy high-rep path (batches 00/24). Found in ≥4 Dart files + 2 services.

### H. Unguarded casts on untrusted server/wearable JSON inside `build()` → full-screen crashes
Hard `as`/`DateTime.parse` casts with no try/catch that red-screen the whole page on one malformed row:
- `synced_workout_detail_screen.dart:772-996` per-sample `as num` on wearable payloads (batch-17).
- `chat_message_bubble.dart:354-365` `as List` on coach action data — crashes the whole chat list (batch-20).
- `challenge_history_screen.dart:164` sort throws on one bad row → blanks the screen; `opponentName[0]` RangeError on empty username (batch-21).

### I. `TextEditingController` created inside `build()`/`StatefulBuilder` → leak + caret-jump
Reproducible "can't edit the middle of the field" bug:
- `program_template_builder_screen.dart:373` (program name) (batch-02).
- `coach_selection_screen.dart:451` (batch-09).
- `combined_health_screen.dart:64`, `edit_gym_profile_sheet_ext` rename dialog (batch-20/32).

### J. State-management subscription bug (live customization doesn't repaint)
4 sites read `ref.watch(metricLayoutProvider.notifier).configFor(...)` — calling `.notifier` then a method does **not** subscribe, so metric size/color/chart edits don't repaint until an unrelated rebuild (batch-32). Same class: `home_my_space_screen.dart`.

---

## 🟡 Tier 3 — Notable correctness, per area

- **Notifications:** `notification_service.dart:329` maps UTC offset → IANA from an 8-entry mostly-US table → **wrong-time notifications for all non-US users** (use `FlutterTimezone.getLocalTimezone()`, already used in `api_client.dart`). `cancelAll()` wipes coach/trial reminders on every toggle. Quiet-Hours toggle in `notifications_section.dart:306` is hardcoded `value:true, onChanged:(_){}` — **dead** (batches 28/19).
- **i18n:** 34/35 non-English locales store the workout-reminder title under typo key `workout_workout_reminder_title` → push **title renders in English in 34 languages** (fix upstream generator) (batch-38).
- **Coach format-brace risk:** `health_coaching.py:1020` `_REPHRASE_PROMPT.format(draft=...)` is the same failure mode as the prior "unescaped brace crashed every coach reply" bug — use `.replace("{draft}", draft)` (batch-26). (`prompts_helpers.py` verified safe — no `.format`.)
- **Subscription:** lifetime detection only fires inside the `premium_plus` branch — a lifetime SKU on the `premium` entitlement never gets lifetime tier + shows a bogus expiry (batch-29).
- **Pricing drift:** hardcoded `$37.49`/`$49.99`/`$59.99` in `paywall_*`, `email_lifecycle.py` vs the live `$47.99`/`$59.99` — verify real SKUs (batches 17/22/25).
- **Nutrition data:** `_FOOD_MODIFIERS` has **14 duplicate keys** silently dropping authored deltas; `food_search_service.dart` 5-min TTL serves a **just-deleted meal** on re-search; `recommend_meal` budget safe-floor reduces to a tautology and never enforces `SAFE_FLOOR_KCAL` (batches 25/30/23).
- **Per-date logging leakage:** search/NL/leftovers/recipe log paths hardcode `today` and splice onto today's provider even when viewing a past date (`food_browser_panel.dart`, `daily_tab.dart` leftovers, `recipe_detail_screen.dart`) (batches 06/07).
- **Dead/inert advertised features:** `contextual_nudge_provider.dart` `_fastingDynamicProvider` returns `null` ("Phase U placeholder") → all 4 fasting nudges dead (batch-30); `pillar_detail_screen.dart` date strip doesn't drive data; hardcoded progress bars (batch-19).

---

## 🧪 Test-suite quality (batches 36–37) — false confidence
Several large "CRITICAL" suites are green on broken behavior:
- `test_neat_system.py`, `test_supersets.py`, `test_exercise_progressions.py` **re-implement product logic inside the test** and assert the re-implementation (NEAT defines `calculate_neat_score` etc. in the test file). NEAT API tests wrap every assert in `if status==200:` → literally unfailable; reference an undefined `client` fixture.
- `test_set_adjustments.py:141` hard-`skipif(True)` on 5 endpoint classes + test-local fatigue fallback; `test_workout_generation.py` "NO FALLBACKS" header but RAG fixture is a stub the marquee tests validate.
- Repo-wide: `TestClient(app)` used by 8+ files despite `project_testclient_httpx_skew` (errors here) — migrate to threaded uvicorn + httpx.
- **Model files to copy:** `test_fasting_impact_api.py`, `test_library.py`, `test_sets_reps_control.py`, `test_progression_service.py` (import real fns, assert concrete numbers).

---

## 📂 Organization / file-size
Every reviewed file is >1000 lines; concrete split recommendations are in each batch report. Key distinctions:
- **Genuinely large-but-cohesive (data/content, split optional):** `shareable_catalog.dart`, `card_doc.dart`, `exercise_instruction_copy.dart`, `coach_notification_templates.dart`, `i18n_translations.py`, `gemini_schemas.py`, `prompts_helpers.py`, `demo_scenes.dart`, `pre_auth_quiz_data.dart`, the `batch_N_*.py` data modules.
- **God-objects that should be decomposed (priority):** the workout `*_mixin.dart` family (one mutable State bag, ~110 unenforced abstract members — wants a session-controller object, not more part-files); `logged_meals_section.dart` (5021); `card_editor_screen.dart` (5142, 5-way split); `workout_summary_advanced.dart` (5675); `unified_home_widgets.dart` (grab-bag); the 700-line single handlers in `crud_completion.py`/`workout_operations.py`.
- **Confusing split/naming debt:** `nutrition_settings_screen` × `_ui`/`_ui_1`/`_ui_2`; two unrelated `overview_tab.dart`; `xp.py` vs `xp_endpoints.py`; ~600 drifted duplicate lines across `generation_endpoints.py`/`generation_streaming.py` and the SSE state machines in `workout_repository_generation.dart`/`nutrition_repository.dart`.

---

## Suggested fix order
1. **Tier 1 A–D** (IDOR sweep, fail-closed privacy/auth, kill fabricated-data renderers, the 3 data-loss bugs). These are security + correctness + the project's own forbidden-pattern rules.
2. **E** (to_thread sweep) — single highest-leverage perf fix; pattern already exists in-repo.
3. **F + G** (route all weight math through `WeightUtils`; cap 1RM rep count).
4. **H + I + J** (crash-hardening casts; controller hygiene; the `.notifier` subscription fix).
5. Tier 3 + test-suite rewrites as follow-ups.
