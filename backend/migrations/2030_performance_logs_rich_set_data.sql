-- Round out per-set fidelity on performance_logs so the active-workout
-- client can persist (and round-trip) every signal it captures during a
-- set, not just a thinned-out projection. Missing pieces today:
--
--   1. `notes` is a single TEXT — overwritten on each "send" from the
--      inline-rest UI, so users who add multiple per-set notes lose all
--      but the last. We migrate it to TEXT[] (preserving any existing
--      single-string note as a one-element array).
--   2. `notes_audio_url` / `notes_photo_urls` were referenced in the
--      writer (crud_background_tasks.py:507-529) but never had a real
--      migration against `performance_logs`. The earlier file
--      `migrations/add_set_note_media.sql` targeted a `set_performances`
--      table that doesn't actually exist; this migration fills the gap.
--   3. `started_at` complements the existing `set_duration_seconds` so we
--      can render a true set timeline on the Advanced summary tab (and
--      compute pace deltas against prior sessions).
--   4. `logging_mode` records which active-workout UI tier the user was
--      on when they tapped ✓ (`'easy'|'simple'|'advanced'`). Powers
--      tier-aware analytics; NULL on legacy rows is treated as 'advanced'
--      by the client (matches the comment in workout_state.dart:25-26).
--
-- Backwards compatibility:
--   - The TEXT → TEXT[] conversion uses CASE/USING so existing rows are
--     wrapped into a single-element array; never lost.
--   - Empty / NULL / whitespace-only notes become an empty array.
--   - All new columns are NULLABLE so legacy reads still succeed.
--   - The backend READ path (crud_completion.py) and the Dart-side
--     SetLogInfo both coerce a list/string/null shape — this migration
--     plus those coercions form a stable round-trip across deploys.

-- 1. notes: TEXT → TEXT[] -----------------------------------------------
-- We can't simply ALTER COLUMN ... TYPE TEXT[] without a USING expression
-- because Postgres doesn't auto-cast scalar to array. The CASE preserves
-- existing single-note rows as a one-element array and discards empty/
-- whitespace strings (which would round-trip as `[""]` otherwise).

ALTER TABLE performance_logs
    ALTER COLUMN notes TYPE TEXT[]
    USING (
        CASE
            WHEN notes IS NULL THEN NULL
            WHEN btrim(notes) = '' THEN ARRAY[]::TEXT[]
            ELSE ARRAY[notes]
        END
    );

ALTER TABLE performance_logs
    ALTER COLUMN notes SET DEFAULT ARRAY[]::TEXT[];

COMMENT ON COLUMN performance_logs.notes IS
    'Per-set user notes, ordered by capture time. TEXT[] so multiple notes per set are preserved (the inline-rest UI lets users add several per set).';


-- 2. notes_audio_url + notes_photo_urls --------------------------------

ALTER TABLE performance_logs
    ADD COLUMN IF NOT EXISTS notes_audio_url TEXT,
    ADD COLUMN IF NOT EXISTS notes_photo_urls TEXT[];

COMMENT ON COLUMN performance_logs.notes_audio_url IS
    'Optional voice-note recording attached to this set. Canonical S3 URL (uploaded via SetNoteMediaService before persistence).';

COMMENT ON COLUMN performance_logs.notes_photo_urls IS
    'Optional photo attachments (0..N) for this set. Canonical S3 URLs.';


-- 3. started_at ---------------------------------------------------------
-- Pairs with the existing set_duration_seconds so the summary screen can
-- show the true set start time, not just elapsed seconds.

ALTER TABLE performance_logs
    ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;

COMMENT ON COLUMN performance_logs.started_at IS
    'When the set began (after rest ended). Pairs with set_duration_seconds. NULL on legacy rows.';


-- 4. logging_mode -------------------------------------------------------
-- 'easy' | 'simple' | 'advanced'. NULL on legacy rows is read as
-- 'advanced' by the client (matches workout_state.dart:25-26).

ALTER TABLE performance_logs
    ADD COLUMN IF NOT EXISTS logging_mode VARCHAR(16);

COMMENT ON COLUMN performance_logs.logging_mode IS
    'Active-workout UI tier the user was on when they logged this set. easy | simple | advanced. NULL = legacy = advanced.';


-- 5. Helpful indexes ----------------------------------------------------
-- The summary-screen read filters by workout_log_id; existing PKey already
-- satisfies that. logging_mode is queried for tier analytics in low-volume
-- aggregate jobs — partial index keeps the cost trivial.

CREATE INDEX IF NOT EXISTS idx_performance_logs_logging_mode
    ON performance_logs(logging_mode)
    WHERE logging_mode IS NOT NULL;
