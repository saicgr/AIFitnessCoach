-- Migration: 235_exercise_metadata_columns.sql
-- Created: 2025-02-09
-- Purpose: Add 22 metadata columns to exercise_library and backfill
--          all warmup/stretch/cardio exercises from migrations 203 and 234.

-- ============================================
-- 1. ALTER TABLE: Add 22 new columns
-- ============================================

ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS movement_pattern VARCHAR(50);
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS mechanic_type VARCHAR(20);
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS force_type VARCHAR(20);
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS plane_of_motion VARCHAR(20);
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS energy_system VARCHAR(30);

ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS default_duration_seconds INTEGER;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS default_rep_range_min SMALLINT;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS default_rep_range_max SMALLINT;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS default_rest_seconds SMALLINT;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS default_tempo VARCHAR(20);

ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS default_incline_percent DECIMAL(4,1);
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS default_speed_mph DECIMAL(4,1);
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS default_resistance_level SMALLINT;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS default_rpm SMALLINT;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS stroke_rate_spm SMALLINT;

ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS contraindicated_conditions TEXT[];
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS impact_level VARCHAR(20);
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS form_complexity SMALLINT;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS stability_requirement VARCHAR(20);

ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS is_dynamic_stretch BOOLEAN;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS hold_seconds_min SMALLINT;
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS hold_seconds_max SMALLINT;


-- ============================================
-- 2. BACKFILL: Migration 234 exercises
-- ============================================

-- ============================================
-- 2a. TREADMILL VARIATIONS (10 exercises from 234)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 300,
    default_rest_seconds = 0,
    default_incline_percent = 12.5,
    default_speed_mph = 2.75,
    contraindicated_conditions = ARRAY['achilles_tendon'],
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Steep Incline Walk');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 120,
    default_rest_seconds = 0,
    default_incline_percent = 0.0,
    default_speed_mph = 1.25,
    impact_level = 'low_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Backward Walk');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 120,
    default_rest_seconds = 0,
    default_incline_percent = 0.0,
    default_speed_mph = 2.5,
    impact_level = 'low_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Side Shuffle Left');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 120,
    default_rest_seconds = 0,
    default_incline_percent = 0.0,
    default_speed_mph = 2.5,
    impact_level = 'low_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Side Shuffle Right');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 420,
    default_rest_seconds = 0,
    default_incline_percent = 2.0,
    default_speed_mph = 4.0,
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Power Walk');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 150,
    default_rest_seconds = 0,
    default_incline_percent = 0.0,
    default_speed_mph = 2.25,
    impact_level = 'low_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Treadmill High Knee Walk');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 300,
    default_rest_seconds = 0,
    default_incline_percent = 6.0,
    default_speed_mph = 5.0,
    impact_level = 'high_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Incline Jog');

UPDATE exercise_library SET
    movement_pattern = 'lunge',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 120,
    default_rest_seconds = 0,
    default_incline_percent = 0.0,
    default_speed_mph = 1.25,
    default_rep_range_min = 10,
    default_rep_range_max = 12,
    impact_level = 'low_impact',
    form_complexity = 3,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Treadmill Walking Lunge');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'mixed',
    default_duration_seconds = 900,
    default_rest_seconds = 0,
    default_incline_percent = 1.0,
    default_speed_mph = 7.75,
    impact_level = 'high_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Tempo Run');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 720,
    default_rest_seconds = 0,
    default_incline_percent = 6.0,
    default_speed_mph = 3.25,
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Gradient Pyramid');

