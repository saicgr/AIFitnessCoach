-- Migration 236: Backfill ~1500 existing strength exercises with metadata
-- Depends on: Migration 235 (adds the 22 metadata columns)
-- Uses pattern matching to classify exercises by movement pattern, mechanic type, etc.
-- All updates use IS NULL guards to avoid overwriting values set by migration 235.

BEGIN;

-- ============================================================
-- 1. MOVEMENT PATTERN + FORCE TYPE CLASSIFICATION
-- ============================================================

-- Push exercises
UPDATE exercise_library SET movement_pattern = 'push', force_type = 'push'
WHERE lower(exercise_name) SIMILAR TO '%(bench press|push up|push-up|pushup|overhead press|shoulder press|chest press|incline press|decline press|floor press|military press|pike push|dip|arnold press|chest fly|pec fly|tricep extension|tricep pushdown|tricep kickback|skull crusher|close grip bench|diamond push)%'
AND category = 'strength'
AND movement_pattern IS NULL;

-- Pull exercises
UPDATE exercise_library SET movement_pattern = 'pull', force_type = 'pull'
WHERE lower(exercise_name) SIMILAR TO '%(pull up|pull-up|pullup|chin up|chin-up|chinup|row|lat pull|face pull|pulldown|curl|reverse fly|rear delt|upright row|shrug)%'
AND category = 'strength'
AND movement_pattern IS NULL;

-- Hinge exercises
UPDATE exercise_library SET movement_pattern = 'hinge'
WHERE lower(exercise_name) SIMILAR TO '%(deadlift|romanian|rdl|good morning|hip thrust|kettlebell swing|hyperextension|back extension|glute bridge|hip hinge|rack pull|snatch)%'
AND category = 'strength'
AND movement_pattern IS NULL;

-- Squat exercises
UPDATE exercise_library SET movement_pattern = 'squat'
WHERE lower(exercise_name) SIMILAR TO '%(squat|leg press|goblet|hack squat|sissy squat|front squat|wall sit|pistol)%'
AND category = 'strength'
AND movement_pattern IS NULL;

-- Lunge exercises
UPDATE exercise_library SET movement_pattern = 'lunge'
WHERE lower(exercise_name) SIMILAR TO '%(lunge|split squat|step up|step-up|bulgarian)%'
AND category = 'strength'
AND movement_pattern IS NULL;

-- Isolation exercises (single-joint)
UPDATE exercise_library SET movement_pattern = 'isolation'
WHERE lower(exercise_name) SIMILAR TO '%(lateral raise|front raise|leg extension|leg curl|hamstring curl|calf raise|wrist curl|concentration curl|preacher curl|cable fly|pec deck|hip abduction|hip adduction|glute kickback|donkey kick|fire hydrant)%'
AND category = 'strength'
AND movement_pattern IS NULL;

-- Carry exercises
UPDATE exercise_library SET movement_pattern = 'carry'
WHERE lower(exercise_name) SIMILAR TO '%(farmer|carry|walk|suitcase)%'
AND category = 'strength'
AND movement_pattern IS NULL;

-- Rotation exercises
UPDATE exercise_library SET movement_pattern = 'rotation'
WHERE lower(exercise_name) SIMILAR TO '%(russian twist|woodchop|wood chop|pallof|cable rotation|landmine rotation|rotational)%'
AND category = 'strength'
AND movement_pattern IS NULL;

-- ============================================================
-- 2. MECHANIC TYPE (compound vs isolation)
-- ============================================================

-- Compound: barbell exercises and multi-joint movements
UPDATE exercise_library SET mechanic_type = 'compound'
WHERE (lower(equipment) LIKE '%barbell%' OR lower(exercise_name) SIMILAR TO '%(press|squat|deadlift|row|pull up|pull-up|pullup|chin up|chin-up|chinup|dip|lunge|clean|snatch|thruster|push up|push-up|pushup)%')
AND category = 'strength'
AND mechanic_type IS NULL;

-- Isolation: single-joint movements
UPDATE exercise_library SET mechanic_type = 'isolation'
WHERE lower(exercise_name) SIMILAR TO '%(curl|raise|extension|fly|kickback|abduction|adduction|calf raise|shrug|crunch|sit up|sit-up|situp)%'
AND category = 'strength'
AND mechanic_type IS NULL;

-- ============================================================
-- 3. FORCE TYPE (for exercises not yet set by movement pattern)
-- ============================================================

-- Push force for push-pattern exercises not yet set
UPDATE exercise_library SET force_type = 'push'
WHERE movement_pattern IN ('push', 'squat', 'lunge')
AND category = 'strength'
AND force_type IS NULL;

-- Pull force for pull-pattern exercises not yet set
UPDATE exercise_library SET force_type = 'pull'
WHERE movement_pattern IN ('pull', 'hinge')
AND category = 'strength'
AND force_type IS NULL;

-- Dynamic force as default for remaining strength exercises
UPDATE exercise_library SET force_type = 'dynamic'
WHERE category = 'strength'
AND force_type IS NULL;

-- ============================================================
-- 4. PLANE OF MOTION
-- ============================================================

