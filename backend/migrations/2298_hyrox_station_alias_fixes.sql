-- 2298_hyrox_station_alias_fixes.sql
-- ============================================================
-- Fix media resolution for HYROX station exercises on BOTH
-- the program-schedule path (exercise_aliases → exercise_canonical
-- → exercise_demos) and the active-workout path
-- (/exercise-images → exercise_image_aliases or RPC fallback).
--
-- STATE BEFORE THIS MIGRATION
-- ─────────────────────────────────────────────────────────────
-- ✓ already correct (no change needed):
--   SkiErg              → Ski Erg Easy             → Generated/ski_erg_easy.png
--   SkiErg Interval/s   → Ski Erg Intervals         → Generated/ski_erg_intervals.png
--   Sled Push           → Sled Push canonical        → Generated/sled_push.png
--   Sled Pull           → Sled Pull canonical        → Generated/sled_pull.png
--   Burpee Broad Jumps  → Burpee canonical           → Burpee  .jpg
--   Rowing / Rowing Machine → Gym Rowing Machine Fast Speed → Gym Rowing Machine Fast Speed.jpg
--   Farmers Carry       → Dumbbell farmer walks       → dumbbell farmer walks.jpg
--   Sandbag Lunges      → Sandbag Walking Lunge       → Generated/sandbag_walking_lunge.png
--   Wall Balls          → Wall Ball canonical         → Generated/wall_ball.png
--
-- ✗ WRONG image served today:
--   "Plank"      → Alternate arm leg plank hold (bird-dog variation — raises
--                  opposite arm+leg; anatomically wrong for HYROX floor plank hold)
--   "Plank Hold" → Bench Reverse Plank Hold (feet on bench, body facing up —
--                  completely wrong; should be a standard prone isometric hold)
--
-- ~ Suboptimal (acceptable machine shown, better image available):
--   "Ski Erg" (with space) → female alternating-arm pull illustration;
--                            bilateral-pull neutral image is more accurate for HYROX
--
-- MISSING aliases (may appear in AI-generated variant weeks):
--   "Ski Erg Interval" / "Ski Erg Intervals" (with space)
--   "Row" (shorthand for Rowing)
-- ============================================================

-- ── 1. Fix "Plank" alias ─────────────────────────────────────────────────────
-- "Alternate arm leg plank hold" = bird-dog (dynamic, opposite limbs raised).
-- HYROX Plank Hold = static prone floor hold.  Remap to "High plank" canonical
-- which has image: ILLUSTRATIONS ALL/Yoga/High plank.jpeg
UPDATE exercise_aliases
SET    canonical_exercise_id = 'dc6422e2-2c36-427f-8553-6a9d749f5e6b'  -- High plank
WHERE  alias_name_normalized  = 'plank'
  AND  canonical_exercise_id  = 'c07c0fe6-6428-4271-99df-9cdf58d506a0'; -- was Alternate arm leg plank hold

-- ── 2. Fix "Plank Hold" alias ─────────────────────────────────────────────────
-- "Bench Reverse Plank Hold" = supine with feet elevated on a bench, facing up.
-- HYROX Plank Hold = standard prone (face-down) floor isometric hold.
-- Remap to "High plank" canonical — correct image, is_timed=TRUE.
UPDATE exercise_aliases
SET    canonical_exercise_id = 'dc6422e2-2c36-427f-8553-6a9d749f5e6b'  -- High plank
WHERE  alias_name_normalized  = 'plank hold'
  AND  canonical_exercise_id  = 'de50f115-a46b-42d5-a013-1f6c627b5aaf'; -- was Bench Reverse Plank Hold

-- ── 3. Improve "Ski Erg" (with space) alias ───────────────────────────────────
-- Was pointing to "Ski Ergometer Cross Country Ski Alternating Arm Pulls"
-- (single-arm alternating motion, female-only demo).  HYROX SkiErg uses a
-- bilateral double-arm simultaneous pull.  Remap to "Ski Erg Easy" canonical
-- (same as "SkiErg" no-space alias) for a neutral bilateral-pull illustration.
UPDATE exercise_aliases
SET    canonical_exercise_id = '1f38c32d-05e8-40e9-ab0c-4d5c6f6979bd'  -- Ski Erg Easy
WHERE  alias_name_normalized  = 'ski erg'
  AND  canonical_exercise_id  = '003ea1d9-6f8f-475b-a630-3287b950e472'; -- was Alternating Arm Pulls

