-- 2109_workouts_display_title_localized.sql
--
-- Per-locale translation cache for LLM-generated workout titles.
--
-- Why: Workouts like "Golden Peak Vitality" are generated in English by Gemini
-- at creation time and persisted to `workouts.name`. Telugu / Hindi / Japanese
-- users see the English string verbatim on the workout detail screen
-- (reported 2026-05-25). Re-translating every read via Gemini would be
-- expensive and slow, so we cache per-locale renderings on the row.
--
-- Shape: `{ "te": "...telugu title...", "hi": "...", ... }`. NULL when no
-- translations have been requested yet. The backend resolves
-- `display_title_localized[user_locale]` at read; if missing, it returns the
-- English `name` and queues a background translation that updates this column.
-- Next read hits the cache.
--
-- This is intentionally append-only at the JSONB level — translations are not
-- deleted automatically. If the source `name` changes (rare) callers can
-- clear the row's JSONB to force re-translation.

ALTER TABLE workouts
    ADD COLUMN IF NOT EXISTS display_title_localized JSONB;

-- Cheap partial index for the "needs translation" check in batch refreshers.
CREATE INDEX IF NOT EXISTS workouts_display_title_localized_null_idx
    ON workouts (id)
    WHERE display_title_localized IS NULL;

COMMENT ON COLUMN workouts.display_title_localized IS
    'Per-locale cache of the LLM-generated `name`. Keys = ISO 639-1 codes (te, hi, ja…). NULL = never translated. Backfilled lazily on first read in a non-en locale via services/workout_title_translator.py.';