-- ============================================
-- 2b. STEPPER / STAIRMASTER VARIATIONS (7 exercises from 234)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 240,
    default_rest_seconds = 0,
    default_resistance_level = 7,
    impact_level = 'low_impact',
    form_complexity = 3,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('StairMaster Skip Step');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 300,
    default_rest_seconds = 0,
    default_resistance_level = 6,
    impact_level = 'low_impact',
    form_complexity = 3,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('StairMaster Crossover Step');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 120,
    default_rest_seconds = 0,
    default_resistance_level = 6,
    impact_level = 'low_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('StairMaster Lateral Step Left');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 120,
    default_rest_seconds = 0,
    default_resistance_level = 6,
    impact_level = 'low_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('StairMaster Lateral Step Right');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 240,
    default_rest_seconds = 0,
    default_resistance_level = 5,
    impact_level = 'low_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('StairMaster Calf Raise Step');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'anaerobic_lactic',
    default_duration_seconds = 300,
    default_rest_seconds = 30,
    default_resistance_level = 12,
    impact_level = 'low_impact',
    form_complexity = 3,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('StairMaster Double Step Sprint');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 450,
    default_rest_seconds = 0,
    default_resistance_level = 4,
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('StairMaster Slow Deep Step');

-- ============================================
-- 2c. STATIONARY BIKE / CYCLING VARIATIONS (6 exercises from 234)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 300,
    default_rest_seconds = 0,
    default_resistance_level = 2,
    default_rpm = 65,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Stationary Bike Light Spin');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 300,
    default_rest_seconds = 30,
    default_resistance_level = 8,
    default_rpm = 65,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Stationary Bike Standing Climb');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 300,
    default_rest_seconds = 0,
    default_resistance_level = 4,
    default_rpm = 55,
    impact_level = 'zero_impact',
    form_complexity = 3,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Stationary Bike Single Leg Drill');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'mixed',
    default_duration_seconds = 300,
    default_rest_seconds = 60,
    default_resistance_level = 4,
    default_rpm = 110,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Stationary Bike High Cadence Spin');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    default_resistance_level = 3,
    default_rpm = 70,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    contraindicated_conditions = ARRAY['lower_back_pain'],
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Recumbent Bike Easy');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'anaerobic_lactic',
    default_duration_seconds = 240,
    default_rest_seconds = 10,
    default_resistance_level = 10,
    default_rpm = 110,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Stationary Bike Tabata Sprint');

-- ============================================
-- 2d. ELLIPTICAL VARIATIONS (4 exercises from 234)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 240,
    default_rest_seconds = 0,
    default_resistance_level = 5,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Elliptical Reverse Stride');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 450,
    default_rest_seconds = 0,
    default_resistance_level = 6,
    default_incline_percent = 17.5,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Elliptical High Incline Forward');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 120,
    default_rest_seconds = 0,
    default_resistance_level = 5,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Elliptical No Hands');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'mixed',
    default_duration_seconds = 630,
    default_rest_seconds = 60,
    default_resistance_level = 9,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Elliptical Interval Bursts');

-- ============================================
-- 2e. ROWING WARMUP VARIATIONS (3 exercises from 234)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 120,
    default_rest_seconds = 0,
    stroke_rate_spm = 19,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Rowing Machine Legs Only');

UPDATE exercise_library SET
    movement_pattern = 'pull',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 120,
    default_rest_seconds = 0,
    stroke_rate_spm = 21,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Rowing Machine Arms Only');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 300,
    default_rest_seconds = 0,
    stroke_rate_spm = 19,
    impact_level = 'zero_impact',
    form_complexity = 3,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Rowing Machine Pick Drill');

-- ============================================
-- 2f. BAR HANGS (7 exercises from 234)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 30,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'unstable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Dead Hang');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 30,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'unstable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 45
WHERE lower(exercise_name) = lower('Active Hang');

UPDATE exercise_library SET
    movement_pattern = 'pull',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 30,
    default_rep_range_min = 8,
    default_rep_range_max = 12,
    impact_level = 'zero_impact',
    form_complexity = 3,
    stability_requirement = 'unstable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 2,
    hold_seconds_max = 3
