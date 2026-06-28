-- 2297_fix_exercise_demos_illustration_prefix.sql
--
-- exercise_demos.image_s3_path stored the legacy, non-existent
-- `ILLUSTRATIONS/` S3 prefix (the bucket only ever had `ILLUSTRATIONS ALL/`,
-- trailing-space + ALL). exercise_demos is what the canonical/demos fallback
-- RPC (resolve_exercise_demo_media) reads, which the Program schedule and the
-- active-workout image resolver use for program-generated exercise names —
-- so every one of those images 404'd. 2113 of 2146 rows were affected.
--
-- Rewrite the prefix to the real one. The match is exact: `ILLUSTRATIONS ALL/`
-- has a space (not a slash) after the word, so already-correct rows are never
-- touched. Video paths (`VERTICAL VIDEOS/`) are already correct and untouched.
-- A read-time guard in api/v1/library/utils.py (_canonical_illustration_prefix)
-- belt-and-suspenders any value this misses.

UPDATE public.exercise_demos
SET image_s3_path = replace(
        image_s3_path,
        's3://ai-fitness-coach/ILLUSTRATIONS/',
        's3://ai-fitness-coach/ILLUSTRATIONS ALL/'
    )
WHERE image_s3_path LIKE 's3://ai-fitness-coach/ILLUSTRATIONS/%';
