-- 2290_resolve_exercise_demo_media_rpc.sql
-- Fallback resolver for GET /exercise-images/{name}: lets the active-workout
-- screen resolve exercise media via the SAME canonical/demos/aliases stack the
-- program schedule uses (exercise_aliases -> exercise_canonical -> exercise_demos),
-- keyed by normalize_exercise_name(). Exact normalized-alias match only — no fuzzy,
-- so it never serves a wrong-sibling image. Prefers a neutral-gender demo.
-- Applied to prod via Supabase MCP on 2026-06-26; idempotent for repo parity.
CREATE OR REPLACE FUNCTION resolve_exercise_demo_media(p_name text)
RETURNS TABLE(image_s3_path text, video_s3_path text, gif_url text, canonical_name text)
LANGUAGE sql STABLE AS $$
  SELECT d.image_s3_path, d.video_s3_path, d.gif_url, ec.canonical_name
  FROM exercise_aliases a
  JOIN exercise_canonical ec ON ec.id = a.canonical_exercise_id
  JOIN exercise_demos d ON d.canonical_exercise_id = a.canonical_exercise_id
  WHERE a.alias_name_normalized = normalize_exercise_name(p_name)
    AND (d.image_s3_path IS NOT NULL OR d.video_s3_path IS NOT NULL)
  ORDER BY (d.demo_gender = 'neutral') DESC NULLS LAST
  LIMIT 1;
$$;
