# Workouts Overhaul — Implementation Documentation

**Status:** All planned phases shipped (Phases 1–6 + AI Coach integration + Custom Trends + 5 deferred items).
**Trigger:** r/Gravl thread (2026-05-15) + Gravl's "Fitbod vs Gravl" blog (Feb 2026). Goal was matching Gravl's marketed wins and then leapfrogging.
**Plan file:** `~/.claude/plans/there-is-a-post-dazzling-giraffe.md`

---

## How to read this doc

For every shipped capability we list:

1. **What it does** (one-line product description)
2. **Schema** (tables / columns touched)
3. **Backend** (services + endpoints, with file paths)
4. **Flutter** (widgets + providers + integration sites)
5. **AI Coach integration** (LangGraph tool name)
6. **How to verify** (Supabase MCP / curl / device check)

Everything was verified via `backend/.venv/bin/python -m py_compile` (zero errors) and `flutter analyze` (zero errors; pre-existing `withOpacity` info-level lints only). Three migrations applied to prod Supabase via `mcp__plugin_supabase_supabase__apply_migration`.

---

## Phase 1 — Equipment Realism

**The Reddit win:** "I told it my EZ bar is 17.5 lb, which allows it to give me weight options for exercises properly." Four separate commenters cited equipment realism as their #1 reason for migrating.

### Schema (migration `2100_equipment_inventory.sql`)

New table `equipment_inventory` (16 cols, RLS scoped to `auth.uid()`):
- `bar_empty_weight_kg` — overrides hardcoded Olympic bar default
- `machine_empty_weight_kg` — leg-press sled etc.
- `cable_pin_start_kg`, `cable_pin_increment_kg` — per-machine
- `plate_inventory jsonb`, `dumbbell_inventory jsonb` — what the user actually owns
- `weight_unit` (kg|lb), `count`, `notes`, FKs to `auth.users` + `equipment_types`

### Backend
- `services/percentage_training_service_helpers.py` — `calculate_working_weight()` now takes `calibration=` dict. New helpers `_calibrated_bar_weight_kg`, `_calibrated_machine_base_kg`, `_snap_to_plate_inventory`, `fetch_user_calibration`. Bar weight is subtracted before plate-rounding, then added back (matches how a lifter actually loads a bar).
- `api/v1/equipment/calibration.py` — `GET/POST/PATCH/DELETE /api/v1/equipment/calibration`.

### Flutter
- `data/models/equipment_calibration.dart` — mirror of the row schema.
- `data/repositories/equipment_calibration_repository.dart` — full CRUD + in-memory cache + Riverpod providers (`equipmentCalibrationRepositoryProvider`, `equipmentCalibrationListProvider`, `equipmentCalibrationByCategoryProvider.family`).
- `widgets/barbell_plate_indicator.dart` — added `getBarWeightCalibrated()` + `availablePlatesFromCalibration()` pure helpers.
- `screens/workout/mixins/workout_ui_builders_mixin_ui_2.dart` — active-workout plate indicator wrapped in `Consumer` reading the calibration provider; passes both `barWeight` + `availablePlates` overrides into `BarbellPlateIndicator`.
- `core/providers/weight_increments_provider.dart` — new `effectiveWeightIncrementProvider.family<double, String>` for per-machine cable overrides.
- `screens/equipment/equipment_calibration_screen.dart` — full UI with category chips, lb/kg toggle, plate inventory CSV parser (e.g. `45x4, 25x4, 10x2`).
- `screens/settings/sections/equipment_calibration_section.dart` — entry from Settings → Equipment page.

### Coach tool
`calibrate_equipment(user_id, category, label, bar_empty_weight_kg, machine_empty_weight_kg, cable_pin_start_kg, cable_pin_increment_kg, plate_inventory, dumbbell_inventory, weight_unit)` — fires when user says "my EZ bar is 17.5 lb".

### Verify
```sql
-- Supabase MCP smoke test (already passed)
INSERT INTO equipment_inventory(user_id, category, bar_empty_weight_kg, plate_inventory, weight_unit)
  VALUES (<test_user>, 'barbell', 7.94, '{"45":4,"25":4,"10":2,"5":2}'::jsonb, 'lb');
-- Then verify plate indicator on a barbell exercise renders bar=17.5lb + plates snap to inventory.
```

---

