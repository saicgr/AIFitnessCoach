-- Migration 2318: cross-user dish image cache
--
-- Menu scans render a thumbnail per dish. Images are resolved through a
-- chain that spends nothing until it has to:
--
--   1. user_photo — the user's own past food_logs photo of the same dish
--   2. food_db    — food_database.image_url when the dish matches a row
--   3. web_cc     — a free-licence photo (Open Food Facts / Wikimedia / Pexels)
--   4. ai         — generated, and only for the ~8 Recommended dishes plus
--                   any dish the user explicitly taps
--
-- This table is what makes step 4 affordable: it is keyed on the NORMALIZED
-- dish name with no user_id, so "caesar salad" is resolved once for the whole
-- app and every later scan of every steakhouse hits the cache. Same shape and
-- intent as menu_scan_cache (2067) — first user pays, everyone else is free.
--
-- Rollback:
--   DROP FUNCTION IF EXISTS dish_image_cache_touch(TEXT);
--   DROP TABLE IF EXISTS dish_image_cache;

CREATE TABLE IF NOT EXISTS dish_image_cache (
  -- Lowercased, punctuation-stripped, stopword-free dish name. Produced by
  -- _normalize_dish_name() in api/v1/nutrition/menu_analyses.py — the same
  -- normalizer the history-frequency + duplicate-menu checks use, so a dish
  -- resolves identically everywhere.
  normalized_name  TEXT PRIMARY KEY,

  -- Human-readable name of the first dish that populated this row. Purely for
  -- debugging / admin review ("what did 'grilled chicken' actually render?").
  display_name     TEXT NOT NULL,

  -- Where the image came from. Drives the attribution line the UI must show
  -- for web_cc, and the "AI-generated" disclosure for ai.
  source           TEXT NOT NULL CHECK (source IN ('user_photo', 'food_db', 'web_cc', 'ai')),

  -- S3 object key for images we host (web_cc downloads + ai generations).
  -- NULL when external_url is set instead (food_db rows already have a URL we
  -- do not need to re-host).
  s3_key           TEXT,
  external_url     TEXT,

  -- Licence / credit string that MUST be rendered with the image for web_cc.
  attribution      TEXT,

  -- Generation model for ai rows (e.g. 'imagen-4.0-fast-generate-001') so a
  -- future quality bump can invalidate just the rows from the older model.
  model            TEXT,

  hit_count        INTEGER NOT NULL DEFAULT 1,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_used_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Exactly one of s3_key / external_url must be populated — a row with
  -- neither is a cache entry that resolves to nothing, which would make the
  -- resolver "succeed" with no image.
  CONSTRAINT dish_image_cache_has_location
    CHECK ((s3_key IS NOT NULL) <> (external_url IS NOT NULL))
);

-- "Which dishes are we generating most?" + cheap source-mix analytics.
CREATE INDEX IF NOT EXISTS idx_dish_image_cache_source
  ON dish_image_cache (source, last_used_at DESC);

-- Bump usage counters on a cache hit. Defined here so the read path stays
-- vendor-neutral (mirrors menu_scan_cache_touch in 2067).
CREATE OR REPLACE FUNCTION dish_image_cache_touch(p_normalized_name TEXT)
RETURNS void
LANGUAGE sql
AS $$
  UPDATE dish_image_cache
     SET hit_count    = hit_count + 1,
         last_used_at = NOW()
   WHERE normalized_name = p_normalized_name;
$$;

COMMENT ON TABLE dish_image_cache IS
  'Cross-user dish thumbnail cache for menu scans. Keyed on normalized dish name (no user_id) so an image is resolved/generated once app-wide. Sources, cheapest first: user_photo, food_db, web_cc, ai.';
COMMENT ON COLUMN dish_image_cache.attribution IS
  'Credit line that MUST be displayed alongside web_cc images to satisfy the source licence.';
