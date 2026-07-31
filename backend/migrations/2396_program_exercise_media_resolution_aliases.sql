-- 2396_program_exercise_media_resolution_aliases.sql
--
-- Hand-verified aliases for the highest-volume names still unresolved after
-- migrations 2391 (canonical self-alias backfill) + 2395 (exercise_name
-- precedence fix) — E2E register #122, follow-up to #126/#127.
--
-- Measured via scripts/audit_program_exercise_media_resolution.py (the new
-- standing gate, replicating the app's real 4-tier resolver from
-- api/v1/program_templates.py) over all 45 published programs / 1,624
-- variants / 177,318 exercise occurrences:
--
--   baseline (register, 2026-07-30, before any fix)........ 20,332 missing / 263 names / 31 programs
--   after migration 2391 + 2395 (this session)..............  1,633 missing /  77 names / 14 programs
--   after this migration.....................................1,039 missing /  73 names / 14 programs
--
-- Same methodology as 2394_inuse_exercise_name_aliases.sql: cross-checked
-- each unresolvable name against exercise_canonical (equipment/target_muscle/
-- body_part) via pg_trgm similarity, confirmed against exercise_library_cleaned
-- (the richer, unbridged source these names are drawn from — see
-- [[project_program_variants_and_schedule_media]]: "91-exercise library→
-- canonical bridging gap"), and required a REAL exercise_demos image before
-- aliasing. Every alias below is the SAME movement as its target — a
-- word-order, article, or single-vs-one-arm synonym difference, never a
-- different exercise (api/v1/program_templates.py:1971 prime directive).
--
-- What did NOT get aliased here, and why (see companion doc
-- docs/planning/exercise-images/inuse_name_resolution.md, "2026-07-31 pass"
-- section for the full per-name table):
--   * Treadmill Walking Lunge (338 occ) / Dumbbell Lying On Floor Chest Press
--     (80 occ) — already classified Bucket B in the 2026-07-30 pass (no
--     matching-equipment canonical exists). Unchanged by this pass.
--   * Warrior II / Pyramid Pose / Triangle Pose / Goddess Pose (yoga poses,
--     ~74 occ combined) and Thoracic Extension Stretch / Thoracic Rotation
--     Quadruped (~118 occ) — genuinely absent from exercise_canonical; the
--     richer exercise_library_cleaned has them (with real S3 images, even),
--     but that library was never bridged to exercise_canonical for these
--     rows. This is the 91-exercise bridging gap, not an alias gap — no
--     canonical row exists to alias onto. Needs
--     scripts/bridge_library_exercises_to_canonical.py extended, or new
--     canonical rows authored, tracked separately (out of scope: this
--     migration only adds aliases, never creates exercise_canonical rows).
--   * Back Extension Machine (12 occ) — ALREADY has a canonical_self alias
--     (migration 2391) and a real S3 VIDEO, but no IMAGE. A genuine asset
--     gap, not a resolution bug — no alias would fix it.
--   * Banded Clamshell / Spiderman Lunge With Reach / Kneeling Plank and the
--     long tail (~1 to ~21 occ each) — either an equipment/movement
--     difference material enough to withhold (banded vs bodyweight changes
--     the visual; "with reach" adds a thoracic-rotation component the base
--     movement doesn't have) or no plausible candidate found at all.
--   * Deep Breathing / Meditation / Complete Rest / Hydration / Sleep /
--     Nutrition / Mobility / Stretching / Yoga / Light Stretching (~10 occ) —
--     these are recovery-day SESSION-TYPE labels stored in the same
--     `exercises[]` array shape, not real exercises. Whether the schedule UI
--     should even attempt image resolution for them is a product question,
--     not a data-fix — flagged, not aliased.
--
-- SAFETY (same properties as 2394)
-- ---------------------------------
-- * Idempotent: WHERE NOT EXISTS guard + ON CONFLICT (alias_name_normalized)
--   DO NOTHING.
-- * match_type = 'manual', match_confidence = 1.0, is_verified = TRUE.
-- * Every target confirmed to carry a real exercise_demos.image_s3_path via
--   direct SQL before being added below.
-- * Does not touch resolve_exercise_demo_media, program_exercises_flat, or
--   any *_s3_path / exercise_demos.original_exercise_name.
-- * No MV refresh needed (exercise_library_cleaned does not reference
--   exercise_aliases).

BEGIN;

INSERT INTO exercise_aliases (
    alias_name, alias_name_normalized, canonical_exercise_id,
    match_type, match_confidence, is_verified
)
SELECT v.alias_name,
       normalize_exercise_name(v.alias_name),
       v.canonical_exercise_id::uuid,
       'manual', 1.0, TRUE
FROM (VALUES
    -- Word-order variant of the exact same barbell hinge movement. Equipment
    -- (Barbell) and target (Hamstrings, Glutes) match exactly against
    -- exercise_library_cleaned's entry for this in-use name. Biggest single
    -- offender in the register (470 occurrences / 18 programs).
    ('Romanian Deadlift Barbell',            'dc93a979-54f2-4fc2-aefe-cca463d5675e'), -- -> Barbell romanian deadlift

    -- "Single-arm" / "one-arm" is the same synonym pair already established
    -- safe by 2394's "Heavy Bag Sled Drag"-class reasoning. Equipment
    -- (Dumbbells) and target (Shoulders / Lateral Deltoids) match exactly.
    ('Dumbbell Single-Arm Lateral Raise',    '5dc10e26-22eb-4837-817a-41ac3d7b8eb7'), -- -> Dumbbell One Arm Lateral Raise

    -- Same synonym pair, same equipment (Dumbbells), same 3-muscle target
    -- list (Shoulders/Quadriceps/Glutes) matching the ballistic full-body
    -- snatch movement exactly.
    ('Dumbbell Single-Arm Snatch',           '9bff0e21-9c01-46ef-a099-41134bf21222'), -- -> Dumbbell One Arm Snatch

    -- "Tempo" is a pacing instruction on the same treadmill-running movement,
    -- not a different exercise -- identical reasoning to 2394's "5K Run" ->
    -- "Running" (a distance/pace qualifier on an unchanged gait). Equipment
    -- (Treadmill) and target (Quadriceps/Hamstrings/Glutes) match exactly.
    ('Treadmill Tempo Run',                  '07e29142-0323-4160-b70b-b5b4b0db04b7')  -- -> Treadmill Running
) AS v(alias_name, canonical_exercise_id)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_aliases a
    WHERE a.alias_name_normalized = normalize_exercise_name(v.alias_name)
)
ON CONFLICT (alias_name_normalized) DO NOTHING;

COMMIT;

-- ─────────────────────────────────────────────────────────────────────────────
-- Verification (run after applying)
-- ─────────────────────────────────────────────────────────────────────────────
--
-- All 4 should now resolve with a real image:
--   SELECT * FROM resolve_exercise_demo_media('Romanian Deadlift Barbell');
--   SELECT * FROM resolve_exercise_demo_media('Dumbbell Single-Arm Lateral Raise');
--   SELECT * FROM resolve_exercise_demo_media('Dumbbell Single-Arm Snatch');
--   SELECT * FROM resolve_exercise_demo_media('Treadmill Tempo Run');
--
-- Full re-measurement:
--   cd backend && set -a && source ./.env && set +a && \
--     .venv/bin/python scripts/audit_program_exercise_media_resolution.py
