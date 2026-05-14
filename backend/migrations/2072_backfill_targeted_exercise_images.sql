-- Targeted image backfill for the leg/back/chest exercises the user
-- reported as showing the dumbbell-placeholder thumbnail in the Swap
-- Exercise Library tab. Each mapping was audited against the actual S3
-- filename under `ILLUSTRATIONS ALL/<Folder>/` before applying.
--
-- These rows had `image_s3_path = NULL` in `exercise_library_manual` even
-- though a matching illustration existed in S3 (the source naming and the
-- exercise display name diverged enough that the original import pass
-- didn't auto-link them).
--
-- Companion to migration 2071 which fixed the wrong-prefix problem. The
-- 700+ remaining NULL rows need a broader backfill pass via the existing
-- `backend/scripts/populate_missing_exercise_images.py` (extend its
-- BODY_PART_FOLDERS map to cover muscle-group names + add a no-Gemini
-- fuzzy-match mode for clear-cut folder matches).

UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Legs/Lever Leg Extension.jpg'                     WHERE exercise_name ILIKE 'Leg Extension'                       AND image_s3_path IS NULL;
UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Legs/Horizontal Leg Press Calf Raise.jpg'         WHERE exercise_name ILIKE 'Leg Press Calf Raise'                AND image_s3_path IS NULL;
UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Legs/leg press wide high stance  .jpg'           WHERE exercise_name ILIKE 'Leg Press Wide Stance'               AND image_s3_path IS NULL;
UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Legs/Seated leg curl machine  .jpg'              WHERE exercise_name ILIKE 'Seated Leg Curl'                     AND image_s3_path IS NULL;
UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Legs/lying leg curl machine  .jpg'               WHERE exercise_name ILIKE 'Lying Leg Curl'                      AND image_s3_path IS NULL;
UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Shoulders/smith machine shoulder press .jpg'     WHERE exercise_name ILIKE 'Smith Machine Shoulder Press'        AND image_s3_path IS NULL;
UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Legs/smith machine calf raise  .jpg'             WHERE exercise_name ILIKE 'Smith Machine Calf Raise'            AND image_s3_path IS NULL;
UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Abdominals/brazilian crunches.jpeg'              WHERE exercise_name ILIKE 'Brazilian crunches'                  AND image_s3_path IS NULL;
UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Chest/machine chest press decline 1.jpg'         WHERE exercise_name ILIKE 'Machine Chest Press'                 AND image_s3_path IS NULL;
UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Back/Seated Row Machine Rows.jpg'                WHERE exercise_name ILIKE 'Seated Row Machine'                  AND image_s3_path IS NULL;
UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Legs/bulgarian split squat bodyweight left  .jpg' WHERE exercise_name ILIKE 'Bulgarian split squat bodyweight'   AND image_s3_path IS NULL;
UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Legs/Bench Bulgarian Split Squats left  .jpg'    WHERE exercise_name ILIKE 'Bench Bulgarian Split Squats'        AND image_s3_path IS NULL;
UPDATE exercise_library_manual SET image_s3_path = 's3://ai-fitness-coach/ILLUSTRATIONS ALL/Legs/Hack Squat Machine_Female.jpg'              WHERE exercise_name ILIKE 'Hack Squat'                          AND image_s3_path IS NULL;

REFRESH MATERIALIZED VIEW CONCURRENTLY public.exercise_library_cleaned;
