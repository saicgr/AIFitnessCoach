-- 2260_food_patterns_symptoms_tags_digestion.sql
--
-- Nutrition overhaul (Phase 2C) — extend the correlation engine to use the new
-- food_logs.tags / food_logs.symptoms columns (migration 2258) and the new
-- digestion_logs table (migration 2259).
--
-- Three things:
--
--   1. REPLACE get_food_patterns to ADD per-symptom counts (bloated_count /
--      bloated_pct / tired_count / energized_count …) ALONGSIDE every existing
--      column. The signature, column order, and existing columns are PRESERVED
--      (the /food-patterns/mood endpoint + the Gemini re-log lookup read by
--      name and tolerate extra columns), so this is purely additive — new
--      trailing columns, nothing removed or reordered.
--        * "symptom" here unions the legacy mood_after / mood_after_inferred
--          vocabulary (tired/stressed/bloated/great/good/satisfied) with the
--          NEW open-vocab food_logs.symptoms[] array values. A row contributes
--          a symptom either via its effective mood OR via each entry in its
--          symptoms[] array.
--
--   2. NEW get_symptom_tag_correlations(user_id, days, min_logs): returns two
--      result shapes flattened into one table via `bucket_kind`:
--        * bucket_kind='symptom' — for each (food_name) the per-symptom counts,
--          so the UI can say "before you felt bloated: oat milk ×4".
--        * bucket_kind='tag'     — for each (tag, symptom) the co-occurrence
--          counts, so the UI can say "dairy → bloated 6/8 times (75%)".
--
--   3. NEW get_digestion_patterns(user_id, days): correlates food_logs.tags /
--      foods consumed in the ~72h BEFORE each digestion_logs entry against that
--      entry's bristol_type, returning (a) "tags before irregular days" and
--      (b) a daily regularity series.
--
-- All SECURITY INVOKER so food_logs / digestion_logs RLS applies; user_id is
-- always an explicit parameter (FastAPI passes the JWT user id under the
-- service role). Fail-open: empty inputs => empty result sets, never an error.

-- ===========================================================================
-- 1. get_food_patterns — extended with per-symptom counts (additive)
-- ===========================================================================
-- Drop+recreate because the RETURNS TABLE shape changes (new trailing cols);
-- CREATE OR REPLACE cannot change a function's return type in place.
DROP FUNCTION IF EXISTS public.get_food_patterns(uuid,int,int,boolean,text[]);

