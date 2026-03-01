-- Program: Busy Parent Workout
-- Category: Quick Workouts -> quick_workout
-- Priority: Low
-- Durations: [1, 2, 4], Sessions: [4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Busy Parent Workout',
    'Naptime-friendly quick fitness for busy parents',
    'quick_workout',
    'all_levels',
    4,
    5,
    'custom',
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
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

-- Variant: Busy Parent Workout - 1w 4x/wk
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
    1,
    'Busy Parent Workout - 1w 4x/wk',
    'quick_workout',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Busy Parent Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 1w 4x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Busy Parent Workout - 1w 5x/wk
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
    1,
    'Busy Parent Workout - 1w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Busy Parent Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 1w 5x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Busy Parent Workout - 2w 4x/wk
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
    'Busy Parent Workout - 2w 4x/wk',
    'quick_workout',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Busy Parent Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 2w 4x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
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
    'Week 2 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 2w 4x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Busy Parent Workout - 2w 5x/wk
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
    'Busy Parent Workout - 2w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Busy Parent Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 2w 5x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
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
    'Week 2 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 2w 5x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Busy Parent Workout - 4w 4x/wk
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
    'Busy Parent Workout - 4w 4x/wk',
    'quick_workout',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Busy Parent Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Start: build the habit, learn the format',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 4w 4x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
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
    'Week 2 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 4w 4x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
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
    'Week 3 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 4w 4x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
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
    'Week 4 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 4w 4x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Busy Parent Workout - 4w 5x/wk
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
    'Busy Parent Workout - 4w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Busy Parent Workout'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Start: build the habit, learn the format',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 4w 5x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
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
    'Week 2 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 4w 5x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
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
    'Week 3 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 4w 5x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
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
    'Week 4 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "Busy Parent Workout", "type": "strength", "duration_minutes": 15, "exercises": [{"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Quick pace, full depth", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Can be on knees, just keep moving", "substitution": "Knee Push-Up"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Quick but effective", "substitution": "Forearm Plank"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top", "substitution": "Hip Thrust"}, {"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 25, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get heart rate up", "substitution": "Step Jack"}]}]'::jsonb,
    'Busy Parent Workout',
    'Busy Parent Workout - 4w 5x/wk',
    'Low',
    false,
    'Naptime-friendly quick fitness for busy parents',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Busy Parent Workout'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