WHERE lower(exercise_name) = lower('Scapular Pull-Up');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 30,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'unstable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 45
WHERE lower(exercise_name) = lower('Mixed Grip Hang');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 30,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'unstable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 45
WHERE lower(exercise_name) = lower('Wide Grip Hang');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 30,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'unstable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 45
WHERE lower(exercise_name) = lower('Chin-Up Grip Hang');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 20,
    default_rest_seconds = 30,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'unstable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 10,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Towel Hang');

-- ============================================
-- 2g. JUMP ROPE VARIATIONS (6 exercises from 234)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 60,
    default_rest_seconds = 30,
    impact_level = 'low_impact',
    form_complexity = 2,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Jump Rope Basic Bounce');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 60,
    default_rest_seconds = 30,
    impact_level = 'low_impact',
    form_complexity = 2,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Jump Rope Alternate Foot Step');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 150,
    default_rest_seconds = 30,
    impact_level = 'low_impact',
    form_complexity = 3,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Jump Rope Boxer Step');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'mixed',
    default_duration_seconds = 30,
    default_rest_seconds = 30,
    impact_level = 'high_impact',
    form_complexity = 3,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Jump Rope High Knees');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 60,
    default_rest_seconds = 30,
    impact_level = 'low_impact',
    form_complexity = 4,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Jump Rope Criss-Cross');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'anaerobic_alactic',
    default_duration_seconds = 60,
    default_rest_seconds = 30,
    impact_level = 'high_impact',
    form_complexity = 5,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Jump Rope Double Under');

-- ============================================
-- 2h. DYNAMIC WARMUPS (28 exercises from 234)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 15,
    impact_level = 'low_impact',
    form_complexity = 2,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('A-Skip');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 15,
    impact_level = 'low_impact',
    form_complexity = 3,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('B-Skip');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 15,
    impact_level = 'low_impact',
    form_complexity = 2,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Carioca Drill');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 15,
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Lateral Shuffle');

UPDATE exercise_library SET
    movement_pattern = 'carry',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 30,
    impact_level = 'zero_impact',
    form_complexity = 3,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Bear Crawl');

UPDATE exercise_library SET
    movement_pattern = 'lunge',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 60,
    default_rest_seconds = 15,
    default_rep_range_min = 5,
    default_rep_range_max = 5,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('World''s Greatest Stretch');

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'transverse',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 15,
    default_rep_range_min = 10,
    default_rep_range_max = 12,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Hip 90/90 Switch');

UPDATE exercise_library SET
    movement_pattern = 'hinge',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 60,
    default_rest_seconds = 15,
    default_rep_range_min = 6,
    default_rep_range_max = 8,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Inchworm');

UPDATE exercise_library SET
    movement_pattern = 'isolation',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 15,
    default_rep_range_max = 20,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Leg Swing Forward-Backward');

UPDATE exercise_library SET
    movement_pattern = 'isolation',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 15,
    default_rep_range_max = 20,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Leg Swing Lateral');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 0,
    default_rep_range_min = 10,
    default_rep_range_max = 12,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Walking Knee Hug');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 0,
    default_rep_range_min = 10,
    default_rep_range_max = 12,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Walking Quad Pull');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 15,
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Butt Kick Run');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 15,
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('High Knee Run');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 10,
    default_rep_range_max = 10,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Frankenstein Walk');

UPDATE exercise_library SET
    movement_pattern = 'lunge',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 60,
    default_rest_seconds = 15,
    default_rep_range_min = 8,
    default_rep_range_max = 10,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Walking Lunge with Rotation');

UPDATE exercise_library SET
    movement_pattern = 'lunge',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 15,
    default_rep_range_min = 8,
    default_rep_range_max = 10,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Lateral Lunge');

UPDATE exercise_library SET
    movement_pattern = 'lunge',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 15,
    default_rep_range_min = 8,
    default_rep_range_max = 10,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Reverse Lunge with Overhead Reach');