CREATE OR REPLACE FUNCTION public.get_food_patterns(
  p_user_id uuid,
  p_days int DEFAULT 90,
  p_min_logs int DEFAULT 3,
  p_include_inferred boolean DEFAULT true,
  p_food_names text[] DEFAULT NULL  -- when non-null, restrict to these names (for Gemini lookup)
)
RETURNS TABLE (
  -- ── existing columns (unchanged order) ──
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
  positive_score numeric,
  -- ── NEW per-symptom counts + pct (additive, trailing) ──
  bloated_count int,
  tired_count int,
  stressed_count int,
  sluggish_count int,
  foggy_count int,
  nauseous_count int,
  energized_count int,
  satisfied_count int,
  good_digestion_count int,
  bloated_pct numeric,
  tired_pct numeric,
  energized_pct numeric
)
LANGUAGE sql STABLE SECURITY INVOKER
AS $$
  WITH base AS (
    SELECT
      fl.id,
      LOWER(TRIM(item->>'name')) AS food_name,
      COALESCE(
        fl.mood_after,
        CASE
          WHEN p_include_inferred AND NOT COALESCE(fl.inference_user_dismissed, false)
          THEN fl.mood_after_inferred
        END
      ) AS effective_mood,
      COALESCE(
        fl.energy_level,
        CASE
          WHEN p_include_inferred AND NOT COALESCE(fl.inference_user_dismissed, false)
          THEN fl.energy_level_inferred
        END
      ) AS effective_energy,
      (fl.mood_after IS NOT NULL OR fl.energy_level IS NOT NULL) AS is_confirmed,
      fl.symptoms AS symptoms,
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
  -- A row counts as "having a check-in" if it has an effective mood/energy OR
  -- any structured symptom in symptoms[]. This widens the v1 definition so the
  -- new symptom capture path also lights up patterns.
  filtered AS (
    SELECT * FROM base
    WHERE effective_mood IS NOT NULL
       OR effective_energy IS NOT NULL
       OR (symptoms IS NOT NULL AND array_length(symptoms, 1) > 0)
  ),
  -- One row per (food_name, symptom_token). A symptom token comes from either
  -- the effective mood OR each member of the symptoms[] array (lower-cased).
  symptom_tokens AS (
    SELECT food_name, LOWER(TRIM(effective_mood)) AS sym
    FROM filtered
    WHERE effective_mood IS NOT NULL
    UNION ALL
    SELECT f.food_name, LOWER(TRIM(s)) AS sym
    FROM filtered f
    CROSS JOIN LATERAL unnest(COALESCE(f.symptoms, ARRAY[]::text[])) AS s
    WHERE s IS NOT NULL AND LENGTH(TRIM(s)) > 0
  ),
  per_food_symptoms AS (
    SELECT
      food_name,
      COUNT(*) FILTER (WHERE sym = 'bloated')::int        AS bloated_count,
      COUNT(*) FILTER (WHERE sym = 'tired')::int          AS tired_count,
      COUNT(*) FILTER (WHERE sym = 'stressed')::int       AS stressed_count,
      COUNT(*) FILTER (WHERE sym = 'sluggish')::int       AS sluggish_count,
      COUNT(*) FILTER (WHERE sym = 'foggy')::int          AS foggy_count,
      COUNT(*) FILTER (WHERE sym = 'nauseous')::int       AS nauseous_count,
      COUNT(*) FILTER (WHERE sym IN ('energized','great','good'))::int AS energized_count,
      COUNT(*) FILTER (WHERE sym = 'satisfied')::int      AS satisfied_count,
      COUNT(*) FILTER (WHERE sym = 'good_digestion')::int AS good_digestion_count
    FROM symptom_tokens
    GROUP BY food_name
  ),
  aggregated AS (
    SELECT
      f.food_name,
      COUNT(*)::int AS logs_with_checkin,
      COUNT(*) FILTER (WHERE f.is_confirmed)::int AS confirmed_count,
      COUNT(*) FILTER (WHERE NOT f.is_confirmed)::int AS inferred_count,
      COUNT(*) FILTER (WHERE f.effective_mood IN ('tired','stressed','bloated'))::int AS negative_mood_count,
      COUNT(*) FILTER (WHERE f.effective_mood IN ('great','good','satisfied'))::int AS positive_mood_count,
      AVG(f.effective_energy)::numeric(4,2) AS avg_energy,
      COUNT(*) FILTER (WHERE f.effective_energy <= 2)::int AS low_energy_count,
      COUNT(*) FILTER (WHERE f.effective_energy >= 4)::int AS high_energy_count,
      MAX(f.logged_at) AS last_logged_at,
      (
        SELECT effective_mood
        FROM filtered f2
        WHERE f2.food_name = f.food_name AND f2.effective_mood IS NOT NULL
        GROUP BY effective_mood
        ORDER BY
          CASE WHEN effective_mood IN ('tired','stressed','bloated') THEN 0 ELSE 1 END,
          COUNT(*) DESC
        LIMIT 1
      ) AS dominant_symptom,
      (
        SUM(CASE WHEN f.effective_mood IN ('tired','stressed','bloated')
                 THEN (CASE WHEN f.is_confirmed THEN 1.0 ELSE 0.5 END) ELSE 0 END)
        + SUM(CASE WHEN f.effective_energy <= 2
                 THEN (CASE WHEN f.is_confirmed THEN 0.5 ELSE 0.25 END) ELSE 0 END)
      ) / GREATEST(COUNT(*),1)::numeric AS negative_score,
      (
        SUM(CASE WHEN f.effective_mood IN ('great','good','satisfied')
                 THEN (CASE WHEN f.is_confirmed THEN 1.0 ELSE 0.5 END) ELSE 0 END)
        + SUM(CASE WHEN f.effective_energy >= 4
                 THEN (CASE WHEN f.is_confirmed THEN 0.5 ELSE 0.25 END) ELSE 0 END)
      ) / GREATEST(COUNT(*),1)::numeric AS positive_score
    FROM filtered f
    GROUP BY f.food_name
  )
  SELECT
    a.food_name,
    a.logs_with_checkin,
    a.confirmed_count,
    a.inferred_count,
    a.negative_mood_count,
    a.positive_mood_count,
    a.avg_energy,
    a.low_energy_count,
    a.high_energy_count,
    a.last_logged_at,
    a.dominant_symptom,
    a.negative_score,
    a.positive_score,
    COALESCE(s.bloated_count, 0),
    COALESCE(s.tired_count, 0),
    COALESCE(s.stressed_count, 0),
    COALESCE(s.sluggish_count, 0),
    COALESCE(s.foggy_count, 0),
    COALESCE(s.nauseous_count, 0),
    COALESCE(s.energized_count, 0),
    COALESCE(s.satisfied_count, 0),
    COALESCE(s.good_digestion_count, 0),
    ROUND(COALESCE(s.bloated_count, 0)::numeric   / GREATEST(a.logs_with_checkin,1) * 100, 1),
    ROUND(COALESCE(s.tired_count, 0)::numeric     / GREATEST(a.logs_with_checkin,1) * 100, 1),
    ROUND(COALESCE(s.energized_count, 0)::numeric / GREATEST(a.logs_with_checkin,1) * 100, 1)
  FROM aggregated a
  LEFT JOIN per_food_symptoms s ON s.food_name = a.food_name
  WHERE a.logs_with_checkin >= p_min_logs
  ORDER BY GREATEST(a.negative_score, a.positive_score) DESC;
$$;

REVOKE ALL ON FUNCTION public.get_food_patterns(uuid,int,int,boolean,text[]) FROM public;
GRANT EXECUTE ON FUNCTION public.get_food_patterns(uuid,int,int,boolean,text[]) TO authenticated, service_role;


-- ===========================================================================
-- 2. get_symptom_tag_correlations — per-symptom (by food) + per-tag (by symptom)
-- ===========================================================================
-- Flattened into one table with a `bucket_kind` discriminator so a single RPC
-- call powers both "before you felt bloated" (food→symptom) and "dairy →
-- bloated" (tag→symptom) correlation cards.
CREATE OR REPLACE FUNCTION public.get_symptom_tag_correlations(
  p_user_id uuid,
  p_days int DEFAULT 90,
  p_min_logs int DEFAULT 2
)
RETURNS TABLE (
  bucket_kind text,         -- 'symptom' | 'tag'
  symptom text,             -- the symptom token
  food_name text,           -- populated when bucket_kind='symptom'
  tag text,                 -- populated when bucket_kind='tag'
  occurrences int,          -- # of meals where (food|tag) co-occurred with symptom
  total_with_signal int,    -- # of meals for that food|tag that had ANY check-in
  pct numeric,              -- occurrences / total_with_signal * 100
  last_image_url text,
  last_logged_at timestamptz
)
LANGUAGE sql STABLE SECURITY INVOKER
AS $$
  WITH log_rows AS (
    SELECT
      fl.id,
      fl.image_url,
      fl.logged_at,
      fl.symptoms,
      fl.tags,
      fl.food_items,
      fl.mood_after,
      fl.mood_after_inferred,
      fl.energy_level,
      fl.inference_user_dismissed
    FROM public.food_logs fl
    WHERE fl.user_id = p_user_id
      AND fl.deleted_at IS NULL
      AND fl.logged_at >= NOW() - (p_days || ' days')::interval
  ),
  -- One symptom token per row (mood + each symptoms[] member).
  row_symptoms AS (
    SELECT id, LOWER(TRIM(COALESCE(mood_after,
              CASE WHEN NOT COALESCE(inference_user_dismissed,false)
                   THEN mood_after_inferred END))) AS sym,
           image_url, logged_at
    FROM log_rows
    WHERE COALESCE(mood_after,
              CASE WHEN NOT COALESCE(inference_user_dismissed,false)
                   THEN mood_after_inferred END) IS NOT NULL
    UNION ALL
    SELECT r.id, LOWER(TRIM(s)) AS sym, r.image_url, r.logged_at
    FROM log_rows r
    CROSS JOIN LATERAL unnest(COALESCE(r.symptoms, ARRAY[]::text[])) AS s
    WHERE s IS NOT NULL AND LENGTH(TRIM(s)) > 0
  ),
  -- has-signal = row has at least one symptom token (for denominators).
  signal_rows AS (
    SELECT DISTINCT id FROM row_symptoms
  ),
  -- ── bucket_kind='symptom' : food_name x symptom ──
  food_sym AS (
    SELECT
      LOWER(TRIM(item->>'name')) AS food_name,
      rs.sym,
      rs.id,
      rs.image_url,
      rs.logged_at
    FROM log_rows r
    JOIN row_symptoms rs ON rs.id = r.id
    CROSS JOIN LATERAL jsonb_array_elements(r.food_items) AS item
    WHERE item->>'name' IS NOT NULL AND LENGTH(TRIM(item->>'name')) >= 2
  ),
  food_totals AS (
    -- denominator: # of has-signal meals containing this food
    SELECT LOWER(TRIM(item->>'name')) AS food_name, COUNT(DISTINCT fl.id)::int AS total_with_signal
    FROM public.food_logs fl
    JOIN signal_rows sr ON sr.id = fl.id
    CROSS JOIN LATERAL jsonb_array_elements(fl.food_items) AS item
    WHERE item->>'name' IS NOT NULL AND LENGTH(TRIM(item->>'name')) >= 2
    GROUP BY 1
  ),
  food_bucket AS (
    SELECT
      'symptom'::text AS bucket_kind,
      fsy.sym AS symptom,
      fsy.food_name,
      NULL::text AS tag,
      COUNT(DISTINCT fsy.id)::int AS occurrences,
      MAX(ft.total_with_signal) AS total_with_signal,
      MAX(CASE WHEN fsy.image_url IS NOT NULL THEN fsy.image_url END) AS last_image_url,
      MAX(fsy.logged_at) AS last_logged_at
    FROM food_sym fsy
    JOIN food_totals ft ON ft.food_name = fsy.food_name
    WHERE fsy.sym IS NOT NULL
    GROUP BY fsy.sym, fsy.food_name
  ),
  -- ── bucket_kind='tag' : tag x symptom ──
  tag_sym AS (
    SELECT LOWER(TRIM(t)) AS tag, rs.sym, rs.id, rs.image_url, rs.logged_at
    FROM log_rows r
    JOIN row_symptoms rs ON rs.id = r.id
    CROSS JOIN LATERAL unnest(COALESCE(r.tags, ARRAY[]::text[])) AS t
    WHERE t IS NOT NULL AND LENGTH(TRIM(t)) > 0
  ),
  tag_totals AS (
    SELECT LOWER(TRIM(t)) AS tag, COUNT(DISTINCT fl.id)::int AS total_with_signal
    FROM public.food_logs fl
    JOIN signal_rows sr ON sr.id = fl.id
    CROSS JOIN LATERAL unnest(COALESCE(fl.tags, ARRAY[]::text[])) AS t
    WHERE t IS NOT NULL AND LENGTH(TRIM(t)) > 0
    GROUP BY 1
  ),
  tag_bucket AS (
    SELECT
      'tag'::text AS bucket_kind,
      tsy.sym AS symptom,
      NULL::text AS food_name,
      tsy.tag,
      COUNT(DISTINCT tsy.id)::int AS occurrences,
      MAX(tt.total_with_signal) AS total_with_signal,
      MAX(CASE WHEN tsy.image_url IS NOT NULL THEN tsy.image_url END) AS last_image_url,
      MAX(tsy.logged_at) AS last_logged_at
    FROM tag_sym tsy
    JOIN tag_totals tt ON tt.tag = tsy.tag
    WHERE tsy.sym IS NOT NULL
    GROUP BY tsy.sym, tsy.tag
  ),
  unioned AS (
    SELECT * FROM food_bucket
    UNION ALL
    SELECT * FROM tag_bucket
  )
  SELECT
    bucket_kind,
    symptom,
    food_name,
    tag,
    occurrences,
    total_with_signal,
    ROUND(occurrences::numeric / GREATEST(total_with_signal,1) * 100, 1) AS pct,
    last_image_url,
    last_logged_at
  FROM unioned
  WHERE occurrences >= p_min_logs
  ORDER BY occurrences DESC, pct DESC;
$$;

REVOKE ALL ON FUNCTION public.get_symptom_tag_correlations(uuid,int,int) FROM public;
GRANT EXECUTE ON FUNCTION public.get_symptom_tag_correlations(uuid,int,int) TO authenticated, service_role;


-- ===========================================================================
-- 3. get_digestion_patterns — food/tag → gut correlations + regularity series
-- ===========================================================================
-- Digestion lags ingestion (research shows transit up to ~72h), so we correlate
-- each digestion_logs entry against the food consumed in the LAGGED window
-- before it (default 6h..72h prior). Returns two flattened shapes via
-- `result_kind`:
--   * result_kind='tag_correlation' — for each tag, how often it preceded an
--     IRREGULAR entry (bristol 1-2 hard, or 6-7 loose) vs a regular one.
--   * result_kind='regularity_day'  — a per-day series: that day's worst-case
--     bristol bucket so the UI can plot a regularity timeline.
CREATE OR REPLACE FUNCTION public.get_digestion_patterns(
  p_user_id uuid,
  p_days int DEFAULT 90,
  p_lag_min_hours numeric DEFAULT 6,
  p_lag_max_hours numeric DEFAULT 72,
  p_min_logs int DEFAULT 2
)
RETURNS TABLE (
  result_kind text,          -- 'tag_correlation' | 'regularity_day'
  tag text,                  -- tag_correlation only
  irregular_count int,       -- tag_correlation: # irregular entries preceded by tag
  regular_count int,         -- tag_correlation: # regular entries preceded by tag
  total_count int,           -- tag_correlation: total entries preceded by tag
  irregular_pct numeric,     -- tag_correlation: irregular / total * 100
  day text,                  -- regularity_day only (YYYY-MM-DD, UTC date)
  worst_bristol int,         -- regularity_day: most-extreme bristol that day
  avg_bristol numeric,       -- regularity_day: mean bristol that day
  entry_count int            -- regularity_day: # digestion entries that day
)
LANGUAGE sql STABLE SECURITY INVOKER
AS $$
  WITH dlogs AS (
    SELECT id, logged_at, bristol_type,
           -- irregular = constipation (1-2) or diarrhea (6-7); regular = 3-5.
           (bristol_type <= 2 OR bristol_type >= 6) AS is_irregular
    FROM public.digestion_logs
    WHERE user_id = p_user_id
      AND logged_at >= NOW() - (p_days || ' days')::interval
  ),
  -- For every digestion entry, the tags from foods eaten in the lag window
  -- before it. A tag may appear once per (entry, tag) — DISTINCT so two meals
  -- with the same tag before one entry count once for that entry.
  preceding_tags AS (
    SELECT DISTINCT
      d.id AS dlog_id,
      d.is_irregular,
      LOWER(TRIM(t)) AS tag
    FROM dlogs d
    JOIN public.food_logs fl
      ON fl.user_id = p_user_id
     AND fl.deleted_at IS NULL
     AND fl.logged_at <= d.logged_at - (p_lag_min_hours || ' hours')::interval
     AND fl.logged_at >= d.logged_at - (p_lag_max_hours || ' hours')::interval
    CROSS JOIN LATERAL unnest(COALESCE(fl.tags, ARRAY[]::text[])) AS t
    WHERE t IS NOT NULL AND LENGTH(TRIM(t)) > 0
  ),
  tag_corr AS (
    SELECT
      'tag_correlation'::text AS result_kind,
      tag,
      COUNT(*) FILTER (WHERE is_irregular)::int AS irregular_count,
      COUNT(*) FILTER (WHERE NOT is_irregular)::int AS regular_count,
      COUNT(*)::int AS total_count,
      ROUND(COUNT(*) FILTER (WHERE is_irregular)::numeric / GREATEST(COUNT(*),1) * 100, 1) AS irregular_pct,
      NULL::text AS day,
      NULL::int AS worst_bristol,
      NULL::numeric AS avg_bristol,
      NULL::int AS entry_count
    FROM preceding_tags
    GROUP BY tag
    HAVING COUNT(*) >= p_min_logs
  ),
  regularity AS (
    SELECT
      'regularity_day'::text AS result_kind,
      NULL::text AS tag,
      NULL::int AS irregular_count,
      NULL::int AS regular_count,
      NULL::int AS total_count,
      NULL::numeric AS irregular_pct,
      to_char(logged_at, 'YYYY-MM-DD') AS day,
      -- worst-case = the bristol furthest from the ideal midpoint (4).
      (ARRAY_AGG(bristol_type ORDER BY ABS(bristol_type - 4) DESC))[1]::int AS worst_bristol,
      ROUND(AVG(bristol_type)::numeric, 1) AS avg_bristol,
      COUNT(*)::int AS entry_count
    FROM dlogs
    GROUP BY to_char(logged_at, 'YYYY-MM-DD')
  )
  SELECT * FROM tag_corr
  UNION ALL
  SELECT * FROM regularity
  ORDER BY result_kind, irregular_pct DESC NULLS LAST, day;
$$;

REVOKE ALL ON FUNCTION public.get_digestion_patterns(uuid,int,numeric,numeric,int) FROM public;
GRANT EXECUTE ON FUNCTION public.get_digestion_patterns(uuid,int,numeric,numeric,int) TO authenticated, service_role;
