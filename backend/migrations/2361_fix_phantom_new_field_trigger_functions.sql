-- ============================================================================
-- 2361 — Repair trigger functions that reference NEW/OLD fields (and tables)
--        that do not exist. E2E register rows 98 + 105.
-- ============================================================================
--
-- SYMPTOM (row 105): every INSERT into public.saved_workouts raised
--   42703  record "new" has no field "workout_id"
-- so the coach workout card's "Save" button 500'd on every tap and
-- saved_workouts stayed at 0 rows for the whole project.
--
-- ROOT CAUSE: migrations 026_fix_function_search_path.sql and
-- 074_fix_function_search_paths.sql were sweeps whose only intent was to add
-- `SET search_path = public` to existing functions. Instead of preserving each
-- function's body they REWROTE it from scratch against an imagined schema:
--
--   update_workout_share_count      → UPDATE workouts SET share_count ...
--                                     WHERE id = NEW.workout_id
--                                     (saved_workouts has no workout_id;
--                                      workouts has no share_count)
--   update_feature_vote_count       → NEW.feature_request_id  (col is feature_id)
--   update_saved_workout_completion → NEW.is_completed        (col is status)
--   update_daily_stats_on_screen_view → NEW.viewed_at + daily_user_stats
--                                     (stat_date, total_screen_views,
--                                      unique_screens_viewed) — none exist
--   create_challenge_notification   → INSERT INTO notifications (no such table)
--                                     + NEW.challenged_user_id (col is to_user_id)
--   notify_challenge_accepted       → same, + NEW.challenger_id (col is from_user_id)
--   notify_challenge_abandoned      → same, + NEW.abandoned_by (no such column)
--
-- PL/pgSQL only resolves record field references at RUNTIME, so CREATE OR
-- REPLACE FUNCTION accepted all seven bodies silently and each one has been a
-- guaranteed 42703 on every firing ever since. This is the phantom-column class
-- CLAUDE.md documents for `.select("...")`, expressed in PL/pgSQL.
--
-- FIX: restore each body from the migration that originally authored it,
-- re-validated column-by-column against live information_schema (2026-07-29),
-- keeping the `SET search_path = public` hardening that 026/074 legitimately
-- wanted. Function bodies only — no DDL on any table, no locks beyond the
-- momentary ACCESS EXCLUSIVE on pg_proc rows that CREATE OR REPLACE takes.
--
-- Verified live column sets used below:
--   saved_workouts(source_activity_id, times_completed, last_completed_at)
--   workout_shares(activity_id, share_count)
--   feature_votes(feature_id) → feature_requests(id, vote_count, updated_at)
--   scheduled_workouts(status, saved_workout_id)
--   screen_views(user_id, entered_at, duration_ms, screen_name)
--   daily_user_stats(user_id, date, screens_viewed, *_time_seconds)   UNIQUE(user_id, date)
--   workout_challenges(from_user_id, to_user_id, status)
--   challenge_notifications(challenge_id, user_id, notification_type)
-- ============================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. update_workout_share_count  (AFTER INSERT ON saved_workouts)
--    Original: migrations/029_saved_scheduled_workouts.sql
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_workout_share_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Only feed-sourced saves bump a share counter; a coach-authored / studio
    -- save has no source activity and must be a no-op (NOT an error).
    IF NEW.source_activity_id IS NOT NULL THEN
        UPDATE workout_shares
        SET share_count = COALESCE(share_count, 0) + 1,
            updated_at = NOW()
        WHERE activity_id = NEW.source_activity_id;
    END IF;
    RETURN NULL;  -- AFTER trigger: return value is ignored
END;
$$;

COMMENT ON FUNCTION public.update_workout_share_count IS
    'Increment workout_shares.share_count when a feed workout is saved. '
    'No-op for saves with no source_activity_id (coach/studio saves).';


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. update_feature_vote_count  (AFTER INSERT OR DELETE ON feature_votes)
--    Original: migrations/046_feature_voting_system.sql
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_feature_vote_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE feature_requests
        SET vote_count = COALESCE(vote_count, 0) + 1,
            updated_at = NOW()
        WHERE id = NEW.feature_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE feature_requests
        SET vote_count = GREATEST(COALESCE(vote_count, 0) - 1, 0),
            updated_at = NOW()
        WHERE id = OLD.feature_id;
    END IF;
    RETURN NULL;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. update_saved_workout_completion  (AFTER UPDATE ON scheduled_workouts)
--    Original: migrations/029_saved_scheduled_workouts.sql
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_saved_workout_completion()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF NEW.status = 'completed'
       AND OLD.status IS DISTINCT FROM 'completed'
       AND NEW.saved_workout_id IS NOT NULL THEN
        UPDATE saved_workouts
        SET times_completed = COALESCE(times_completed, 0) + 1,
            last_completed_at = NOW()
        WHERE id = NEW.saved_workout_id;
    END IF;
    RETURN NULL;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. update_daily_stats_on_screen_view  (AFTER INSERT ON screen_views)
--    Original: migrations/023_analytics_screen_time.sql
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_daily_stats_on_screen_view()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    view_date DATE;
    duration_sec INTEGER;
    screen_category VARCHAR;
