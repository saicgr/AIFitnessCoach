-- 2331 — index food_database(name) for the dish-image catalog lookup.
--
-- WHY
-- ---
-- `services/dish_image_service.py::_lookup_food_database` resolves menu-scan
-- dishes against the food catalog with:
--
--     .select("name, image_url").in_("name", [up to 60 names])
--                               .not_.is_("image_url", "null")
--
-- `food_database` has NO btree index on `name` — the only name indexes are GIN
-- trigram over `name_normalized` (partial, is_primary = true), which Postgres
-- cannot use for an equality/IN predicate. On a 714k-row / 1.8 GB table that
-- means a sequential scan on EVERY menu scan, and it duly blew the statement
-- timeout in production:
--
--     [DishImage] food_database lookup failed: canceling statement due to
--     statement timeout (57014)          -- after ~9.3s, resolved=0
--
-- The lookup is fail-soft (it logs and returns {}), so nothing 500s — the whole
-- free catalog tier just silently never resolves, pushing every dish to the
-- paid Imagen path or a placeholder.
--
-- Partial on `image_url IS NOT NULL` because the query only ever wants rows
-- that actually carry an image; that keeps the index small relative to the
-- table.
--
-- ALREADY APPLIED to production with CREATE INDEX CONCURRENTLY (no write lock;
-- verified indisvalid = true). Kept here so a fresh environment gets it too.
-- CONCURRENTLY cannot run inside a transaction block — if your migration runner
-- wraps statements in one, run this statement on its own.

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_food_database_name_with_image
ON public.food_database (name)
WHERE image_url IS NOT NULL;
