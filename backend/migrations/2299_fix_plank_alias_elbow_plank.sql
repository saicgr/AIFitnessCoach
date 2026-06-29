-- 2299_fix_plank_alias_elbow_plank.sql
-- ============================================================
-- Corrects 2298_hyrox_station_alias_fixes.sql.
--
-- 2298 remapped the HYROX "Plank" / "Plank Hold" aliases to "High plank".
-- That is the STRAIGHT-ARM plank (push-up position). A HYROX plank hold is a
-- static FOREARM / ELBOW plank. Repoint both aliases to the "Plank on elbows"
-- canonical, which has the correct illustration
-- (ILLUSTRATIONS ALL/Abdominals/plank on elbows.jpeg) and a matching
-- exercise_library video ("plank on elbows").
--
-- The VIDEO path (/videos/by-exercise) is aligned in code via the static
-- override in backend/api/v1/videos.py (_STATIC_NAME_ALIASES).
--
-- Idempotent: only updates rows still pointing at the 2298 "High plank" target.
-- ============================================================

UPDATE exercise_aliases
SET    canonical_exercise_id = '2e133235-8f83-4968-bc2a-d6d873038daa'  -- Plank on elbows
WHERE  alias_name_normalized IN ('plank', 'plank hold')
  AND  canonical_exercise_id = 'dc6422e2-2c36-427f-8553-6a9d749f5e6b'; -- High plank (set by 2298)
