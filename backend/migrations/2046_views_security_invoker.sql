-- ============================================================================
-- 2046 — Flip 4 public views from SECURITY DEFINER → security_invoker=true
-- ============================================================================
--
-- Supabase database linter (lint code 0010) flagged these 4 views as ERROR-
-- level: they execute with the view-creator's permissions and bypass the
-- querying user's RLS. With `security_invoker = true` the view honors the
-- caller's RLS, which is what we want for every public view.
--
-- Already applied to prod via .venv/bin/python on 2026-05-02; this file
-- is the durable record so a future env restore picks it up.
--
-- Docs: https://supabase.com/docs/guides/database/database-linter?lint=0010_security_definer_view
-- ============================================================================

ALTER VIEW public.lifetime_founder_seats_public SET (security_invoker = true);
ALTER VIEW public.exercise_workout_history       SET (security_invoker = true);
ALTER VIEW public.weekly_progress_summary        SET (security_invoker = true);
ALTER VIEW public.muscle_group_weekly_volume     SET (security_invoker = true);

-- Verify (no-op runtime, just an assertion via NOTICE):
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT c.relname,
           COALESCE((SELECT option_value FROM pg_options_to_table(c.reloptions)
                     WHERE option_name = 'security_invoker'), 'false') AS si
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname IN (
        'lifetime_founder_seats_public',
        'exercise_workout_history',
        'weekly_progress_summary',
        'muscle_group_weekly_volume'
      )
  LOOP
    IF r.si <> 'true' THEN
      RAISE EXCEPTION 'View % did not flip to security_invoker=true (got %)', r.relname, r.si;
    END IF;
  END LOOP;
  RAISE NOTICE '✅ All 4 views now use security_invoker=true';
END $$;
