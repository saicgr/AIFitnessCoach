-- 2394_inuse_exercise_name_aliases.sql
--
-- Register aliases for exercise names that generators actively write into
-- `workouts.exercises_json` / `warmup_json` / `stretch_json` but which resolve to
-- NO media via resolve_exercise_demo_media() (migration 2290/2392). Every request
-- for these names 404s.
--
-- See docs/planning/exercise-images/inuse_name_resolution.md for the full
-- investigation: all ~51 unresolvable in-use names, evidence for every decision,
-- and the ~34 names that are genuinely new exercises (need a new canonical row +
-- illustration, out of scope for an alias) or data-quality artifacts (fix at the
-- source generator, not by aliasing to a real exercise).
--
-- THE PRIME DIRECTIVE (api/v1/program_templates.py:1971)
-- --------------------------------------------------------
-- Mapping an exercise to a similar-but-different movement silently relabels it
-- catalog-wide and is worse than showing no image. Every alias below is a name
-- variant of the SAME movement: same equipment, same target muscle, same
-- unilateral/bilateral, same body position as its target canonical row. Evidence
-- (equipment/body_part/target_muscle comparison, cross-checked against the
-- `exercise_library_cleaned` view — the richer, unbridged source most of these
-- in-use names are drawn from) is in the companion doc; summary per row below.
--
-- All targets carry real S3 media (confirmed via resolve_exercise_demo_media_batch)
-- EXCEPT one: "Horizontal Leg Press Calf Raise Single-Leg" -> "Single leg calf
-- raise leg press machine", which is registered for correctness/future-proofing
-- but will not itself flip to resolved until that canonical exercise gets an
-- illustration (tracked separately, not part of this migration's resolved-count
-- delta).
--
-- SAFETY
-- ------
-- * Idempotent: INSERT ... WHERE NOT EXISTS guards re-runs, ON CONFLICT
--   (alias_name_normalized) DO NOTHING is the second safety net (that column is
--   UNIQUE) since two different in-use names could theoretically normalize to the
--   same key.
-- * match_type = 'manual', match_confidence = 1.0, is_verified = TRUE per the
--   review protocol for hand-verified, human-reasoned aliases (2300-style),
--   distinct from the noisy bulk-imported 'exact'/'word_overlap'/'fuzzy' rows
--   that api/v1/program_templates.py:1971 explicitly warns are NOT trustworthy.
-- * Does NOT touch resolve_exercise_demo_media, does NOT add fuzzy matching,
--   does NOT touch 2391/2392/2393.
-- * No MV refresh needed (exercise_library_cleaned does not reference
--   exercise_aliases; verified against pg_matviews per 2391's note).

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
    -- Redundant plural / article / prefix noise on an otherwise identical name --
    ('Seated Row Machine Rows',                  '443fc883-b06a-4d55-879e-fbb260ebc76a'), -- -> Seated Row Machine
    ('The Wall Ball',                            '2360d23e-2552-439e-b95d-c22583c8986e'), -- -> Wall Ball

    -- Shorthand of the exact same cable/machine exercise (confirmed against
    -- exercise_library_cleaned's fuller name for the same row) --
    ('Triceps Rope',                             'b8b7c779-bf1d-4640-b01b-e206f8c45bbe'), -- -> Triceps rope extension on crossover machine

    -- CARS (Controlled Articular Rotations) at the ankle is a full circular ROM
    -- drill through dorsi/plantar-flexion + inversion/eversion -- the same
    -- movement as "Ankle Circles" (equipment/target overlap: calves + tibialis
    -- anterior) --
    ('Ankle Cars',                                '278fc36b-2593-4b5c-aae8-31614e4450ea'), -- -> Ankle Circles

    -- Same wall-press calf stretch, same target muscle (Calves), same bodyweight
    -- equipment class; "Push"/"V.2" is a naming/versioning variant, not a
    -- different stretch --
    ('Calf Push Stretch with Hands Against Wall V.2', 'b27a4840-5340-4be7-94b7-7ec7e2442f91'), -- -> Calf stretch with hands against wall

    -- "Horizontal Leg Press" cluster: exercise_library_cleaned confirms equipment
    -- = "Leg Press Machine" for all of these (no separate 45-degree/incline
    -- machine exists in this catalog to confuse it with), same target muscles --
    ('Horizontal Leg Press',                      '94a1483e-320d-42db-88f1-f7bdc4b9ac2f'), -- -> Leg press machine normal stance
    ('Horizontal Leg Press Calf Raise',            '3c0c5744-9119-41a7-ad45-ae4bb0e56ea7'), -- -> Leg Press Calf Raise

    -- "[Load type] Sled [verb]" names -- exercise_library_cleaned confirms the
    -- EQUIPMENT is "Sled" for all three (kettlebell/heavy-bag is just what's
    -- loaded onto the sled, not a different apparatus), and target muscles match
    -- the corresponding Sled Pull/Push direction --
    ('Kettlebell Sled Drag',                      '0cc2ed40-3bcb-4cab-a42e-7053abb320bc'), -- -> Sled Pull (target: Hamstrings/Glutes/Back, matches)
    ('Heavy Bag Sled Drag',                       '0cc2ed40-3bcb-4cab-a42e-7053abb320bc'), -- -> Sled Pull (target: Hamstrings/Glutes, matches)
    ('Single Kettlebell Sled Push',                '2fed6718-26be-41d7-b9ce-f3e87fec9f36'), -- -> Sled Push (target: Quads/Glutes, matches)

    -- Distance qualifier of the same running gait/movement, not a different
    -- movement --
    ('5K Run',                                    '80951e3d-8337-4187-8359-8a9c28a96bd1'), -- -> Running

    -- Same movement + target (unilateral leg-press-machine calf raise); target
    -- canonical currently has NO media (tracked separately, see header note) --
    ('Horizontal Leg Press Calf Raise Single-Leg', 'f084a829-2e12-4623-8b7d-95d9fd9c9f43')  -- -> Single leg calf raise leg press machine
) AS v(alias_name, canonical_exercise_id)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_aliases a
    WHERE a.alias_name_normalized = normalize_exercise_name(v.alias_name)
)
ON CONFLICT (alias_name_normalized) DO NOTHING;

COMMIT;

-- ─────────────────────────────────────────────────────────────────────────────
