-- Program: Podcast Workout
-- Category: Content Creator/Influencer Fitness -> influencer
-- Priority: Med
-- Durations: [2, 4, 8], Sessions: [3, 4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Podcast Workout',
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'influencer',
    'all_levels',
    8,
    5,
    'custom',
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
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

-- Variant: Podcast Workout - 2w 3x/wk
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
    'Podcast Workout - 2w 3x/wk',
    'influencer',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Podcast Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 2w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 2 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 2w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Podcast Workout - 2w 4x/wk
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
    'Podcast Workout - 2w 4x/wk',
    'influencer',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Podcast Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 2w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 2 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 2w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Podcast Workout - 2w 5x/wk
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
    'Podcast Workout - 2w 5x/wk',
    'influencer',
    5,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Podcast Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 2w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 2 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 2w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Podcast Workout - 4w 3x/wk
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
    'Podcast Workout - 4w 3x/wk',
    'influencer',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Podcast Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Build Base: establish form and starting weights',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 4w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 2 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 4w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 3 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 4w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 4 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 4w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Podcast Workout - 4w 4x/wk
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
    'Podcast Workout - 4w 4x/wk',
    'influencer',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Podcast Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Build Base: establish form and starting weights',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 4w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 2 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 4w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 3 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 4w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 4 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 4w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Podcast Workout - 4w 5x/wk
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
    'Podcast Workout - 4w 5x/wk',
    'influencer',
    5,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Podcast Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Build Base: establish form and starting weights',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 4w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 2 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 4w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 3 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 4w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 4 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 4w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Podcast Workout - 8w 3x/wk
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
    'Podcast Workout - 8w 3x/wk',
    'influencer',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Podcast Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Build Base: establish form and starting weights',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 2 - Build Base: establish form and starting weights',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 3 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 4 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 5 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 6 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 7 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 8 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 3x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Podcast Workout - 8w 4x/wk
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
    'Podcast Workout - 8w 4x/wk',
    'influencer',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Podcast Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Build Base: establish form and starting weights',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 2 - Build Base: establish form and starting weights',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 3 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 4 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 5 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 6 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 7 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 8 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 4x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Podcast Workout - 8w 5x/wk
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
    'Podcast Workout - 8w 5x/wk',
    'influencer',
    5,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Podcast Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Build Base: establish form and starting weights',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 2 - Build Base: establish form and starting weights',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 3 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 4 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 5 - Intensify: progressive overload, track all lifts',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 6 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 7 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
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
    'Week 8 - Peak Aesthetics: pump training and definition work',
    '[{"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Podcast Zone-2 Session", "type": "cardio", "duration_minutes": 45, "exercises": [{"name": "Incline Treadmill Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 min at 3.0-3.5mph, 5-8% incline", "equipment": "Treadmill", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Zone 2 heart rate, can hold conversation", "substitution": "Outdoor Walk"}, {"name": "Stairmaster Climb", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min moderate pace", "equipment": "Stairmaster", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "beginner", "form_cue": "Steady pace, don''t lean on rails", "substitution": "Step-Up"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight between cardio", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full range during rest break", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Podcast Workout',
    'Podcast Workout - 8w 5x/wk',
    'Med',
    false,
    'Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks',
    'Content Creator/Influencer Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Podcast Workout'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
