-- Companion-aware logging (Fix 2).
--
-- When the user taps a food in "Recent" we fan in three signals before
-- logging — same-log siblings, cross-log co-occurrence, and a Gemini-sourced
-- global pairing — and let them opt in via a bottom sheet. Those last two
-- signals need persistence:
--
--   1. food_companion_suggestions_cache — memoizes the Gemini response keyed
--      by primary food name (+ locale), so tapping "masala dosa" a second
--      time hits cache instantly and doesn't burn another model call.
--
--   2. food_companion_rejected_pairs — records when the user explicitly
--      removed a suggested companion, so we suppress it on future prompts
--      for that (primary, companion) pair. Never auto-un-suppress; this is
--      a user-taught negative.

CREATE TABLE IF NOT EXISTS food_companion_suggestions_cache (
    -- Canonical lowercase name of the primary food. We normalize on write.
    primary_name     TEXT        NOT NULL,
    -- IANA locale / language hint ("en", "en-IN", "hi", etc.). Different
    -- locales return genuinely different sides (sambar vs lentil soup), so
    -- we scope the cache to avoid cross-pollution.
    locale           TEXT        NOT NULL DEFAULT 'en',
    suggestions      JSONB       NOT NULL,
    cuisine_tag      TEXT,
    model_version    TEXT,
    generated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (primary_name, locale)
);

COMMENT ON TABLE food_companion_suggestions_cache IS
  'Memoized Gemini-sourced companion suggestions. Read by /nutrition/companions.';

CREATE INDEX IF NOT EXISTS idx_food_companion_cache_generated_at
    ON food_companion_suggestions_cache (generated_at);


CREATE TABLE IF NOT EXISTS food_companion_rejected_pairs (
    user_id          UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    primary_name     TEXT        NOT NULL,
    companion_name   TEXT        NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, primary_name, companion_name)
);

COMMENT ON TABLE food_companion_rejected_pairs IS
  'User explicitly removed <companion_name> while logging <primary_name>. Suppress on future prompts.';

CREATE INDEX IF NOT EXISTS idx_food_companion_rejected_user
    ON food_companion_rejected_pairs (user_id, primary_name);


-- RLS: the cache is a global read-through cache — it holds no user data, so
-- authenticated users can read it; writes happen via the service role (the
-- backend's supabase client).
ALTER TABLE food_companion_suggestions_cache ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "companions_cache_read" ON food_companion_suggestions_cache;
CREATE POLICY "companions_cache_read"
    ON food_companion_suggestions_cache
    FOR SELECT
    TO authenticated
    USING (true);

-- The rejected-pairs table is user-scoped.
ALTER TABLE food_companion_rejected_pairs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "companions_rejected_owner_read" ON food_companion_rejected_pairs;
CREATE POLICY "companions_rejected_owner_read"
    ON food_companion_rejected_pairs
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "companions_rejected_owner_write" ON food_companion_rejected_pairs;
CREATE POLICY "companions_rejected_owner_write"
    ON food_companion_rejected_pairs
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "companions_rejected_owner_delete" ON food_companion_rejected_pairs;
CREATE POLICY "companions_rejected_owner_delete"
    ON food_companion_rejected_pairs
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
