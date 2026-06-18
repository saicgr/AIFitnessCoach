-- Migration 2264: Fix broken feature-request suggestion-limit trigger
--
-- BUG: migration 074_fix_function_search_paths.sql redefined
-- check_user_suggestion_limit() to reference column `suggested_by`, which does
-- NOT exist on feature_requests (the column is `created_by`). Result: EVERY
-- insert into feature_requests raised `column "suggested_by" does not exist`,
-- so the in-app feature board could never accept a user submission (and the
-- board was unreachable, so it went unnoticed).
--
-- FIX: restore the function to the real column `created_by`, align the cap with
-- the backend (api/v1/features.py enforces 2 total per user), and skip the check
-- for team/official rows (created_by IS NULL). Keep 074's hardening
-- (SECURITY INVOKER + fixed search_path).

CREATE OR REPLACE FUNCTION public.check_user_suggestion_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Official / seeded rows (no author) bypass the per-user cap.
    IF NEW.created_by IS NULL THEN
        RETURN NEW;
    END IF;

    IF (SELECT COUNT(*) FROM feature_requests WHERE created_by = NEW.created_by) >= 2 THEN
        RAISE EXCEPTION 'User has reached the maximum of 2 feature suggestions';
    END IF;

    RETURN NEW;
END;
$$;