BEGIN
    IF NEW.duration_ms IS NULL OR NEW.user_id IS NULL THEN
        RETURN NULL;
    END IF;

    view_date := DATE(NEW.entered_at);
    duration_sec := NEW.duration_ms / 1000;

    screen_category := CASE
        WHEN NEW.screen_name IN ('home', 'senior_home') THEN 'home'
        WHEN NEW.screen_name LIKE '%workout%' OR NEW.screen_name LIKE '%exercise%' THEN 'workout'
        WHEN NEW.screen_name LIKE '%chat%' THEN 'chat'
        WHEN NEW.screen_name LIKE '%nutrition%' OR NEW.screen_name LIKE '%food%' THEN 'nutrition'
        WHEN NEW.screen_name LIKE '%profile%' OR NEW.screen_name LIKE '%settings%' THEN 'profile'
        ELSE 'other'
    END;

    -- NOTE: the 023 original inserted only screens_viewed on the first view of
    -- a day, so that view's duration was silently dropped (the time columns are
    -- only accumulated in the DO UPDATE branch). The seed row below carries the
    -- categorized duration too, so day 1's first screen is counted like the rest.
    INSERT INTO daily_user_stats (
        user_id, date, screens_viewed,
        home_time_seconds, workout_time_seconds, chat_time_seconds,
        nutrition_time_seconds, profile_time_seconds, other_time_seconds
    )
    VALUES (
        NEW.user_id, view_date, 1,
        CASE WHEN screen_category = 'home' THEN duration_sec ELSE 0 END,
        CASE WHEN screen_category = 'workout' THEN duration_sec ELSE 0 END,
        CASE WHEN screen_category = 'chat' THEN duration_sec ELSE 0 END,
        CASE WHEN screen_category = 'nutrition' THEN duration_sec ELSE 0 END,
        CASE WHEN screen_category = 'profile' THEN duration_sec ELSE 0 END,
        CASE WHEN screen_category = 'other' THEN duration_sec ELSE 0 END
    )
    ON CONFLICT (user_id, date)
    DO UPDATE SET
        screens_viewed = COALESCE(daily_user_stats.screens_viewed, 0) + 1,
        home_time_seconds = CASE WHEN screen_category = 'home'
            THEN COALESCE(daily_user_stats.home_time_seconds, 0) + duration_sec
            ELSE daily_user_stats.home_time_seconds END,
        workout_time_seconds = CASE WHEN screen_category = 'workout'
            THEN COALESCE(daily_user_stats.workout_time_seconds, 0) + duration_sec
            ELSE daily_user_stats.workout_time_seconds END,
        chat_time_seconds = CASE WHEN screen_category = 'chat'
            THEN COALESCE(daily_user_stats.chat_time_seconds, 0) + duration_sec
            ELSE daily_user_stats.chat_time_seconds END,
        nutrition_time_seconds = CASE WHEN screen_category = 'nutrition'
            THEN COALESCE(daily_user_stats.nutrition_time_seconds, 0) + duration_sec
            ELSE daily_user_stats.nutrition_time_seconds END,
        profile_time_seconds = CASE WHEN screen_category = 'profile'
            THEN COALESCE(daily_user_stats.profile_time_seconds, 0) + duration_sec
            ELSE daily_user_stats.profile_time_seconds END,
        other_time_seconds = CASE WHEN screen_category = 'other'
            THEN COALESCE(daily_user_stats.other_time_seconds, 0) + duration_sec
            ELSE daily_user_stats.other_time_seconds END,
        updated_at = NOW();

    RETURN NULL;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. create_challenge_notification  (AFTER INSERT ON workout_challenges)
--    Original: migrations/030_workout_challenges.sql, superseded by the
--    conditional accept-from-feed form in migrations/267 (never applied to
--    production — notify_challenge_completed is absent from pg_proc). The
--    conditional form is restored here because api/v1/challenges.py:842
--    inserts rows with status='accepted' (accept-from-feed).
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_challenge_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF NEW.status = 'pending' THEN
        -- Direct challenge: notify the recipient.
        INSERT INTO challenge_notifications (challenge_id, user_id, notification_type)
        VALUES (NEW.id, NEW.to_user_id, 'challenge_received');
    ELSIF NEW.status = 'accepted' THEN
        -- Accept-from-feed: notify the original poster that someone accepted.
        INSERT INTO challenge_notifications (challenge_id, user_id, notification_type)
        VALUES (NEW.id, NEW.from_user_id, 'challenge_accepted');
    END IF;
    RETURN NULL;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 6. notify_challenge_accepted  (AFTER UPDATE ON workout_challenges)
--    Original: migrations/030_workout_challenges.sql
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_challenge_accepted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        INSERT INTO challenge_notifications (challenge_id, user_id, notification_type)
        VALUES (NEW.id, NEW.from_user_id, 'challenge_accepted');
    END IF;
    RETURN NULL;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 7. notify_challenge_abandoned  (AFTER UPDATE ON workout_challenges)
--    Original: migrations/031_challenge_abandonment.sql
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_challenge_abandoned()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF NEW.status = 'abandoned' AND OLD.status = 'accepted' THEN
        -- Notify the challenger that their opponent quit.
        INSERT INTO challenge_notifications (challenge_id, user_id, notification_type)
        VALUES (NEW.id, NEW.from_user_id, 'challenge_abandoned');
    END IF;
    RETURN NULL;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 8. update_challenge_participant_count  (AFTER INSERT/DELETE ON
--    challenge_participants) — same 074 sweep damage, phantom TABLE rather than
--    phantom field: it targets `fitness_challenges`, which does not exist.
--    challenge_participants.challenge_id FKs challenges(id), and
--    challenges.participant_count is the real counter.
--    Original: migrations/028_social_features.sql
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_challenge_participant_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE challenges
        SET participant_count = COALESCE(participant_count, 0) + 1
        WHERE id = NEW.challenge_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE challenges
        SET participant_count = GREATEST(COALESCE(participant_count, 0) - 1, 0)
        WHERE id = OLD.challenge_id;
    END IF;
    RETURN NULL;
END;
$$;

COMMIT;
