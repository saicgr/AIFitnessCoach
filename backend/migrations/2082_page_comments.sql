-- Migration 2082: page_comments — comments on marketing comparison/roundup pages
--
-- Powers the comment section on zealova.com long-form pages (/vs/* comparison
-- pages and /best-*-2026 roundup pages). Email-keyed, frictionless, publishes
-- immediately — the same model as the public /roadmap board (migration 2078).
--
-- Differences from roadmap_comments:
--   * keyed by `page_slug` (the page's route, e.g. 'vs/bevel') not feature_slug
--   * `email` is REQUIRED here (roadmap_comments made it optional). The visitor
--     must supply an email to comment, mirroring roadmap voting.
--   * flat by design — no threading. Marketing-page comments are not a forum.
--
-- Board/page CONTENT is prerendered static; this table only holds the dynamic
-- comments, fetched client-side and keyed by the stable page_slug string.

CREATE TABLE IF NOT EXISTS page_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    page_slug TEXT NOT NULL,                      -- e.g. 'vs/bevel', 'best-ai-fitness-apps-2026'
    author_name TEXT NOT NULL,
    body TEXT NOT NULL,
    email TEXT NOT NULL,                          -- required; never shown publicly
    is_hidden BOOLEAN NOT NULL DEFAULT false,     -- admin soft-moderation
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Partial index: public reads only ever ask for non-hidden rows of one page.
CREATE INDEX IF NOT EXISTS idx_page_comments_slug
    ON page_comments (page_slug)
    WHERE is_hidden = false;

-- ===================================
-- Row Level Security
-- ===================================
-- Writes go through the backend's service-role Supabase client (bypasses RLS).
-- The anon key only gets public read of non-hidden rows.
ALTER TABLE page_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public read page_comments" ON page_comments;
CREATE POLICY "public read page_comments"
    ON page_comments FOR SELECT USING (is_hidden = false);

COMMENT ON TABLE page_comments IS 'Comments on marketing comparison/roundup pages (zealova.com/vs/*, /best-*-2026)';
COMMENT ON COLUMN page_comments.page_slug IS 'Stable page route key, e.g. vs/bevel or best-ai-fitness-apps-2026';
COMMENT ON COLUMN page_comments.email IS 'Required commenter email; never shown publicly; admin contact + dedup';
COMMENT ON COLUMN page_comments.is_hidden IS 'Admin soft-moderation flag; hidden rows excluded from public reads';
