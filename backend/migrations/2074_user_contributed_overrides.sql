-- 2074_user_contributed_overrides.sql
--
-- Phase 2: per-user contributed-foods cache. When the canonical override DB
-- (food_nutrition_overrides_canonical) misses for a dish a user logs, the
-- runtime path falls through to Gemini, then auto-upserts the result here.
-- Next time THIS user logs the same dish → instant hit (no Gemini call).
--
-- Schema mirrors food_nutrition_overrides for the 6 macros + 9 enrichment
-- + 29 micronutrients so the runtime read path can use the same row shape
-- regardless of source. Adds per-user metadata (log_count, edit flags,
-- promotion flag) that drive the §2.10 cross-user promotion job.
--
-- Cross-table relationship: rows here can be PROMOTED to
-- food_nutrition_overrides (with source='auto_promoted', see mig 2075)
-- when ≥5 distinct users converge on similar macros for the same dish name.
-- Promoted rows stay here too (promoted_to_canonical=TRUE) for audit.
--
-- Privacy: RLS enforces user_id = auth.uid() so users only see their own
-- contributions. The promotion job runs as service role to aggregate.

CREATE TABLE IF NOT EXISTS food_overrides_user_contributed (
  -- Matches the codebase convention used by saved_foods + user_food_overrides:
  -- public.users.id (which equals auth.uid()) so RLS works directly.
  user_id                  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  food_name_normalized     TEXT NOT NULL,
  display_name             TEXT NOT NULL,

  -- 6 macros (mirror food_nutrition_overrides per-100g)
  calories_per_100g        REAL,
  protein_per_100g         REAL,
  carbs_per_100g           REAL,
  fat_per_100g             REAL,
  fiber_per_100g           REAL,
  sugar_per_100g           REAL,

  -- Portion hints
  default_weight_per_piece_g REAL,
  default_serving_g        REAL,
  default_count            INTEGER,

  -- 9 enrichment fields (mirror mig 2064)
  inflammation_score       SMALLINT,
  inflammation_triggers    TEXT[],
  glycemic_load            INTEGER,
  fodmap_rating            TEXT,
  fodmap_reason            TEXT,
  added_sugar_g            REAL,
  is_ultra_processed       BOOLEAN,
  rating                   TEXT,
  rating_reason            TEXT,

  -- 29 micronutrient fields (mirror mig 324 + 2073)
  saturated_fat_g          REAL,
  trans_fat_g              REAL,
  cholesterol_mg           REAL,
  sodium_mg                REAL,
  potassium_mg             REAL,
  calcium_mg               REAL,
  iron_mg                  REAL,
  magnesium_mg             REAL,
  zinc_mg                  REAL,
  phosphorus_mg            REAL,
  selenium_ug              REAL,
  copper_mg                REAL,
  manganese_mg             REAL,
  vitamin_a_ug             REAL,
  vitamin_c_mg             REAL,
  vitamin_d_iu             REAL,
  vitamin_e_mg             REAL,
  vitamin_k_ug             REAL,
  vitamin_b1_mg            REAL,
  vitamin_b2_mg            REAL,
  vitamin_b3_mg            REAL,
  vitamin_b5_mg            REAL,
  vitamin_b6_mg            REAL,
  vitamin_b7_ug            REAL,
  vitamin_b9_ug            REAL,
  vitamin_b12_ug           REAL,
  choline_mg               REAL,
  omega3_g                 REAL,
  omega6_g                 REAL,

  -- Per-user metadata (drives the runtime read path + promotion job)
  log_count                INTEGER NOT NULL DEFAULT 1,
  first_logged_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_logged_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_edited              BOOLEAN NOT NULL DEFAULT FALSE,        -- did the user manually override macros?
  source                   TEXT NOT NULL,                          -- 'gemini_runtime' | 'user_manual' | 'imported'
  promoted_to_canonical    BOOLEAN NOT NULL DEFAULT FALSE,

  PRIMARY KEY (user_id, food_name_normalized),
  CONSTRAINT user_contributed_source_enum
    CHECK (source IN ('gemini_runtime', 'user_manual', 'imported'))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_contributed_name
  ON food_overrides_user_contributed (food_name_normalized);

-- Promotion-job hot path — only un-promoted rows are interesting to aggregate.
CREATE INDEX IF NOT EXISTS idx_user_contributed_promotion_candidates
  ON food_overrides_user_contributed (food_name_normalized)
  WHERE promoted_to_canonical = FALSE AND user_edited = FALSE;

-- Per-user recent lookup (lets the read path order by recency for ties).
CREATE INDEX IF NOT EXISTS idx_user_contributed_user_recent
  ON food_overrides_user_contributed (user_id, last_logged_at DESC);

-- RLS — owner only.
ALTER TABLE food_overrides_user_contributed ENABLE ROW LEVEL SECURITY;

-- Owner CRUD (mirrors user_food_overrides policy pattern)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'food_overrides_user_contributed'
      AND policyname = 'user_contributed_owner_select'
  ) THEN
    CREATE POLICY user_contributed_owner_select
      ON food_overrides_user_contributed FOR SELECT
      USING ((SELECT auth.uid()) = user_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='food_overrides_user_contributed'
    AND policyname='user_contributed_owner_insert'
  ) THEN
    CREATE POLICY user_contributed_owner_insert
      ON food_overrides_user_contributed FOR INSERT
      WITH CHECK ((SELECT auth.uid()) = user_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='food_overrides_user_contributed'
    AND policyname='user_contributed_owner_update'
  ) THEN
    CREATE POLICY user_contributed_owner_update
      ON food_overrides_user_contributed FOR UPDATE
      USING ((SELECT auth.uid()) = user_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='food_overrides_user_contributed'
    AND policyname='user_contributed_owner_delete'
  ) THEN
    CREATE POLICY user_contributed_owner_delete
      ON food_overrides_user_contributed FOR DELETE
      USING ((SELECT auth.uid()) = user_id);
  END IF;
  -- Service role bypass for the cross-user promotion job (mirrors saved_foods)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='food_overrides_user_contributed'
    AND policyname='user_contributed_service_role_all'
  ) THEN
    CREATE POLICY user_contributed_service_role_all
      ON food_overrides_user_contributed
      USING (
        (SELECT current_setting('role'::text)) = 'service_role'::text
        OR (SELECT auth.role()) = 'service_role'::text
      )
      WITH CHECK (
        (SELECT current_setting('role'::text)) = 'service_role'::text
        OR (SELECT auth.role()) = 'service_role'::text
      );
  END IF;
END $$;

COMMENT ON TABLE food_overrides_user_contributed IS
  'Per-user cache of novel dishes that fell through canonical lookup. Self-warming via Gemini runtime fallback writes; the daily promotion job (backend/scripts/promote_user_contributed.py) migrates cross-user-validated entries into food_nutrition_overrides with source=auto_promoted.';

COMMENT ON COLUMN food_overrides_user_contributed.user_edited IS
  'TRUE when the user manually corrected macros via the per-item edit affordance. The promotion job EXCLUDES user_edited rows from cross-user averaging — one user''s correction must not propagate to everyone.';

COMMENT ON COLUMN food_overrides_user_contributed.promoted_to_canonical IS
  'TRUE once the promotion job has copied this dish into food_nutrition_overrides. Row stays here for audit + per-user lookup; the canonical row is what new users see.';
