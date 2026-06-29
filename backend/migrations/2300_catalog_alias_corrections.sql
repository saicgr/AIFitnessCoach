-- 2300_catalog_alias_corrections.sql
--
-- Catalog-wide alias correctness sweep across all curated-program exercise names.
-- Fixes 15 wrong alias→canonical mappings (band variants, advanced variants,
-- completely wrong movements) plus deletes 4 yoga aliases pointing to wrong moves.
-- Adds 17 new aliases for common exercise names with no alias at all.
-- Sets is_timed + hold metadata on plank and wall-sit exercise_library rows.
--
-- All changes idempotent: UPDATE…WHERE canonical_id=<wrong>, INSERT…WHERE NOT EXISTS,
-- DELETE…WHERE canonical_id=<wrong>. Refreshes exercise_library_cleaned at end.
--
-- Normalization notes verified before writing:
--   normalize_exercise_name strips punctuation incl. hyphens/apostrophes and trailing
--   -s on SINGLE words ("Squats"→"squat", "Raises"→"raise", "Planks"→"planks").
--   Multi-word trailing -s is kept ("Wall Balls"→"wall balls").
--   "Cool-Down Jog" → "cool down jog" (hyphen stripped, not trailing-s).
--
-- Applied to prod project hpbzfahijszqmgsybuor.

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 1 — Fix wrong alias→canonical mappings (UPDATE)
-- Covers: pre-existing wrong aliases + discovered wrong aliases on "pull ups",
-- "push ups", "childs pose".
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. "air squat" → was Cossack squat (lateral/unilateral) → Bodyweight squat
UPDATE exercise_aliases
SET    canonical_exercise_id = '290234f2-2587-4e15-b211-262b8f156631'
WHERE  alias_name_normalized  = 'air squat'
  AND  canonical_exercise_id  = 'ddcc3946-6729-441d-ac5a-4637dd5acb1a';

-- 2. "barbell squat" → was barbell front squat → Barbell squat back POV
UPDATE exercise_aliases
SET    canonical_exercise_id = 'da70ff1c-2c34-4d5a-8270-ad0cc187e818'
WHERE  alias_name_normalized  = 'barbell squat'
  AND  canonical_exercise_id  = '817d3263-ede8-4396-aa50-d343e16e9327';

-- 3. "bench press" → was Band Bench Press → Barbell bench press
UPDATE exercise_aliases
SET    canonical_exercise_id = '6452b5ee-daed-41cc-8b95-299715e2045e'
WHERE  alias_name_normalized  = 'bench press'
  AND  canonical_exercise_id  = '38d710b2-a675-438b-bac7-44ab9f4ee227';

-- 4. "bent over row" → was Band bent-over row → Barbell bent over row pronated grip
UPDATE exercise_aliases
SET    canonical_exercise_id = '08fb59ab-7689-43ec-bc8a-fa58f77a2663'
WHERE  alias_name_normalized  = 'bent over row'
  AND  canonical_exercise_id  = 'f5a0f65d-4d1b-418b-a336-acc51276f14b';

-- 5. "dips" → was Ring Dips (gymnastics rings) → Chest dip with pause bodyweight
UPDATE exercise_aliases
SET    canonical_exercise_id = 'feba11e2-68fb-4742-a7bc-f7188453c259'
WHERE  alias_name_normalized  = 'dips'
  AND  canonical_exercise_id  = 'af27a900-89f3-411f-87fd-e571bff08ad8';

-- 6. "front raise" → was Band front raise → Dumbbell Front Raise
--    Note: "Front Raises" also normalizes to "front raise" so this UPDATE covers both.
UPDATE exercise_aliases
SET    canonical_exercise_id = '94e41ca9-0561-402a-a5d3-ec27531f7a7c'
WHERE  alias_name_normalized  = 'front raise'
  AND  canonical_exercise_id  = '309b91ac-0b7c-43d3-9172-a5c4f2201317';

-- 7. "jump rope" → was Jump Rope row (a back exercise) → Jump Rope basic jump
UPDATE exercise_aliases
SET    canonical_exercise_id = 'd22b3ddb-a877-4330-bff4-4a82d93a3723'
WHERE  alias_name_normalized  = 'jump rope'
  AND  canonical_exercise_id  = '0c39eb37-c148-497b-a158-0466cb6ec870';

-- 8. "leg press" → was Band Leg Press → Leg press machine normal stance
UPDATE exercise_aliases
SET    canonical_exercise_id = '94a1483e-320d-42db-88f1-f7bdc4b9ac2f'
WHERE  alias_name_normalized  = 'leg press'
  AND  canonical_exercise_id  = 'a24eefd0-d055-409a-a112-5889f0047fca';

-- 9. "pull up" (from "pull-up") → was Assisted Pull-up → Pull up normal grip
UPDATE exercise_aliases
SET    canonical_exercise_id = 'd7331412-7500-49ee-8664-8a425fc3f7ba'
WHERE  alias_name_normalized  = 'pull up'
  AND  canonical_exercise_id  = '30b7278c-1ed9-4369-8609-c384d7286dca';

