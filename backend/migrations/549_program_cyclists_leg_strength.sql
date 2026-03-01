-- Program: Cyclist's Leg Strength
-- Category: Cycling & Biking -> cycling
-- Priority: Med
-- Durations: [2, 4, 8], Sessions: [2, 3]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Cyclist''s Leg Strength',
    'Off-bike leg power building for cycling performance',
    'cycling',
    'all_levels',
    8,
    3,
    'custom',
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve athletic performance', 'Develop explosiveness']::text[],
    true,
    true
) ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    difficulty_level = EXCLUDED.difficulty_level,
    duration_weeks = EXCLUDED.duration_weeks,
    sessions_per_week = EXCLUDED.sessions_per_week,
    split_type = EXCLUDED.split_type,
    goals = EXCLUDED.goals,
    requires_gym = EXCLUDED.requires_gym,
    updated_at = NOW();

-- Variant: Cyclist's Leg Strength - 2w 2x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    2,
    'Cyclist''s Leg Strength - 2w 2x/wk',
    'cycling',
    2,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve athletic performance', 'Develop explosiveness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Cyclist''s Leg Strength'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 2w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 2w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

-- Variant: Cyclist's Leg Strength - 2w 3x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    2,
    'Cyclist''s Leg Strength - 2w 3x/wk',
    'cycling',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve athletic performance', 'Develop explosiveness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Cyclist''s Leg Strength'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 2w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 2w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Cyclist's Leg Strength - 4w 2x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    4,
    'Cyclist''s Leg Strength - 4w 2x/wk',
    'cycling',
    2,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve athletic performance', 'Develop explosiveness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Cyclist''s Leg Strength'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: build base fitness and learn movements',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 4w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Build (Progressive Overload)',
    'Week 2 - Build: increase intensity and duration',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 4w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Peak (Intensification)',
    'Week 3 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 4w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Test/Maintenance',
    'Week 4 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 4w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

-- Variant: Cyclist's Leg Strength - 4w 3x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    4,
    'Cyclist''s Leg Strength - 4w 3x/wk',
    'cycling',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve athletic performance', 'Develop explosiveness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Cyclist''s Leg Strength'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: build base fitness and learn movements',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 4w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Build (Progressive Overload)',
    'Week 2 - Build: increase intensity and duration',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 4w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Peak (Intensification)',
    'Week 3 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 4w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Test/Maintenance',
    'Week 4 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 4w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Cyclist's Leg Strength - 8w 2x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    8,
    'Cyclist''s Leg Strength - 8w 2x/wk',
    'cycling',
    2,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve athletic performance', 'Develop explosiveness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Cyclist''s Leg Strength'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: build base fitness and learn movements',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation: build base fitness and learn movements',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Build (Progressive Overload)',
    'Week 3 - Build: increase intensity and duration',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Build: increase intensity and duration',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Peak (Intensification)',
    'Week 5 - Build: increase intensity and duration',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Peak (Intensification)',
    'Week 6 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Taper (Deload)',
    'Week 7 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Test/Maintenance',
    'Week 8 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 2x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 2
ON CONFLICT DO NOTHING;

-- Variant: Cyclist's Leg Strength - 8w 3x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    8,
    'Cyclist''s Leg Strength - 8w 3x/wk',
    'cycling',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve athletic performance', 'Develop explosiveness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Cyclist''s Leg Strength'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: build base fitness and learn movements',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation: build base fitness and learn movements',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Build (Progressive Overload)',
    'Week 3 - Build: increase intensity and duration',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Build: increase intensity and duration',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Peak (Intensification)',
    'Week 5 - Build: increase intensity and duration',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Peak (Intensification)',
    'Week 6 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Taper (Deload)',
    'Week 7 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Test/Maintenance',
    'Week 8 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}, {"workout_name": "Cycling Leg Power", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat"}, {"name": "Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Feet shoulder width, full range", "substitution": "Goblet Squat"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar close to shins", "substitution": "Dumbbell RDL"}, {"name": "Single-Leg Leg Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "One leg at a time, balance push power", "substitution": "Bulgarian Split Squat"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Heavy", "equipment": "Smith Machine", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, 2 second hold at top", "substitution": "Standing Calf Raise"}]}]'::jsonb,
    'Cyclist''s Leg Strength',
    'Cyclist''s Leg Strength - 8w 3x/wk',
    'Med',
    false,
    'Off-bike leg power building for cycling performance',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cyclist''s Leg Strength'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;
