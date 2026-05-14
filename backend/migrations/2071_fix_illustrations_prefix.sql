-- Fix wrong S3 prefix on exercise illustration paths.
--
-- The bucket has `ILLUSTRATIONS ALL/` (with trailing space + ALL). Plain
-- `ILLUSTRATIONS/` does not exist as a top-level prefix, so any row whose
-- image_s3_path starts with `s3://ai-fitness-coach/ILLUSTRATIONS/` resolves
-- to a missing S3 object and the Flutter client falls back to the dumbbell
-- placeholder. As of 2026-05-13 there are 53 such rows in
-- exercise_library_manual; exercise_library base table is clean.
--
-- Symptom this fixes: "Leg Press" (and several other manual-table exercises)
-- show the empty placeholder thumbnail in the Swap Exercise Library tab even
-- though their illustration files exist in S3 at the correct prefix.

UPDATE exercise_library_manual
   SET image_s3_path = replace(
         image_s3_path,
         's3://ai-fitness-coach/ILLUSTRATIONS/',
         's3://ai-fitness-coach/ILLUSTRATIONS ALL/'
       )
 WHERE image_s3_path LIKE 's3://ai-fitness-coach/ILLUSTRATIONS/%';

-- Same defensive fix for the base table in case future inserts use the
-- wrong prefix. No-op today (count = 0 at write time).
UPDATE exercise_library
   SET image_s3_path = replace(
         image_s3_path,
         's3://ai-fitness-coach/ILLUSTRATIONS/',
         's3://ai-fitness-coach/ILLUSTRATIONS ALL/'
       )
 WHERE image_s3_path LIKE 's3://ai-fitness-coach/ILLUSTRATIONS/%';

-- Refresh the cleaned MV so the corrected paths are immediately visible to
-- the library list endpoint and the /exercise-images/ lookup.
REFRESH MATERIALIZED VIEW CONCURRENTLY public.exercise_library_cleaned;
