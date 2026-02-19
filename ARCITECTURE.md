# FitWiz Workout Generation Architecture

Complete system documentation covering workout generation, pre-caching, invalidation, comeback mode, and injury handling.

---

## 1. Early Generation at Sign-Up

**Goal**: Utilize the 60-120 seconds of dead time while the user completes onboarding screens to pre-generate their first workouts.

**File**: `mobile/flutter/lib/screens/auth/sign_in_screen.dart`

### Flow

1. User taps "Sign in with Google" on the `SignInScreen`
2. `_signInWithGoogle()` calls `authStateProvider.notifier.signInWithGoogle()`
3. After successful sign-in, `_triggerEarlyGeneration()` is called **fire-and-forget** (line 81)
4. The method runs as a detached `Future<void>` so it does not block navigation

### `_triggerEarlyGeneration()` (line 98)

```
1. Gets userId from apiClient
2. Reads quiz data from preAuthQuizProvider
3. Builds payload via AIProfilePayloadBuilder.buildPayload(quizData)
4. Adds personal info (gender, age, height_cm, weight_kg, workout_days)
5. POST /users/{userId}/preferences  -> submits workout config to backend
6. GET  /workouts/today?user_id={userId} -> triggers backend auto-generation
```

The `/today` endpoint detects missing workouts and schedules background generation via `BackgroundTasks`. By the time the user finishes ~6 remaining onboarding screens (60-120s), workouts are often already generated and waiting.

**Failure handling**: If early generation fails, it's non-critical. The `WorkoutLoadingScreen` will trigger generation normally.

---

## 2. Backend Auto-Generation (`today.py`)

**File**: `backend/api/v1/workouts/today.py`

### `GET /today` Endpoint (line 345)

Returns today's workout or the next upcoming workout. **The hero card should ALWAYS show a workout** - if none exist, this endpoint triggers auto-generation.

**Parallel DB queries** (line 404): Three independent queries run concurrently via `asyncio.gather()` + `ThreadPoolExecutor(max_workers=15)`:

| Query | Purpose |
|-------|---------|
| `today_rows` | Today's incomplete workout (filtered by gym profile) |
| `future_rows` | Next upcoming workout in 30-day window |
| `completed_today_rows` | Today's completed workout |

**Gym profile filtering**: All queries filter by active gym profile via `_get_active_gym_profile_id()`. Users only see workouts for their currently active gym.

### Proactive Background Generation (line 498)

On **every** `/today` call, the endpoint checks for missing upcoming workouts:

```python
upcoming_missing = _get_upcoming_dates_needing_generation(
    db, user_id, selected_days, active_profile_id,
    max_dates=7, user_today_str=today_str
)
```

For each missing date, `auto_generate_workout()` is scheduled as a background task.

### `_get_upcoming_dates_needing_generation()` (line 222)

