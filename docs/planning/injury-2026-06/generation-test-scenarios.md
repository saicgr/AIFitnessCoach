# Injury generation test scenarios — live Render API safety matrix

**Purpose:** measure what the LIVE deployed generator actually produces for injured
users, to drive an evidence-based safety fix (Phase 0 of the injury plan).

**How it runs:** `backend/scripts/injury_test_harness.py` hits the real Render API.
Per scenario it admin-creates a confirmed throwaway user → `/auth/sync` → sets the
profile via SQL → calls the generation endpoint **N times** (Gemini is stochastic) →
cross-checks every produced exercise against `exercise_safety_index_mat` → records the
worst verdict → deletes the user. **Rows are written here ONE BY ONE as each scenario
finishes** (resumable: a restart skips rows already recorded).

**Verdict:** `PASS` = no `<injury>_safe=FALSE` for the user's injuries + ≥ floor real
exercises · `LEAK` = ≥1 contraindicated exercise shipped · `EMPTY` = 0 exercises ·
`THIN` = ≤2 exercises · `500` = crash. Only the 8 jointed injuries have a vetted
`*_safe` column (shoulder/lower_back/knee/elbow/wrist/ankle/hip/neck); muscle-area
chips have none → their rows show the produced exercises for the Opus pass to judge.

---

## Results matrix (written live, one row per scenario as it completes)

