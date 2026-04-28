-- Migration: 2037 — Convert exercise_library_cleaned VIEW to MATERIALIZED VIEW
-- Why:
--   The plain view UNIONs exercise_library (2440) + exercise_library_manual (786),
--   runs INITCAP + double REGEXP_REPLACE + 23-branch CASE for display_body_part +
--   ROW_NUMBER() over the full 3226 rows on EVERY query. EXPLAIN ANALYZE shows
--   ~167 ms per `SELECT … ORDER BY name LIMIT 100` with an external-merge sort
--   spilling to disk. Library tab calls this view 3+ times per cold open.
--
-- What:
--   Materialize the view, add covering indexes, recreate the two dependent
--   safety views (regular + materialized) plus their indexes (CASCADE drop).
--
-- Refresh strategy:
--   - REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_library_cleaned;
--   - Triggered manually from import scripts and from a backend startup probe.
--   - A pg_notify-based hook is added in migration 2038.
--
-- Note on view body:
--   The MV body below is captured verbatim from `pg_get_viewdef` against the
--   current production view, so it includes the `display_body_part` CASE and
--   the UNION with `exercise_library_manual` that aren't in migration 103.
--
-- Atomicity: apply_migration runs DDL in its own transaction; do not add a
-- nested BEGIN/COMMIT here.

-- 1. Drop old view (CASCADE removes exercise_safety_index + exercise_safety_index_mat)
DROP VIEW IF EXISTS public.exercise_library_cleaned CASCADE;

