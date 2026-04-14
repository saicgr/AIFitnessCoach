-- 1924_food_patterns_rpcs.sql
-- RPC functions backing the new Nutrition > Patterns tab and Gemini re-log warning.
--
-- get_food_patterns       -> mood/energy correlations per food (Section 3)
-- get_top_foods_by_metric -> ranked foods by nutrient over a window (Section 2)
--
-- Both are SECURITY INVOKER so RLS on food_logs applies naturally.
-- user_id is always a parameter, not trusted from session context directly, because
-- callers may be FastAPI using the service role. FastAPI must pass the authenticated
-- user's id from JWT.

-- ---------------------------------------------------------------------------
-- Mood / energy patterns
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_food_patterns(
  p_user_id uuid,
  p_days int DEFAULT 90,
  p_min_logs int DEFAULT 3,
  p_include_inferred boolean DEFAULT true,
  p_food_names text[] DEFAULT NULL  -- when non-null, restrict to these names (for Gemini lookup)
)
RETURNS TABLE (
  food_name text,
  logs_with_checkin int,
  confirmed_count int,
  inferred_count int,
  negative_mood_count int,
  positive_mood_count int,
  avg_energy numeric,
  low_energy_count int,
  high_energy_count int,
  last_logged_at timestamptz,
  dominant_symptom text,
  negative_score numeric,
  positive_score numeric
)
LANGUAGE sql STABLE SECURITY INVOKER
AS $$
  WITH items AS (
    SELECT
      LOWER(TRIM(item->>'name')) AS food_name,
      -- effective mood/energy: confirmed wins, else inferred (if allowed)
      COALESCE(
        fl.mood_after,
        CASE
          WHEN p_include_inferred
            AND NOT COALESCE(fl.inference_user_dismissed, false)
          THEN fl.mood_after_inferred
        END
      ) AS effective_mood,
      COALESCE(
        fl.energy_level,
        CASE
          WHEN p_include_inferred
            AND NOT COALESCE(fl.inference_user_dismissed, false)
          THEN fl.energy_level_inferred
        END
      ) AS effective_energy,
      (fl.mood_after IS NOT NULL OR fl.energy_level IS NOT NULL) AS is_confirmed,
      fl.logged_at
    FROM public.food_logs fl
    CROSS JOIN LATERAL jsonb_array_elements(fl.food_items) AS item
    WHERE fl.user_id = p_user_id
      AND fl.deleted_at IS NULL
      AND fl.logged_at >= NOW() - (p_days || ' days')::interval
      AND item->>'name' IS NOT NULL
      AND LENGTH(TRIM(item->>'name')) >= 2
      AND (p_food_names IS NULL OR LOWER(TRIM(item->>'name')) = ANY(
        SELECT LOWER(TRIM(n)) FROM unnest(p_food_names) AS n
      ))
  ),
  filtered AS (
    SELECT * FROM items
    WHERE effective_mood IS NOT NULL OR effective_energy IS NOT NULL
  ),
  aggregated AS (
    SELECT
      food_name,
      COUNT(*)::int AS logs_with_checkin,
      COUNT(*) FILTER (WHERE is_confirmed)::int AS confirmed_count,
      COUNT(*) FILTER (WHERE NOT is_confirmed)::int AS inferred_count,
      COUNT(*) FILTER (WHERE effective_mood IN ('tired','stressed','bloated'))::int AS negative_mood_count,
      COUNT(*) FILTER (WHERE effective_mood IN ('great','good','satisfied'))::int AS positive_mood_count,
      AVG(effective_energy)::numeric(4,2) AS avg_energy,
      COUNT(*) FILTER (WHERE effective_energy <= 2)::int AS low_energy_count,
      COUNT(*) FILTER (WHERE effective_energy >= 4)::int AS high_energy_count,
      MAX(logged_at) AS last_logged_at,
      -- dominant symptom = most common negative mood, else most common positive
      (
        SELECT effective_mood
        FROM filtered f2
        WHERE f2.food_name = filtered.food_name AND f2.effective_mood IS NOT NULL
        GROUP BY effective_mood
        ORDER BY
          CASE WHEN effective_mood IN ('tired','stressed','bloated') THEN 0 ELSE 1 END,
          COUNT(*) DESC
        LIMIT 1
      ) AS dominant_symptom,
      -- confirmed rows weighted 1.0, inferred rows 0.5
      (
        SUM(
          CASE WHEN effective_mood IN ('tired','stressed','bloated')
               THEN (CASE WHEN is_confirmed THEN 1.0 ELSE 0.5 END)
               ELSE 0 END
        )
        + SUM(
          CASE WHEN effective_energy <= 2
               THEN (CASE WHEN is_confirmed THEN 0.5 ELSE 0.25 END)
               ELSE 0 END
        )
      ) / GREATEST(COUNT(*),1)::numeric AS negative_score,
      (
        SUM(
          CASE WHEN effective_mood IN ('great','good','satisfied')
               THEN (CASE WHEN is_confirmed THEN 1.0 ELSE 0.5 END)
               ELSE 0 END
        )
        + SUM(
          CASE WHEN effective_energy >= 4
               THEN (CASE WHEN is_confirmed THEN 0.5 ELSE 0.25 END)
               ELSE 0 END
        )
      ) / GREATEST(COUNT(*),1)::numeric AS positive_score
    FROM filtered
    GROUP BY food_name
  )
  SELECT
    food_name,
    logs_with_checkin,
    confirmed_count,
    inferred_count,
    negative_mood_count,
    positive_mood_count,
    avg_energy,
    low_energy_count,
    high_energy_count,
    last_logged_at,
    dominant_symptom,
    negative_score,
    positive_score
  FROM aggregated
  WHERE logs_with_checkin >= p_min_logs
  ORDER BY GREATEST(negative_score, positive_score) DESC;