-- Frontal (side-to-side) - check first to avoid sagittal overriding lateral raises
UPDATE exercise_library SET plane_of_motion = 'frontal'
WHERE lower(exercise_name) SIMILAR TO '%(lateral raise|side raise|lateral lunge|side bend|hip abduction|hip adduction|side plank)%'
AND category = 'strength'
AND plane_of_motion IS NULL;

-- Transverse (rotational)
UPDATE exercise_library SET plane_of_motion = 'transverse'
WHERE lower(exercise_name) SIMILAR TO '%(twist|rotation|woodchop|wood chop|pallof|fly|pec deck|reverse fly|face pull|cable crossover)%'
AND category = 'strength'
AND plane_of_motion IS NULL;

-- Sagittal (forward/backward) - most standard lifts
UPDATE exercise_library SET plane_of_motion = 'sagittal'
WHERE lower(exercise_name) SIMILAR TO '%(bench press|squat|deadlift|curl|extension|press|row|lunge|step up|step-up|calf raise|pull up|pull-up|pullup|chin up|chin-up|chinup|leg press|hip thrust|good morning|push up|push-up|pushup|dip|shrug|kickback|glute bridge|back extension|hyperextension|leg curl|leg extension|hamstring curl)%'
AND category = 'strength'
AND plane_of_motion IS NULL;

-- ============================================================
-- 5. IMPACT LEVEL
-- ============================================================

-- Bodyweight exercises: low impact
UPDATE exercise_library SET impact_level = 'low_impact'
WHERE lower(equipment) IN ('bodyweight', 'body weight', 'body_weight')
AND category = 'strength'
AND impact_level IS NULL;

-- Machine and cable exercises: low impact
UPDATE exercise_library SET impact_level = 'low_impact'
WHERE (lower(equipment) LIKE '%machine%' OR lower(equipment) LIKE '%cable%')
AND category = 'strength'
AND impact_level IS NULL;

-- Free weight exercises: low impact (controlled movements)
UPDATE exercise_library SET impact_level = 'low_impact'
WHERE lower(equipment) IN ('barbell', 'dumbbell', 'dumbbells', 'kettlebell', 'ez_barbell', 'ez barbell')
AND category = 'strength'
AND impact_level IS NULL;

-- Remaining strength exercises default to low_impact
UPDATE exercise_library SET impact_level = 'low_impact'
WHERE category = 'strength'
AND impact_level IS NULL;

-- ============================================================
-- 6. FORM COMPLEXITY (1-5 from difficulty_level)
-- ============================================================

UPDATE exercise_library SET form_complexity =
    CASE difficulty_level
        WHEN 'Beginner' THEN 1
        WHEN 'Intermediate' THEN 3
        WHEN 'Advanced' THEN 4
        WHEN 'Expert' THEN 5
        ELSE 2
    END
WHERE category = 'strength'
AND form_complexity IS NULL;

-- ============================================================
-- 7. STABILITY REQUIREMENT
-- ============================================================

-- Stable: machines, cables, bench, seated, lying exercises
UPDATE exercise_library SET stability_requirement = 'stable'
WHERE (lower(equipment) LIKE '%machine%' OR lower(equipment) LIKE '%cable%'
       OR lower(exercise_name) LIKE '%bench%' OR lower(exercise_name) LIKE '%seated%'
       OR lower(exercise_name) LIKE '%lying%')
AND category = 'strength'
AND stability_requirement IS NULL;

-- Semi-stable: free weights (standing by default)
UPDATE exercise_library SET stability_requirement = 'semi_stable'
WHERE lower(equipment) IN ('barbell', 'dumbbell', 'dumbbells', 'kettlebell', 'ez_barbell', 'ez barbell')
AND category = 'strength'
AND stability_requirement IS NULL;

-- ============================================================
-- 8. ENERGY SYSTEM
-- ============================================================

-- All strength exercises are anaerobic alactic
UPDATE exercise_library SET energy_system = 'anaerobic_alactic'
WHERE category = 'strength'
AND energy_system IS NULL;

-- ============================================================
-- 9. DEFAULT TRAINING PARAMETERS
-- ============================================================

-- Default rep ranges for strength exercises
UPDATE exercise_library
SET default_rep_range_min = 8,
    default_rep_range_max = 12,
    default_rest_seconds = 90
WHERE category = 'strength'
AND default_rep_range_min IS NULL;

-- ============================================================
-- 10. CONTRAINDICATED CONDITIONS (pattern-based)
-- ============================================================

-- Exercises with "knee" in name
UPDATE exercise_library SET contraindicated_conditions = ARRAY['knee_injury']
WHERE lower(exercise_name) LIKE '%knee%'
AND category = 'strength'
AND contraindicated_conditions IS NULL;

-- Exercises with "back" or "spinal" in name
UPDATE exercise_library SET contraindicated_conditions = ARRAY['lower_back_pain']
WHERE (lower(exercise_name) LIKE '%back%' OR lower(exercise_name) LIKE '%spinal%')
AND category = 'strength'
AND contraindicated_conditions IS NULL;

-- Overhead exercises
UPDATE exercise_library SET contraindicated_conditions = ARRAY['shoulder_injury']
WHERE lower(exercise_name) SIMILAR TO '%(overhead|shoulder press|military press|arnold press|pike push|behind the neck)%'
AND category = 'strength'
AND contraindicated_conditions IS NULL;

COMMIT;
