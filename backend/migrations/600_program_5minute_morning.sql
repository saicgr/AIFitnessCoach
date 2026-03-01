-- Program: 5-Minute Morning
-- Category: Quick Workouts -> quick_workout
-- Priority: High
-- Durations: [1, 2, 4], Sessions: [7]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    '5-Minute Morning',
    'Quick wake-up energizer to start every day with movement',
    'quick_workout',
    'all_levels',
    4,
    7,
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

-- Variant: 5-Minute Morning - 1w 7x/wk
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
    '5-Minute Morning - 1w 7x/wk',
    'quick_workout',
    7,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '5-Minute Morning'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "5-Minute Morning Energizer", "type": "hiit", "duration_minutes": 5, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get blood flowing, full range of motion", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Wake up legs, continuous squats", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps with good form", "substitution": "Knee Push-Up"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Moderate pace, drive knees", "substitution": "Plank March"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Finish strong, max effort", "substitution": "Squat Thrust"}]}]'::jsonb,
    '5-Minute Morning',
    '5-Minute Morning - 1w 7x/wk',
    'High',
    false,
    'Quick wake-up energizer to start every day with movement',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '5-Minute Morning'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

-- Variant: 5-Minute Morning - 2w 7x/wk
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
    '5-Minute Morning - 2w 7x/wk',
    'quick_workout',
    7,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '5-Minute Morning'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "5-Minute Morning Energizer", "type": "hiit", "duration_minutes": 5, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get blood flowing, full range of motion", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Wake up legs, continuous squats", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps with good form", "substitution": "Knee Push-Up"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Moderate pace, drive knees", "substitution": "Plank March"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Finish strong, max effort", "substitution": "Squat Thrust"}]}]'::jsonb,
    '5-Minute Morning',
    '5-Minute Morning - 2w 7x/wk',
    'High',
    false,
    'Quick wake-up energizer to start every day with movement',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '5-Minute Morning'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "5-Minute Morning Energizer", "type": "hiit", "duration_minutes": 5, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get blood flowing, full range of motion", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Wake up legs, continuous squats", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps with good form", "substitution": "Knee Push-Up"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Moderate pace, drive knees", "substitution": "Plank March"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Finish strong, max effort", "substitution": "Squat Thrust"}]}]'::jsonb,
    '5-Minute Morning',
    '5-Minute Morning - 2w 7x/wk',
    'High',
    false,
    'Quick wake-up energizer to start every day with movement',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '5-Minute Morning'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

-- Variant: 5-Minute Morning - 4w 7x/wk
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
    '5-Minute Morning - 4w 7x/wk',
    'quick_workout',
    7,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '5-Minute Morning'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Start: build the habit, learn the format',
    '[{"workout_name": "5-Minute Morning Energizer", "type": "hiit", "duration_minutes": 5, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get blood flowing, full range of motion", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Wake up legs, continuous squats", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps with good form", "substitution": "Knee Push-Up"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Moderate pace, drive knees", "substitution": "Plank March"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Finish strong, max effort", "substitution": "Squat Thrust"}]}]'::jsonb,
    '5-Minute Morning',
    '5-Minute Morning - 4w 7x/wk',
    'High',
    false,
    'Quick wake-up energizer to start every day with movement',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '5-Minute Morning'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Build (Progressive Overload)',
    'Week 2 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "5-Minute Morning Energizer", "type": "hiit", "duration_minutes": 5, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get blood flowing, full range of motion", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Wake up legs, continuous squats", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps with good form", "substitution": "Knee Push-Up"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Moderate pace, drive knees", "substitution": "Plank March"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Finish strong, max effort", "substitution": "Squat Thrust"}]}]'::jsonb,
    '5-Minute Morning',
    '5-Minute Morning - 4w 7x/wk',
    'High',
    false,
    'Quick wake-up energizer to start every day with movement',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '5-Minute Morning'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Peak (Intensification)',
    'Week 3 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "5-Minute Morning Energizer", "type": "hiit", "duration_minutes": 5, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get blood flowing, full range of motion", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Wake up legs, continuous squats", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps with good form", "substitution": "Knee Push-Up"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Moderate pace, drive knees", "substitution": "Plank March"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Finish strong, max effort", "substitution": "Squat Thrust"}]}]'::jsonb,
    '5-Minute Morning',
    '5-Minute Morning - 4w 7x/wk',
    'High',
    false,
    'Quick wake-up energizer to start every day with movement',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '5-Minute Morning'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Test/Maintenance',
    'Week 4 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "5-Minute Morning Energizer", "type": "hiit", "duration_minutes": 5, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Get blood flowing, full range of motion", "substitution": "Step Jack"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Wake up legs, continuous squats", "substitution": "Wall Sit"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps with good form", "substitution": "Knee Push-Up"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Moderate pace, drive knees", "substitution": "Plank March"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "45 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Finish strong, max effort", "substitution": "Squat Thrust"}]}]'::jsonb,
    '5-Minute Morning',
    '5-Minute Morning - 4w 7x/wk',
    'High',
    false,
    'Quick wake-up energizer to start every day with movement',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '5-Minute Morning'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;
