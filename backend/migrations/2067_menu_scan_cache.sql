-- 2067_menu_scan_cache.sql
--
-- Cross-user whole-menu cache. Used by the Phase-2 menu-scan acceleration:
-- the first user to scan an Olive Garden / IHOP / Sweetgreen menu pays the
-- full cost; every subsequent user across the entire app gets the cached
-- result keyed on (restaurant_name, menu_hash).
--
-- menu_hash is a SHA-256 of the sorted, normalized OCR'd dish-list — so the
-- same menu photographed at slightly different angles still hits the cache,
-- but a stale menu (Olive Garden seasonal menu changed) misses naturally
-- because the dish list will differ.

CREATE TABLE IF NOT EXISTS menu_scan_cache (
  restaurant_name   TEXT NOT NULL,
  menu_hash         TEXT NOT NULL,
  dishes            JSONB NOT NULL,
  scan_count        INTEGER NOT NULL DEFAULT 1,
  first_scanned_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_scanned_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at        TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '90 days'),
  PRIMARY KEY (restaurant_name, menu_hash)
);

CREATE INDEX IF NOT EXISTS idx_menu_scan_cache_restaurant
  ON menu_scan_cache (restaurant_name);

CREATE INDEX IF NOT EXISTS idx_menu_scan_cache_expires
  ON menu_scan_cache (expires_at);

-- Bumps the hit counters on cache hit. Called from the Phase-2 menu lookup
-- path; defined here so the read code stays vendor-neutral.
CREATE OR REPLACE FUNCTION menu_scan_cache_touch(
  p_restaurant_name TEXT,
  p_menu_hash       TEXT
) RETURNS void
LANGUAGE sql
AS $$
  UPDATE menu_scan_cache
     SET scan_count      = scan_count + 1,
         last_scanned_at = NOW()
   WHERE restaurant_name = p_restaurant_name
     AND menu_hash       = p_menu_hash;
$$;

COMMENT ON TABLE menu_scan_cache IS
  'Cross-user whole-menu cache for Phase-2 menu-scan acceleration. First user pays the cost; everyone else hits this cache for 90 days.';
COMMENT ON COLUMN menu_scan_cache.menu_hash IS
  'SHA-256 of sorted+normalized OCR-extracted dish list. Stable across photo angle, sensitive to menu content changes.';