-- ── 4. Add "Ski Erg Interval(s)" aliases (with space) ────────────────────────
-- "SkiErg Interval" (no space) already maps to Ski Erg Intervals canonical.
-- "Ski Erg Interval" / "Ski Erg Intervals" (with space) normalise differently
-- and have no alias — AI-generated variant weeks may emit either form.
INSERT INTO exercise_aliases
  (alias_name, alias_name_normalized, canonical_exercise_id,
   match_type, match_confidence, is_verified)
SELECT
  t.name,
  normalize_exercise_name(t.name),
  '4ab27b98-ef3f-4fa8-9916-9a1df188950a',  -- Ski Erg Intervals canonical (ski_erg_intervals.png)
  'ai_curated',
  0.9,
  false
FROM (VALUES
  ('Ski Erg Interval'),
  ('Ski Erg Intervals')
) t(name)
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_aliases ea
  WHERE ea.alias_name_normalized = normalize_exercise_name(t.name)
);

-- ── 5. Add "Row" shorthand alias ──────────────────────────────────────────────
-- AI-generated weeks may abbreviate the station as "Row" (one word).
-- Route to the same canonical as "Rowing" / "Rowing Machine" (Gym Rowing
-- Machine Fast Speed) which has a correct machine illustration.
INSERT INTO exercise_aliases
  (alias_name, alias_name_normalized, canonical_exercise_id,
   match_type, match_confidence, is_verified)
SELECT
  'Row',
  normalize_exercise_name('Row'),
  'e1a2cda4-0c68-46ce-a972-7e404fe65006',  -- Gym Rowing Machine Fast Speed
  'ai_curated',
  0.85,
  false
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_aliases
  WHERE alias_name_normalized = normalize_exercise_name('Row')
);

-- ── 6. exercise_image_aliases — step-2 fast path for active-workout screen ────
-- The /exercise-images resolver tries exercise_image_aliases (step 2) before
-- the heavier resolve_exercise_demo_media RPC (step 4).  Adding these entries
-- saves a round-trip for the most common HYROX names.
--
-- Table columns: display_name (text), library_exercise_id (uuid),
--                source (text), created_at (timestamptz)
-- display_name is stored as lowercase (matched via .eq("display_name", name.lower()))

-- 6a. "skierg" → Ski Ergometer Cross Country Ski Basic Pull
--     (library row with bilateral pull illustration — anatomically correct for HYROX)
INSERT INTO exercise_image_aliases (display_name, library_exercise_id, source)
SELECT
  'skierg',
  '5a56a2ab-07a3-4daf-a715-73d946794a1d',  -- Ski Ergometer Cross Country Ski Basic Pull
  'hyrox_migration'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_image_aliases WHERE display_name = 'skierg'
);

-- 6b. "ski erg" (with space) → same library row
INSERT INTO exercise_image_aliases (display_name, library_exercise_id, source)
SELECT
  'ski erg',
  '5a56a2ab-07a3-4daf-a715-73d946794a1d',  -- Ski Ergometer Cross Country Ski Basic Pull
  'hyrox_migration'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_image_aliases WHERE display_name = 'ski erg'
);

-- 6c. "plank hold" → High plank (standard prone floor isometric hold)
INSERT INTO exercise_image_aliases (display_name, library_exercise_id, source)
SELECT
  'plank hold',
  'aa3f0718-16c4-4113-9802-51198ebc843f',  -- High plank (is_timed=TRUE, correct image)
  'hyrox_migration'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_image_aliases WHERE display_name = 'plank hold'
);

-- 6d. "farmers carry" → Farmer's Carry library row (purpose-generated illustration)
--     Covers the no-apostrophe program spelling that ilike won't match on "Farmer's Carry"
INSERT INTO exercise_image_aliases (display_name, library_exercise_id, source)
SELECT
  'farmers carry',
  '9cf7070b-2ada-4f76-92cf-8038b183c3b6',  -- Farmer's Carry (Generated/farmer_s_carry.png)
  'hyrox_migration'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_image_aliases WHERE display_name = 'farmers carry'
);

-- ── 7. Ensure High plank metadata is populated ────────────────────────────────
-- Migration 207 already set is_timed=TRUE for all %plank% rows; this confirms
-- the hold-second ranges on the specific row used by HYROX Plank Hold aliases.
UPDATE exercise_library
SET
  is_timed             = TRUE,
  default_hold_seconds = COALESCE(default_hold_seconds, 30),
  hold_seconds_min     = COALESCE(hold_seconds_min, 20),
  hold_seconds_max     = COALESCE(hold_seconds_max, 120)
WHERE exercise_name = 'High plank';

-- ── 8. Refresh materialized view ─────────────────────────────────────────────
REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_library_cleaned;
