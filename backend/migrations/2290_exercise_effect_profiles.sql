-- Migration: 2290_exercise_effect_profiles.sql
-- Created: 2026-06-26
-- Purpose: Dr-Yaad audit #5 — give every exercise an "effect profile" so the
--          engine can reason about it as a TOOL, not a flat list item:
--            • recoverability   (1 slow … 5 fast)  — how quickly it recovers
--            • tissue_stress    JSONB {tissue: 0–5} — per-joint/tendon load
--                               (feeds the tissue-fatigue ledger, migration 2291)
--            • time_cost_seconds INTEGER           — rough wall-clock per exercise
--            • is_prehab        BOOLEAN            — mobility/prehab slot
--            • systemic_load    (1 light … 5 heavy) — whole-body / CNS demand
--
--          Values are SEEDED DETERMINISTICALLY from the existing movement_pattern
--          family + impact_level (no LLM, 100% coverage, matches the
--          deterministic-first instruction-audit philosophy). The LLM refiner
--          `scripts/generate_exercise_effect_profiles.py` can sharpen
--          tissue_stress/recoverability afterwards. Refresh the
--          exercise_library_cleaned MV after applying.

-- ============================================
-- 1. Columns
-- ============================================
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS recoverability SMALLINT;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS tissue_stress JSONB;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS time_cost_seconds INTEGER;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS is_prehab BOOLEAN DEFAULT FALSE;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS systemic_load SMALLINT;