- Scans a **14-day window** from today
- Single DB query fetches all workouts in the range (not one query per day)
- Finds up to **7 scheduled days** (based on user's `workout_days` preference) without workouts
- Returns a `List[date]` of dates needing generation

### `auto_generate_workout()` (line 276)

Background task with dedup via `_active_background_generations` set:

```python
_active_background_generations: Set[str] = set()  # Key: "user_id:date_str"
```

**Safety guarantees**:
1. Checks `_active_background_generations` set to prevent duplicate in-flight tasks
2. Double-checks DB for existing workout (race condition prevention)
3. Checks for `status='generating'` placeholder (another request may have started it)
4. Catches all exceptions so background tasks never crash the server
5. Always clears the generation key in `finally` block

### `generate_next_day_background()` (line 118 in `generation.py`)

Pre-caches tomorrow's workout after workout completion:

- Called from `/today` when `has_completed_workout_today` is true (line 448)
- Semaphore-limited: `asyncio.Semaphore(50)` prevents overloading Gemini API
- Checks for existing workout and `status='generating'` before proceeding
- Resolves active gym profile for generation context

### Workout Day Configuration

- Flutter stores days as **1-indexed** (Mon=1..Sun=7)
- Python normalizes to **0-indexed** (Mon=0..Sun=6) in `_get_user_workout_days()` (line 170)
- `_is_today_a_workout_day()` checks if today matches user's schedule
- `_calculate_next_workout_date()` finds the nearest scheduled workout day

---

## 3. Workout Generation (`generation.py`)

**File**: `backend/api/v1/workouts/generation.py`

### `POST /generate` - Non-streaming (line 341)

`generate_workout(request, background_tasks)`:

**3-layer dedup**:

| Layer | Check | Purpose |
|-------|-------|---------|
| 1 | DB query for existing workout (non-cancelled) | Return existing if already generated |
| 2 | Insert placeholder with `status='generating'` | Prevent concurrent generation |
| 3 | `_active_background_generations` set (in `today.py`) | Prevent duplicate background tasks |

**Placeholder lifecycle**:
1. Insert placeholder: `{id: uuid, user_id, scheduled_date, status: 'generating', name: 'Generating...'}`
2. Generate workout via Gemini
3. Save real workout to DB
4. Delete placeholder

On error, the placeholder is cleaned up in exception handlers.

### `POST /generate-stream` - Streaming (line 1193)

`generate_workout_streaming(request, body)`:

- Rate limited: `15/minute` per user
- Returns **Server-Sent Events (SSE)** with event types:
  - `chunk` - Partial workout data as generated
  - `done` - Final complete workout
  - `error` - Error message
  - `already_generating` - Generation already in progress

**Idempotency checks** before streaming begins:
1. Check for `status='generating'` row -> return `already_generating` SSE event
2. Check for existing completed workout -> return `done` SSE event with full workout data

Time to first content: typically **< 500ms** vs 3-8s for full generation.

### Comeback Status Endpoint (line 193)

`GET /comeback-status`: Lightweight pre-generation check that returns comeback mode info before workout generation begins.

---

## 4. Frontend Loading Flow

### `WorkoutLoadingScreen` (post-onboarding)

**File**: `mobile/flutter/lib/screens/loading/workout_loading_screen.dart`

Shown after onboarding while workouts are being generated.

- **Polls immediately** on init (no 2s delay) - early generation may have already produced the workout
- Then polls every **5 seconds** via `Timer.periodic`
- **Max 30 polls** (~2.5 min at 5s intervals)
- Shows animated step progress: "Analyzing your fitness profile" -> "Setting up your AI coach" -> "Selecting exercises" -> "Building your plan" -> "Finalizing workout"
- On workout ready: shows 100% progress, 800ms pause, then navigates to home
- On max polls reached: navigates to home anyway (workout may still be generating)

### `TodayWorkoutNotifier` (home screen)

**File**: `mobile/flutter/lib/data/providers/today_workout_provider.dart`

Cache-first pattern with exponential backoff:

**Cache-first strategy**:
1. In-memory cache (`_inMemoryCache`) checked first - survives provider invalidation
2. If cached, display instantly and fetch fresh data silently in background
3. If no cache, show loading state and fetch from API

**Exponential backoff polling** (when `is_generating` is true):
- Sequence: **2s -> 4s -> 8s -> 16s -> 30s** (capped at 30s)
- Formula: `min(30, 2 * pow(2, min(pollCount, 4)))`
- Max **30 polls** before giving up

**30s cooldown after failures**:
- Static `_lastGenerationFailure` timestamp tracks last failure
- Static `_generationCooldown = Duration(seconds: 30)`
- Prevents 429 rate limit spam after failed generation
- Cleared on successful generation

**Background generation polling** (when `needs_generation` is true):
- Polls every **15 seconds** for background-generated workout
- **60 second** safety timeout
- Checks if `needsGeneration` and `isGenerating` flags have resolved

**Auto-generation trigger**:
- When `needs_generation` is true from `/today`, triggers `POST /generate-stream`
- Static `_isAutoGenerating` flag prevents duplicate generation calls across provider invalidation

### `WorkoutGenerationScreen` (onboarding)

**File**: `mobile/flutter/lib/screens/onboarding/workout_generation_screen.dart`

Streaming generation during onboarding with step-by-step progress UI. Uses `POST /generate-stream` for SSE-based real-time updates.

---

## 5. Invalidation System (`utils.py`)

**File**: `backend/api/v1/workouts/utils.py` (line 37)

### `invalidate_upcoming_workouts(user_id, reason, only_next=False)`

Deletes upcoming non-completed workouts so the next `/today` call regenerates them.

**Logic**:
1. Query all workouts where `scheduled_date >= today` and `is_completed = False`
2. Filter out workouts with `status='generating'` (protects in-flight generation)
3. If `only_next=True`: sort by date, keep only the earliest one
4. Delete matching workout IDs via `db.client.table("workouts").delete().in_("id", ids_to_delete)`
5. Log the deletion count and reason

**Returns**: Number of workouts deleted.

### Invalidation Triggers

| Trigger | File | `only_next` | Reason |
|---------|------|-------------|--------|
| Injury reported | `backend/api/v1/injuries.py:426` | `False` | `"injury reported: {body_part}"` |
| Exercise avoided | `backend/api/v1/exercise_preferences.py:983` | `False` | `"exercise avoided: {name}"` |
| Exercise avoidance removed | `backend/api/v1/exercise_preferences.py:1067` | `False` | `"exercise avoidance removed: {id}"` |
| Muscle avoidance updated | `backend/api/v1/exercise_preferences.py:1229` | `False` | `"muscle avoidance updated: {group}"` |
| Exercise queued | `backend/api/v1/users.py:2091` | `True` | `"exercise queued: {name}"` |

When `only_next=False`, **all** upcoming workouts are deleted and will regenerate on next `/today` call. Exercise queue changes use `only_next=True` since only the next workout needs the queued exercise.

---

## 6. Comeback Mode

### Detection: `get_user_comeback_status()` (utils.py line 2606)

A user is in comeback mode if:
1. Explicit `comeback_mode` flag set in user preferences, **OR**
2. No completed workout in **14+ days**

**Safeguards**:
- Accounts < 14 days old are **skipped** (not treated as comeback)
- Users with no workout history are treated as new users, not comeback

**Returns**: `{in_comeback_mode: bool, days_since_last_workout: int|None, reason: str}`

### Context: `get_comeback_context()` (utils.py line 2718)

Integrates with `ComebackService` (`backend/services/comeback_service.py`) for full break detection:

```python
{
    "needs_comeback": True,
    "break_status": {
        "days_off": int,
        "break_type": str,       # e.g., "short_break", "extended_break"
        "comeback_week": int,
        "in_comeback_mode": bool,
        "recommended_weeks": int,
        "user_age": int|None,
    },
    "adjustments": {
        "volume_multiplier": float,      # e.g., 0.6
        "intensity_multiplier": float,   # e.g., 0.7
        "extra_rest_seconds": int,       # e.g., 30
        "extra_warmup_minutes": int,
        "max_exercise_count": int,       # e.g., 5
        "avoid_movements": list,
        "focus_areas": list,
    },
    "prompt_context": str,         # For Gemini prompt injection
    "extra_warmup_minutes": int,
}
```

**Age-specific guidance**: Additional adjustments for users aged 50+, 60+, 70+ (logged at line 2762).

### Application: `apply_comeback_adjustments_to_exercises()` (utils.py line 2798)

Post-processes generated exercises:

| Adjustment | Formula | Minimum |
|-----------|---------|---------|
| Sets | `sets * volume_multiplier` | 2 |
| Reps | `reps * (volume_multiplier + 0.1)` | 6 |
| Weight | `weight_kg * intensity_multiplier` | Rounded to nearest 2.5 kg |
| Rest | `rest_seconds + extra_rest_seconds` | - |
| Exercise count | Truncate to `max_exercise_count` | - |

Each exercise gets a comeback note: `"[COMEBACK: {days_off} days off] Reduced intensity for safe return."`

### Activation: `start_comeback_mode_if_needed()` (utils.py line 2878)

Called during workout generation. Uses `ComebackService.should_trigger_comeback()` and `start_comeback_mode()` to create a comeback history record.

---

## 7. Injury UX Flow

### Frontend Flow

**Files**:
- `mobile/flutter/lib/screens/workout/active_workout_screen_refactored.dart` (line 2599)
- `mobile/flutter/lib/screens/workout/widgets/quit_workout_dialog.dart`

1. User taps quit during active workout -> `showQuitWorkoutDialog()` appears
2. Dialog shows reason chips including **"Pain/Injury"** (with `Icons.healing`)
3. User selects "Pain/Injury" and confirms quit
4. `_logWorkoutExit(result.reason, result.notes)` logs the exit
5. `context.pop()` closes the workout screen
6. **300ms delay** -> `context.push('/injuries/report')` navigates to injury report screen

### Backend Flow

**File**: `backend/api/v1/injuries.py` (line 384)

`POST /{user_id}/report`:

1. Creates injury record in database
2. Gets recommended rehab exercises via `_get_recommended_rehab_exercises(body_part)`
3. Calls `invalidate_upcoming_workouts(user_id, reason=f"injury reported: {body_part}")`
4. All upcoming non-completed workouts are deleted

### Injury-to-Muscle Mapping

**File**: `backend/api/v1/workouts/utils.py` (line 1895)

`INJURY_TO_AVOIDED_MUSCLES` maps **15 body parts** to muscle groups:

| Body Part | Avoided Muscles |
|-----------|----------------|
| shoulder | shoulders, chest, triceps, delts, anterior_delts, lateral_delts, rear_delts |
| back | back, lats, lower_back, traps, rhomboids, erector_spinae |
| lower_back | lower_back, back, erector_spinae, glutes, hamstrings |
| knee | quads, hamstrings, calves, legs, quadriceps, glutes |
| wrist | forearms, biceps, triceps, grip |
| ankle | calves, legs, tibialis, soleus, gastrocnemius |
| hip | glutes, hip_flexors, legs, quads, hamstrings, adductors, abductors |
| elbow | biceps, triceps, forearms, brachialis |
| neck | traps, shoulders, neck, upper_back |
| chest | chest, pectorals, shoulders, triceps |
| groin | adductors, hip_flexors, legs, quads |
| hamstring | hamstrings, glutes, legs |
| quad | quads, quadriceps, legs, knee |
| calf | calves, legs, ankle |
| rotator_cuff | shoulders, chest, delts, rotator_cuff |

**Matching**: Supports both exact matches and partial matches (e.g., "shoulder pain" -> "shoulder").

### Regeneration

After invalidation, the next `/today` call detects missing workouts and triggers auto-generation. The new workouts are generated with the injured muscles excluded via `get_muscles_to_avoid_from_injuries()` and `get_active_injuries_with_muscles()`, which are passed into the Gemini prompt context.

---

## 8. Files Changed (Recent Implementation)

### Backend Files

| File | Changes |
|------|---------|
| `backend/api/v1/workouts/today.py` | Parallel DB queries via `asyncio.gather()`, proactive background generation for up to 7 upcoming dates, gym profile filtering on all queries, pre-cache tomorrow after completion |
| `backend/api/v1/workouts/generation.py` | 3-layer dedup (placeholder + active set + DB check), `generate_next_day_background()` with semaphore (50 concurrent), comeback status endpoint, streaming SSE idempotency checks |
| `backend/api/v1/workouts/utils.py` | `invalidate_upcoming_workouts()` with `only_next` parameter, `INJURY_TO_AVOIDED_MUSCLES` mapping (15 body parts), `get_user_comeback_status()`, `get_comeback_context()`, `apply_comeback_adjustments_to_exercises()`, `start_comeback_mode_if_needed()` |
| `backend/api/v1/injuries.py` | `report_injury()` endpoint calls `invalidate_upcoming_workouts()` after injury report |

### Frontend Files

| File | Changes |
|------|---------|
| `mobile/flutter/lib/screens/auth/sign_in_screen.dart` | `_triggerEarlyGeneration()` fire-and-forget after Google sign-in, submits quiz preferences then triggers `/today` for background generation |
| `mobile/flutter/lib/data/providers/today_workout_provider.dart` | Cache-first pattern with in-memory cache, exponential backoff polling (2s->4s->8s->16s->30s), 30s cooldown after failures, background generation polling (15s interval, 60s timeout), static flags survive provider invalidation |
| `mobile/flutter/lib/screens/loading/workout_loading_screen.dart` | Immediate first poll (no 2s delay), 5s poll interval, max 30 polls, animated step progress, navigates to home on max polls |

---

## System Diagram

```
Sign-In Screen                    Onboarding Screens (60-120s)              Loading Screen
      |                                    |                                      |
      |-- _triggerEarlyGeneration() ------>|                                      |
      |   POST /users/{id}/preferences     |                                      |
      |   GET /workouts/today ------------>|-- Backend auto_generate_workout() -->|
      |                                    |   (background, up to 7 dates)        |
      |                                    |                                      |-- Poll every 5s
      |                                    |                                      |-- Max 30 polls
      |                                    |                                      |-- Navigate to Home
                                                                                  |
                                                                                  v
                                                                            Home Screen
                                                                                  |
                                                                         TodayWorkoutNotifier
                                                                                  |
                                                                         Cache-first display
                                                                                  |
                                                                         Auto-gen if needed
                                                                         (exponential backoff)
```

```
Injury Flow:
Active Workout -> Quit Dialog -> "Pain/Injury" -> 300ms delay -> /injuries/report
                                                                        |
                                                               Backend: report_injury()
                                                                        |
                                                          invalidate_upcoming_workouts()
                                                                        |
                                                          Next /today -> auto-regenerate
                                                          (without injured muscles)
```

```
Invalidation Triggers:
injury reported ---------> invalidate ALL upcoming
exercise avoided --------> invalidate ALL upcoming
exercise unavoided ------> invalidate ALL upcoming
muscle avoidance --------> invalidate ALL upcoming
exercise queued ---------> invalidate NEXT workout only
```