| # | injuries | equip | lvl | goal | focus | path | leaks/runs | sample unsafe (col/pattern) | VERDICT |
|---|----------|-------|-----|------|-------|------|-----------|------------------------------|---------|
| 1 | none | full_gym | beginner | lose_weight | full_body | stream | 0/2 | — | **PASS** |
| 2 | lower_back | full_gym | beginner | lose_weight | full_body | stream | 1/1 | Barbell Reverse Deadlift[lower_back_safe/hinge]; Dumbbell Bent-Over Face Pull[lower_back_safe/horizontal_pull]; 45 degree side bend[lower_back_safe/None]; Kettlebell Swing[lower_back_safe/hinge] | **LEAK** |
| 3 | knees | full_gym | beginner | lose_weight | full_body | stream | 2/2 | Dumbbell Goblet Reverse Lunge[knee_safe/squat]; barbell full squat(back)[knee_safe/squat]; barbell full squat side pov[knee_safe/squat]; Dumbbell Offset Squat[knee_safe/squat] | **LEAK** |
| 4 | shoulders | full_gym | beginner | build_muscle | full_body | stream | 2/2 | Assisted Parallel Close-Grip Pull-up[shoulder_safe/overhead_pull]; Kettlebell Walkover Pushup[shoulder_safe/horizontal_push]; Barbell seated overhead press[shoulder_safe/overhead_press]; Assisted Close-grip Underhand Chin-up[shoulder_safe/overhead_pull] | **LEAK** |
| 5 | wrists | full_gym | beginner | build_muscle | full_body | stream | 1/2 | Landmine Lunge to Overhead Press[wrist_safe/overhead_press] | **LEAK** |
| 6 | elbows | full_gym | beginner | build_muscle | full_body | stream | 0/2 | — | **PASS** |
| 7 | hips | full_gym | beginner | lose_weight | full_body | stream | 2/2 | barbell full squat(back)[hip_safe/squat]; 45 degree bicycle twist knee to elbow[hip_safe/loaded_rotation]; Kettlebell Swing[hip_safe/hinge]; Kettlebell Snatch[hip_safe/hinge] | **LEAK** |
| 8 | ankles | full_gym | beginner | lose_weight | full_body | stream | 2/2 | Bulgarian Split Squat[ankle_safe/squat]; barbell full squat(back)[ankle_safe/squat]; Kettlebell Snatch[ankle_safe/hinge]; Dumbbell Goblet Reverse Lunge[ankle_safe/squat] | **LEAK** |
| 9 | neck | full_gym | beginner | build_muscle | full_body | stream | 2/2 | Assisted Parallel Close-Grip Pull-up[neck_safe/overhead_pull]; Dumbbell Single-Arm Upright Row[neck_safe/overhead_press]; 45 degree twisting hyperextension[neck_safe/loaded_rotation]; Barbell seated overhead press[neck_safe/overhead_press] | **LEAK** |
| 10 | upper_back | full_gym | beginner | build_muscle | full_body | stream | 0/2 | — | **PASS** |
| 11 | chest | full_gym | beginner | build_muscle | full_body | stream | 0/2 | — | **PASS** |
| 12 | biceps | full_gym | beginner | build_muscle | full_body | stream | 0/2 | — | **PASS** |
| 13 | triceps | full_gym | beginner | build_muscle | full_body | stream | 0/2 | — | **PASS** |
| 14 | forearms | full_gym | beginner | build_muscle | full_body | stream | 0/2 | — | **PASS** |
| 15 | abs | full_gym | beginner | lose_weight | full_body | stream | 0/2 | — | **PASS** |
| 16 | glutes | full_gym | beginner | lose_weight | full_body | stream | 0/2 | — | **PASS** |
| 17 | groin | full_gym | beginner | lose_weight | full_body | stream | 0/2 | — | **PASS** |
| 18 | quads | full_gym | beginner | lose_weight | full_body | stream | 0/2 | — | **PASS** |
| 19 | hamstrings | full_gym | beginner | lose_weight | full_body | stream | 0/2 | — | **PASS** |
| 20 | calves | full_gym | beginner | lose_weight | full_body | stream | 0/2 | — | **PASS** |
| 21 | other: carpal tunnel | full_gym | beginner | lose_weight | full_body | stream | 0/2 | — | **PASS** |
| 22 | lower_back,knees,shoulders | full_gym | beginner | lose_weight | full_body | stream | 2/2 | Barbell Reverse Deadlift[lower_back_safe/hinge]; barbell lunges on the spot[knee_safe/None]; Barbell Upright Row[lower_back_safe/overhead_press]; Dumbbell Offset Squat[lower_back_safe/squat] | **LEAK** |
| 23 | knees,ankles | full_gym | beginner | lose_weight | full_body | stream | 2/2 | Dumbbell Goblet Reverse Lunge[knee_safe/squat]; barbell full squat side pov[knee_safe/squat]; 45 degree Bicycle Twisting Crunch[knee_safe/loaded_rotation]; barbell lunges on the spot[knee_safe/None] | **LEAK** |
| 24 | shoulders,wrists,elbows | full_gym | intermediate | build_muscle | full_body | stream | 2/2 | Assisted Parallel Close-Grip Pull-up[shoulder_safe/overhead_pull]; Dumbbell Lying on Floor Chest Press[shoulder_safe/horizontal_push]; Barbell seated overhead press[shoulder_safe/overhead_press]; svend press flat bench[shoulder_safe/None] | **LEAK** |
| 25 | lower_back,hips | full_gym | beginner | lose_weight | full_body | stream | 2/2 | Dumbbell Goblet Reverse Lunge[hip_safe/squat]; Dumbbell Bent-Over Face Pull[lower_back_safe/horizontal_pull]; Dumbbell Offset Squat[lower_back_safe/squat]; 90 degree heel touch[lower_back_safe/None] | **LEAK** |
| 26 | knees,lower_back,wrists,shoulders | full_gym | beginner | lose_weight | full_body | stream | 2/2 | Assisted Parallel Close-Grip Pull-up[lower_back_safe/overhead_pull]; svend press flat bench[shoulder_safe/None]; Barbell Upright Row[lower_back_safe/overhead_press]; barbell full squat side pov[knee_safe/squat] | **LEAK** |
| 27 | none | bodyweight | beginner | lose_weight | full_body | stream | 0/2 | — | **PASS** |
| 28 | lower_back | bodyweight | beginner | lose_weight | full_body | stream | 2/2 | Cossack Squat[lower_back_safe/squat]; Alternating Superman[lower_back_safe/None]; 90 degree heel touch[lower_back_safe/None]; Air Squat[lower_back_safe/squat] | **LEAK** |
| 29 | knees | bodyweight | beginner | lose_weight | full_body | stream | 2/2 | bodyweight squats[knee_safe/None]; Cossack Squat[knee_safe/squat]; Air Squat[knee_safe/squat]; Bulgarian Split Squat[knee_safe/squat] | **LEAK** |
| 30 | lower_back,knees | bodyweight | beginner | lose_weight | full_body | stream | 2/2 | Bulgarian Split Squat[knee_safe/squat]; bodyweight squats[knee_safe/None]; Back squeeze[lower_back_safe/None]; 3-4 Sit-up[lower_back_safe/hinge] | **LEAK** |
| 31 | shoulders | bodyweight | intermediate | build_muscle | full_body | stream | 2/2 | Archer Push-Up[shoulder_safe/horizontal_push]; bodyweight Bent-Over rear delt fly[shoulder_safe/horizontal_push]; Plank Pushup[shoulder_safe/horizontal_push]; Push-Up Plus[shoulder_safe/horizontal_push] | **LEAK** |
| 32 | lower_back | full_gym | beginner | build_muscle | full_body_push | stream | 2/2 | Assisted Parallel Close-Grip Pull-up[lower_back_safe/overhead_pull]; Kettlebell Single-Arm Clean and Press[lower_back_safe/hinge]; Dumbbell Offset Squat[lower_back_safe/squat] | **LEAK** |
| 33 | lower_back | full_gym | beginner | build_muscle | full_body_pull | stream | 2/2 | Assisted Close-grip Underhand Chin-up[lower_back_safe/overhead_pull]; Back squeeze[lower_back_safe/None]; Barbell Rack Pull[lower_back_safe/None]; Cable Pulldown[lower_back_safe/None] | **LEAK** |
| 34 | lower_back | full_gym | beginner | lose_weight | legs | stream | 2/2 | Barbell Calf Jump[lower_back_safe/plyometric]; Landmine Squat and Press[lower_back_safe/squat]; Cossack Squat[lower_back_safe/squat]; Landmine Lunge to Overhead Press[lower_back_safe/overhead_press] | **LEAK** |
| 35 | knees | full_gym | beginner | lose_weight | legs | stream | 2/2 | Barbell lunges[knee_safe/None]; Dumbbell Goblet Reverse Lunge[knee_safe/squat]; barbell full squat(back)[knee_safe/squat]; Landmine Squat and Press[knee_safe/squat] | **LEAK** |
| 36 | shoulders | full_gym | intermediate | build_muscle | full_body_push | stream | 2/2 | Assisted Parallel Close-Grip Pull-up[shoulder_safe/overhead_pull]; svend press flat bench[shoulder_safe/None]; Kettlebell Walkover Pushup[shoulder_safe/horizontal_push]; Archer Push-Up[shoulder_safe/horizontal_push] | **LEAK** |
| 37 | lower_back | full_gym | intermediate | get_stronger | full_body | stream | 2/2 | Assisted Parallel Close-Grip Pull-up[lower_back_safe/overhead_pull]; Dumbbell Bent-Over Face Pull[lower_back_safe/horizontal_pull]; 45 degree twisting hyperextension[lower_back_safe/loaded_rotation]; Long Lever Plank[lower_back_safe/horizontal_push] | **LEAK** |
| 38 | lower_back | full_gym | advanced | get_stronger | full_body | stream | 2/2 | Barbell Reverse Deadlift[lower_back_safe/hinge]; Barbell seated overhead press[lower_back_safe/overhead_press]; Assisted Parallel Close-Grip Pull-up[lower_back_safe/overhead_pull]; 45 degree side bend[lower_back_safe/None] | **LEAK** |
| 39 | knees | full_gym | intermediate | get_stronger | legs | stream | 2/2 | Dumbbell Goblet Reverse Lunge[knee_safe/squat]; barbell lunges on the spot[knee_safe/None]; barbell full squat side pov[knee_safe/squat]; Dumbbell Offset Squat[knee_safe/squat] | **LEAK** |
| 40 | lower_back | full_gym | beginner | lose_weight | full_body | RAG | 0/2 |  | **EMPTY** |
| 41 | knees | full_gym | beginner | lose_weight | full_body | RAG | 0/2 |  | **EMPTY** |
| 42 | lower_back,knees,shoulders | full_gym | beginner | lose_weight | full_body | RAG | 0/2 |  | **EMPTY** |
| 43 | shoulders | bodyweight | beginner | build_muscle | full_body | RAG | 0/2 |  | **EMPTY** |
| 44 | abs,lower_back | full_gym | beginner | lose_weight | full_body | stream | 2/2 | 45 degree twisting hyperextension[lower_back_safe/loaded_rotation]; Long Lever Plank[lower_back_safe/horizontal_push]; Barbell Deadlift[lower_back_safe/hinge]; Kettlebell Swing[lower_back_safe/hinge] | **LEAK** |
| 45 | hamstrings,lower_back | full_gym | beginner | lose_weight | full_body | stream | 2/2 | Barbell seated overhead press[lower_back_safe/overhead_press]; 90 degree heel touch[lower_back_safe/None]; Barbell Deadlift[lower_back_safe/hinge]; Kettlebell Swing[lower_back_safe/hinge] | **LEAK** |
| 46 | wrists | full_gym | beginner | build_muscle | full_body_push | stream | 2/2 | Archer Push-Up[wrist_safe/horizontal_push]; Dumbbell Press Squat[wrist_safe/horizontal_push]; Kettlebell Single-Arm Clean and Press[wrist_safe/hinge]; Kettlebell Walkover Pushup[wrist_safe/horizontal_push] | **LEAK** |
| 47 | ankles | full_gym | beginner | lose_weight | legs | stream | 2/2 | Dumbbell Goblet Reverse Lunge[ankle_safe/squat]; barbell full squat side pov[ankle_safe/squat]; Barbell Calf Jump[ankle_safe/plyometric] | **LEAK** |
| 48 | neck | full_gym | intermediate | build_muscle | full_body_push | stream | 2/2 | Assisted Close-grip Underhand Chin-up[neck_safe/overhead_pull]; Barbell Clean and Press[neck_safe/hinge] | **LEAK** |
| 49 | hips,knees | full_gym | beginner | lose_weight | legs | stream | 2/2 | barbell lunges on the spot[knee_safe/None]; bulgarian split squat right bodyweight side view[hip_safe/squat]; barbell full squat(back)[hip_safe/squat]; Dumbbell Offset Squat[knee_safe/squat] | **LEAK** |
| 50 | none | full_gym | beginner | lose_weight | full_body | stream | 0/2 | — | **PASS** |

