-- Migration 2079: threaded comments for the public /roadmap board
--
-- Supersedes the "flat only" note in migration 2078. Roadmap comments are now
-- Reddit-style threaded, capped at 10 levels deep (depth 0..9).
--
--   parent_id  -> the comment this one replies to (NULL = top-level)
--   depth      -> 0 for top-level, parent.depth + 1 for replies (cap enforced
--                 in the API at insert time)

ALTER TABLE roadmap_comments
    ADD COLUMN IF NOT EXISTS parent_id UUID
        REFERENCES roadmap_comments(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS depth INTEGER NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_roadmap_comments_parent
    ON roadmap_comments(parent_id);

COMMENT ON COLUMN roadmap_comments.parent_id IS 'Replied-to comment; NULL = top-level';
COMMENT ON COLUMN roadmap_comments.depth IS 'Thread depth 0..9 (10 levels max, enforced in API)';
