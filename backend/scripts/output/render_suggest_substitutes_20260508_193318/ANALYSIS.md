# /suggest-substitutes Validation — Analysis

**Run:** `render_suggest_substitutes_20260508_193318` — 100 scenarios
**Endpoint:** `POST /api/v1/exercise-preferences/suggest-substitutes` (algorithmic, no AI)
**Verdict:** **FAILED** — 59/100 (59%) returned 0 substitutes.

This is identical to the prior run (`192401`); both predate the schema-fix deploy.

---

## Headline metrics (vs checklist Section AAA / BBB)

| Metric | Required (BBB) | Observed |
|---|---|---|
| Zero-substitute rate | < 1% | **59%** ❌ |
| n_substitutes distribution | all ≥3 | 0=59, 1=2, 2=1, 3=32, 4=5, 6=1 ❌ |
| `substitutes_with_library_id` per row | ≥3 | **0 across all 100 rows** ❌ |
| HTTP 200 rate | 100% | 100% ✓ |
| `all_safe_for_reason` | True | True ✓ (trivially — empty lists "safe") |

The library-id metric is the smoking gun: NOT ONE substitute on this run was sourced
from the `exercise_library` table — meaning every `is_safe_for_reason` flag is just
metadata on synthetic curated names from `SAFE_ALTERNATIVES` / `EXERCISE_SUBSTITUTES`.

---

## Root causes (5 bugs, all in `backend/api/v1/exercise_preferences_endpoints.py`)

### Bug 1 (CRITICAL) — Wrong column name on library SELECT

```python
# old (broken):
.select("id", "name", "body_part", "equipment", "gif_url")  # "name" doesn't exist
# correct table is exercise_library_cleaned which DOES have `name` —
# but raw exercise_library has `exercise_name` instead.
```

`exercise_library` (raw) does not have a `name` column — it's `exercise_name`. So
`row.get("name", "")` returned `""` for every row → all results skipped silently.
Hence `substitutes_with_library_id=0` across all 100 scenarios.

### Bug 2 (CRITICAL) — Wrong column for muscle filtering

`body_part` column on raw `exercise_library` has only 11 coarse values: `waist, chest,
back, full body, shoulders, upper arms, upper legs, lower arms, cardio, lower legs, neck`.

The endpoint queried `body_part ILIKE '%biceps%'` (and 13 other muscle keywords) —
NONE of which exist as `body_part` values. Every fine-grained muscle query
(biceps, triceps, quadriceps, hamstrings, glutes, calves, core, abs, forearms, lower_back)
returned 0 hits. Verified empirically:

```
ilike body_part '%biceps%'    →  0 hits
ilike body_part '%triceps%'   →  0 hits
ilike body_part '%quadriceps%' →  0 hits
ilike body_part '%hamstrings%' →  0 hits
ilike body_part '%glutes%'    →  0 hits
ilike body_part '%calves%'    →  0 hits
ilike body_part '%core%'      →  0 hits
ilike body_part '%abs%'       →  0 hits
```

### Bug 3 — `get_exercise_muscle_group()` returned None for many exercises

Plank, Side Plank, Russian Twist, Hanging Leg Raise, Ab Wheel Rollout, Crunch,
Box Jump, Burpee, Mountain Climber, Bicep Curl, Hammer Curl, Tricep Extension,
Cable Fly, Pec Deck, Calf Raise — all returned `None` because the keyword list
was incomplete. With `muscle_group=None`, step 3 (library search) was skipped
entirely, so even if the column names were right, these exercises would still
have returned 0.

### Bug 4 — `SAFE_ALTERNATIVES` covers only 7 of 56 possible injury×muscle combos

`SAFE_ALTERNATIVES` is keyed `[injury_type][muscle_group]` and only has entries for:
- knee × {quadriceps, hamstrings, glutes}
- shoulder × {chest, shoulders}
- lower_back × {back, glutes}

