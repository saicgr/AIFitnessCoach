-- Migration 1597: Fix stretch exercises in exercise library and existing workouts
--
-- Part 1: Reclassify exercises with stretch/flexibility indicators in their name
-- but wrong body_part/category metadata.
-- ~115 exercises have body_part = 'Bodyweight' and category = NULL
-- despite being stretch/flexibility movements.

UPDATE exercise_library
SET body_part = 'stretching', category = 'stretching'
WHERE body_part != 'stretching'
  AND (
    exercise_name ILIKE '%stretch%'
    OR exercise_name ILIKE '%opens'
    OR exercise_name ILIKE '%opener%'
    OR exercise_name ILIKE 'child pose%'
    OR exercise_name ILIKE '%pigeon%'
    OR exercise_name ILIKE '%cat stretch%'
    OR exercise_name ILIKE '%pretzel%'
    OR exercise_name ILIKE '%scorpion%'
  )
  AND exercise_name NOT ILIKE '%dumbbell%'
  AND exercise_name NOT ILIKE '%resistance band%'
  AND exercise_name NOT ILIKE '%plyo%';

-- Part 2: Delete future incomplete strength/cardio workouts that contain
-- stretch exercises. The /today endpoint's proactive background generation
-- will automatically detect the missing workouts and regenerate them
-- (clean, without stretches) on each user's next app open.
-- Mobility/recovery/flexibility workouts are left untouched.

DELETE FROM workouts
WHERE is_completed = false
  AND scheduled_date >= NOW()
  AND type NOT IN ('mobility', 'recovery', 'flexibility')
  AND EXISTS (
    SELECT 1 FROM jsonb_array_elements(exercises_json) AS ex
    WHERE ex->>'name' ILIKE '%stretch%'
       OR ex->>'name' ILIKE '%opens'
       OR ex->>'name' ILIKE '%opener%'
       OR ex->>'name' ILIKE '%child pose%'
       OR ex->>'name' ILIKE '%pigeon%'
       OR ex->>'name' ILIKE '%scorpion%'
       OR ex->>'name' ILIKE '%pretzel%'
       OR ex->>'body_part' ILIKE 'stretching'
  );