-- 2. Re-create as a materialized view
CREATE MATERIALIZED VIEW public.exercise_library_cleaned AS
WITH combined AS (
    SELECT exercise_library.id, exercise_library.exercise_name, exercise_library.body_part,
           exercise_library.equipment, exercise_library.target_muscle, exercise_library.secondary_muscles,
           exercise_library.instructions, exercise_library.difficulty_level, exercise_library.category,
           exercise_library.gif_url, exercise_library.video_s3_path, exercise_library.raw_data,
           exercise_library.created_at, exercise_library.image_s3_path, exercise_library.goals,
           exercise_library.suitable_for, exercise_library.avoid_if, exercise_library.single_dumbbell_friendly,
           exercise_library.single_kettlebell_friendly, exercise_library.is_unilateral,
           exercise_library.default_hold_seconds, exercise_library.is_timed, exercise_library.movement_pattern,
           exercise_library.mechanic_type, exercise_library.force_type, exercise_library.plane_of_motion,
           exercise_library.energy_system, exercise_library.default_duration_seconds,
           exercise_library.default_rep_range_min, exercise_library.default_rep_range_max,
           exercise_library.default_rest_seconds, exercise_library.default_tempo,
           exercise_library.default_incline_percent, exercise_library.default_speed_mph,
           exercise_library.default_resistance_level, exercise_library.default_rpm,
           exercise_library.stroke_rate_spm, exercise_library.contraindicated_conditions,
           exercise_library.impact_level, exercise_library.form_complexity, exercise_library.stability_requirement,
           exercise_library.is_dynamic_stretch, exercise_library.hold_seconds_min, exercise_library.hold_seconds_max
    FROM exercise_library
    UNION ALL
    SELECT exercise_library_manual.id, exercise_library_manual.exercise_name, exercise_library_manual.body_part,
           exercise_library_manual.equipment, exercise_library_manual.target_muscle, exercise_library_manual.secondary_muscles,
           exercise_library_manual.instructions, exercise_library_manual.difficulty_level, exercise_library_manual.category,
           exercise_library_manual.gif_url, exercise_library_manual.video_s3_path, exercise_library_manual.raw_data,
           exercise_library_manual.created_at, exercise_library_manual.image_s3_path, exercise_library_manual.goals,
           exercise_library_manual.suitable_for, exercise_library_manual.avoid_if, exercise_library_manual.single_dumbbell_friendly,
           exercise_library_manual.single_kettlebell_friendly, exercise_library_manual.is_unilateral,
           exercise_library_manual.default_hold_seconds, exercise_library_manual.is_timed, exercise_library_manual.movement_pattern,
           exercise_library_manual.mechanic_type, exercise_library_manual.force_type, exercise_library_manual.plane_of_motion,
           exercise_library_manual.energy_system, exercise_library_manual.default_duration_seconds,
           exercise_library_manual.default_rep_range_min, exercise_library_manual.default_rep_range_max,
           exercise_library_manual.default_rest_seconds, exercise_library_manual.default_tempo,
           exercise_library_manual.default_incline_percent, exercise_library_manual.default_speed_mph,
           exercise_library_manual.default_resistance_level, exercise_library_manual.default_rpm,
           exercise_library_manual.stroke_rate_spm, exercise_library_manual.contraindicated_conditions,
           exercise_library_manual.impact_level, exercise_library_manual.form_complexity, exercise_library_manual.stability_requirement,
           exercise_library_manual.is_dynamic_stretch, exercise_library_manual.hold_seconds_min, exercise_library_manual.hold_seconds_max
    FROM exercise_library_manual
), cleaned_exercises AS (
    SELECT combined.id,
           initcap(TRIM(BOTH FROM regexp_replace(regexp_replace(combined.exercise_name, '[_\s]*(Female|Male|female|male)$', '', 'i'), '_', ' ', 'g'))) AS name,
           combined.exercise_name AS original_name,
           combined.body_part,
           CASE
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'hamstring|biceps femoris|semitendinosus|semimembranosus') THEN 'Hamstrings'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'tricep') THEN 'Triceps'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'bicep|biceps brachii') THEN 'Biceps'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'chest|pectoralis|pec |serratus') THEN 'Chest'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'rear_delts|rear delts|posterior delt') THEN 'Shoulders'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'lower back|erector spinae') THEN 'Lower Back'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'thoracic|spine') THEN 'Back'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'lats|back|latissimus|rhomboid|trapezius|teres') THEN 'Back'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'rotator cuff|infraspinatus|supraspinatus|subscapularis') THEN 'Rotator Cuff'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'shoulder|deltoid') THEN 'Shoulders'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'forearm|wrist|brachioradialis|flexor carpi|extensor carpi') THEN 'Forearms'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'quadriceps|quad|rectus femoris|vastus') THEN 'Quadriceps'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'glute|gluteus') THEN 'Glutes'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'calf|calves|gastrocnemius|soleus') THEN 'Calves'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'tibialis|shin') THEN 'Calves'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'abdomin|rectus abdominis|oblique|core|abs|diaphragm') THEN 'Core'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'hip_flexors|hip flexor|iliopsoas|adductor|abductor|tensor fasciae') THEN 'Hips'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'it band|iliotibial') THEN 'Hips'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'neck|sternocleidomastoid|cervical|levator scapulae') THEN 'Neck'
               WHEN (lower(COALESCE(combined.target_muscle, '')) ~ 'full body|multiple muscle') THEN 'Full Body'
               WHEN (lower(COALESCE(combined.body_part, '')) = 'full body') THEN 'Full Body'
               WHEN (lower(COALESCE(combined.body_part, '')) = 'cardio') THEN 'Cardio'
               ELSE 'Other'
           END AS display_body_part,
           combined.equipment, combined.target_muscle, combined.secondary_muscles,
           combined.instructions, combined.difficulty_level, combined.category,
           combined.gif_url,
           combined.video_s3_path AS video_url,
           combined.image_s3_path AS image_url,
           combined.goals, combined.suitable_for, combined.avoid_if,
           CASE
               WHEN ((combined.equipment ILIKE '%dumbbell%') OR (combined.exercise_name ILIKE '%dumbbell%') OR (combined.exercise_name ILIKE '%db %')) THEN true
               ELSE false
           END AS single_dumbbell_friendly,
           CASE
               WHEN ((combined.equipment ILIKE '%kettlebell%') OR (combined.exercise_name ILIKE '%kettlebell%') OR (combined.exercise_name ILIKE '%kb %')) THEN true
               ELSE false
           END AS single_kettlebell_friendly,
           row_number() OVER (
               PARTITION BY (lower(TRIM(BOTH FROM regexp_replace(regexp_replace(combined.exercise_name, '[_\s]*(Female|Male|female|male)$', '', 'i'), '_', ' ', 'g'))))
               ORDER BY
                   CASE
                       WHEN ((combined.video_s3_path IS NOT NULL) AND (combined.image_s3_path IS NOT NULL)) THEN 0
                       WHEN (combined.video_s3_path IS NOT NULL) THEN 1
                       WHEN (combined.image_s3_path IS NOT NULL) THEN 2
                       ELSE 3
                   END,
                   CASE
                       WHEN (combined.exercise_name !~* '(female|male)$') THEN 0
                       WHEN ((combined.exercise_name ~* 'male$') AND (combined.exercise_name !~* 'female$')) THEN 1
                       ELSE 2
                   END,
                   combined.exercise_name,
                   combined.id
           ) AS rn
    FROM combined
)
SELECT id, name, original_name, body_part, display_body_part, equipment, target_muscle,
       secondary_muscles, instructions, difficulty_level, category, gif_url, video_url,
       image_url, goals, suitable_for, avoid_if, single_dumbbell_friendly, single_kettlebell_friendly