-- ============================================
-- 2. Deterministic seed by movement-pattern family
-- ============================================
-- A normalized family bucket from the (messy, 54-value) movement_pattern vocab.
WITH fam AS (
  SELECT id,
    CASE
      WHEN lower(movement_pattern) IN ('horizontal_push','vertical_push','press','push','fly','pullover')
        THEN 'push'
      WHEN lower(movement_pattern) IN ('horizontal_pull','vertical_pull','row','pull','pulldown','explosive pull')
        THEN 'pull'
      WHEN lower(movement_pattern) LIKE '%curl%' OR lower(movement_pattern) = 'shrug'
        THEN 'arm_iso'
      WHEN lower(movement_pattern) IN ('hinge','hip extension','hip flexion')
        THEN 'hinge'
      WHEN lower(movement_pattern) IN ('squat','lunge')
        THEN 'squat'
      WHEN lower(movement_pattern) IN ('knee flexion','knee extension')
        THEN 'knee_iso'
      WHEN lower(movement_pattern) IN ('ankle plantarflexion')
        THEN 'calf'
      WHEN lower(movement_pattern) IN ('wrist flexion','wrist extension')
        THEN 'wrist'
      WHEN lower(movement_pattern) IN ('jump','plyometric')
        THEN 'plyo'
      WHEN lower(movement_pattern) IN ('carry','gait','locomotion')
        THEN 'carry'
      WHEN lower(movement_pattern) IN ('raise','abduction')
        THEN 'shoulder_iso'
      WHEN lower(movement_pattern) IN ('core_flexion','rotation','anti_rotation','anti-extension','flexion','extension','isometric_hold','static hold')
        THEN 'core'
      WHEN lower(movement_pattern) IN ('static_stretch','static stretch','dynamic_mobility','dynamic stretch','dynamic flow','dynamic')
        THEN 'mobility'
      WHEN lower(movement_pattern) = 'compound'
        THEN 'compound'
      ELSE 'isolation'
    END AS family
  FROM exercise_library
)
UPDATE exercise_library e SET
  recoverability = CASE f.family
      WHEN 'push' THEN 3 WHEN 'pull' THEN 3 WHEN 'arm_iso' THEN 4
      WHEN 'hinge' THEN 2 WHEN 'squat' THEN 2 WHEN 'knee_iso' THEN 3
      WHEN 'calf' THEN 4 WHEN 'wrist' THEN 4 WHEN 'plyo' THEN 2
      WHEN 'carry' THEN 3 WHEN 'shoulder_iso' THEN 4 WHEN 'core' THEN 4
      WHEN 'mobility' THEN 5 WHEN 'compound' THEN 2 ELSE 4 END,
  systemic_load = CASE f.family
      WHEN 'push' THEN 3 WHEN 'pull' THEN 3 WHEN 'arm_iso' THEN 2
      WHEN 'hinge' THEN 4 WHEN 'squat' THEN 4 WHEN 'knee_iso' THEN 2
      WHEN 'calf' THEN 1 WHEN 'wrist' THEN 1 WHEN 'plyo' THEN 4
      WHEN 'carry' THEN 3 WHEN 'shoulder_iso' THEN 2 WHEN 'core' THEN 2
      WHEN 'mobility' THEN 1 WHEN 'compound' THEN 4 ELSE 2 END,
  time_cost_seconds = CASE f.family
      WHEN 'push' THEN 180 WHEN 'pull' THEN 180 WHEN 'arm_iso' THEN 120
      WHEN 'hinge' THEN 200 WHEN 'squat' THEN 200 WHEN 'knee_iso' THEN 120
      WHEN 'calf' THEN 90 WHEN 'wrist' THEN 80 WHEN 'plyo' THEN 120
      WHEN 'carry' THEN 120 WHEN 'shoulder_iso' THEN 100 WHEN 'core' THEN 90
      WHEN 'mobility' THEN 60 WHEN 'compound' THEN 200 ELSE 100 END,
  is_prehab = (f.family = 'mobility') OR COALESCE(e.is_dynamic_stretch, FALSE),
  tissue_stress = CASE f.family
      WHEN 'push'         THEN '{"shoulder":3,"elbow":2,"wrist":1}'::jsonb
      WHEN 'pull'         THEN '{"elbow":2,"shoulder":2,"wrist":1}'::jsonb
      WHEN 'arm_iso'      THEN '{"elbow":3,"wrist":2}'::jsonb
      WHEN 'hinge'        THEN '{"lumbar":3,"hip":2}'::jsonb
      WHEN 'squat'        THEN '{"knee":3,"hip":2,"lumbar":2}'::jsonb
      WHEN 'knee_iso'     THEN '{"knee":3}'::jsonb
      WHEN 'calf'         THEN '{"ankle":2,"achilles":2}'::jsonb
      WHEN 'wrist'        THEN '{"wrist":3}'::jsonb
      WHEN 'plyo'         THEN '{"knee":3,"ankle":3,"achilles":3}'::jsonb
      WHEN 'carry'        THEN '{"lumbar":2,"wrist":1}'::jsonb
      WHEN 'shoulder_iso' THEN '{"shoulder":2}'::jsonb
      WHEN 'core'         THEN '{"lumbar":2}'::jsonb
      WHEN 'mobility'     THEN '{}'::jsonb
      WHEN 'compound'     THEN '{"shoulder":2,"elbow":2,"lumbar":2,"knee":2}'::jsonb
      ELSE '{"elbow":1}'::jsonb
    END
FROM fam f
WHERE e.id = f.id;

-- ============================================
-- 3. High-impact bump (knees/ankles/achilles take more on plyo/jumps/runs)
-- ============================================
UPDATE exercise_library
SET tissue_stress = tissue_stress
      || jsonb_build_object(
           'knee', GREATEST(COALESCE((tissue_stress->>'knee')::int, 0), 3),
           'ankle', GREATEST(COALESCE((tissue_stress->>'ankle')::int, 0), 3),
           'achilles', GREATEST(COALESCE((tissue_stress->>'achilles')::int, 0), 2)
         ),
    systemic_load = GREATEST(COALESCE(systemic_load, 1), 3)
WHERE lower(COALESCE(impact_level, '')) = 'high_impact';

-- ============================================
-- 4. Index for tissue-stress lookups (the fatigue ledger reads these)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_exercise_library_is_prehab
  ON exercise_library (is_prehab);
