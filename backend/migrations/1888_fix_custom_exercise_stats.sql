-- Migration 1888: Fix get_custom_exercise_stats function
--
-- Migration 074 overwrote the correct function (from migration 070) with a broken one that:
--   1. References custom_exercises table instead of exercises table
--   2. Joins workout_logs on wl.exercise_id which doesn't exist
--   3. Returns wrong columns (exercise_name, times_used, last_used)
--      instead of (exercise_id, exercise_name, usage_count, last_used, avg_rating)
--
-- This restores the correct definition that uses exercises + custom_exercise_usage tables.

-- First drop the broken function (must drop because return type changes)
DROP FUNCTION IF EXISTS public.get_custom_exercise_stats(uuid);

-- Recreate with correct definition from migration 070
CREATE OR REPLACE FUNCTION public.get_custom_exercise_stats(p_user_id UUID)
RETURNS TABLE (
  exercise_id UUID,
  exercise_name TEXT,
  usage_count BIGINT,
  last_used TIMESTAMPTZ,
  avg_rating NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.id,
    e.name::TEXT,
    COUNT(u.id)::BIGINT as usage_count,
    MAX(u.used_at) as last_used,
    AVG(u.rating)::NUMERIC as avg_rating
  FROM exercises e
  LEFT JOIN custom_exercise_usage u ON e.id = u.exercise_id
  WHERE e.created_by_user_id = p_user_id AND e.is_custom = true
  GROUP BY e.id, e.name
  ORDER BY usage_count DESC, last_used DESC NULLS LAST;
END;
$$;
