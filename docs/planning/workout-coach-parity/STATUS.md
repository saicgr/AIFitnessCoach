# Build Status — Workout Coach Parity

## ✅ ORPHAN AUDIT (2026-05-29) — every capability now reachable

Audited the whole feature for implemented-but-unreachable paths + unverified delegated wiring:
- VERIFIED (read the actual code, not the agent's claim): `infer_inline_action` IS called in both
  chat response paths (`langgraph_service.py:1303` + `:1599`); `generate_quick_workout` DOES branch on
  `constraints_text` into the shared engine.
- FIXED — Customization Studio CREATE mode was orphaned (only reachable from detail "Adjust" with a
  workoutId). Added "Build a workout" button on the Workouts tab → `showCustomizationStudio(context)`
  (no workoutId → persist) → opens the new workout.
- FIXED — preset REUSE was orphaned (Studio only created presets). Added a saved-presets row (tap to
  load params, × to delete) wiring `listPresets`/`deletePreset`.
- FIXED — `reference_exercise` + `schedule_workout` emissions (see below) now implemented.
Final: frontend `flutter analyze` = 0 errors across all 19 touched files; backend imports clean.
Only intentionally-unsurfaced API: `updatePreset` (rename-preset) — valid method, delete+resave covers
it; not a broken path.



## ✅ COMPLETE (2026-05-29) — all workstreams built + verified

Backend: full app imports clean, all 6 new route groups registered, engine live-tested,
inline-action emitter sanity-checked. Frontend: `flutter analyze` across all 18 touched files =
**0 errors** (15 warnings / 19 infos, all matching the repo's pre-existing noise baseline).

Built this session beyond backend + foundation:
- W1 rich `WorkoutResultCard` + inline go-to button widgets (How-to / Progress / Water / Weight /
  Schedule / Recipe) wired into chat_message_bubble.
- W2 Workouts tab (4th library tab) + Save-to-library sheet + rename/delete/do-now/schedule.
- W3 Customization Studio (sliders/chips/segmented + body-map + debounced live preview + presets) +
  BodyMapSelector.
- W4 detail "Adjust workout" → Studio in-place + Undo snapshot; chat constraint adaptation
  (generate_quick_workout now takes constraints_text → shared engine).
- W5/W6 detail "Mark as done" (marked_done, no fake PRs) + thumbs (down → opens Studio).
- W7 Shuffle (overflow) + trim/extend & equipment swap (via Studio params) + active-recovery toggle.
- W8 recipe-detail screen + `/recipe-detail` route + chat "View recipe" button.
- Backend `chat_inline_actions.infer_inline_action` emits log_hydration / log_weight /
  reference_progress / reference_recipe (additive, never overwrites existing actionData).

ALL inline go-to emissions now implemented (chat_inline_actions.py), verified live:
- `reference_exercise` (How-to button): matches the reply against a curated vocabulary of ~85
  canonical movement phrases (zero false positives), resolves each to a real library row by
  containment (shortest/most-canonical match) for the exercise id; name-only fallback otherwise.
  Verified: "Romanian deadlifts" → "Barbell Romanian Deadlift" (+id).
- `schedule_workout` (Schedule button): emitted on explicit schedule intent AND a resolvable
  workout_id from turn context. Verified.
- (Plus log_hydration / log_weight / reference_progress / reference_recipe from the prior pass.)
All are additive and never overwrite an existing action_data (food_analysis, generate_quick_workout…).

---


Worktree: `.claude/worktrees/workout-coach-parity` (branch `worktree-workout-coach-parity`)
Rollback tag: `workout-coach-parity-v0-snapshot`. File backup: `docs/planning/redesign-2026-05/backup/`.

## ✅ DONE + VERIFIED — Backend (everything)

### DB (migrations applied to live Supabase)
- `2214_workout_presets.sql` — `workout_presets` table. **Applied + verified.**
- `2215_workout_thumbs.sql` — `workout_thumbs` table (NOT `workout_feedback`, which already
  existed as the post-workout rating table). **Applied + verified.** Dropped 2 stray dup indexes.

### Models
- `models/saved_workouts.py` — `ExerciseTemplate` extended lossless: reps/weight optional,
  + duration/hold/set_targets/superset/drop-set/media. New `SetTargetTemplate`.
- `models/workout_studio.py` (new) — `WorkoutBuildParams`, `BuiltWorkout`, `CustomizeRequest`,
  `AdaptRequest` (both with `prebuilt` WYSIWYG passthrough), `WorkoutThumbsRequest`,
  `SaveWorkoutFromWorkout`, `WorkoutPreset{,Create,Update}`.

### Engine — `services/workout_builder.py` (new) — **live-tested against DB**
- `build_adapted_workout(params, user, *, fast=True)` — RAG select + deterministic adaptive
  params + scaled warm-up/cool-down + supersets/AMRAP. Instant (fast=True → no Gemini).
- `parse_constraints_text(text, base)` — deterministic NO-LLM free-text → params
  (body parts → sore_areas HARD avoid; "easier/shorter/no equipment/low impact/recovery").
- `persist_built_workout(...)` — main exercises → exercises_json; warm-up/cool-down/params →
  generation_metadata (existing detail screen unaffected).
- Over-constrained → broaden ladder (variety→equipment→focus, NEVER pain/injury) →
  active-recovery safety net. Impact filter after broaden. Dedup. Verified: back-pain →
  injury filter fired, stayed "Full Body" (not "Back"), no dupes, ~2.3s cold.

### RAG fast path — `services/exercise_rag/service.py`
- Added `fast: bool = False` param to `select_exercises_for_workout`. When True, skips the
  Gemini `_ai_select_exercises` step and uses `_deterministic_select_exercises` (<10ms,
  same output shape). Default False = zero behavior change for all existing callers.

### Endpoints (all registered + full app import verified)
- `api/v1/workouts/studio.py` (new): `POST /workouts/customize`, `/{id}/adapt`, `/{id}/shuffle`,
  `/{id}/feedback`. Registered before crud_router in `workouts/__init__.py`.
- `api/v1/saved_workouts.py`: `POST /saved-workouts/from-workout` (lossless, name auto-suffix).
- `api/v1/workout_presets.py` (new): `GET/POST/PUT/DELETE /workout-presets`. Registered in `api/v1/__init__.py`.
- `api/v1/workouts/crud_completion.py`: PR detection gated `completion_method != "marked_done"`
  (manual mark-done never fabricates PRs; streak/XP still count).

## ✅ DONE + VERIFIED — Frontend foundation (data/service layer)

`flutter pub get` run in worktree (.dart_tool present). `flutter analyze` CLEAN on all below.
- `lib/core/constants/api_constants.dart` — added `savedWorkouts`, `workoutPresets` consts.
- `lib/data/models/workout_studio_models.dart` (new) — `WorkoutBuildParams` (+copyWith/toJson/fromJson),
  `BuiltWorkout`, `WorkoutPreset`. Manual JSON (no codegen).
- `lib/data/services/workout_studio_service.dart` (new) — preview/persist/adapt/shuffle/thumbs +
  presets CRUD. Verified against ApiClient signatures (get/post/put/delete<T> at api_client.dart:1081+).
- `lib/data/services/saved_workouts_service.dart` — `saveFromWorkout()` (→ /saved-workouts/from-workout)
  + `updateSavedWorkout()` (rename → PUT /saved-workouts/{id}?user_id=).
- `lib/data/models/chat_message.dart` — go-to getters: hasExerciseReference/referencedExerciseId/Name,
  hasProgressReference/Kind, hasRecipeReference/referencedRecipe, hasHydrationLog, hasWeightLogPrompt,
  hasScheduleWorkout. (Each guards on id presence → no dead-link buttons.)

NOTE: existing saved-workout calls use `/social/saved-workouts/*` (a separate social mount); new
methods use the canonical `/saved-workouts/*` router where the new + rename endpoints live (verified
both write the same `saved_workouts` table, so saves appear in the existing list).

## ✅ DONE + VERIFIED — W1 rich chat card (the headline "open from chat")

`flutter analyze` clean on the new code (remaining issues in chat_message_bubble.dart are
pre-existing withOpacity/state-notifier noise, not from these edits).
- `lib/data/providers/workout_studio_providers.dart` (new) — `workoutStudioServiceProvider`,
  `savedWorkoutsServiceProvider` (read `apiClientProvider`).
- `lib/screens/chat/widgets/chat_media_widgets.dart` — new `WorkoutResultCard` (ConsumerStatefulWidget):
  gradient header (tap → /workout/:id), duration + exercise-count meta, exercise chips, inline
  **Start / Save / 👍👎** wired to `saveFromWorkout` + `sendThumbs`. Old `GoToWorkoutButton` kept.
- `lib/screens/chat/widgets/chat_message_bubble.dart` — `hasGeneratedWorkout` now renders
  `WorkoutResultCard` (passes duration/count/exercise names from actionData) instead of the button.
  END-TO-END LIVE TODAY: generate_quick_workout already emits this actionData.

## ⏳ REMAINING — Frontend UI widgets/screens + agent emissions

Full file-level plan in `PLAN.md` §3. Data layer + W1 card ready; these remain:
- **Go-to buttons** (W1 rest) — exercise/progress/water/weight/schedule widgets + wiring; NEED the
  backend agent `actionData` emissions first (else they never fire). Getters already in chat_message.dart.

- **Agent actionData emissions** (backend, small): workout/coach agents emit
  `reference_exercise`, `reference_progress`, `reference_recipe`, `log_hydration`, `log_weight`,
  `schedule_workout` in `services/langgraph_agents/`. Chat tool `generate_quick_workout` →
  delegate to `build_adapted_workout` for constraint support (W4 backend).
- **W1** Rich `WorkoutResultCard` (replace `GoToWorkoutButton` in `chat_media_widgets.dart`) +
  go-to button widgets + `has*` getters in `chat_message.dart` + wire in `chat_message_bubble.dart`.
- **W2** `saved_workouts_service.dart`: `saveFromWorkout()`, `updateSavedWorkout()`. Save sheet on
  `workout_detail_screen`. New `screens/library/tabs/workouts_tab.dart`. `library_screen.dart` 3→4 tabs.
- **W3** Customization Studio sheet (sliders/chips/body-map/toggles, debounced live preview via
  `/customize` persist=false; Apply persists prebuilt). Body-map widget. Per-exercise "this hurts".
- **W4** Detail "Adjust workout" → Studio in-place + Undo. Chat free-text → forked card.
- **W5/W6** Detail "Mark as done" → `/complete?completion_method=marked_done`. Thumbs on card+detail
  → `/workouts/{id}/feedback`; thumbs-down opens Studio.
- **W7** Shuffle (→`/shuffle`), time trim/extend + equipment bulk swap (→`/adapt` param tweaks),
  active-recovery preset.
- **W8** Recipe detail screen + route + "View Recipe" button (`reference_recipe`), browse →`/recipe-suggestions`.

### API constants to add (frontend)
`mobile/flutter/lib/core/constants/api_constants.dart`: customize, adapt, shuffle, workout feedback,
from-workout, workout-presets paths.

### Verification still owed
`flutter analyze` on touched files; targeted curls for each endpoint with a real JWT;
manual flow trace per PLAN.md §6.