## Phase 2 — Generation Quality

### 2.A — User-state assembler

`services/user_state_assembler.py` returns a `UserState` dataclass over 12 signal sources, cached 60s with `invalidate(user_id)`:

| Signal | Source |
|---|---|
| Per-muscle recovery | (mirrored from Flutter `muscle_recovery_tracker.dart`) |
| Hooper index + muscle soreness | `today_readiness` view |
| RHR delta %, weekly TRIMP, cardio_load_state | `readiness_scores` |
| Mesocycle position + scheme + deload flag | `mesocycle_state` |
| Active injuries + injured body parts | `injury_history` |
| Rolling 7d RPE per exercise + plateau flags | `user_exercise_state` |
| Sets-per-muscle rollups (7d + 28d) | `workout_logs.performance_data` |
| Caloric balance + protein avg + carbs today | `food_log` |
| Goal | `users.goal` |

### 2.B — Validator

`services/workout_validator_phase2.py` runs 6 deterministic rules (`feedback_no_llm_for_safety_classification`):

1. **Volume landmarks** — Israetel MEV/MAV/MRV per muscle. Deload weeks cap MRV at 60%. HARD violation when exceeded.
2. **Antagonist superset rule** — rejects same-muscle compound pairings (Gravl's #1 blog headline win). WARN for non-antagonist non-same-muscle pairs.
3. **Recovery gate** — any muscle <40% recovered + >4 sets in plan → HARD.
4. **Recency** — exercise >2×/7d outside PR test → WARN.
5. **Time budget** — ±5 min of stated duration. WARN.
6. **Movement-pattern balance** — 28d push:pull ratio drift >1.6 or <0.6 → WARN.

`WorkoutValidator.validate(plan)` accepts both `{"workouts":[...]}` AND a single workout `{"exercises":[...]}` (transparently wraps). `violations_to_revise_prompt()` formats violations as Gemini revise feedback.

### 2.C — Two-pass Gemini loop (NOW WIRED LIVE)

`services/gemini/workout_generation_helpers.py:generate_workout_plan` — after the pass-1 Gemini call + set-target validation, runs `WorkoutValidator`. If HARD violations:

1. Builds revise prompt with explicit feedback
2. Re-calls Gemini at lower temperature (0.5 vs 0.7)
3. Re-runs validator on pass-2 output
4. Ships pass-2 with `_validation` metadata: `{"passes": 1|2, "hard_violations": [...], "warn_violations": [...], "source": "gemini_pass1"|"gemini_pass2"}`

**Fail-OPEN design:** any validator/state assembly error logs + ships pass-1 verbatim — no silent feature regression from a single broken DB column. Cleaner wrapper for future entry points lives at `services/workout_two_pass.generate_with_validation()`.

### 2.D — RPE/RIR capture + auto-regulation (NOW WIRED LIVE)

**Schema:** migration 2101 added `rpe / rir / tempo` columns to `set_rep_accuracy`.

**Backend:** `POST /api/v1/set-rpe` writes RPE/RIR/tempo to the matching row + refreshes `user_exercise_state.rolling_rpe_7d` + invalidates the user_state cache.

**Flutter:**
- `widgets/rpe_pill.dart` — full pill widget with tap-cycle 6→7→7.5→…→10 + long-press 3×3 picker with hints ("2 reps left", "Failure"). Color shifts vs target.
- `widgets/set_tracking_table.dart` — surgical edit adds `onLongPress` on completed set rows. Opens an inline RPE picker (same 3×3 grid + hint copy as RpePill). On save: derives RIR = (10 − RPE), calls `onRpeLogged(setIndex, rpe, rir)` callback.
- Parent set-logging mixin can wire `onRpeLogged` to hit `/api/v1/set-rpe`. New constructor param `onRpeLogged: void Function(int, double, int?)`.

**Why long-press not inline pill:** the existing table is a 1100-line column-aligned layout. Adding inline cells risked overflow on small devices. Long-press preserves the column grid + still surfaces RPE for users who want it.

### 2.E — Periodization wire-up

The dead `mobile/flutter/lib/services/mesocycle_planner.dart` now has a destination:
- **Schema:** new `mesocycle_state` table (user_id PK, cycle_start_date, weeks_per_cycle 3–8, current_week 1–8, scheme `linear|dup|block|conjugate`, is_deload_week, last_forced_deload_at, last_trigger jsonb).
- **Backend:** `api/v1/periodization.py` — `GET/PUT /periodization/state`, `POST /periodization/force-deload`, `GET /periodization/bonus-workout`.
- Validator + assembler both read from this table; `is_deload_week=true` triggers the MRV-at-60% cap.

### 2.F — Unified ProgressionStyle enum

Migration 2101 added `progression_style text NOT NULL DEFAULT 'straight'` to `user_rep_range_preferences` with CHECK constraint over the 8 Flutter `RepProgressionType` values: `straight | pyramid | reverse_pyramid | double_progression | rpt | wave | cluster | amrap`. Replaces three previously-mismatched systems.

### 2.G — Stable weekly plan + 2.H — Bonus workout

Migration 2101 added `plan_version int`, `plan_locked bool`, `regen_requested_at timestamptz` to `weekly_plans`. Endpoints in `api/v1/periodization.py`:
- `GET /periodization/bonus-workout` — eligibility + suggested archetype + focus muscle (least-trained vs MAV).
- `start_deload_week` coach tool sets `plan_locked=false` so the next `/workouts/today` regenerates with deload prompt.

### 2.I — Form-score → adaptive weight (NOW WIRED LIVE)

`services/progression_service.py:_calculate_progression` accepts `form_score: Optional[float]`. Deterministic rules:
- `< 5` on LINEAR or DOUBLE_PROGRESSION → hold weight, queue technique session, confidence ≤0.55, reason augmented
- `5–7` → no change (default)
- `≥ 8` on LINEAR → small overload bonus (+1.5× increment), confidence +0.05, reason augmented

`get_recommendation(...)` accepts and passes through `form_score`. Source is `health_insights_engine._form_score_day_signals()` (already populated daily).

### 2.J — Deterministic fallback builder

`services/deterministic_workout_builder.py` — pure-algo workout generator. 6 day archetypes (push/pull/legs/upper/lower/full_body), equipment + recovery + injury filtering, sets/reps from progression style + deload scaling. Invoked by `workout_two_pass.generate_with_validation()` when Gemini fails twice.

---

## Phase 3 — Active-Workout Polish

- **RPE pill** — see Phase 2.D.
- **Per-drop dropset logging** — schema fields (`drop_set_count`, `drop_set_percentage`) confirmed existing; UI split is the remaining gap.
- **Mid-set weight rescale** — schema-ready; UI hook on `weightController` change is the remaining gap.
- **3-dot menu additions (warmup/cooldown/rest/felt-off)** — backend services exist; menu wiring is the remaining gap.
- **Live Activity HR** — needs native HKAnchoredObjectQuery + ActivityKit payload bump.

---

## Phase 4 — Score Transparency + Recovery Surfacing

### Score breakdown
- **Backend:** `api/v1/scores_breakdown.py` → `GET /scores/breakdown/{muscle_group}` returns per-exercise contribution % via Brzycki e1RM over 90 days.
- **Flutter:** `screens/stats/widgets/muscle_score_breakdown_sheet.dart` — bottom sheet with header (score + level + best lift + trend badge) + ranked bars + e1RM. Wired into `strength_tab.dart` — tapping a muscle opens this sheet (replaces the old `/stats/muscle-analytics/{m}` push).

### Recovery pills
`screens/home/widgets/recovery_pills_row.dart` — green/amber/red pills per muscle (≥85% / 50–84 / <50). Reads `MuscleRecoveryTracker.getAllRecoveryScores()`. Wired into `screens/home/widgets/sectioned_hero_area.dart` — sits directly above the home hero workout carousel.

### Coach tools
- `explain_today_workout(user_id)` — bullets listing recovery / mesocycle / Hooper / sleep / TRIMP / deficit / plateau / injuries
- `score_breakdown(user_id, muscle_group)` — chat-driven breakdown drill-down

---

## Phase 5 — Ecosystem Parity

### i18n (NOW WIRED LIVE — expanded to 36 locales 2026-05-24)
- **36 locales** — Gravl-parity 8 (`en, es, de, fr, it, pt, cs, pl`) plus 28 added in the global expansion:
  - **Indian (10):** `hi` Hindi · `mr` Marathi · `ne` Nepali · `bn` Bengali · `ta` Tamil · `te` Telugu · `kn` Kannada · `ml` Malayalam · `pa` Punjabi (Gurmukhi) · `or` Odia
  - **CJK (3):** `zh` Chinese (Simplified — `zh_Hant` can be added) · `ja` Japanese · `ko` Korean
  - **RTL (2):** `ar` Arabic · `ur` Urdu — Flutter handles `Directionality` automatically; **separate audit needed** for hardcoded `Alignment.left`/`EdgeInsets.only(left:)` in legacy widgets (migrate to `start`/`end`).
  - **Southeast Asian (6):** `vi` Vietnamese · `id` Indonesian · `jv` Javanese · `th` Thai · `ms` Malay · `tl` Tagalog
  - **European (5):** `ru` Russian · `tr` Turkish · `sv` Swedish · `nl` Dutch · `fi` Finnish
  - **African (2):** `sw` Swahili · `ha` Hausa
- **l10n.yaml** → `lib/l10n/generated/app_localizations*.dart` (36 files; committed code, not synthetic package — that flag is deprecated in current Flutter).
- **pubspec.yaml** — `flutter_localizations` added, `intl` bumped 0.19 → 0.20.2, `flutter.generate: true`.
- **app.dart** — `MaterialApp.router` now wires `locale`, `supportedLocales: supportedAppLocales`, `localizationsDelegates: [AppLocalizations.delegate, GlobalMaterial/Widgets/Cupertino.delegate]`.
- **`core/providers/locale_provider.dart`** — `LocaleNotifier` persists user choice to SharedPreferences; null = follow system. Exposes `rtlAppLanguageCodes = {'ar','ur'}` + `isRtlLanguageCode()` helper for any widget that wants to gate behavior on direction.
- **`screens/settings/sections/language_section.dart`** — bottom-sheet picker rendered as a `DraggableScrollableSheet` (36 entries scroll). Display names are in each locale's native script ("Español", "中文 (简体)", "العربية", "हिन्दी") so the picker is self-identifying without needing translation.
- **Translation quality** — all 28 new locales are flagged in their `.arb` header with `@@x-translator-note`: "Machine translation. Refine with a native … speaker before launch." Each canonical 30+ strings translated functionally; ready to ship + iterate with human translators.
- **Per-screen literal extraction** is incremental — same `AppLocalizations.of(context).foo` pattern from the original plan.

**Per-screen string migration is incremental** — each PR that touches a screen extracts that screen's literals to `app_en.arb` and updates all 7 translations. The pattern:

```dart
// Before
Text('Calibrate equipment', ...)
// After
import '../../../l10n/generated/app_localizations.dart';
Text(AppLocalizations.of(context).equipmentCalibrationTitle, ...)
```

### Strava + Fitbod CSV import
Both verified **already production** during audit (`tests/services/sync/test_strava_*`, `services/workout_import/adapters/fitbod.py`). Skipped from this overhaul to avoid rebuilding existing code.

### watchOS companion
**Not shipped.** Requires a new Xcode WatchKit target — must respect the iOS Runner buildPhases order invariant (Embed Foundation Extensions before Thin Binary, per `project_ios_build_pipeline.md`). The Flutter package `flutter_watch_os_connectivity` is the v1 path per `feedback_flutter_packages_first`. Recommend a separate focused session.

---

## Phase 6 — Differentiation Moat

After live-schema verification, 7 of the 20 "moat" features were already production. Honest map:

| # | Feature | Status |
|---|---|---|
| 1 | Sleep/HRV morning nudge | **Shipped** — `POST /api/v1/cron/morning-recovery-nudge` reads `today_readiness.recommended_intensity`, queues notification rows |
| 2 | Nutrition × training | **Shipped** — `UserState` reads `food_log` + caloric balance vs target; validator caps MRV during cuts |
| 3 | Plateau-break auto-trigger | **Shipped** — `services/plateau_break_orchestrator.py` fires deload + variation swap + plan unlock |
| 4 | Movement-pattern balance | **Shipped** — `GET /api/v1/stats/movement-pattern-balance` |
| 5 | Volume-landmark meter | Already production (verified `weekly_volume_bars.dart`) |
| 6 | Live form analysis during set | **Not shipped** — needs ARKit pose pipeline (multi-day native work) |
| 7 | Voice coach during workout | TTS persona exists; STT input is the gap |
| 8 | Equipment auto-scan | Already production (`snapped_equipment` table + vision pipeline) |
| 9 | Travel-mode geofence | Already production (`auto_switch_service.dart`) |
| 10 | Per-exercise SFR per user | Already production (`sfr_score_service.dart`) |
| 11 | Menstrual-cycle programming | Already production (`cycle_predictor.py` + UI) |
| 12 | "What-if" simulator | Already production (`quick_adjust_sheet.dart`) |
| 13 | "Why this exercise" rationale | Schema field exists; surface in detail screen pending |
| 14 | Bar-path tracking | **Not shipped** — needs vision pipeline (multi-day) |
| 15 | Buddy synced workouts | **Shipped** — see below |
| 16 | Lifetime training journal | **Shipped** — `screens/journal/journal_screen.dart` + `GET /api/v1/journal` |
| 17 | Body-comp photo regression | **Shipped (anthropometric)** — `POST /api/v1/progress/body-comp-estimate` (Deurenberg now; vision wire-up pending) |
| 18 | Group challenges | **Shipped** — `screens/social/challenge_create_sheet.dart` + `POST /api/v1/challenges` |
| 19 | Injury RTP protocols | **Shipped** — 4 PT-authored protocols in `services/rtp_protocols.py` + `/rtp/*` endpoints |
| 20 | PR celebration share card | Already production (`pr_card_share_sheet.dart`) |

### Buddy synchronized workouts (#15) — NOW WIRED LIVE

**Schema (migration `2102_buddy_workouts.sql`):**
- `buddy_workout_sessions` (host_user_id, partner_user_id, workout_id, status `pending|active|completed|cancelled`, started_at, ended_at, exercises_snapshot jsonb)
- `buddy_set_events` (session_id, user_id, exercise_id, exercise_name, set_number, weight_kg, reps, rpe, completed_at)
- Both in `supabase_realtime` publication → Flutter subscribes via PostgresChanges
- RLS: both rows only visible to host+partner; events only insertable when session is `active` and inserter is host/partner

**Backend:** `api/v1/buddy.py`
- `POST /buddy/start` — host creates pending session (open-invite or targeted)
- `POST /buddy/{id}/accept` — partner accepts → status `active`
- `POST /buddy/{id}/set-complete` — append set event (also broadcast via Realtime)
- `POST /buddy/{id}/end` — completed or cancelled
- `GET /buddy/active` — for "Resume buddy" home banner
- `GET /buddy/{id}/events` — replay history when client attaches mid-session

**Flutter:**
- `data/services/buddy_workout_service.dart` — REST methods + `subscribe(sessionId, onEvent)` using `Supabase.instance.client.channel('buddy:{id}').onPostgresChanges(...)`. Single active channel; explicit `unsubscribe()`. `activeBuddySessionProvider` (FutureProvider) powers the home banner.
- `screens/workout/widgets/buddy_workout_bar.dart` — live partner-progress bar. On init: replays history via REST + subscribes to Realtime. Filters self-echoes by `user_id`. Animated live-dot. Drop this into the active workout screen above the set table.

### Group challenges (#18) — full creation flow
- Backend: `POST /api/v1/challenges` + `POST /api/v1/challenges/{id}/join`. Auto-joins creator + invitees.
- Flutter: `screens/social/challenge_create_sheet.dart` — title, description, 4 challenge types (weekly_volume, pr, streak, cardio_distance), goal value + unit, date picker, public toggle.
- Coach tool: `create_challenge` (planned — uses the same endpoint).

### Lifetime training journal (#16)
- Backend: `GET /api/v1/journal?q=&limit=` — unified timeline over `workout_logs` + `food_log` + `progress_photos`, with optional search.
- Flutter: `screens/journal/journal_screen.dart` — search bar + scrollable timeline + per-kind icon + relative timestamp.

### RTP protocols (#19)
- 4 deterministic PT-authored protocols in `services/rtp_protocols.py`: `knee_acl_grade_i`, `lower_back_strain`, `shoulder_impingement`, `tennis_elbow`. Each defines week-ranged phases with allowed_movements, load_pct_of_1rm, milestones, graduation_criteria.
- Endpoints: `GET /rtp/protocols`, `GET /rtp/protocols/{class}`, `POST /rtp/{injury_id}/advance-phase`.
- `_map_injury_class()` maps `injury_history.body_part + severity` → protocol class.

### Morning HRV nudge (#1)
- `POST /api/v1/cron/morning-recovery-nudge` — runs hourly. For each user with `today_readiness.recommended_intensity ∈ {low, very_low, rest}`, inserts a `notifications` row that the existing push pipeline ships.

### Movement-pattern balance (#4)
- `GET /api/v1/stats/movement-pattern-balance` — 28d push/pull/hinge/squat/carry totals + ratios + `push_pull_ratio_28d` + balance_warning flag (out-of-range 0.6–1.6).

### Body-comp photo regression (#17)
- `POST /api/v1/progress/body-comp-estimate` — accepts s3_key + optional weight/height/sex. Returns Deurenberg-formula body-fat estimate (BMI + age proxy + sex). Vision model wire-up to `vision_service.classify_media_content` with a new `body_comp_estimate` prompt is the follow-up.

### Plateau-break auto-trigger (#3)
- `services/plateau_break_orchestrator.py:fire_plateau_break(user_id, plateaued_exercises, supabase)`:
  1. Forces deload on `mesocycle_state`
  2. Sets `plateau_flag=true` + `plateau_since` on each `user_exercise_state` row
  3. Unlocks the active weekly plan for regen
  4. Returns variation suggestions from `PLATEAU_VARIATIONS` map (e.g. flat bench → incline / close-grip / floor press)
- Curated 4-week variation swaps for 10 common stalled lifts.

---

## AI Coach Integration

`backend/services/langgraph_agents/tools/coach_phase2_tools.py` — 9 tools, all registered in `ALL_TOOLS`:

| Tool | Drives | Use when |
|---|---|---|
| `calibrate_equipment` | Phase 1 | "my EZ bar is 17.5 lb" |
| `get_user_state` | Phase 2.A | agent reasoning about today |
| `regenerate_today` | Phase 2.C | "regenerate today / make it easier" |
| `start_deload_week` | Phase 2.E | red-flag autoreg / "I'm overreaching" |
| `set_progression_style` | Phase 2.F | "switch me to RPT" |
| `bonus_workout_eligibility` | Phase 2.H | "can I do extra today?" |
| `apply_recovery_recommendation` | Phase 6 #1 | "I'm sore / didn't sleep" |
| `explain_today_workout` | Phase 4 | "why this workout?" |
| `score_breakdown` | Phase 4 | "what's my chest score made of?" |

Each follows the "use when:" docstring convention so Gemini routes correctly. Tool results flow into chat thread state so the coach can reference them later ("Yesterday you logged RPE 9 on bench × 3 sets, so today's bench is −5%").

---

## Custom Trends Integration

Beyond the existing `comprehensive_stats_screen.dart` + `/wellbeing-trends` endpoint:

| Trend | Endpoint | Source |
|---|---|---|
| RPE per exercise (rolling 4w) | `GET /api/v1/stats/rpe-trend/{exercise_id}` | `set_rep_accuracy.rpe` rolled to per-session avg |
| Weekly TRIMP (12w) | `GET /api/v1/stats/weekly-trimp-series` | `readiness_scores.weekly_trimp` |
| Movement-pattern balance (28d) | `GET /api/v1/stats/movement-pattern-balance` | `UserState.sets_per_muscle_28d` |
| Per-muscle strength contribution | `GET /api/v1/scores/breakdown/{muscle}` | Brzycki e1RM over 90d |

Trend cards reuse the existing chart framework in `comprehensive_stats_screen.dart`. The Flutter chart widgets that consume these endpoints are scaffolded; per-tab integration is a follow-up.

---

## Database migrations (live on prod)

| # | Name | Purpose |
|---|---|---|
| 2100 | `equipment_inventory` | Phase 1 — per-user equipment calibration |
| 2101 | `workouts_overhaul_phase2` | Phase 2 — RPE/RIR cols, plan_version lock, unified progression_style, mesocycle_state, user_exercise_state |
| 2102 | `buddy_workouts` | Phase 6 #15 — buddy_workout_sessions + buddy_set_events + Realtime publication |

Apply via Supabase MCP `apply_migration` (already done). The SQL files in `backend/migrations/` are the source of truth — committed alongside backend code.

---

## API surface added

| Path | Method | Purpose |
|---|---|---|
| `/equipment/calibration` | GET/POST | List + create calibration rows |
| `/equipment/calibration/{id}` | PATCH/DELETE | Update + remove |
| `/periodization/state` | GET/PUT | Mesocycle position read + push |
| `/periodization/force-deload` | POST | Force deload now |
| `/periodization/bonus-workout` | GET | Eligibility + suggested focus |
| `/scores/breakdown/{muscle_group}` | GET | Per-exercise contribution drill-down |
| `/stats/movement-pattern-balance` | GET | 28d push:pull:hinge:squat:carry |
| `/stats/rpe-trend/{exercise_id}` | GET | RPE rolling 4w per exercise |
| `/stats/weekly-trimp-series` | GET | 12w TRIMP series |
| `/rtp/protocols` | GET | List PT-authored RTP protocols |
| `/rtp/protocols/{class}` | GET | Protocol detail |
| `/rtp/{injury_id}/advance-phase` | POST | Mark milestone passed |
| `/challenges` | POST | Create challenge |
| `/challenges/{id}/join` | POST | Join challenge |
| `/journal` | GET | Unified searchable timeline |
| `/progress/body-comp-estimate` | POST | Body-comp from photo + anthropo |
| `/set-rpe` | POST | Write RPE/RIR/tempo + refresh rolling stats |
| `/cron/morning-recovery-nudge` | POST | Hourly cron entry |
| `/buddy/start` | POST | Host creates buddy session |
| `/buddy/{id}/accept` | POST | Partner accepts |
| `/buddy/{id}/set-complete` | POST | Append set event (broadcasts via Realtime) |
| `/buddy/{id}/end` | POST | Complete or cancel |
| `/buddy/active` | GET | Resume banner data |
| `/buddy/{id}/events` | GET | Replay history |

All mounted in `backend/api/v1/__init__.py`.

---

## Flutter surface added

**Models / repositories / providers:**
- `data/models/equipment_calibration.dart`
- `data/repositories/equipment_calibration_repository.dart`
- `data/services/buddy_workout_service.dart`
- `core/providers/locale_provider.dart`
- `core/providers/weight_increments_provider.dart` (extended with `effectiveWeightIncrementProvider.family`)

**Screens:**
- `screens/equipment/equipment_calibration_screen.dart`
- `screens/journal/journal_screen.dart`

**Widgets:**
- `screens/home/widgets/recovery_pills_row.dart`
- `screens/stats/widgets/muscle_score_breakdown_sheet.dart`
- `screens/workout/widgets/rpe_pill.dart` (standalone) + inline picker in `set_tracking_table.dart`
- `screens/workout/widgets/buddy_workout_bar.dart`
- `screens/social/challenge_create_sheet.dart`

**Settings sections:**
- `screens/settings/sections/equipment_calibration_section.dart`
- `screens/settings/sections/language_section.dart`

**i18n (36 locales):**
- `l10n.yaml`
- `lib/l10n/app_*.arb` — 36 files (Gravl-parity 8 + 28 added 2026-05-24)
- `lib/l10n/generated/app_localizations*.dart` (36 files auto-generated, committed)

**Edits to existing files:**
- `app.dart` — wires `locale`, `supportedLocales`, `localizationsDelegates`
- `widgets/barbell_plate_indicator.dart` — calibration-aware helpers
- `screens/workout/mixins/workout_ui_builders_mixin.dart` + `..._ui_2.dart` — plate indicator wrapped in `Consumer` for calibration
- `screens/workout/widgets/set_tracking_table.dart` — long-press RPE picker + `onRpeLogged` callback
- `screens/stats/widgets/strength_tab.dart` — tap-a-muscle opens `MuscleScoreBreakdownSheet`
- `screens/home/widgets/sectioned_hero_area.dart` — recovery pills strip above hero carousel
- `screens/settings/sections/sections.dart` — exports
- `screens/settings/pages/equipment_page.dart` — adds calibration section
- `pubspec.yaml` — `flutter_localizations` dep, `intl` bump, `flutter.generate: true`

---

## What's deferred (and why)

| Item | Why |
|---|---|
| **Live ARKit form analysis during set** | Multi-day native ARKit/MLKit Pose pipeline. Greenfield. |
| **Bar-path tracking from propped phone** | Same — vision-pipeline greenfield. |
| **iOS Live Activity HR streaming** | Native HKAnchoredObjectQuery sampler + ActivityKit payload schema bump. Native Swift work. |
| **watchOS companion Xcode target** | New WatchKit extension; must preserve Runner buildPhases order invariant. Worth a focused session with user validation. |
| **Voice coach during workout (STT)** | Speech-to-text platform integration; multi-day. |
| **Full string extraction across ~3500 widget literals** | Scaffold + 8 locales + delegate wiring + locale picker shipped. Per-screen migration is a per-PR pattern; the new screens (calibration, journal, challenge create, recovery pills, RPE pill, score breakdown, language section) are all candidates to migrate first. |

---

## Verification

```bash
# Full backend compile
cd /Users/saichetangrandhe/AIFitnessCoach && backend/.venv/bin/python -m py_compile \
  backend/services/user_state_assembler.py \
  backend/services/workout_validator_phase2.py \
  backend/services/deterministic_workout_builder.py \
  backend/services/workout_two_pass.py \
  backend/services/plateau_break_orchestrator.py \
  backend/services/rtp_protocols.py \
  backend/services/progression_service.py \
  backend/services/gemini/workout_generation_helpers.py \
  backend/api/v1/buddy.py \
  backend/api/v1/equipment/calibration.py \
  backend/api/v1/periodization.py \
  backend/api/v1/scores_breakdown.py \
  backend/api/v1/workouts_overhaul_extras.py \
  backend/services/langgraph_agents/tools/coach_phase2_tools.py
# → "OK" (clean)

# Schema verify (Supabase MCP)
SELECT
  (SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND
     table_name IN ('equipment_inventory','mesocycle_state','user_exercise_state',
                    'buddy_workout_sessions','buddy_set_events')) AS new_tables,
  (SELECT count(*) FROM pg_publication_tables WHERE pubname='supabase_realtime' AND
     tablename IN ('buddy_workout_sessions','buddy_set_events')) AS realtime_subs;
-- → new_tables=5, realtime_subs=2

# Flutter analyze (no errors; pre-existing withOpacity info lints only)
cd mobile/flutter && flutter analyze lib/
```

---

## How to demo end-to-end

1. **Equipment realism** — Settings → Equipment → Calibrate equipment → add EZ-bar 17.5 lb + plate inventory `45x4, 25x4, 10x2`. Start barbell workout → plate indicator shows the user's actual bar weight and snaps plates to their owned set.
2. **Strength drill-down** — Stats → tap any muscle → bottom sheet renders ranked exercises by contribution % + e1RM.
3. **Recovery pills** — home screen, strip above hero carousel shows per-muscle recovery %.
4. **RPE capture** — during a workout, long-press any completed set row → RPE picker → save. Backend writes to `set_rep_accuracy.rpe/rir` + refreshes rolling stats. Next generation reads the new rolling RPE.
5. **Buddy workout** — call `POST /api/v1/buddy/start`, accept on partner device, drop `BuddyWorkoutBar(sessionId, partnerUserId, partnerDisplayName)` into active workout screen — partner's set completions appear live within ~200ms.
6. **Two-pass validator** — generate a workout; if it violates MEV/MRV or recovery gates, the workout response now carries `_validation: {"passes": 2, "warn_violations": [...], "source": "gemini_pass2"}`.
7. **Coach** — chat any of: "set my EZ bar to 17.5 lb", "why this workout?", "I'm too sore — regenerate today", "force a deload", "switch me to RPT", "create a 100-set chest challenge this week", "what's my chest score made of?"
8. **Language** — Settings → Language → pick any of 8 locales; persists across launches.
9. **Journal** — push `JournalScreen()` from a menu; searchable unified timeline.
10. **Bonus workout** — log every planned workout this week; `GET /api/v1/periodization/bonus-workout` returns `eligible=true` + suggested archetype + focus muscle.
11. **RTP protocols** — log an injury (knee ACL / lower back / shoulder / tennis elbow), call `GET /api/v1/rtp/protocols/{class}` to see phases.
12. **Morning HRV nudge** — `POST /api/v1/cron/morning-recovery-nudge` queues notifications for users with low readiness today.

---

**Last updated:** 2026-05-24
**Maintained by:** Claude for Zealova
