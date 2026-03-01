-- Program: 12-3-30 Treadmill
-- Category: Viral TikTok Programs -> viral
-- Priority: High
-- Durations: [2, 4, 8], Sessions: [3, 4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    '12-3-30 Treadmill',
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'viral',
    'all_levels',
    8,
    5,
    'custom',
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
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

-- Variant: 12-3-30 Treadmill - 2w 3x/wk
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
    '12-3-30 Treadmill - 2w 3x/wk',
    'viral',
    3,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '12-3-30 Treadmill'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 2w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
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
    'Week 2 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 2w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: 12-3-30 Treadmill - 2w 4x/wk
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
    '12-3-30 Treadmill - 2w 4x/wk',
    'viral',
    4,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '12-3-30 Treadmill'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 2w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 2w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: 12-3-30 Treadmill - 2w 5x/wk
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
    '12-3-30 Treadmill - 2w 5x/wk',
    'viral',
    5,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '12-3-30 Treadmill'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 2w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 2w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: 12-3-30 Treadmill - 4w 3x/wk
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
    '12-3-30 Treadmill - 4w 3x/wk',
    'viral',
    3,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '12-3-30 Treadmill'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: learn the movements and build consistency',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 4w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
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
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 4w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
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
    'Week 3 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 4w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
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
    'Week 4 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 4w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: 12-3-30 Treadmill - 4w 4x/wk
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
    '12-3-30 Treadmill - 4w 4x/wk',
    'viral',
    4,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '12-3-30 Treadmill'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: learn the movements and build consistency',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 4w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Build (Progressive Overload)',
    'Week 2 - Build: increase intensity and duration',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 4w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Peak (Intensification)',
    'Week 3 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 4w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Test/Maintenance',
    'Week 4 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 4w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: 12-3-30 Treadmill - 4w 5x/wk
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
    '12-3-30 Treadmill - 4w 5x/wk',
    'viral',
    5,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '12-3-30 Treadmill'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: learn the movements and build consistency',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 4w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Build (Progressive Overload)',
    'Week 2 - Build: increase intensity and duration',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 4w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Peak (Intensification)',
    'Week 3 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 4w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Test/Maintenance',
    'Week 4 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 4w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: 12-3-30 Treadmill - 8w 3x/wk
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
    '12-3-30 Treadmill - 8w 3x/wk',
    'viral',
    3,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '12-3-30 Treadmill'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: learn the movements and build consistency',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
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
    'Week 2 - Foundation: learn the movements and build consistency',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
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
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
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
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
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
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
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
    'Week 6 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
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
    'Week 7 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
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
    'Week 8 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 3x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: 12-3-30 Treadmill - 8w 4x/wk
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
    '12-3-30 Treadmill - 8w 4x/wk',
    'viral',
    4,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '12-3-30 Treadmill'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: learn the movements and build consistency',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation: learn the movements and build consistency',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Build (Progressive Overload)',
    'Week 3 - Build: increase intensity and duration',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Build: increase intensity and duration',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Peak (Intensification)',
    'Week 5 - Build: increase intensity and duration',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Peak (Intensification)',
    'Week 6 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Taper (Deload)',
    'Week 7 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Test/Maintenance',
    'Week 8 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 4x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: 12-3-30 Treadmill - 8w 5x/wk
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
    '12-3-30 Treadmill - 8w 5x/wk',
    'viral',
    5,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '12-3-30 Treadmill'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: learn the movements and build consistency',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation: learn the movements and build consistency',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Build (Progressive Overload)',
    'Week 3 - Build: increase intensity and duration',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Build: increase intensity and duration',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Peak (Intensification)',
    'Week 5 - Build: increase intensity and duration',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Peak (Intensification)',
    'Week 6 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Taper (Deload)',
    'Week 7 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Test/Maintenance',
    'Week 8 - Push: maximize effort and track progress',
    '[{"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}, {"workout_name": "12-3-30 Treadmill Walk", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 30, "rest_seconds": 0, "weight_guidance": "12% incline, 3.0 mph, 30 min", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Calves", "Quadriceps"], "difficulty": "beginner", "form_cue": "Stand upright, no holding rails, engage core", "substitution": "Stairmaster 30 min"}, {"name": "Walking Lunge Cooldown", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Step forward, knee to 90 degrees", "substitution": "Stationary Lunge"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    '12-3-30 Treadmill',
    '12-3-30 Treadmill - 8w 5x/wk',
    'High',
    false,
    'The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting',
    'Viral TikTok Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '12-3-30 Treadmill'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
