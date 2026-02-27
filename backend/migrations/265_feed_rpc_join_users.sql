-- Fix get_feed_for_user to join with users table for name + avatar
DROP FUNCTION IF EXISTS get_feed_for_user(uuid, text, int, int);

CREATE OR REPLACE FUNCTION get_feed_for_user(
  p_user_id uuid, p_activity_type text DEFAULT NULL,
  p_limit int DEFAULT 20, p_offset int DEFAULT 0
)
RETURNS TABLE(
  id uuid, user_id uuid, activity_type varchar, activity_data jsonb,
  visibility varchar, reaction_count int, comment_count int,
  created_at timestamptz, workout_log_id uuid,
  achievement_id uuid, pr_id uuid, is_pinned boolean,
  pinned_at timestamptz, pinned_by uuid,
  user_name text, user_avatar text,
  total_count bigint
) AS $$
  SELECT
    af.id, af.user_id, af.activity_type, af.activity_data,
    af.visibility, af.reaction_count, af.comment_count,
    af.created_at, af.workout_log_id,
    af.achievement_id, af.pr_id, af.is_pinned,
    af.pinned_at, af.pinned_by,
    u.name AS user_name,
    u.avatar_url AS user_avatar,
    COUNT(*) OVER() as total_count
  FROM activity_feed af
  LEFT JOIN users u ON u.id = af.user_id
  WHERE (
      af.user_id = p_user_id
      OR af.user_id IN (
        SELECT uc.following_id FROM user_connections uc
        WHERE uc.follower_id = p_user_id AND uc.status = 'active'
      )
    )
    AND (p_activity_type IS NULL OR af.activity_type = p_activity_type)
  ORDER BY af.created_at DESC
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;
