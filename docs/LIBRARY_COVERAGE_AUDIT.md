# Exercise Library Coverage Audit (2026-05-09)

Read-only audit run before rewriting `backend/scripts/build_canonical_map.py`.
Goal: for each commonly-cited program-exercise name, identify whether the failure is:

- **Matcher bug** — library has a correct row (image+video populated) but the old matcher missed it.
- **Library gap (needs_media_production)** — basic version is genuinely missing OR exists but lacks `image_url`/`video_url`.
- **Niche-only** — only obscure variants exist; the basic name has no equivalent at all.

`blessed` = `image_url IS NOT NULL AND image_url <> '' AND video_url IS NOT NULL AND video_url <> ''`.

## Findings per cited exercise

### plank / forearm plank / elbow plank
- **Plain `Plank` row: ABSENT** from `exercise_library_cleaned` entirely.
- Closest existing: `Plank On Elbows` (Bodyweight) — blessed. This IS the canonical "plank".
- Niche variants present and blessed: `Plank Iytw`, `Plank Jack`, `Plank Lunge`, `Plank Cross Knee Drive`, `Plank Pushup`, `Plank Reach Through`, `Plank Reverse Fly With Bottle`, `Plank Shoulder Taps`, `Side Plank`, `Plank Individual Arm Reach`, `Plank Knee Tucks`.
- **Old matcher failure**: 432 programs use "plank" → matched to `Plank Iytw` because trigram tied for top. The CORRECT match is `Plank On Elbows`. Matcher bug + no plain "Plank" row.
- **Verdict**: matcher bug — alias `plank → Plank On Elbows`.

### pull-up / pull up / pullup / chin-up
- **Plain `Pull-Up` row: ABSENT**.
- Blessed variants: `Pull-Up Normal Grip`, `Pull-Up Wide-Grip`, `Pull-Up Wide-Grip Front View`, `Chin-Up`, `Band Pull-Up` (resistance band, REGRESSION), `Archer Pull-Up`, `Kipping Pull-Up`, `Commando Pull-Up`, `Bench Pull-Ups`, plus many Assisted variants.
- **Old matcher failure**: 193 programs use "pull-up" → matched to `Band Pull-Up` (band-assisted regression). Should match `Pull-Up Normal Grip`.
- **Verdict**: matcher bug — alias `pull-up / pullup / pull ups → Pull-Up Normal Grip`.

### leg press
- Plain `Leg Press` row EXISTS (Leg Press Machine) — but **`has_video=false`** (image only). NOT blessed.
- Blessed alternatives: `Leg Press Machine Normal Stance`, `Leg Press Machine Close Stance`, `Horizontal Leg Press`, `Band Leg Press` (resistance band — wrong equipment).
- **Old matcher failure**: 140 programs use "leg press" → matched to `Band Leg Press` (band) because the plain "Leg Press" lacks video so it's filtered out of blessed.
- **Verdict**: library gap — `Leg Press` row needs a video. Best alias today: `leg press → Leg Press Machine Normal Stance`. Tag for media production.

### face pull
- Plain `Cable Face Pull` row EXISTS — but **`has_image=false, has_video=false`**.
- Blessed alternatives: `Cable Face Pull With Rope`, `Band Face Pull`, `Resistance Band Face Pull`, `Dumbbell Bent-Over Face Pull`, `Suspension Trainer With Grips Face Pull`, `Jump Rope Face Pull` (literal jump rope).
- **Old matcher failure**: 115 programs use "face pull" → matched to `Band Face Pull`. The correct match is `Cable Face Pull With Rope` (cable is the standard equipment for "face pull" by industry convention).
- **Verdict**: library gap (Cable Face Pull plain has no media) + matcher bug. Alias today: `face pull → Cable Face Pull With Rope`. Production: add media to plain `Cable Face Pull`.
- For `face pull (rope)`: parenthetical equipment hint not handled by old normalizer. Same target — `Cable Face Pull With Rope`.

### lat pulldown / lat pull down
- Plain `Lat Pulldown` row EXISTS (Lat Pulldown Machine) — but **`has_video=false`**.
- Blessed alternatives: `Lat Pull Down Normal Grip`, `Lat Pull Down Wide-Grip`, `Lat Pull Down Close-Grip`, `V Bar Lat Pull Down`, `Reverse Grip Lat Pull Down`, `Cable Close-Grip Front Lat Pulldown`, `Behind Neck Lat Pull Down Machine`.
- **Old matcher failure**: `lat pulldown (machine)` → matched to `Behind Neck Lat Pull Down Machine` (niche behind-neck variant) because parenthetical not handled.
- **Verdict**: matcher bug. Alias: `lat pulldown / lat pull down / lat pulldown (machine) → Lat Pull Down Normal Grip`. Production: add video to plain `Lat Pulldown`.

