CREATE OR REPLACE FUNCTION get_workout_counts(p_user_ids uuid[])
RETURNS TABLE(user_id uuid, workout_count bigint) AS $$
  SELECT user_id, COUNT(*) as workout_count
  FROM workout_logs
  WHERE user_id = ANY(p_user_ids)
  GROUP BY user_id;
$$ LANGUAGE sql STABLE;
