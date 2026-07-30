-- 2381 — give the onboarding fitness assessment somewhere to land, and stop
--        pretending an un-chosen weight unit is a chosen 'kg'.
--
-- WHY (E2E register rows 8 + 18)
-- ------------------------------
-- 1. FITNESS ASSESSMENT WAS 100% THEATRE.
--    `fitness_assessment_screen.dart` collects five capacities, the payload
--    builder POSTs pushup/pullup/plank/squat/cardio_capacity to
--    POST /users/{id}/preferences, and `users` had NO column for any of them —
--    so the whole assessment step of onboarding wrote nothing anywhere.
--    Meanwhile the generator reads them straight off the users row
--    (api/v1/workouts/generation_endpoints.py:461-467
--     `user.get("pushup_capacity") ... has_assessment = any([...])`),
--    which was therefore structurally False for every user, forever.
--    `training_experience` has the same shape: the generator reads
--    `user.get("training_experience")` off the users row, but onboarding only
--    ever stored it inside the `preferences` JSONB — so that read was always
--    None too. Both are fixed here by making the columns real; the JSONB copy
--    is kept as-is (nothing is deleted) and backfilled forward.
--
-- 2. users.weight_unit DEFAULT 'kg' MADE "NEVER ASKED" INDISTINGUISHABLE FROM
--    "CHOSE KG". Nothing in onboarding ever wrote the column, so every account
--    — including US users who toggled to lb during the quiz — read back 'kg',
--    and the workout logger followed it. The project rule is three SEPARATE
--    unit settings (body weight / workout weight / measurement), each of which
--    must record an actual choice. Dropping the column DEFAULT makes NULL mean
--    "not chosen yet", which is what lets the resolvers that already prefer
--    lbs (api/v1/workouts_db_versioning.py:450-459,
--    api/v1/workouts/suggestions.py:350) behave correctly, and what lets the
--    onboarding write in api/v1/users/onboarding.py be verified.
--
--    Existing rows are NOT touched: their stored 'kg' may be a real choice and
--    logged-data durability is a standing rule. Only new rows get the honest
--    NULL.
--
-- SAFETY
-- ------
-- ADD COLUMN ... text with no DEFAULT and no NOT NULL is a catalog-only change
-- in PostgreSQL (no table rewrite, no long ACCESS EXCLUSIVE hold).
-- ALTER COLUMN ... DROP DEFAULT is also catalog-only.
-- The backfill UPDATE touches at most the handful of rows that already carry
-- training_experience in their preferences JSONB.

BEGIN;

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS pushup_capacity     text,
  ADD COLUMN IF NOT EXISTS pullup_capacity     text,
  ADD COLUMN IF NOT EXISTS plank_capacity      text,
  ADD COLUMN IF NOT EXISTS squat_capacity      text,
  ADD COLUMN IF NOT EXISTS cardio_capacity     text,
  ADD COLUMN IF NOT EXISTS training_experience text;

COMMENT ON COLUMN public.users.pushup_capacity IS
  'Onboarding fitness assessment bucket, verbatim from the client '
  '(''none'' | ''1-10'' | ''11-25'' | ''26-40'' | ''40+''). Read by '
  'api/v1/workouts/generation_endpoints.py to personalise the first plan.';
COMMENT ON COLUMN public.users.pullup_capacity IS
  'Onboarding fitness assessment bucket (''none'' | ''assisted'' | ''1-5'' | ''6-10'' | ''10+'').';
COMMENT ON COLUMN public.users.plank_capacity IS
  'Onboarding fitness assessment bucket (''<15sec'' | ''15-30sec'' | ''31-60sec'' | ''1-2min'' | ''2+min'').';
COMMENT ON COLUMN public.users.squat_capacity IS
  'Onboarding fitness assessment bucket (''0-10'' | ''11-25'' | ''26-40'' | ''40+'').';
COMMENT ON COLUMN public.users.cardio_capacity IS
  'Onboarding fitness assessment bucket (''<5min'' | ''5-15min'' | ''15-30min'' | ''30+min'').';
COMMENT ON COLUMN public.users.training_experience IS
  'Onboarding "how long have you trained" answer. Promoted from the preferences '
  'JSONB to a real column because the workout generator reads it off the users row.';

-- Forward-fill the column from the JSONB copy onboarding has been writing.
UPDATE public.users
   SET training_experience = nullif(preferences->>'training_experience', '')
 WHERE training_experience IS NULL
   AND preferences ? 'training_experience'
   AND nullif(preferences->>'training_experience', '') IS NOT NULL;

-- "Never chose a unit" must be representable.
ALTER TABLE public.users ALTER COLUMN weight_unit DROP DEFAULT;

COMMENT ON COLUMN public.users.weight_unit IS
  'BODY weight unit (''kg''|''lbs''). NULL = the user has not chosen one yet — '
  'callers resolve their own default (backend convention is lbs). Deliberately '
  'has no column DEFAULT so an un-asked user is distinguishable from one who '
  'picked kg. Separate from workout_weight_unit / measurement_unit / distance_unit.';

COMMIT;
