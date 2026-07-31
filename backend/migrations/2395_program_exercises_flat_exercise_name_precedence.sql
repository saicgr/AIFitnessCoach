-- 2395_program_exercises_flat_exercise_name_precedence.sql
--
-- Fix the media resolver reading the WRONG name field. E2E register #126.
--
-- THE BUG
-- -------
-- Each `program_variant_weeks.workouts[].exercises[]` JSON element carries TWO
-- sibling name fields:
--   "name"          -- a free-text / display spelling, e.g. "Bodyweight standing
--                       calf raise"
--   "exercise_name" -- the library-matched spelling, e.g. "Standing Calf Raise"
--
-- They disagree on 11,899 of 177,318 occurrences catalogue-wide. The app's own
-- schedule endpoint (api/v1/program_templates.py:1949-1953) already knows
-- `exercise_name` is the trustworthy one and reads it FIRST:
--     ex_name = ex.get("exercise_name") or ex.get("name") or ""
--
-- But `program_exercises_flat` (the view `program_exercises_with_media` is
-- built on top of, via `pef.*`) normalizes ONLY `name`:
--     normalize_exercise_name(ex.value ->> 'name') AS exercise_name_normalized
-- and `program_exercises_with_media` joins exercise_aliases on exactly that
-- column:
--     LEFT JOIN exercise_aliases ea
--       ON pef.exercise_name_normalized = ea.alias_name_normalized
--
-- So the view's alias lookup — which feeds the position-matched media tier the
-- app tries FIRST — silently uses the worse-resolving field. Measured on the
-- 11,899 disagreeing rows: `exercise_name` resolves via alias for 100%
-- (11,899/11,899) while `name` resolves for only 50.6% (6,018). 5,214 of the
-- 20,332 missing-image occurrences (25.6%, E2E #122) would resolve today, with
-- NO program-content edit, once the view checks `exercise_name` too.
--
-- THE FIX
-- -------
-- Change `exercise_name_normalized`'s definition to match the app's own
-- precedence: `exercise_name` first, `name` second. This is a query-only
-- change — no new columns, no reordering — so both `program_exercises_flat`
-- and (unchanged) `program_exercises_with_media` (which selects `pef.*`) pick
-- it up automatically; views are not materialized, so the downstream view
-- re-evaluates through the corrected definition on every query without being
-- touched itself.
--
-- RECOVERED DDL (this view's definition lived ONLY in production — it is not
-- anywhere in the repo prior to this migration; captured verbatim via
-- `SELECT pg_get_viewdef('program_exercises_flat', true)` before this change,
-- so the repo is no longer blind to it):
--
--   SELECT pvw.variant_id,
--       pvw.week_number,
--       pvw.priority,
--       pvw.program_name,
--       pvw.phase,
--       pvw.focus,
--       w.workout_idx,
--       w.value ->> 'name'::text AS workout_name,
--       w.value ->> 'day'::text AS workout_day,
--       w.value ->> 'type'::text AS workout_type,
--       ex.exercise_idx,
--       ex.value ->> 'name'::text AS exercise_name,
--       normalize_exercise_name(ex.value ->> 'name'::text) AS exercise_name_normalized,
--       ex.value ->> 'sets'::text AS sets,
--       ex.value ->> 'reps'::text AS reps,
--       ex.value ->> 'duration'::text AS duration,
--       ex.value ->> 'rest'::text AS rest,
--       ex.value ->> 'tempo'::text AS tempo,
--       ex.value ->> 'notes'::text AS notes,
--       ex.value ->> 'equipment'::text AS equipment,
--       ex.value ->> 'body_part'::text AS body_part,
--       ex.value AS exercise
--      FROM program_variant_weeks pvw,
--       LATERAL jsonb_array_elements(pvw.workouts) WITH ORDINALITY w(value, workout_idx),
--       LATERAL jsonb_array_elements(w.value -> 'exercises'::text) WITH ORDINALITY ex(value, exercise_idx);
--
-- (reloptions at capture time: security_invoker=true — set via migration
-- 211_fix_security_definer_issues.sql's ALTER VIEW, not baked into the CREATE.)
--
-- SAFETY
-- ------
-- * `exercise_name` (the OUTPUT column, sourced from JSON `name`) is left
--   untouched — it is the display/free-text field and downstream consumers
--   (mark_programs_upcoming.py's report, generate_curated_variants.py's
--   printout) expect that semantic. Only `exercise_name_normalized` — the
--   join key, which nothing outside this view/its children reads directly —
--   changes meaning, from "resolve by display name" to "resolve the way the
--   app actually resolves."
-- * No columns added, none removed, none reordered ⇒ CREATE OR REPLACE VIEW
--   is legal without CASCADE, so the four dependent views this repo does not
--   carry DDL for (program_exercises_with_fallback,
--   program_exercises_with_media_fallback, program_analysis,
--   unmatched_exercises — none on the live serving path, all in
--   backend/scripts/ maintenance tooling only) are left completely alone.
-- * NULLIF on both sides: an empty-string "exercise_name" (seen in a handful
--   of older rows) falls through to "name" instead of normalizing to ''.
-- * Idempotent — CREATE OR REPLACE, safe to re-run.
-- * No MV refresh needed: exercise_library_cleaned does not depend on this
--   view (verified against pg_matviews, same as migration 2391).

BEGIN;

CREATE OR REPLACE VIEW program_exercises_flat AS
SELECT pvw.variant_id,
    pvw.week_number,
    pvw.priority,
    pvw.program_name,
    pvw.phase,
    pvw.focus,
    w.workout_idx,
    w.value ->> 'name'::text AS workout_name,
    w.value ->> 'day'::text AS workout_day,
    w.value ->> 'type'::text AS workout_type,
    ex.exercise_idx,
    ex.value ->> 'name'::text AS exercise_name,
    normalize_exercise_name(
        COALESCE(
            NULLIF(ex.value ->> 'exercise_name', ''),
            NULLIF(ex.value ->> 'name', '')
        )
    ) AS exercise_name_normalized,
    ex.value ->> 'sets'::text AS sets,
    ex.value ->> 'reps'::text AS reps,
    ex.value ->> 'duration'::text AS duration,
    ex.value ->> 'rest'::text AS rest,
    ex.value ->> 'tempo'::text AS tempo,
    ex.value ->> 'notes'::text AS notes,
    ex.value ->> 'equipment'::text AS equipment,
    ex.value ->> 'body_part'::text AS body_part,
    ex.value AS exercise
   FROM program_variant_weeks pvw,
    LATERAL jsonb_array_elements(pvw.workouts) WITH ORDINALITY w(value, workout_idx),
    LATERAL jsonb_array_elements(w.value -> 'exercises'::text) WITH ORDINALITY ex(value, exercise_idx);

ALTER VIEW program_exercises_flat SET (security_invoker = true);

COMMIT;

-- ─────────────────────────────────────────────────────────────────────────────
-- Verification (run after applying)
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Column shape unchanged (still 22 columns, same names/order):
--   SELECT count(*) FROM information_schema.columns
--   WHERE table_name = 'program_exercises_flat';
--
-- The headline case now resolves through the view's own alias join
-- (exercise_name_normalized = 'standing calf raise', which DOES have a
-- self-alias after migration 2391):
--   SELECT exercise_name, exercise_name_normalized
--   FROM program_exercises_flat
--   WHERE exercise_name = 'Bodyweight standing calf raise' LIMIT 1;
--
--   SELECT canonical_name, image_s3_path, media_status
--   FROM program_exercises_with_media
--   WHERE exercise_name = 'Bodyweight standing calf raise' LIMIT 1;
--
-- Reloptions preserved:
--   SELECT relname, reloptions FROM pg_class
--   WHERE relname IN ('program_exercises_flat','program_exercises_with_media');