UPDATE exercise_library SET
    movement_pattern = 'lunge',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 15,
    default_rep_range_min = 6,
    default_rep_range_max = 8,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Spiderman Lunge');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 15,
    default_rep_range_min = 20,
    default_rep_range_max = 30,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Mountain Climber');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 15,
    default_rep_range_min = 20,
    default_rep_range_max = 30,
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Jumping Jack');

UPDATE exercise_library SET
    movement_pattern = 'squat',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 15,
    default_rep_range_min = 8,
    default_rep_range_max = 10,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Squat to Stand');

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 15,
    default_rep_range_max = 20,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Arm Circle Forward');

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 15,
    default_rep_range_max = 20,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Arm Circle Backward');

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'transverse',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 15,
    default_rep_range_max = 20,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Torso Twist');

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 10,
    default_rep_range_max = 10,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Hip Circle');

UPDATE exercise_library SET
    movement_pattern = 'hinge',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 15,
    default_rep_range_min = 10,
    default_rep_range_max = 12,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Bodyweight Good Morning');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 15,
    default_rep_range_min = 15,
    default_rep_range_max = 20,
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Seal Jack');

-- ============================================
-- 2i. STATIC STRETCHES (35 exercises from 234)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Standing Hamstring Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Seated Hamstring Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Single Leg Hamstring Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Standing Quad Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Prone Quad Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Kneeling Hip Flexor Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 45
WHERE lower(exercise_name) = lower('Pigeon Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Figure Four Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Standing Calf Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Soleus Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Chest Doorway Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'transverse',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Cross-Body Shoulder Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Overhead Triceps Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 20,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 15,
    hold_seconds_max = 20
WHERE lower(exercise_name) = lower('Neck Side Bend Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 45
WHERE lower(exercise_name) = lower('Butterfly Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Seated Straddle Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Child''s Pose');

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 10,
    default_rep_range_max = 15,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Cat-Cow Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'transverse',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Supine Spinal Twist');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 15,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Cobra Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Lying Glute Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Seated Forward Fold');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Standing Side Bend');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Lat Stretch Wall');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 20,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 15,
    hold_seconds_max = 20
WHERE lower(exercise_name) = lower('Wrist Flexor Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 20,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 15,
    hold_seconds_max = 20
WHERE lower(exercise_name) = lower('Wrist Extensor Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 20,
    default_rest_seconds = 0,
    default_rep_range_min = 10,
    default_rep_range_max = 15,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 15,
    hold_seconds_max = 20
WHERE lower(exercise_name) = lower('Ankle Dorsiflexion Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('IT Band Stretch Standing');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Doorway Pec Stretch High');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Supine Hamstring Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'transverse',
    energy_system = 'aerobic',
    default_duration_seconds = 20,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 15,
    hold_seconds_max = 20
WHERE lower(exercise_name) = lower('Seated Neck Rotation Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'transverse',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Shoulder Sleeper Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 45,
    contraindicated_conditions = ARRAY['knee_pain']
WHERE lower(exercise_name) = lower('Hip Flexor Couch Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 45
WHERE lower(exercise_name) = lower('Frog Stretch');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 20,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 15,
    hold_seconds_max = 20
WHERE lower(exercise_name) = lower('Scorpion Stretch');

-- ============================================
-- 2j. FOAM ROLLER EXERCISES (12 exercises from 234)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Foam Roll IT Band');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Foam Roll Quadriceps');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Foam Roll Hamstrings');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Foam Roll Calves');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Foam Roll Glutes');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Foam Roll Thoracic Spine');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Foam Roll Lats');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Foam Roll Adductors');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Foam Roll Hip Flexors');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Foam Roll Upper Back');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Foam Roll Peroneals');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 20,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Foam Roll Pecs');

-- ============================================
-- 2k. MOBILITY DRILLS (12 exercises from 234)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'transverse',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 5,
    default_rep_range_max = 6,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE,
    hold_seconds_min = 15,
    hold_seconds_max = 20
