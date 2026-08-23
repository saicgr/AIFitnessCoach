-- Migration: Migrate users.goals from VARCHAR-of-JSON to real jsonb (finding #40)
--
-- `goals` is stored as a stringified JSON array ('["build_muscle"]') while its
-- sibling column `active_injuries` on the very same row is a real jsonb array.
-- Every consumer of `goals` has to `json.loads()` a text column and handle the
-- failure case (a handful of legacy rows hold bare non-JSON tokens like "N/A"
-- instead of an array). Convert the column to jsonb so it matches
-- `active_injuries` and downstream code can drop the string-vs-list branching.
--
-- USING clause handles every shape seen in production:
--   NULL                          -> NULL
--   valid JSON array text         -> cast directly
--   ''                            -> '[]'
--   bare sentinel ('N/A'/'NA'/'none', case-insensitive) -> '[]'
--   any other bare scalar string  -> wrapped as a single-element array,
--                                    matching how the app already treats a
--                                    lone non-JSON value (see
--                                    api/v1/users/profile.py:_parse_list_field).

-- public.chat_message_reports_with_user selects users.goals, so the column
-- type cannot be altered while it exists. Drop and recreate it verbatim.
DROP VIEW IF EXISTS public.chat_message_reports_with_user;

DO $mig$
BEGIN
  -- Idempotent: only convert when the column is still text. Re-running this
  -- migration against an already-converted column would fail on trim(jsonb).
  IF (SELECT data_type FROM information_schema.columns
       WHERE table_name='users' AND column_name='goals') <> 'jsonb' THEN
ALTER TABLE users
  ALTER COLUMN goals TYPE jsonb USING (
    CASE
      WHEN goals IS NULL THEN NULL
      WHEN trim(goals) = '' THEN '[]'::jsonb
      WHEN lower(trim(goals)) IN ('n/a', 'na', 'none') THEN '[]'::jsonb
      WHEN trim(goals) ~ '^\[' THEN goals::jsonb
      ELSE to_jsonb(ARRAY[trim(goals)])
    END
  );
  END IF;
END
$mig$;

ALTER TABLE users ALTER COLUMN goals SET DEFAULT '[]'::jsonb;

CREATE VIEW public.chat_message_reports_with_user AS
 SELECT r.id,
    r.user_id,
    r.message_id,
    r.report_category,
    r.report_reason,
    r.original_user_message,
    r.reported_ai_response,
    r.ai_analysis,
    r.status,
    r.resolution_note,
    r.reviewed_at,
    r.reviewed_by,
    r.created_at,
    r.updated_at,
    u.username,
    u.name AS user_name,
    u.fitness_level,
    u.goals AS user_goals
   FROM chat_message_reports r
     LEFT JOIN users u ON r.user_id = u.auth_id;




-- VERIFY: select data_type from information_schema.columns where table_name='users' and column_name='goals'; -- expect jsonb
-- VERIFY: select id, goals from users where jsonb_typeof(goals) <> 'array'; -- expect 0 rows
