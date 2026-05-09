-- Audit + retag exercises that should be tagged as core but aren't.
--
-- Result of dry-run on 2026-05-08 against Supabase project
-- `hpbzfahijszqmgsybuor` (ai-fitness-coach):
--   - 131 / 143 plank|crunch|hollow|sit-up rows already tagged
--     `body_part = 'waist'` and `target_muscle` containing 'Abs'.
--   - 12 outliers all correctly tagged to non-core (Plank Pushup =
--     chest, Dip Leg Raise = triceps, Bridge w/ Leg Raise = glutes,
--     Side Bend Lats Stretch = back). NO retag needed.
--
-- The actual fix lived in the Flutter alias map: `'waist' → 'Core'`
-- in `mobile/flutter/lib/core/utils/muscle_aliases.dart`. The
-- Advanced atlas heatmap was only matching by substring so 'waist'
-- never lit up the abdomen. Frontend canonicalization now handles it.
--
-- Keep this audit query in source so future imports can be re-checked
-- with one command:
--
--   backend/.venv/bin/python -c "import os, psycopg2; \
--     conn = psycopg2.connect(os.environ['DATABASE_URL_DIRECT']); \
--     cur = conn.cursor(); cur.execute(open('backend/scripts/retag_core_exercises.sql').read()); \
--     print(cur.fetchall())"

-- ─── 1. AUDIT ────────────────────────────────────────────────────────
-- All exercises that NAME-MATCH core movements but lack a core tag.
-- Should return ZERO rows after import.
SELECT
  exercise_name,
  body_part,
  target_muscle
FROM exercise_library
WHERE exercise_name ~* '^(crunch|sit.?up|hollow|ab wheel|reverse crunch|cable crunch|dead.?bug|v.?up|toes.?to.?bar|russian twist|flutter kick|scissor kick|side plank$|plank$)'
  AND lower(coalesce(target_muscle, '')) NOT SIMILAR TO '%(abs|abdominal|core|oblique|rectus|transverse|waist)%'
  AND lower(coalesce(body_part, '')) NOT SIMILAR TO '%(waist|core|abdomi)%'
ORDER BY exercise_name;

-- ─── 2. (ONLY IF AUDIT RETURNS ROWS) RETAG ──────────────────────────
-- Uncomment the UPDATE below and review carefully. Each candidate
-- should be inspected — many "leg raise" and "plank pushup" variants
-- are correctly NOT tagged as core (they're hip flexor / chest moves).
--
-- UPDATE exercise_library
-- SET body_part = 'waist'
-- WHERE exercise_name ~* 'PASTE_NAME_HERE_AFTER_REVIEW';
--
-- After any update:
--   SELECT refresh_exercise_library_cleaned();