FROM cleaned_exercises
WHERE rn = 1 AND body_part IS NOT NULL AND target_muscle IS NOT NULL;

-- 3. Indexes on the new MV
-- UNIQUE on id is required for REFRESH MATERIALIZED VIEW CONCURRENTLY.
CREATE UNIQUE INDEX exercise_library_cleaned_id_uidx
    ON public.exercise_library_cleaned (id);

-- Eliminates the disk-spilling Sort for `ORDER BY name LIMIT n` queries.
CREATE INDEX exercise_library_cleaned_name_idx
    ON public.exercise_library_cleaned (name);

-- Filter equality on display_body_part (used by /grouped + body-part filters).
CREATE INDEX exercise_library_cleaned_display_body_part_idx
    ON public.exercise_library_cleaned (display_body_part);

-- Equipment ILIKE filter — backed by lower() expression index.
CREATE INDEX exercise_library_cleaned_equipment_lower_idx
    ON public.exercise_library_cleaned (lower(equipment));

-- GIN indexes for array containment filters (goals, suitable_for, avoid_if).
CREATE INDEX exercise_library_cleaned_goals_gin_idx
    ON public.exercise_library_cleaned USING GIN (goals);
CREATE INDEX exercise_library_cleaned_suitable_for_gin_idx
    ON public.exercise_library_cleaned USING GIN (suitable_for);
CREATE INDEX exercise_library_cleaned_avoid_if_gin_idx
    ON public.exercise_library_cleaned USING GIN (avoid_if);

-- Trigram index for fuzzy_search_exercises_api (replaces the trigram index that
-- migration 159 attached to the underlying exercise_library table).
CREATE INDEX exercise_library_cleaned_name_trgm_idx
    ON public.exercise_library_cleaned USING GIN (name gin_trgm_ops);

-- 4. Grants — preserve original Supabase role access.
GRANT SELECT ON public.exercise_library_cleaned TO anon, authenticated, service_role;

COMMENT ON MATERIALIZED VIEW public.exercise_library_cleaned IS
    'Deduplicated exercise library (UNION of exercise_library + exercise_library_manual). Materialized for performance — refresh via 2038 hooks.';

-- 5. Re-create dependent objects dropped by CASCADE.

-- 5a. exercise_safety_index (regular view — joins MV with exercise_safety_tags)
CREATE VIEW public.exercise_safety_index AS
SELECT e.id AS exercise_id,
       e.name,
       e.original_name,
       lower(regexp_replace(e.name, '[^a-zA-Z0-9]+', '', 'g')) AS name_normalized,
       e.body_part,
       e.display_body_part,
       e.equipment,
       e.target_muscle,
       e.secondary_muscles,
       e.instructions,
       e.difficulty_level,
       e.category,
       e.gif_url,
       e.video_url,
       e.image_url,
       e.goals,
       e.suitable_for,
       e.avoid_if,
       e.single_dumbbell_friendly,
       e.single_kettlebell_friendly,
       t.shoulder_safe,
       t.lower_back_safe,
       t.knee_safe,
       t.elbow_safe,
       t.wrist_safe,
       t.ankle_safe,
       t.hip_safe,
       t.neck_safe,
       t.movement_pattern,
       t.plane_of_motion,
       t.load_axis,
       t.is_overhead,
       t.is_loaded_rotation,
       t.is_high_impact,
       t.is_inversion,
       t.is_hanging,
       t.grip_intensity,
       t.safety_difficulty,
       t.is_beginner_safe,
       t.embedding,
       t.source_citation,
       t.tagged_by,
       t.tagged_at,
       t.notes,
       (t.source_citation IS NOT NULL) AS is_tagged