Wrist, elbow, hip, ankle, neck have ZERO entries. Step 1 silently fell through
for any of these injury types — combined with bugs 1+2, this meant 0 substitutes.

### Bug 5 — `EXERCISE_SUBSTITUTES` dict has only 15 keys

Bench press, dumbbell press, push-ups, barbell row, pull-ups, lat pulldown, overhead
press, lateral raise, squat, leg press, deadlift, barbell curl, tricep pushdown.

Most CSV scenarios used names not in this dict: "Bicep Curl" (only "barbell curl"
matches), "Hammer Curl", "Tricep Extension", "Plank", "Box Jump", "Crunch", "Face
Pull", "Diamond Push-up", "Archer Push-up", "Inverted Row", "Cable Fly", "Pec Deck",
"Hanging Leg Raise", "Ab Wheel Rollout", "Burpee", "Mountain Climber", "Side Plank".

---

## Fixes shipped (in code, not deployed yet)

| Fix | Location | Description |
|---|---|---|
| **Library-table switch** | `_query_library_by_muscle()` | Now queries `exercise_library_cleaned` (the materialized view per `project_exercise_library_mv` memory — 51× faster) |
| **Schema correction** | `_query_library_by_muscle()` | Reads `name` (cleaned) + `display_body_part` (16 canonical muscle values) + `avoid_if[]` (authoritative safety) |
| **Muscle-group expansion** | `get_exercise_muscle_group()` | 14 categories: cardio, core, calves, forearms, triceps, biceps, hamstrings, glutes, quadriceps, chest, back, shoulders. Order: most-specific-first. |
| **`MUSCLE_TO_LIBRARY_QUERY`** | new dict | Maps logical muscle name → `display_body_part` exact match (Quadriceps, Hamstrings, Glutes, Calves, Chest, Back, Shoulders, Biceps, Triceps, Forearms, Core, Hips, Lower Back) or `category=cardio` |
| **`avoid_if[]` safety filter** | `_is_unsafe_for_injury()` | Replaces brittle name-substring contraindication with library's authoritative `avoid_if[]` metadata |
| **`INJURY_SAFE_MUSCLE_EXPANSION`** | new dict | When injury fully restricts the original muscle, query OTHER muscle groups the user CAN safely train |
| **Token-based fallback search** | step 4 | When same-muscle library returns < 3, search by exercise-name tokens against `name ILIKE` |
| **Curated lists removed** | per user feedback | All substitutes now sourced exclusively from `exercise_library_cleaned` so every result has `library_id + gif_url` |

Local smoke confirms 100% library coverage post-fix:

```
quadriceps  : 5 rows | sample: '180 Jump Turns'
hamstrings  : 5 rows | sample: '3 Leg Dog Pose'
glutes      : 5 rows | sample: '90 To 90 Stretch'
calves      : 5 rows | sample: 'Agility Ladder Skipping 1 Touch'
chest       : 5 rows | sample: 'Above Head Chest Stretch'
back        : 5 rows | sample: 'Active Hang'
shoulders   : 5 rows | sample: '4 Corners Curtsy'
biceps      : 5 rows | sample: 'Alternate Bicep Curl Resistance Band'
triceps     : 5 rows | sample: '3 Leg Chatarunga Pose'
forearms    : 5 rows | sample: 'Band Wrist Curl'
core        : 5 rows | sample: '3-4 Sit-Up'
abs         : 5 rows | sample: '3-4 Sit-Up'
cardio      : 5 rows | sample: '4 Corners Curtsy'
lower_back  : 5 rows | sample: '45 Degree Hyperextension'
hips        : 5 rows | sample: 'A-Skip'
```

---

## Re-run expectations (post-deploy)

| Metric | Before | After (predicted) |
|---|---|---|
| Zero-substitute rate | 59% | < 2% |
| `substitutes_with_library_id > 0` rate | 0% | **100%** |
| Mean n_substitutes | 1.5 | 5–7 |
| Latency p95 | n/a | < 400ms (warm Render, MV) |