### glute ham raise / GHR
- **No `Glute Ham Raise` or `Glute-Ham Raise` row at all.**
- Closest related (different exercise): `Nordic Hamstring Curl With Partner` (the bodyweight regression of GHR — this is actually a defensible substitution).
- **Old matcher failure**: 10 programs use "glute ham raise" → matched to `Calf Raise` (totally wrong — trigram on "raise"). Composite 0.39.
- **Verdict**: real library gap. `needs_media_production` for `Glute Ham Raise`. Alternative swap-in-prompt: `Nordic Hamstring Curl With Partner`.

### dumbbell shrug
- Blessed: `Dumbbell Shrugs` (literal plural). 14 other shrug variants blessed.
- **Old matcher failure**: composite 0.51, movement=✗ (singular vs plural). Should be a near-100 match.
- **Verdict**: pure matcher bug — singularization missing. New strategy A0 fixes this.

### good morning
- Blessed: `Good Mornings` (plural, bodyweight), `Good Mornings Barbell`, `Good Mornings Dumbbells`, `Good Mornings Kettlebell`, `Barbell Good Morning`, `Barbell Seated Good Morning`, `Barbell Zercher Good Morning`, `Dumbbell Goblet Good Morning`, `Plate Good Morning`, `Plate Good Morning Anterior`, `Good Morning Resistance Band`.
- Non-blessed: `Bodyweight Good Morning` (no media), `Good Morning Resistace Band` (typo, no media).
- **Old matcher failure**: composite 0.50, movement=✗. Singular vs plural again.
- **Verdict**: pure matcher bug — singularization fixes this. Alias `good morning → Good Mornings`.

### incline bench press / incline barbell press
- Blessed: `Barbell Incline Bench Press`, `Dumbbell Incline Bench Press`, `Band Incline Bench Press`, `Barbell Pause Incline Bench Press`.
- **Old matcher failure**: 17 programs use "incline barbell press" → matched to `Barbell Incline Bench Press` correctly BUT with composite 0.76, movement=✗ body=✗ flagged ✗. The match itself is right, the signal flags were wrong.
- **Verdict**: matcher signal-correctness bug (movement_match should fire on "press", body_region should fire on chest/bench). Map is correct; metadata is wrong. New movement-phrase logic ("bench press" as a phrase) fixes this.

### bicep curl / dumbbell bicep curl
- **Plain `Bicep Curl` / `Biceps Curl` row: ABSENT**.
- Blessed: `Barbell Biceps Curl`, `Biceps Curl Cable`, `Biceps Curl Resistance Band`, `Bicep Curl Low Cable Machine Normal Grip`, plus 17+ hammer-curl variants.
- **Verdict**: library gap. `needs_media_production` for plain `Bicep Curl` (the dumbbell one is the canonical implied default in fitness vocab — but no `Dumbbell Bicep Curl` row exists either; plenty of dumbbell hammer curl rows but no standard supinated curl). Alias today: best near-match for `dumbbell bicep curl` is none ideal.

### bench press / barbell bench press
- Blessed: `Barbell Bench Press`, `Dumbbell Bench Press`. Many incline/decline variants exist too.
- `bench press` (raw) → should map to `Barbell Bench Press` (default equipment convention).
- **Verdict**: matcher works for "barbell bench press"; for plain "bench press" the answer is "Barbell Bench Press" by the bench-press-default-is-barbell convention. Strategy 4 (same-equipment fallback).

### squat / back squat / front squat
- Blessed: `Barbell Front Squat`, `Barbell Front Squats`, `Bodyweight Squats`. Many other squat variants exist (split squat, goblet, sumo, etc.) but **no plain `Back Squat` or `Barbell Back Squat`**.
- **Verdict**: real library gap. The most common exercise in strength training (`barbell back squat`) is missing. `needs_media_production`. For raw `squat`, fall back to `Bodyweight Squats`.

### deadlift / romanian deadlift
- Blessed: `Barbell Deadlift`, `Barbell Romanian Deadlift`, `Dumbbell Romanian Deadlift`, etc. Plain `Deadlift` row not present but `Barbell Deadlift` is the canonical default.
- **Verdict**: matcher should map `deadlift → Barbell Deadlift` and `romanian deadlift → Barbell Romanian Deadlift` cleanly with phrase matching.