WHERE lower(exercise_name) = lower('Thread the Needle');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 45
WHERE lower(exercise_name) = lower('90/90 Hip Stretch');

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'transverse',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 8,
    default_rep_range_max = 10,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Thoracic Rotation Quadruped');

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'transverse',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 8,
    default_rep_range_max = 10,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Open Book Stretch');

UPDATE exercise_library SET
    movement_pattern = 'push',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 10,
    default_rep_range_max = 12,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Wall Slide');

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'isolation',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 10,
    default_rep_range_max = 10,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Ankle CARs');

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 5,
    default_rep_range_max = 5,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Hip CARs');

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 5,
    default_rep_range_max = 5,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Shoulder CARs');

UPDATE exercise_library SET
    movement_pattern = 'rotation',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    default_rep_range_min = 6,
    default_rep_range_max = 8,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Prone Scorpion');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 3,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 45
WHERE lower(exercise_name) = lower('Bretzel Stretch');

UPDATE exercise_library SET
    movement_pattern = 'squat',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 15,
    default_rep_range_min = 5,
    default_rep_range_max = 6,
    impact_level = 'zero_impact',
    form_complexity = 3,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE
WHERE lower(exercise_name) = lower('Shinbox Get-Up');

UPDATE exercise_library SET
    movement_pattern = 'squat',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Deep Squat Hold');

-- ============================================
-- 2l. YOGA-BASED WARMUPS (10 exercises from 234)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 90,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 3,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = TRUE,
    hold_seconds_min = 60,
    hold_seconds_max = 90
WHERE lower(exercise_name) = lower('Sun Salutation A');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Downward Facing Dog');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 45
WHERE lower(exercise_name) = lower('Warrior I');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 45
WHERE lower(exercise_name) = lower('Warrior II');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 60,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 45,
    hold_seconds_max = 90
WHERE lower(exercise_name) = lower('Pigeon Pose');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'isolation',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 15,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Cobra Pose');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 15,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Upward Facing Dog');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 45
WHERE lower(exercise_name) = lower('Low Lunge (Anjaneyasana)');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'frontal',
    energy_system = 'aerobic',
    default_duration_seconds = 30,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 30
WHERE lower(exercise_name) = lower('Triangle Pose (Trikonasana)');

UPDATE exercise_library SET
    movement_pattern = 'static_hold',
    mechanic_type = 'compound',
    force_type = 'static',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 45,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE,
    hold_seconds_min = 30,
    hold_seconds_max = 60
WHERE lower(exercise_name) = lower('Standing Forward Fold (Uttanasana)');


-- ============================================
-- 3. BACKFILL: Migration 203 exercises
-- ============================================

-- ============================================
-- 3a. TREADMILL EXERCISES (5 exercises from 203)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    default_incline_percent = 0.0,
    default_speed_mph = 3.0,
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Walk');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    default_incline_percent = 4.5,
    default_speed_mph = 3.0,
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Incline Walk');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    default_incline_percent = 0.0,
    default_speed_mph = 5.5,
    impact_level = 'high_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Jog');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'mixed',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    default_incline_percent = 0.0,
    default_speed_mph = 7.0,
    impact_level = 'high_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Run');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'anaerobic_lactic',
    default_duration_seconds = 600,
    default_rest_seconds = 60,
    default_incline_percent = 0.0,
    default_speed_mph = 10.0,
    impact_level = 'high_impact',
    form_complexity = 2,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Treadmill Sprint Intervals');

-- ============================================
-- 3b. STATIONARY BIKE EXERCISES (3 exercises from 203)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    default_resistance_level = 3,
    default_rpm = 75,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Stationary Bike Easy');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    default_resistance_level = 6,
    default_rpm = 85,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Stationary Bike Moderate');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'anaerobic_lactic',
    default_duration_seconds = 480,
    default_rest_seconds = 30,
    default_resistance_level = 8,
    default_rpm = 100,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'semi_stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Spin Bike HIIT');

