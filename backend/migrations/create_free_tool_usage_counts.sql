-- Free-tool usage counters.
--
-- One row per tool slug. Incremented (fire-and-forget) each time a visitor
-- produces a result on /free-tools/<slug>. The /free-tools index page reads
-- the aggregate to show "N calculations run" social proof on each card.
--
-- Counts are deliberately coarse: we never join them to a user or IP. The
-- per-IP increment throttle lives in the application layer, not here.

CREATE TABLE IF NOT EXISTS free_tool_usage_counts (
    slug        TEXT PRIMARY KEY,
    count       BIGINT NOT NULL DEFAULT 0,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Atomic increment helper. Upserts the row if the slug is seen for the
-- first time, otherwise bumps the counter. SECURITY DEFINER so the anon
-- key can call it without direct table write grants.
CREATE OR REPLACE FUNCTION increment_free_tool_usage(p_slug TEXT)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_count BIGINT;
BEGIN
    INSERT INTO free_tool_usage_counts (slug, count, updated_at)
    VALUES (p_slug, 1, now())
    ON CONFLICT (slug)
    DO UPDATE SET count = free_tool_usage_counts.count + 1,
                  updated_at = now()
    RETURNING count INTO new_count;
    RETURN new_count;
END;
$$;

-- RLS: counts are public-readable, writes only through the function above.
ALTER TABLE free_tool_usage_counts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS free_tool_usage_counts_select ON free_tool_usage_counts;
CREATE POLICY free_tool_usage_counts_select
    ON free_tool_usage_counts
    FOR SELECT
    USING (true);
