-- Migration 2421: refresh the stale exercise_library_cleaned materialized
-- view so the Chaturanga spelling fix (migration 2416) reaches search.
--
-- `exercise_library_cleaned` is a MATERIALIZED view (migration 2037); the
-- dirty-marker trigger from migration 2038 correctly queued it after 2416's
-- UPDATE on exercise_library, but nothing has consumed that queue since
-- (`mv_refresh_queue.last_refresh` for exercise_library_cleaned is still
-- 2026-08-07, well before 2416 ran). Until it is refreshed, the search RPC
-- (`fuzzy_search_exercises_api`, which reads this MV, not the base table)
-- keeps serving the pre-fix "3 Leg Chatarunga Pose" name and a search for
-- the correct "chaturanga" spelling still returns nothing — the base-table
-- fix alone does not reach the user-facing search path.
--
-- `refresh_exercise_library_cleaned(true)` (added in 2038) forces the
-- CONCURRENTLY refresh of both this MV and its dependent
-- exercise_safety_index_mat, and clears the queue marker.

SELECT public.refresh_exercise_library_cleaned(true);

-- VERIFY: select name from exercise_library_cleaned where name ilike '%chaturanga%'; -- expect 1 row, "3 Leg Chaturanga Pose"
-- VERIFY: select name from fuzzy_search_exercises_api('chaturanga', NULL, NULL, 5); -- expect a match, not empty
-- VERIFY: select queued_at from mv_refresh_queue where mv_name = 'exercise_library_cleaned'; -- expect NULL