-- ============================================
-- 3c. ROWING MACHINE EXERCISES (3 exercises from 203)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    stroke_rate_spm = 20,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Rowing Machine Easy');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    stroke_rate_spm = 26,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Rowing Machine Moderate');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'mixed',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    stroke_rate_spm = 30,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Rowing Machine Intervals');

-- ============================================
-- 3d. ELLIPTICAL EXERCISES (2 exercises from 203)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    default_resistance_level = 3,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Elliptical Easy');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'multi_plane',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    default_resistance_level = 5,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Elliptical Moderate');

-- ============================================
-- 3e. STAIR CLIMBER EXERCISES (3 exercises from 203)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    default_resistance_level = 5,
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Stair Climber Easy');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    default_resistance_level = 8,
    impact_level = 'low_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Stair Climber Moderate');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'anaerobic_lactic',
    default_duration_seconds = 600,
    default_rest_seconds = 60,
    default_resistance_level = 11,
    impact_level = 'low_impact',
    form_complexity = 2,
    stability_requirement = 'dynamic',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('StairMaster Intervals');

-- ============================================
-- 3f. ASSAULT BIKE EXERCISES (3 exercises from 203)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Assault Bike Easy');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'anaerobic_lactic',
    default_duration_seconds = 480,
    default_rest_seconds = 40,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Assault Bike HIIT');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'anaerobic_lactic',
    default_duration_seconds = 120,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Assault Bike Calories');

-- ============================================
-- 3g. SKI ERG EXERCISES (2 exercises from 203)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'pull',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'aerobic',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Ski Erg Easy');

UPDATE exercise_library SET
    movement_pattern = 'pull',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'mixed',
    default_duration_seconds = 600,
    default_rest_seconds = 0,
    impact_level = 'zero_impact',
    form_complexity = 2,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Ski Erg Intervals');

-- ============================================
-- 3h. SLED EXERCISES (3 exercises from 203)
-- ============================================

UPDATE exercise_library SET
    movement_pattern = 'push',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'mixed',
    default_duration_seconds = 30,
    default_rest_seconds = 60,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Sled Push');

UPDATE exercise_library SET
    movement_pattern = 'pull',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'mixed',
    default_duration_seconds = 30,
    default_rest_seconds = 60,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Sled Pull');

UPDATE exercise_library SET
    movement_pattern = 'locomotion',
    mechanic_type = 'compound',
    force_type = 'dynamic',
    plane_of_motion = 'sagittal',
    energy_system = 'mixed',
    default_duration_seconds = 30,
    default_rest_seconds = 60,
    impact_level = 'zero_impact',
    form_complexity = 1,
    stability_requirement = 'stable',
    is_dynamic_stretch = FALSE
WHERE lower(exercise_name) = lower('Sled Drag');


-- ============================================
-- DONE
-- ============================================
COMMENT ON COLUMN exercise_library.movement_pattern IS 'push, pull, hinge, squat, lunge, carry, rotation, locomotion, static_hold, isolation';
COMMENT ON COLUMN exercise_library.mechanic_type IS 'compound or isolation';
COMMENT ON COLUMN exercise_library.force_type IS 'push, pull, static, dynamic';
COMMENT ON COLUMN exercise_library.plane_of_motion IS 'sagittal, frontal, transverse, multi_plane';
COMMENT ON COLUMN exercise_library.energy_system IS 'aerobic, anaerobic_alactic, anaerobic_lactic, mixed';
COMMENT ON COLUMN exercise_library.impact_level IS 'zero_impact, low_impact, high_impact';
COMMENT ON COLUMN exercise_library.stability_requirement IS 'stable, semi_stable, unstable, dynamic';
COMMENT ON COLUMN exercise_library.form_complexity IS '1 (simplest) to 5 (most complex)';