$$;

REVOKE ALL ON FUNCTION public.get_food_patterns(uuid,int,int,boolean,text[]) FROM public;
GRANT EXECUTE ON FUNCTION public.get_food_patterns(uuid,int,int,boolean,text[]) TO authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Top foods by nutrient metric
-- ---------------------------------------------------------------------------
-- Returns ranked foods for the given metric and window. Supported metrics map to
-- JSONB per-item fields: calories, protein_g, carbs_g, fat_g, fiber_g, sugar_g,
-- sodium_mg. If an item is missing that field, we fall back to the row total
-- divided by item count (approximate but reasonable).
CREATE OR REPLACE FUNCTION public.get_top_foods_by_metric(
  p_user_id uuid,
  p_metric text,
  p_start_ts timestamptz,
  p_end_ts timestamptz,
  p_limit int DEFAULT 20
)
RETURNS TABLE (
  food_name text,
  total_value numeric,
  occurrences int,
  last_image_url text,
  last_food_score int,
  last_logged_at timestamptz
)
LANGUAGE plpgsql STABLE SECURITY INVOKER
AS $$
DECLARE
  item_field text;
  row_field text;
BEGIN
  -- Map metric to the JSONB item key + the row-level column used for fallback.
  CASE p_metric
    WHEN 'calories' THEN item_field := 'calories'; row_field := 'total_calories';
    WHEN 'protein'  THEN item_field := 'protein_g'; row_field := 'protein_g';
    WHEN 'carbs'    THEN item_field := 'carbs_g'; row_field := 'carbs_g';
    WHEN 'fat'      THEN item_field := 'fat_g'; row_field := 'fat_g';
    WHEN 'fiber'    THEN item_field := 'fiber_g'; row_field := 'fiber_g';
    WHEN 'sugar'    THEN item_field := 'sugar_g'; row_field := 'sugar_g';
    WHEN 'sodium'   THEN item_field := 'sodium_mg'; row_field := 'sodium_mg';
    ELSE
      RAISE EXCEPTION 'Unsupported metric: %', p_metric
        USING HINT = 'Expected one of calories, protein, carbs, fat, fiber, sugar, sodium';
  END CASE;

  RETURN QUERY EXECUTE format($f$
    WITH items AS (
      SELECT
        LOWER(TRIM(item->>'name')) AS food_name,
        COALESCE(
          NULLIF(item->>%1$L, '')::numeric,
          fl.%2$I / GREATEST(jsonb_array_length(fl.food_items), 1)
        ) AS value,
        fl.image_url,
        fl.health_score,
        fl.logged_at,
        ROW_NUMBER() OVER (
          PARTITION BY LOWER(TRIM(item->>'name'))
          ORDER BY fl.logged_at DESC
        ) AS rn
      FROM public.food_logs fl
      CROSS JOIN LATERAL jsonb_array_elements(fl.food_items) AS item
      WHERE fl.user_id = $1
        AND fl.deleted_at IS NULL
        AND fl.logged_at >= $2
        AND fl.logged_at < $3
        AND item->>'name' IS NOT NULL
        AND LENGTH(TRIM(item->>'name')) >= 2
    )
    SELECT
      food_name,
      SUM(value)::numeric AS total_value,
      COUNT(*)::int AS occurrences,
      MAX(CASE WHEN rn = 1 THEN image_url END) AS last_image_url,
      MAX(CASE WHEN rn = 1 THEN health_score END)::int AS last_food_score,
      MAX(logged_at) AS last_logged_at
    FROM items
    WHERE value IS NOT NULL AND value > 0
    GROUP BY food_name
    ORDER BY total_value DESC
    LIMIT $4
  $f$, item_field, row_field)
  USING p_user_id, p_start_ts, p_end_ts, p_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_top_foods_by_metric(uuid,text,timestamptz,timestamptz,int) FROM public;
GRANT EXECUTE ON FUNCTION public.get_top_foods_by_metric(uuid,text,timestamptz,timestamptz,int) TO authenticated, service_role;
