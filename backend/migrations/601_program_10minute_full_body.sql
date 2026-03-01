-- Program: 10-Minute Full Body
-- Category: Quick Workouts -> quick_workout
-- Priority: High
-- Durations: [1, 2, 4], Sessions: [5, 6]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    '10-Minute Full Body',
    'Quick but complete full body workout covering all major movement patterns',
    'quick_workout',
    'all_levels',
    4,
    6,
    'full_body',
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

-- Variant: 10-Minute Full Body - 1w 5x/wk
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
    '10-Minute Full Body - 1w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '10-Minute Full Body'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 1w 5x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: 10-Minute Full Body - 1w 6x/wk
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
    '10-Minute Full Body - 1w 6x/wk',
    'quick_workout',
    6,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '10-Minute Full Body'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 1w 6x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

-- Variant: 10-Minute Full Body - 2w 5x/wk
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
    '10-Minute Full Body - 2w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '10-Minute Full Body'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 2w 5x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
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
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 2w 5x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: 10-Minute Full Body - 2w 6x/wk
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
    '10-Minute Full Body - 2w 6x/wk',
    'quick_workout',
    6,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '10-Minute Full Body'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 2w 6x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 2w 6x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

-- Variant: 10-Minute Full Body - 4w 5x/wk
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
    '10-Minute Full Body - 4w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '10-Minute Full Body'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Start: build the habit, learn the format',
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 4w 5x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
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
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 4w 5x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
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
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 4w 5x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
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
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 4w 5x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: 10-Minute Full Body - 4w 6x/wk
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
    '10-Minute Full Body - 4w 6x/wk',
    'quick_workout',
    6,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '10-Minute Full Body'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Start: build the habit, learn the format',
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 4w 6x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Build (Progressive Overload)',
    'Week 2 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 4w 6x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Peak (Intensification)',
    'Week 3 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 4w 6x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Test/Maintenance',
    'Week 4 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "10-Minute Full Body", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 15, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full range, rhythmic breathing", "substitution": "Step Jack"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Full ROM, chest to floor", "substitution": "Knee Push-Up"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Full depth each rep", "substitution": "Wall Sit"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Tight core, straight body", "substitution": "Forearm Plank"}, {"name": "Reverse Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Alternate legs, controlled motion", "substitution": "Split Squat"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Full extension at top", "substitution": "Squat Thrust"}]}]'::jsonb,
    '10-Minute Full Body',
    '10-Minute Full Body - 4w 6x/wk',
    'High',
    false,
    'Quick but complete full body workout covering all major movement patterns',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '10-Minute Full Body'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;
