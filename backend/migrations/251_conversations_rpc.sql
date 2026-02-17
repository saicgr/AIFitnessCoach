CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id uuid)
RETURNS TABLE(
  conversation_id uuid, last_message_at timestamptz, created_at timestamptz,
  last_msg_id uuid, last_msg_content text, last_msg_sender_id uuid,
  last_msg_sender_name text, last_msg_sender_avatar text, last_msg_created_at timestamptz,
  unread_count bigint
) AS $$
  SELECT
    c.id as conversation_id, c.last_message_at, c.created_at,
    lm.id, lm.content, lm.sender_id, u.name, u.avatar_url, lm.created_at,
    COALESCE(
      (SELECT COUNT(*) FROM direct_messages dm
       WHERE dm.conversation_id = c.id AND dm.sender_id != p_user_id
       AND dm.created_at > COALESCE(cp.last_read_at, '1970-01-01'::timestamptz)),
      0
    ) as unread_count
  FROM conversation_participants cp
  JOIN conversations c ON c.id = cp.conversation_id
  JOIN LATERAL (
    SELECT * FROM direct_messages dm
    WHERE dm.conversation_id = c.id
    ORDER BY dm.created_at DESC LIMIT 1
  ) lm ON true
  LEFT JOIN users u ON u.id = lm.sender_id
  WHERE cp.user_id = p_user_id
  ORDER BY c.last_message_at DESC NULLS LAST
  LIMIT 50;
$$ LANGUAGE sql STABLE;
