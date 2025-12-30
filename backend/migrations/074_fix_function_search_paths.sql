-- ============================================================================
-- Migration 074: Fix function search_path mutable warnings
-- ============================================================================
-- This migration fixes functions flagged by Supabase linter with mutable search_path.
-- Functions should have search_path set to prevent search path injection attacks.
--
-- Fix: Add SET search_path = public to each function
-- ============================================================================

-- Drop functions that need return type or parameter name changes first
DROP FUNCTION IF EXISTS public.cleanup_old_context_logs();
DROP FUNCTION IF EXISTS public.cleanup_old_activity_logs();
DROP FUNCTION IF EXISTS public.expire_old_goal_invites();
DROP FUNCTION IF EXISTS public.cleanup_expired_suggestions();
DROP FUNCTION IF EXISTS public.expire_old_challenges();
DROP FUNCTION IF EXISTS public.increment_feature_usage(TEXT);
DROP FUNCTION IF EXISTS public.record_workout_regeneration(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.save_user_profile(UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.refresh_all_leaderboards();
DROP FUNCTION IF EXISTS public.get_iso_week_boundaries(DATE);
DROP FUNCTION IF EXISTS public.get_primary_nutrition_goal(UUID);
DROP FUNCTION IF EXISTS public.is_dangerous_fasting_protocol(TEXT);
DROP FUNCTION IF EXISTS public.get_protocol_fasting_hours(TEXT);
DROP FUNCTION IF EXISTS public.get_friends_on_goal(UUID, TEXT);
DROP FUNCTION IF EXISTS public.get_composite_exercise_details(UUID);
DROP FUNCTION IF EXISTS public.get_custom_exercise_stats(UUID);
DROP FUNCTION IF EXISTS public.get_user_retry_stats(UUID);
DROP FUNCTION IF EXISTS public.get_active_avoided_exercises(UUID);
DROP FUNCTION IF EXISTS public.get_active_avoided_muscles(UUID);
DROP FUNCTION IF EXISTS public.get_user_leaderboard_rank(UUID, TEXT);
DROP FUNCTION IF EXISTS public.check_leaderboard_unlock(UUID);
DROP FUNCTION IF EXISTS public.get_user_abandonment_stats(UUID);

-- 1. update_saved_food_log_count
CREATE OR REPLACE FUNCTION public.update_saved_food_log_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE saved_food_logs SET use_count = use_count + 1 WHERE id = NEW.saved_food_log_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE saved_food_logs SET use_count = use_count - 1 WHERE id = OLD.saved_food_log_id;
    END IF;
    RETURN NULL;
END;
$$;

-- 2. cleanup_old_activity_logs
CREATE OR REPLACE FUNCTION public.cleanup_old_activity_logs()
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    DELETE FROM user_activity_log WHERE created_at < NOW() - INTERVAL '7 days';
END;
$$;

-- 3. recalculate_recipe_nutrition
CREATE OR REPLACE FUNCTION public.recalculate_recipe_nutrition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    total_calories DECIMAL(10,2) := 0;
    total_protein DECIMAL(10,2) := 0;
    total_carbs DECIMAL(10,2) := 0;
    total_fat DECIMAL(10,2) := 0;
BEGIN
    SELECT
        COALESCE(SUM(calories), 0),
        COALESCE(SUM(protein_g), 0),
        COALESCE(SUM(carbs_g), 0),
        COALESCE(SUM(fat_g), 0)
    INTO total_calories, total_protein, total_carbs, total_fat
    FROM recipe_ingredients
    WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id);

    UPDATE recipes SET
        total_calories = total_calories,
        total_protein_g = total_protein,
        total_carbs_g = total_carbs,
        total_fat_g = total_fat,
        updated_at = NOW()
    WHERE id = COALESCE(NEW.recipe_id, OLD.recipe_id);

    RETURN NULL;
END;
$$;

-- 4. update_recipe_log_count
CREATE OR REPLACE FUNCTION public.update_recipe_log_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE recipes SET times_logged = times_logged + 1 WHERE id = NEW.recipe_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE recipes SET times_logged = times_logged - 1 WHERE id = OLD.recipe_id;
    END IF;
    RETURN NULL;
END;
$$;

-- 5. update_progress_photos_updated_at
CREATE OR REPLACE FUNCTION public.update_progress_photos_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 6. update_1rm_updated_at
CREATE OR REPLACE FUNCTION public.update_1rm_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 7. cleanup_old_context_logs
CREATE OR REPLACE FUNCTION public.cleanup_old_context_logs()
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    DELETE FROM context_logs WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$;

-- 8. update_workout_history_imports_updated_at
CREATE OR REPLACE FUNCTION public.update_workout_history_imports_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 9. update_workout_gallery_updated_at
CREATE OR REPLACE FUNCTION public.update_workout_gallery_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 10. update_feature_vote_count
CREATE OR REPLACE FUNCTION public.update_feature_vote_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE feature_requests SET vote_count = vote_count + 1 WHERE id = NEW.feature_request_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE feature_requests SET vote_count = vote_count - 1 WHERE id = OLD.feature_request_id;
    END IF;
    RETURN NULL;
END;
$$;

-- 11. check_user_suggestion_limit
CREATE OR REPLACE FUNCTION public.check_user_suggestion_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    suggestion_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO suggestion_count
    FROM feature_requests
    WHERE suggested_by = NEW.suggested_by
    AND created_at > NOW() - INTERVAL '30 days';

    IF suggestion_count >= 5 THEN
        RAISE EXCEPTION 'User has reached maximum suggestion limit (5 per month)';
    END IF;

    RETURN NEW;
END;
$$;

-- 12. update_feature_request_updated_at
CREATE OR REPLACE FUNCTION public.update_feature_request_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 13. update_custom_goals_updated_at
CREATE OR REPLACE FUNCTION public.update_custom_goals_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 14. get_primary_nutrition_goal
CREATE OR REPLACE FUNCTION public.get_primary_nutrition_goal(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    primary_goal TEXT;
BEGIN
    SELECT nutrition_goal INTO primary_goal
    FROM nutrition_preferences
    WHERE user_id = p_user_id;

    RETURN COALESCE(primary_goal, 'maintain');
END;
$$;

-- 15. get_iso_week_boundaries
CREATE OR REPLACE FUNCTION public.get_iso_week_boundaries(p_date DATE)
RETURNS TABLE(week_start DATE, week_end DATE)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE_TRUNC('week', p_date)::DATE as week_start,
        (DATE_TRUNC('week', p_date) + INTERVAL '6 days')::DATE as week_end;
END;
$$;

-- 16. is_dangerous_fasting_protocol
CREATE OR REPLACE FUNCTION public.is_dangerous_fasting_protocol(protocol TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    RETURN protocol IN ('24h', '48h', '72h', '7-day', 'extended');
END;
$$;

-- 17. update_goal_records
CREATE OR REPLACE FUNCTION public.update_goal_records()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 18. increment_feature_usage
CREATE OR REPLACE FUNCTION public.increment_feature_usage(p_feature_name TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    INSERT INTO feature_usage (feature_name, use_count)
    VALUES (p_feature_name, 1)
    ON CONFLICT (feature_name)
    DO UPDATE SET use_count = feature_usage.use_count + 1;
END;
$$;

-- 19. calculate_measurement_changes
CREATE OR REPLACE FUNCTION public.calculate_measurement_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    prev_measurement RECORD;
BEGIN
    SELECT * INTO prev_measurement
    FROM body_measurements
    WHERE user_id = NEW.user_id
    AND measurement_date < NEW.measurement_date
    ORDER BY measurement_date DESC
    LIMIT 1;

    IF FOUND THEN
        NEW.weight_change = NEW.weight_kg - prev_measurement.weight_kg;
    END IF;

    RETURN NEW;
END;
$$;

-- 20. sync_latest_measurements_to_user
CREATE OR REPLACE FUNCTION public.sync_latest_measurements_to_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    UPDATE users SET
        weight_kg = NEW.weight_kg,
        body_fat_percentage = NEW.body_fat_percentage
    WHERE id = NEW.user_id;

    RETURN NEW;
END;
$$;

-- 21. update_weekly_goals_updated_at
CREATE OR REPLACE FUNCTION public.update_weekly_goals_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 22. update_activity_reaction_count
CREATE OR REPLACE FUNCTION public.update_activity_reaction_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE activity_feed SET reaction_count = reaction_count + 1 WHERE id = NEW.activity_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE activity_feed SET reaction_count = reaction_count - 1 WHERE id = OLD.activity_id;
    END IF;
    RETURN NULL;
END;
$$;

-- 23. update_activity_comment_count
CREATE OR REPLACE FUNCTION public.update_activity_comment_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE activity_feed SET comment_count = comment_count + 1 WHERE id = NEW.activity_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE activity_feed SET comment_count = comment_count - 1 WHERE id = OLD.activity_id;
    END IF;
    RETURN NULL;
END;
$$;

-- 24. update_challenge_participant_count
CREATE OR REPLACE FUNCTION public.update_challenge_participant_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE fitness_challenges SET participant_count = participant_count + 1 WHERE id = NEW.challenge_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE fitness_challenges SET participant_count = participant_count - 1 WHERE id = OLD.challenge_id;
    END IF;
    RETURN NULL;
END;
$$;

-- 25. get_friends_on_goal
CREATE OR REPLACE FUNCTION public.get_friends_on_goal(p_user_id UUID, p_goal_type TEXT)
RETURNS TABLE(friend_id UUID, friend_name TEXT)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.name
    FROM users u
    JOIN user_friends uf ON u.id = uf.friend_id
    JOIN custom_goals cg ON u.id = cg.user_id
    WHERE uf.user_id = p_user_id
    AND cg.goal_type = p_goal_type
    AND cg.is_active = true;
END;
$$;

-- 26. expire_old_goal_invites
CREATE OR REPLACE FUNCTION public.expire_old_goal_invites()
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    UPDATE goal_invites
    SET status = 'expired'
    WHERE status = 'pending'
    AND created_at < NOW() - INTERVAL '7 days';
END;
$$;

-- 27. cleanup_expired_suggestions
CREATE OR REPLACE FUNCTION public.cleanup_expired_suggestions()
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    DELETE FROM feature_requests
    WHERE status = 'rejected'
    AND updated_at < NOW() - INTERVAL '90 days';
END;
$$;

-- 28. update_goal_friends_cache
CREATE OR REPLACE FUNCTION public.update_goal_friends_cache()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Placeholder for cache update logic
    RETURN NEW;
END;
$$;

-- 29. save_user_profile
CREATE OR REPLACE FUNCTION public.save_user_profile(
    p_user_id UUID,
    p_name TEXT,
    p_email TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    INSERT INTO users (id, name, email)
    VALUES (p_user_id, p_name, p_email)
    ON CONFLICT (id)
    DO UPDATE SET name = p_name, email = p_email, updated_at = NOW();
END;
$$;

-- 30. get_protocol_fasting_hours
CREATE OR REPLACE FUNCTION public.get_protocol_fasting_hours(protocol TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    RETURN CASE protocol
        WHEN '12:12' THEN 12
        WHEN '14:10' THEN 14
        WHEN '16:8' THEN 16
        WHEN '18:6' THEN 18
        WHEN '20:4' THEN 20
        WHEN 'omad' THEN 23
        WHEN '24h' THEN 24
        WHEN '48h' THEN 48
        WHEN '72h' THEN 72
        ELSE 16
    END;
END;
$$;

-- 31. update_workout_share_count
CREATE OR REPLACE FUNCTION public.update_workout_share_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE workouts SET share_count = COALESCE(share_count, 0) + 1 WHERE id = NEW.workout_id;
    END IF;
    RETURN NULL;
END;
$$;

-- 32. update_saved_workout_completion
CREATE OR REPLACE FUNCTION public.update_saved_workout_completion()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF NEW.is_completed = true AND OLD.is_completed = false THEN
        UPDATE saved_workouts
        SET times_completed = times_completed + 1
        WHERE id = NEW.saved_workout_id;
    END IF;
    RETURN NEW;
END;
$$;

-- 33. update_updated_at_column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 34. update_strength_scores_updated_at
CREATE OR REPLACE FUNCTION public.update_strength_scores_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 35. record_workout_regeneration
CREATE OR REPLACE FUNCTION public.record_workout_regeneration(
    p_user_id UUID,
    p_workout_id UUID,
    p_reason TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    INSERT INTO workout_regenerations (user_id, workout_id, reason)
    VALUES (p_user_id, p_workout_id, p_reason);
END;
$$;

-- 36. update_home_layouts_updated_at
CREATE OR REPLACE FUNCTION public.update_home_layouts_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 37. create_challenge_notification
CREATE OR REPLACE FUNCTION public.create_challenge_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    INSERT INTO notifications (user_id, type, title, message, data)
    VALUES (
        NEW.challenged_user_id,
        'challenge_received',
        'New Challenge!',
        'You have been challenged!',
        jsonb_build_object('challenge_id', NEW.id)
    );
    RETURN NEW;
END;
$$;

-- 38. notify_challenge_accepted
CREATE OR REPLACE FUNCTION public.notify_challenge_accepted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        INSERT INTO notifications (user_id, type, title, message, data)
        VALUES (
            NEW.challenger_id,
            'challenge_accepted',
            'Challenge Accepted!',
            'Your challenge has been accepted!',
            jsonb_build_object('challenge_id', NEW.id)
        );
    END IF;
    RETURN NEW;
END;
$$;

-- 39. expire_old_challenges
CREATE OR REPLACE FUNCTION public.expire_old_challenges()
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    UPDATE fitness_challenges
    SET status = 'expired'
    WHERE status = 'pending'
    AND created_at < NOW() - INTERVAL '7 days';
END;
$$;

-- 40. notify_challenge_abandoned
CREATE OR REPLACE FUNCTION public.notify_challenge_abandoned()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF NEW.status = 'abandoned' AND OLD.status != 'abandoned' THEN
        -- Notify the other participant
        INSERT INTO notifications (user_id, type, title, message, data)
        SELECT
            CASE WHEN NEW.challenger_id = NEW.abandoned_by
                THEN NEW.challenged_user_id
                ELSE NEW.challenger_id
            END,
            'challenge_abandoned',
            'Challenge Abandoned',
            'A challenge has been abandoned',
            jsonb_build_object('challenge_id', NEW.id);
    END IF;
    RETURN NEW;
END;
$$;

-- 41. get_user_abandonment_stats
CREATE OR REPLACE FUNCTION public.get_user_abandonment_stats(p_user_id UUID)
RETURNS TABLE(total_challenges INTEGER, abandoned_count INTEGER, abandonment_rate DECIMAL)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::INTEGER as total_challenges,
        COUNT(*) FILTER (WHERE status = 'abandoned' AND abandoned_by = p_user_id)::INTEGER as abandoned_count,
        ROUND(
            COUNT(*) FILTER (WHERE status = 'abandoned' AND abandoned_by = p_user_id)::DECIMAL /
            NULLIF(COUNT(*), 0) * 100, 2
        ) as abandonment_rate
    FROM fitness_challenges
    WHERE challenger_id = p_user_id OR challenged_user_id = p_user_id;
END;
$$;

-- 42. get_composite_exercise_details
CREATE OR REPLACE FUNCTION public.get_composite_exercise_details(p_exercise_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'id', id,
        'name', name,
        'muscle_group', muscle_group,
        'equipment', equipment
    ) INTO result
    FROM exercises
    WHERE id = p_exercise_id;

    RETURN result;
END;
$$;

-- 43. get_custom_exercise_stats
CREATE OR REPLACE FUNCTION public.get_custom_exercise_stats(p_user_id UUID)
RETURNS TABLE(exercise_name TEXT, times_used INTEGER, last_used TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ce.name,
        COUNT(*)::INTEGER as times_used,
        MAX(wl.created_at) as last_used
    FROM custom_exercises ce
    LEFT JOIN workout_logs wl ON wl.exercise_id = ce.id::TEXT
    WHERE ce.user_id = p_user_id
    GROUP BY ce.id, ce.name;
END;
$$;

-- 44. increment_retry_count
CREATE OR REPLACE FUNCTION public.increment_retry_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.retry_count = COALESCE(OLD.retry_count, 0) + 1;
    RETURN NEW;
END;
$$;

-- 45. get_user_retry_stats
CREATE OR REPLACE FUNCTION public.get_user_retry_stats(p_user_id UUID)
RETURNS TABLE(action_type TEXT, total_retries INTEGER, success_rate DECIMAL)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        action,
        SUM(COALESCE((metadata->>'retry_count')::INTEGER, 0))::INTEGER as total_retries,
        ROUND(
            COUNT(*) FILTER (WHERE status_code = 200)::DECIMAL /
            NULLIF(COUNT(*), 0) * 100, 2
        ) as success_rate
    FROM user_activity_log
    WHERE user_id = p_user_id::TEXT
    GROUP BY action;
END;
$$;

-- 46. get_active_avoided_exercises
CREATE OR REPLACE FUNCTION public.get_active_avoided_exercises(p_user_id UUID)
RETURNS TABLE(exercise_id UUID, exercise_name TEXT, reason TEXT)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT ae.exercise_id, e.name, ae.reason
    FROM avoided_exercises ae
    JOIN exercises e ON e.id = ae.exercise_id
    WHERE ae.user_id = p_user_id
    AND ae.is_active = true;
END;
$$;

-- 47. get_active_avoided_muscles
CREATE OR REPLACE FUNCTION public.get_active_avoided_muscles(p_user_id UUID)
RETURNS TABLE(muscle_group TEXT, reason TEXT, until_date DATE)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT am.muscle_group, am.reason, am.until_date
    FROM avoided_muscles am
    WHERE am.user_id = p_user_id
    AND am.is_active = true
    AND (am.until_date IS NULL OR am.until_date >= CURRENT_DATE);
END;
$$;

-- 48. get_user_leaderboard_rank
CREATE OR REPLACE FUNCTION public.get_user_leaderboard_rank(
    p_user_id UUID,
    p_leaderboard_type TEXT
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    user_rank INTEGER;
BEGIN
    -- Implementation depends on leaderboard type
    SELECT rank INTO user_rank
    FROM (
        SELECT user_id, ROW_NUMBER() OVER (ORDER BY score DESC) as rank
        FROM leaderboard_entries
        WHERE leaderboard_type = p_leaderboard_type
    ) ranked
    WHERE user_id = p_user_id;

    RETURN user_rank;
END;
$$;

-- 49. check_leaderboard_unlock
CREATE OR REPLACE FUNCTION public.check_leaderboard_unlock(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    completed_workouts INTEGER;
BEGIN
    SELECT COUNT(*) INTO completed_workouts
    FROM workouts
    WHERE user_id = p_user_id
    AND is_completed = true;

    RETURN completed_workouts >= 5;
END;
$$;

-- 50. refresh_all_leaderboards
CREATE OR REPLACE FUNCTION public.refresh_all_leaderboards()
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_streaks;
    REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_weekly_challenges;
    REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_challenge_masters;
    REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_volume_kings;
END;
$$;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