### overhead press / shoulder press
- Blessed: `Barbell Standing Shoulder Press`, `Barbell Seated Overhead Press`, `Barbell Standing Military Press`, `Dumbbell Standing Overhead Press`, `Dumbbell Standing Shoulder Press`, `Dumbbell Seated Shoulder Press`, plus many landmine/kettlebell/band variants.
- Plain `Overhead Press` / `Shoulder Press` row: ABSENT (`Machine Shoulder Press` exists but no media).
- **Verdict**: matcher should map `overhead press → Barbell Standing Overhead Press` (closest match). For raw `shoulder press`, best is `Barbell Standing Shoulder Press` or `Dumbbell Standing Shoulder Press`. Library has plenty of coverage; just needs disambiguation.

### hip thrust / glute bridge
- Blessed: `Barbell Hip Thrust`, `Bodyweight Hip Thrust`, `Barbell Glute Bridge`. Plain `Hip Thrust` and `Glute Bridge` rows: ABSENT.
- **Verdict**: matcher should map `hip thrust → Barbell Hip Thrust` (canonical default) and `glute bridge → Barbell Glute Bridge`.

### handstand hold (wall)
- Blessed: `Hand Stand Hold` (with space). Tokenization needs to collapse `handstand` ↔ `hand stand`.
- **Verdict**: matcher bug. Add token-collapse rule `handstand → hand stand`.

## Summary table

| Raw name (cited) | Library gap? | Best blessed match today | Old matcher result | Fix |
|---|---|---|---|---|
| dumbbell shrug | no | Dumbbell Shrugs | ✗ unmapped 0.51 | singularize |
| incline barbell press | no | Barbell Incline Bench Press | ✓ matched but flags wrong | phrase-movement |
| good morning | no | Good Mornings | ✗ unmapped 0.50 | singularize |
| glute ham raise | YES | (none — Nordic Hamstring Curl as substitute) | wrongly matched Calf Raise | needs_media_production + swap_in_prompt |
| face pull (rope) | partial — `Cable Face Pull` lacks media | Cable Face Pull With Rope | wrongly flagged equipment✗ | parenthetical handling |
| handstand hold (wall) | no | Hand Stand Hold | wrongly unmapped | space-collapse handstand→hand stand |
| plank | YES — no plain "Plank" row | Plank On Elbows | wrongly matched Plank Iytw | alias plank→Plank On Elbows + needs_media_production |
| pull-up | YES — no plain "Pull-Up" row | Pull-Up Normal Grip | wrongly matched Band Pull-Up (regression) | needs_media_production for plain Pull-Up + alias |
| leg press | YES — `Leg Press` lacks video | Leg Press Machine Normal Stance | wrongly matched Band Leg Press | needs_media_production for plain Leg Press |
| face pull | partial — `Cable Face Pull` lacks media | Cable Face Pull With Rope | wrongly matched Band Face Pull | needs_media_production + alias |
| lat pulldown (machine) | partial — `Lat Pulldown` lacks video | Lat Pull Down Normal Grip | wrongly matched Behind Neck Lat Pull Down Machine | parenthetical + alias |
| bicep curl | YES — no plain `Bicep Curl` / `Dumbbell Bicep Curl` | Barbell Biceps Curl (closest) | n/a | needs_media_production |
| bench press (plain) | no | Barbell Bench Press (default) | ok via aliases | same-equipment-default |
| squat / back squat | YES — no plain Back Squat | Bodyweight Squats / Barbell Front Squat | n/a | needs_media_production for `Barbell Back Squat` |
| deadlift | no | Barbell Deadlift | ok | phrase-movement |
| overhead press | no | Barbell Standing Overhead Press | ok | phrase-movement |
| hip thrust / glute bridge | no | Barbell Hip Thrust / Barbell Glute Bridge | ok | phrase-movement |

## Library gaps prioritized for media production

1. **Barbell Back Squat** (or "Back Squat") — the most-used compound lift in strength training, currently absent.
2. **Pull-Up** (plain bodyweight) — basic version missing; band/assisted variants are regressions, not equivalents.
3. **Plank** (or "Forearm Plank") — basic version missing; `Plank On Elbows` is functionally equivalent but mis-named.
4. **Bicep Curl** / **Dumbbell Bicep Curl** — surprisingly absent; only barbell/cable/band rows.
5. **Leg Press** — row exists but missing video.
6. **Cable Face Pull** — row exists but missing image AND video.
7. **Lat Pulldown** — row exists but missing video.
8. **Glute Ham Raise** — row absent; Nordic Hamstring Curl is the only nearby relative.
