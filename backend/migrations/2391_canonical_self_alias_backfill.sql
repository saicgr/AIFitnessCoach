-- 2391_canonical_self_alias_backfill.sql
--
-- Make every canonical exercise resolvable BY ITS OWN NAME.
--
-- THE BUG
-- -------
-- `resolve_exercise_demo_media(p_name)` (migration 2290) is the read-time chokepoint
-- for exercise images and videos. It resolves a name only through `exercise_aliases`:
--
--     WHERE a.alias_name_normalized = normalize_exercise_name(p_name)
--
-- But `exercise_aliases` was only ever populated with *alternate* spellings — the
-- canonical exercise's own name was never registered. 1697 of 2070 canonical
-- exercises (82%) had no alias for their own normalized name, so they were invisible
-- to the resolver even when `exercise_demos` held real S3 media for them.
--
-- Production symptom (2026-07-30): a continuous 404 storm on
--   GET /api/v1/exercise-images/Bodyweight%20standing%20calf%20raise
--   GET /api/v1/videos/by-exercise/Bodyweight%20standing%20calf%20raise
-- That exercise HAS a canonical row AND an exercise_demos row carrying both
--   s3://ai-fitness-coach/ILLUSTRATIONS ALL/Legs/Bodyweight Standing Calf Raise.jpg
--   s3://ai-fitness-coach/VERTICAL VIDEOS ALL/Legs/Bodyweight Standing Calf Raise.mp4
-- Its aliases were 'bodyweight calf raise' and 'standing calf raise' — but not its
-- own name. The media existed and was simply unreachable.
--
-- This is a reachability fix, not a media fix: `exercise_library` has 0 rows missing
-- an image. 1581 of the 1697 inserted here have demo media and become resolvable
-- immediately; the remaining 116 are covered by the separate missing-illustration
-- generation pass.
--
-- SAFETY
-- ------
-- * Exact-normalized only. A self-alias maps an exercise to ITSELF, so this cannot
--   serve a sibling exercise's media. The cross-exercise fuzzy fallback stays
--   disabled (see api/v1/videos.py "lat-pulldown bug" and
--   tests/test_exercise_image_no_fuzzy.py).
-- * Existing aliases WIN. `NOT EXISTS` skips any normalized name already mapped, so
--   the hand-curated corrections in 2300_catalog_alias_corrections.sql are preserved
--   untouched.
-- * `alias_name_normalized` carries a UNIQUE index. 102 normalized names are shared
--   by more than one canonical row (e.g. six 'Crunch (…)' variants all normalize to
--   'crunch', since normalize_exercise_name strips parentheticals). DISTINCT ON picks
--   exactly one winner per normalized name, deterministically: prefers a row that has
--   demo media, then one with BOTH image and video, then the shortest canonical name
--   (favouring 'Barbell Deadlift' over 'Barbell Deadlift (side POV)'), then lowest id.
--   ON CONFLICT DO NOTHING makes re-runs and concurrent application safe.
-- * `match_type = 'canonical_self'` deliberately does NOT reuse 'exact'. Per the note
--   at api/v1/program_templates.py:1971, existing match_confidence/is_verified values
--   are NOT trustworthy for separating good matches from bad. Self-aliases are
--   definitionally correct, so they get their own tag and can be trusted as a subset
--   without implying anything about the noisy word_overlap/fuzzy rows.
-- * Uses normalize_exercise_name(canonical_name), NOT the stored
--   exercise_canonical.canonical_name_normalized column — that column disagrees with
--   the function on 109 rows, and the function is what the RPC matches against.
-- * Idempotent. Re-running inserts nothing.
--
-- No MV refresh: exercise_library_cleaned does not reference exercise_aliases
-- (verified against pg_matviews).

BEGIN;

INSERT INTO exercise_aliases (
    alias_name,
    alias_name_normalized,
    canonical_exercise_id,
    match_type,
    match_confidence,
    is_verified
)
SELECT DISTINCT ON (normalize_exercise_name(ec.canonical_name))
       ec.canonical_name,
       normalize_exercise_name(ec.canonical_name),
       ec.id,
       'canonical_self',
       1.0,
       TRUE
FROM   exercise_canonical ec
LEFT JOIN LATERAL (
    SELECT bool_or(d.image_s3_path IS NOT NULL OR  d.video_s3_path IS NOT NULL) AS has_media,
           bool_or(d.image_s3_path IS NOT NULL AND d.video_s3_path IS NOT NULL) AS has_both
    FROM   exercise_demos d
    WHERE  d.canonical_exercise_id = ec.id
) m ON TRUE
WHERE  normalize_exercise_name(ec.canonical_name) IS NOT NULL
  AND  normalize_exercise_name(ec.canonical_name) <> ''
  AND  NOT EXISTS (
           SELECT 1
           FROM   exercise_aliases a
           WHERE  a.alias_name_normalized = normalize_exercise_name(ec.canonical_name)
       )
ORDER  BY normalize_exercise_name(ec.canonical_name),
          COALESCE(m.has_media, FALSE) DESC,   -- a self-alias to a media-less row is useless
          COALESCE(m.has_both,  FALSE) DESC,   -- prefer image + video
          LENGTH(ec.canonical_name) ASC,       -- prefer the unqualified base name
          ec.id ASC                            -- fully deterministic
ON CONFLICT (alias_name_normalized) DO NOTHING;

COMMIT;

-- ─────────────────────────────────────────────────────────────────────────────
-- Verification (run after applying)
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Measured on a rolled-back dry run against production before applying.
--
-- Expect 1612 rows tagged canonical_self. (1697 canonical rows needed one, but the
-- 102 collision groups collapse to a single winner each.)
--   SELECT count(*) FROM exercise_aliases WHERE match_type = 'canonical_self';
--
-- Expect 0 — every canonical's normalized name is now covered by some alias:
--   SELECT count(*) FROM exercise_canonical ec
--   WHERE NOT EXISTS (SELECT 1 FROM exercise_aliases a
--                     WHERE a.alias_name_normalized = normalize_exercise_name(ec.canonical_name));
--
-- Expect 42 — canonicals whose normalized name resolves to a DIFFERENT canonical
-- (the collision losers). Pre-existing casing/parenthetical duplicates in
-- exercise_canonical; NOT made worse here. Deduplicating exercise_canonical is the
-- real fix and is deliberately out of scope:
--   SELECT count(*) FROM exercise_canonical ec
--   WHERE EXISTS (SELECT 1 FROM exercise_aliases a
--                 WHERE a.alias_name_normalized = normalize_exercise_name(ec.canonical_name)
--                   AND a.canonical_exercise_id <> ec.id);
--
-- Expect 1946/2070 canonical names resolvable through the RPC. The ~124 shortfall is
-- exactly the set with no exercise_demos media at all — covered by the separate
-- illustration-generation pass, not by aliasing:
--   SELECT count(*) FROM exercise_canonical ec
--   WHERE EXISTS (SELECT 1 FROM resolve_exercise_demo_media(ec.canonical_name));
--
-- The headline case must now return an image AND a video path:
--   SELECT * FROM resolve_exercise_demo_media('Bodyweight standing calf raise');