-- 10. "push up" (from "push-up") → was Archer Push up → Normal Push-up
UPDATE exercise_aliases
SET    canonical_exercise_id = 'cfeba482-fc43-4431-b1a9-29c32259749c'
WHERE  alias_name_normalized  = 'push up'
  AND  canonical_exercise_id  = '1192650c-00c1-458a-9d5e-6e79f04a5587';

-- 11. "shrug" → was Band Horizontal Shrug (wrong direction) → Barbell shrugs
UPDATE exercise_aliases
SET    canonical_exercise_id = 'a981b03c-a9a6-46ae-8830-33a20520c7d4'
WHERE  alias_name_normalized  = 'shrug'
  AND  canonical_exercise_id  = '503f0681-305c-4f76-aa28-ac1c4d87e09d';

-- 12. "step ups" (from "step-ups") → was Barbell Bench Lateral Step-up → Box Step-Up
UPDATE exercise_aliases
SET    canonical_exercise_id = '489e795e-a379-431e-be02-5b70900d9761'
WHERE  alias_name_normalized  = 'step ups'
  AND  canonical_exercise_id  = 'cf1e8d2e-4745-4c83-95a7-f1ed52ecc25d';

-- 13. "pull ups" (from "pull-ups"/"pull ups") → was Bench pull-ups → Pull up normal grip
UPDATE exercise_aliases
SET    canonical_exercise_id = 'd7331412-7500-49ee-8664-8a425fc3f7ba'
WHERE  alias_name_normalized  = 'pull ups';

-- 14. "push ups" (from "push-ups"/"push ups") → was Clap push ups → Normal Push-up
UPDATE exercise_aliases
SET    canonical_exercise_id = 'cfeba482-fc43-4431-b1a9-29c32259749c'
WHERE  alias_name_normalized  = 'push ups';

-- 15. "childs pose" (from "child's pose") → was Child Pose Arms On Side → Child pose
UPDATE exercise_aliases
SET    canonical_exercise_id = '818012cd-44b9-4463-a782-37b9f69dc028'
WHERE  alias_name_normalized  = 'childs pose';

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 2 — Delete aliases pointing to anatomically-wrong movements.
-- No correct canonicals with images exist for these yoga poses;
-- removing lets the icon fallback serve rather than a wrong-movement image.
-- ─────────────────────────────────────────────────────────────────────────────

-- 16. "tree pose" → was Single-Leg Balance on Hay Bale (no image, wrong equipment)
DELETE FROM exercise_aliases
WHERE alias_name_normalized = 'tree pose'
  AND canonical_exercise_id = '200f7e51-e7ed-4479-8849-5c895533e271';

-- 17. "triangle pose" → was Bodyweight standing triangle fly (wrong movement, not the pose)
DELETE FROM exercise_aliases
WHERE alias_name_normalized = 'triangle pose'
  AND canonical_exercise_id = '64ce3349-9d50-4053-be81-73dca49cf837';

-- 18. "warrior ii" → was Dumbbell Side Lunge Single Leg (wrong movement + wrong equipment)
DELETE FROM exercise_aliases
WHERE alias_name_normalized = 'warrior ii'
  AND canonical_exercise_id = 'fe2a6895-3314-4b07-a1d7-5487b797d314';

-- 19. "savasana" → was Side Lying Parsva Savasana Variation (wrong orientation; no image)
DELETE FROM exercise_aliases
WHERE alias_name_normalized = 'savasana'
  AND canonical_exercise_id = 'b11f8961-7ef3-4392-8ac8-7afa33d816a6';

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 3 — Add new aliases for unaliased common exercise names.
-- De-duplicated after verifying normalize_exercise_name() output for each name:
--   - "Squats" normalizes to "squat" (same as "Squat") → omitted, one entry covers both
--   - "Front Raises" normalizes to "front raise" (same) → covered by Section 1 UPDATE
--   - "Pull-Ups"/"Pull Ups" both normalize to "pull ups" → covered by Section 1 UPDATE
--   - "Push-Ups"/"Push Ups" both normalize to "push ups" → covered by Section 1 UPDATE
--   - "Child's Pose" normalizes to "childs pose" → covered by Section 1 UPDATE #15
--   - "Cobra Pose" already exists (correct) → skip
--   - "Happy Baby Pose" already exists (correct) → skip
--   - "Extended Side Angle Pose" already exists (correct) → skip
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO exercise_aliases
  (alias_name, alias_name_normalized, canonical_exercise_id, match_type, match_confidence, is_verified)