---

## Opus analysis (Phase 0.3)

**Corpus:** 50 scenarios × 2 runs against live Render, cross-checked vs
`exercise_safety_index_mat`, plus live backend logs captured during the run.
Corrected verdict tally (the harness's original `"500" in r.text` substring check
falsely flagged successful generations whose SSE contained a calorie/weight number
`500` — recomputed from the reliable per-run `n_ex`/`n_leak` data):

```
LEAK 30 · PASS 16 · EMPTY 4   (0 genuine HTTP 500s — all 23 "500" were the substring bug)
LEAK:  2,3,4,5,7,8,9, 22,23,24,25,26,28,29,30,31,32,33,34,35,36,37,38,39, 44,45,46,47,48,49
PASS:  1,6,10,11,12,13,14,15,16,17,18,19,20,21,27,50
EMPTY: 40,41,42,43   (RAG path)
```

### Failure modes (evidence-grounded)

**FM-1 — `/generate-stream` has NO injury gate (the headline, 30 LEAK).**
Every JOINT injury and every multi-injury combo ships contraindicated movements:
- `lower_back` → Barbell Deadlift, Barbell Reverse Deadlift, Kettlebell Swing (all `lower_back_safe=FALSE`, pattern=`hinge`)
- `knees` → Goblet Reverse Lunge, Barbell Full Squat, Offset Squat (`knee_safe=FALSE`, `squat`)
- `shoulders` → Seated Overhead Press, Close-Grip Pull-up, Walkover Pushup (`shoulder_safe=FALSE`, `overhead_press`/`overhead_pull`/`horizontal_push`)
- `wrists`/`ankles`/`neck`/`hips` → analogous leaks
- multi (#22 `lower_back,knees,shoulders`) → **7/7 unsafe**
Root cause: the streaming path passes injuries to **neither** the Gemini prompt
**nor** any post-filter. Its only injury-adjacent guard is `avoided_muscles` (muscle
chips), which doesn't cover the 8 jointed `*_safe` columns and isn't even populated
from the injury list for joints.

**FM-2 — "PASS" is UNVERIFIED for the 13 muscle-area chips.** `chest/biceps/triceps/
forearms/abs/glutes/groin/quads/hamstrings/calves/upper_back` + `other` (#10–21) show
PASS only because the safety index has **no `*_safe` column** to check them against —
the harness literally cannot detect a leak there. The only TRULY-safe passes are the
`none` controls (#1/#27/#50) and joints that leaked nothing by luck (#6 elbows).
→ Phase-1 must also right-size `avoided_muscles` for these chips (already broadly wired
via `get_muscles_to_avoid_from_injuries`; keep + verify, don't regress).

**FM-3 — RAG path (`/today` auto-gen) collapses to ALL STRETCHES for injured users.**
Live logs: shoulders/knees/multi → `fetch_safe_candidates returned 0 results …
clearing candidate pool` → `after_injury_filter=0 → after_avoided_muscles=0 →
pre_variety=0` → safe-pool backfill fires but the surviving pool is stretch-dominated
→ `AI selected 28 unique: ['Seated Side Stretch','Elbow Flexor Stretch','Wrist Extensor
Stretch','Standing Calf Stretch', …]`. A stretch-only "workout" is a degraded workout
(violates "no stretches, just works"). The matrix marked these EMPTY because the read
raced the BG-GEN poll window; the logs reveal the real failure is stretch-collapse.

**FM-4 — RAG path `.single()` 0-rows → HTTP 500.** `generation_endpoints.py:1710`
refetches the just-updated placeholder with `.single().execute()`; under a concurrent
generation (or the harness's delete-between-runs) the placeholder is gone → `PGRST116
Cannot coerce the result to a single JSON object` → 500. A real generation crash.

**FM-5 — FK-race 404 on placeholder insert.** BG-GEN from `/today` fires before
`auth_sync` creates `public.users` → `workouts_user_id_fkey` violation → `db.get_user`
None → 404. Largely a test artifact (sync precedes gen in the real client flow) but
also a fresh-install race; the placeholder insert already fails-soft (sets
`placeholder_id=None`), and today.py logs+skips. Low priority; monitor only.

**FM-6 — AI-selector duplicate indices** (`AI returned duplicate index N, skipping` →
`Only got 9/12 unique`) shrink the candidate pool, compounding FM-3's thinness. Quality
nit, not a safety leak; out of Phase-1 scope.

### Phase-1 fix spec (drives the implementation)

1. **Shared chokepoint — `enforce_injury_safety(exercises, injuries, *, equipment,
   focus_areas, difficulty_ceiling)`** (`services/exercise_rag/injury_guard.py`).
   Batch-joins each exercise name to `exercise_safety_index_mat`, DROPS any whose
   `<injury>_safe IS FALSE` for an active injury (reuse `_resolve_injury_columns`),
   and REPLACES each drop from `fetch_safe_candidates` (cloning the structural
   fields — sets/reps/rest/set_targets — of a survivor so the replacement is a valid,
   already-targeted exercise). The durable invariant at one chokepoint.
2. **Streaming (FM-1):** read injuries via `get_active_injuries_with_muscles` in the
   gather; pass them into the Gemini prompt (prevention) AND call
   `enforce_injury_safety` right after `validate_set_targets_strict` (guarantee).
3. **RAG (FM-3/FM-4):** call `enforce_injury_safety` on the final list before persist
   (belt-and-suspenders over the existing candidate gate); fix the `.single()` 500 to
   fall back to the in-memory `update_payload` on 0 rows instead of raising.
4. **Acceptance:** re-run this matrix → every joint + multi row PASS (zero
   `*_safe=FALSE`), no 500/EMPTY; codify as `test_injury_safety_matrix.py`.
