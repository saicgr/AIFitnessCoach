-- Migration 2277: durable store for AI target recommendations.
-- The AI "Recommend Targets" endpoint (api/v1/nutrition/ai_recommend.py) returns a
-- rich response (daily + per-meal + per-day blocks, reasoning, confidence, clamped[]).
-- Previously that rich object lived ONLY in a 12h RedisCache (lost on Redis outage /
-- restart / cache miss), and a flat audit row was INSERTed into the weekly table on
-- every non-cached call (no unique constraint → duplicate-row bloat, and a daily rec
-- in a "weekly" table is a semantic misfit).
--
-- This dedicated table is the durable L2 cache: one row per (user, local day, window),
-- upserted (idempotent), holding the full payload as JSONB. Read order in the endpoint
-- is RedisCache (L1) → this table (L2) → regenerate. Additive; no other table touched.
CREATE TABLE IF NOT EXISTS nutrition_ai_recommendations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL,
  rec_date    DATE NOT NULL,                 -- user's local day the rec was generated for
  window_days INTEGER NOT NULL DEFAULT 14,   -- context window used
  payload     JSONB NOT NULL,                -- full NutritionTargetsRecommendation.model_dump()
  confidence  TEXT,                          -- denormalized for quick filtering
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT nutrition_ai_recommendations_uniq UNIQUE (user_id, rec_date, window_days)
);

CREATE INDEX IF NOT EXISTS idx_nutrition_ai_recs_user_date
  ON nutrition_ai_recommendations (user_id, rec_date DESC);

COMMENT ON TABLE nutrition_ai_recommendations IS
  'Durable L2 cache for AI target recommendations (api/v1/nutrition/ai_recommend.py). One upserted row per (user_id, rec_date, window_days); payload = full rich response JSONB. Survives Redis outage/restart; read after the RedisCache L1, before regenerating.';