SELECT t.name, normalize_exercise_name(t.name), t.cid::uuid, 'ai_curated', 0.9, false
FROM (VALUES
  -- Plank variants
  -- High Plank → High plank [dc6422e2] ✓ image: Yoga/High plank.jpeg (is_timed=TRUE)
  ('High Plank',        'dc6422e2-2c36-427f-8553-6a9d749f5e6b'),
  -- Planks normalizes to "planks" (NOT "plank" — multi-char stem differs) → High plank
  ('Planks',            'dc6422e2-2c36-427f-8553-6a9d749f5e6b'),
  -- Plank On Elbows → Plank on elbows [2e133235] ✓ image: Abdominals/plank on elbows.jpeg
  ('Plank On Elbows',   '2e133235-8f83-4968-bc2a-d6d873038daa'),
  -- Plank Pushup (elbow→high transition) → Elbow-Up and Down Dynamic Plank [c34ebc19]
  -- ✓ image: Abdominals/Elbow-Up and Down Dynamic Plank.jpeg
  ('Plank Pushup',      'c34ebc19-a326-4794-96f0-fe6b366395e8'),

  -- Squat (only one entry; "Squats" also normalizes to "squat" so one covers both)
  -- → Bodyweight squat [290234f2] ✓ image: Legs/Bodyweight Squat.jpg
  ('Squat',             '290234f2-2587-4e15-b211-262b8f156631'),

  -- Pull-Up grip name (literal program name)
  -- → Pull up normal grip [d7331412] ✓ image: Back/pull up normal grip .jpg
  ('Pull-Up Normal Grip', 'd7331412-7500-49ee-8664-8a425fc3f7ba'),

  -- Floor dip → Floor Tricep Dip [d041f5ce] ✓ image: Triceps/Floor Tricep Dip.jpg
  ('Floor Tricep Dip',  'd041f5ce-c9be-4a99-b00d-f28e60934411'),

  -- Running / cardio intervals → Running [80951e3d]
  -- ✓ image: Calisthenics-Cardio-Functional/Running.jpg
  ('1 Km Run',                  '80951e3d-8337-4187-8359-8a9c28a96bd1'),
  ('Steady Run',                '80951e3d-8337-4187-8359-8a9c28a96bd1'),
  ('Running In Place',          '80951e3d-8337-4187-8359-8a9c28a96bd1'),
  ('Treadmill Sprint',          '80951e3d-8337-4187-8359-8a9c28a96bd1'),
  ('800 M Interval',            '80951e3d-8337-4187-8359-8a9c28a96bd1'),
  ('1 Km Threshold Interval',   '80951e3d-8337-4187-8359-8a9c28a96bd1'),
  -- Cool-down / warm-up jog → Jogging [725f7824]
  -- Note: hyphens stripped by normalize → "cool down jog" / "warm up jog"
  -- ✓ image: Calisthenics-Cardio-Functional/Jogging.jpg
  ('Cool-Down Jog',     '725f7824-d28e-4660-a51a-202746bedb3e'),
  ('Warm-Up Jog',       '725f7824-d28e-4660-a51a-202746bedb3e'),

  -- Yoga: child pose (no apostrophe variant; apostrophe variant handled by Section 1 UPDATE)
  -- → Child pose [818012cd] ✓ image: Yoga/Child pose.jpg
  ('Child Pose',        '818012cd-44b9-4463-a782-37b9f69dc028'),

  -- SkiErg full canonical name (some AI programs emit this as the exercise name)
  -- → Ski Erg Easy [1f38c32d] ✓ image: Generated/ski_erg_easy.png
  ('Ski Ergometer Cross Country Ski Basic Pull',
                        '1f38c32d-05e8-40e9-ab0c-4d5c6f6979bd')
) AS t(name, cid)
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_aliases ea
  WHERE ea.alias_name_normalized = normalize_exercise_name(t.name)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 4 — Set is_timed + hold metadata on exercise_library rows.
-- Migration 207 already set is_timed for ILIKE '%plank%'; this catches any gaps
-- from newly-imported rows and adds wall sit (not covered by migration 207).
-- ─────────────────────────────────────────────────────────────────────────────

-- Plank isometric holds (exclude dynamic/jumping/walking/lunge/push-up variants)
UPDATE exercise_library
SET    is_timed              = TRUE,
       default_hold_seconds  = COALESCE(default_hold_seconds, 30),
       hold_seconds_min      = COALESCE(hold_seconds_min, 20),
       hold_seconds_max      = COALESCE(hold_seconds_max, 120)
WHERE  exercise_name ILIKE '%plank%'
  AND  exercise_name NOT ILIKE '%push%'
  AND  exercise_name NOT ILIKE '%jump%'
  AND  exercise_name NOT ILIKE '%lunge%'
  AND  exercise_name NOT ILIKE '%walk%'
  AND  (is_timed = FALSE OR is_timed IS NULL);

-- Wall sit (timed isometric hold)
UPDATE exercise_library
SET    is_timed              = TRUE,
       default_hold_seconds  = COALESCE(default_hold_seconds, 45),
       hold_seconds_min      = COALESCE(hold_seconds_min, 20),
       hold_seconds_max      = COALESCE(hold_seconds_max, 180)
WHERE  exercise_name ILIKE '%wall sit%'
  AND  (is_timed = FALSE OR is_timed IS NULL);

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 5 — Refresh MV
-- ─────────────────────────────────────────────────────────────────────────────

REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_library_cleaned;
