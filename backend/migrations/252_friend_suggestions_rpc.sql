CREATE OR REPLACE FUNCTION get_friend_suggestions_rpc(
  p_user_id uuid, p_limit int DEFAULT 10
)
RETURNS TABLE(suggested_user_id uuid, mutual_count bigint) AS $$
  SELECT uc2.following_id as suggested_user_id, COUNT(*) as mutual_count
  FROM user_connections uc1
  JOIN user_connections uc2 ON uc2.follower_id = uc1.following_id
  WHERE uc1.follower_id = p_user_id
    AND uc2.following_id != p_user_id
    AND uc2.following_id NOT IN (
      SELECT following_id FROM user_connections WHERE follower_id = p_user_id
    )
  GROUP BY uc2.following_id
  ORDER BY mutual_count DESC
  LIMIT p_limit;
$$ LANGUAGE sql STABLE;