FROM public.exercise_library_cleaned e
LEFT JOIN public.exercise_safety_tags t ON t.exercise_id = e.id;

GRANT SELECT ON public.exercise_safety_index TO anon, authenticated, service_role;

-- 5b. exercise_safety_index_mat (materialized — same body, indexed)
CREATE MATERIALIZED VIEW public.exercise_safety_index_mat AS
SELECT e.id AS exercise_id,
       e.name,
       e.original_name,
       lower(regexp_replace(e.name, '[^a-zA-Z0-9]+', '', 'g')) AS name_normalized,
       e.body_part,
       e.display_body_part,
       e.equipment,
       e.target_muscle,
       e.secondary_muscles,
       e.instructions,
       e.difficulty_level,
       e.category,
       e.gif_url,
       e.video_url,
       e.image_url,
       e.goals,
       e.suitable_for,
       e.avoid_if,
       e.single_dumbbell_friendly,
       e.single_kettlebell_friendly,
       t.shoulder_safe,
       t.lower_back_safe,
       t.knee_safe,
       t.elbow_safe,
       t.wrist_safe,
       t.ankle_safe,
       t.hip_safe,
       t.neck_safe,
       t.movement_pattern,
       t.plane_of_motion,
       t.load_axis,
       t.is_overhead,
       t.is_loaded_rotation,
       t.is_high_impact,
       t.is_inversion,
       t.is_hanging,
       t.grip_intensity,
       t.safety_difficulty,
       t.is_beginner_safe,
       t.embedding,
       t.source_citation,
       t.tagged_by,
       t.tagged_at,
       t.notes,
       (t.source_citation IS NOT NULL) AS is_tagged
FROM public.exercise_library_cleaned e
LEFT JOIN public.exercise_safety_tags t ON t.exercise_id = e.id;

-- 5c. Re-create the 13 indexes on exercise_safety_index_mat
CREATE UNIQUE INDEX idx_esim_exercise_id ON public.exercise_safety_index_mat (exercise_id);
CREATE INDEX idx_esim_pattern_diff ON public.exercise_safety_index_mat (movement_pattern, safety_difficulty);
CREATE INDEX idx_esim_shoulder_safe ON public.exercise_safety_index_mat (shoulder_safe) WHERE shoulder_safe = true;
CREATE INDEX idx_esim_lower_back_safe ON public.exercise_safety_index_mat (lower_back_safe) WHERE lower_back_safe = true;
CREATE INDEX idx_esim_knee_safe ON public.exercise_safety_index_mat (knee_safe) WHERE knee_safe = true;
CREATE INDEX idx_esim_elbow_safe ON public.exercise_safety_index_mat (elbow_safe) WHERE elbow_safe = true;
CREATE INDEX idx_esim_wrist_safe ON public.exercise_safety_index_mat (wrist_safe) WHERE wrist_safe = true;
CREATE INDEX idx_esim_ankle_safe ON public.exercise_safety_index_mat (ankle_safe) WHERE ankle_safe = true;
CREATE INDEX idx_esim_hip_safe ON public.exercise_safety_index_mat (hip_safe) WHERE hip_safe = true;
CREATE INDEX idx_esim_neck_safe ON public.exercise_safety_index_mat (neck_safe) WHERE neck_safe = true;
CREATE INDEX idx_esim_swap_pattern_shoulder_lb ON public.exercise_safety_index_mat (movement_pattern, shoulder_safe, lower_back_safe);
CREATE INDEX idx_esim_name_normalized ON public.exercise_safety_index_mat (name_normalized);
CREATE INDEX idx_esim_name_trgm ON public.exercise_safety_index_mat USING GIN (name gin_trgm_ops);

GRANT SELECT ON public.exercise_safety_index_mat TO anon, authenticated, service_role;
