-- Migration 2078: Public Roadmap (marketing site)
--
-- Email-keyed feature voting + flat comments + feature suggestions for the
-- public /roadmap kanban board on zealova.com.
--
-- Deliberately DECOUPLED from migration 046 (feature_requests / feature_votes),
-- which is auth-keyed (auth.users) for the in-app mobile feature board. The
-- marketing site has no logged-in users, so this uses a plain email key.
-- Board CONTENT lives in a TS data file (frontend/src/data/roadmap.ts); these
-- tables only hold the dynamic votes / comments / suggestions, keyed by the
-- stable `feature_slug` string from that file.

-- ===================================
-- Table: roadmap_votes  (one vote per email per feature)
-- ===================================
CREATE TABLE IF NOT EXISTS roadmap_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feature_slug TEXT NOT NULL,
    email TEXT NOT NULL,
    notify_on_ship BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- One vote per email per feature (case-insensitive). Re-votes hit this and
-- are treated as idempotent success by the API.
CREATE UNIQUE INDEX IF NOT EXISTS uniq_roadmap_vote_slug_email
    ON roadmap_votes (feature_slug, lower(email));
CREATE INDEX IF NOT EXISTS idx_roadmap_votes_slug ON roadmap_votes (feature_slug);

-- ===================================
-- Table: roadmap_comments  (FLAT — no threading by design)
-- ===================================
CREATE TABLE IF NOT EXISTS roadmap_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feature_slug TEXT NOT NULL,
    author_name TEXT NOT NULL,
    body TEXT NOT NULL,
    email TEXT,                                  -- optional, never shown publicly
    is_hidden BOOLEAN NOT NULL DEFAULT false,    -- admin soft-moderation
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
-- No parent_id column — comments are intentionally flat (no Reddit-style nesting).

CREATE INDEX IF NOT EXISTS idx_roadmap_comments_slug
    ON roadmap_comments (feature_slug)
    WHERE is_hidden = false;

-- ===================================
-- Table: roadmap_suggestions  (admin-moderated; accepted ones hand-added to roadmap.ts)
-- ===================================
CREATE TABLE IF NOT EXISTS roadmap_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_roadmap_suggestions_status
    ON roadmap_suggestions (status);

-- ===================================
-- Row Level Security
-- ===================================
-- All writes go through the backend's service-role Supabase client, which
-- bypasses RLS. Policies below only constrain the anon key. Votes + comments
-- are public-readable; suggestions are NOT (they contain submitter emails).
ALTER TABLE roadmap_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE roadmap_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE roadmap_suggestions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public read roadmap_votes" ON roadmap_votes;
CREATE POLICY "public read roadmap_votes"
    ON roadmap_votes FOR SELECT USING (true);

DROP POLICY IF EXISTS "public read roadmap_comments" ON roadmap_comments;
CREATE POLICY "public read roadmap_comments"
    ON roadmap_comments FOR SELECT USING (is_hidden = false);

-- roadmap_suggestions: intentionally no anon SELECT policy (emails are private).

-- ===================================
-- Documentation
-- ===================================
COMMENT ON TABLE roadmap_votes IS 'Public /roadmap board: one vote per email per feature_slug';
COMMENT ON TABLE roadmap_comments IS 'Public /roadmap board: flat (non-threaded) feature comments';
COMMENT ON TABLE roadmap_suggestions IS 'Public /roadmap board: visitor feature suggestions, admin-moderated';
COMMENT ON COLUMN roadmap_votes.notify_on_ship IS 'Voter opted in to a one-off email when the feature ships';
COMMENT ON COLUMN roadmap_comments.is_hidden IS 'Admin soft-moderation flag; hidden rows excluded from public reads';
