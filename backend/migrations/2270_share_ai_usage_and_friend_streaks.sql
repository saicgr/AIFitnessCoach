-- Migration 2270 — Share viral layer (Workstream F) backend tables.
-- APPLIED via Supabase MCP (project hpbzfahijszqmgsybuor) on 2026-06-18.
-- (Authored/applied as 2263; renamed to 2270 to avoid a repo-filename collision
--  with 2263_feature_request_comments.sql and the 2266/2267 claims — the DB
--  apply via MCP is name-agnostic, so this rename is repo-only.)
--
-- Cost-discipline tables for the AI/growth/social share features:
--   share_ai_usage          F1 per-user daily cap counter (cache hits are free, not counted)
--   share_ai_restyle_cache  F1 cache of generated images keyed by sha256(bytes)+style
--   share_insight_cache     F2 cache of derived insight/roast/hype lines keyed by workout/day+tone
--   friend_streaks          F14 1:1 shared streak (workout|food), no public feed
--   share_links             F5/F8 self-hosted deferred-deep-link tokens
-- Plus users.referral_code for the F5 issue/lookup path.

-- ============================================================
-- F1 cost discipline: per-user daily cap for AI photo-restyle.
-- ============================================================
CREATE TABLE IF NOT EXISTS share_ai_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    day DATE NOT NULL,
    feature TEXT NOT NULL DEFAULT 'ai_restyle',
    count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, day, feature)
);
CREATE INDEX IF NOT EXISTS idx_share_ai_usage_user_day ON share_ai_usage(user_id, day);
COMMENT ON TABLE share_ai_usage IS 'Per-user daily cap counter for generative AI share features (F1). Cache hits are free and never counted.';
ALTER TABLE share_ai_usage ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS share_ai_usage_select_own ON share_ai_usage;
CREATE POLICY share_ai_usage_select_own ON share_ai_usage FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS share_ai_usage_service ON share_ai_usage;
CREATE POLICY share_ai_usage_service ON share_ai_usage FOR ALL USING (auth.role() = 'service_role');

-- ============================================================
-- F1 cache: AI-restyle outputs keyed by sha256(image_bytes)+style.
-- ============================================================
CREATE TABLE IF NOT EXISTS share_ai_restyle_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cache_key TEXT NOT NULL UNIQUE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    style TEXT NOT NULL,
    source_sha256 TEXT NOT NULL,
    s3_key TEXT NOT NULL,
    model TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_share_ai_restyle_cache_key ON share_ai_restyle_cache(cache_key);
COMMENT ON TABLE share_ai_restyle_cache IS 'F1 AI photo-transform cache. cache_key = sha256(photo bytes)+style; a hit re-serves the stored S3 image for free.';
ALTER TABLE share_ai_restyle_cache ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS share_ai_restyle_cache_service ON share_ai_restyle_cache;
CREATE POLICY share_ai_restyle_cache_service ON share_ai_restyle_cache FOR ALL USING (auth.role() = 'service_role');

-- ============================================================
-- F2 cache: derived insight/roast/hype lines keyed by workout/day+tone.
-- ============================================================
CREATE TABLE IF NOT EXISTS share_insight_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cache_key TEXT NOT NULL UNIQUE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    line TEXT NOT NULL,
    tone TEXT NOT NULL DEFAULT 'supportive',
    source TEXT NOT NULL DEFAULT 'deterministic',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_share_insight_cache_key ON share_insight_cache(cache_key);
COMMENT ON TABLE share_insight_cache IS 'F2 share insight-line cache keyed by workout/day+tone. Reuses coach_daily_insights when present; otherwise deterministic variant pool or one cached Flash call.';
ALTER TABLE share_insight_cache ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS share_insight_cache_select_own ON share_insight_cache;
CREATE POLICY share_insight_cache_select_own ON share_insight_cache FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS share_insight_cache_service ON share_insight_cache;
CREATE POLICY share_insight_cache_service ON share_insight_cache FOR ALL USING (auth.role() = 'service_role');

-- ============================================================
-- F14 Friend Streak — 1:1 shared streak (workout | food). No public feed.
-- ============================================================
CREATE TABLE IF NOT EXISTS friend_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b UUID REFERENCES users(id) ON DELETE CASCADE,
    kind TEXT NOT NULL DEFAULT 'workout',
    invite_code TEXT NOT NULL UNIQUE,
    current_streak INT NOT NULL DEFAULT 0,
    longest_streak INT NOT NULL DEFAULT 0,
    last_a_at DATE,
    last_b_at DATE,
    last_incremented_on DATE,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_friend_streaks_user_a ON friend_streaks(user_a);
CREATE INDEX IF NOT EXISTS idx_friend_streaks_user_b ON friend_streaks(user_b);
CREATE INDEX IF NOT EXISTS idx_friend_streaks_code ON friend_streaks(invite_code);
CREATE INDEX IF NOT EXISTS idx_friend_streaks_status ON friend_streaks(status);
COMMENT ON TABLE friend_streaks IS 'F14 1:1 friend streak (workout|food). Increments once per shared local day when both members logged. No public feed (project_gamification_role).';
ALTER TABLE friend_streaks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS friend_streaks_select_member ON friend_streaks;
CREATE POLICY friend_streaks_select_member ON friend_streaks FOR SELECT USING (auth.uid() = user_a OR auth.uid() = user_b);
DROP POLICY IF EXISTS friend_streaks_service ON friend_streaks;
CREATE POLICY friend_streaks_service ON friend_streaks FOR ALL USING (auth.role() = 'service_role');

-- ============================================================
-- F5/F8 share-link resolver — short tokens for deferred deep links.
-- ============================================================
CREATE TABLE IF NOT EXISTS share_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token TEXT NOT NULL UNIQUE,
    kind TEXT NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    referral_code TEXT,
    clicks INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_share_links_token ON share_links(token);
CREATE INDEX IF NOT EXISTS idx_share_links_user ON share_links(user_id);
CREATE INDEX IF NOT EXISTS idx_share_links_kind ON share_links(kind);
COMMENT ON TABLE share_links IS 'F5/F8 self-hosted deferred-deep-link tokens (zealova.com/s/{token}). kind routes resolution. Branch/OneLink seam in referral_service.py.';
ALTER TABLE share_links ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS share_links_service ON share_links;
CREATE POLICY share_links_service ON share_links FOR ALL USING (auth.role() = 'service_role');

-- F5 per-user referral code on users.
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code) WHERE referral_code IS NOT NULL;
