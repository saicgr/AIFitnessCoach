-- Share template preferences + analytics
-- Tracks each user's favorite share-card templates and custom ordering,
-- plus a rolling log of share events for "which templates are viral"
-- analytics.

-- ─── Per-user preferences ────────────────────────────────────────
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS share_favorite_templates TEXT[] DEFAULT ARRAY[]::TEXT[],
  ADD COLUMN IF NOT EXISTS share_template_order    TEXT[] DEFAULT ARRAY[]::TEXT[];

COMMENT ON COLUMN users.share_favorite_templates IS
  'Ordered list of share template ids the user has starred (pinned to top of gallery).';
COMMENT ON COLUMN users.share_template_order IS
  'User-defined ordering of share templates. Missing ids fall back to the app default.';

-- ─── Share events (analytics) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS share_events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  template_id     TEXT NOT NULL,
  destination     TEXT NOT NULL,   -- 'instagram_stories' | 'system_share' | 'save_only'
  workout_log_id  UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_share_events_user_created
  ON share_events(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_share_events_template_created
  ON share_events(template_id, created_at DESC);

COMMENT ON TABLE share_events IS
  'Append-only log of share actions. Powers "which templates are most viral" analytics.';
