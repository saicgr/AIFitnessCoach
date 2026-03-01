-- Program: 15-Minute HIIT
-- Category: Quick Workouts -> quick_workout
-- Priority: High
-- Durations: [1, 2, 4], Sessions: [4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    '15-Minute HIIT',
    'Quick high-intensity interval training for maximum calorie burn',
    'quick_workout',
    'all_levels',
    4,
    5,
    'full_body',
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

-- Variant: 15-Minute HIIT - 1w 4x/wk
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
    '15-Minute HIIT - 1w 4x/wk',
    'quick_workout',
    4,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '15-Minute HIIT'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 1w 4x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: 15-Minute HIIT - 1w 5x/wk
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
    '15-Minute HIIT - 1w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '15-Minute HIIT'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 1w 5x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: 15-Minute HIIT - 2w 4x/wk
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
    '15-Minute HIIT - 2w 4x/wk',
    'quick_workout',
    4,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '15-Minute HIIT'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 2w 4x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
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
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 2w 4x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: 15-Minute HIIT - 2w 5x/wk
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
    '15-Minute HIIT - 2w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '15-Minute HIIT'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 2w 5x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
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
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 2w 5x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: 15-Minute HIIT - 4w 4x/wk
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
    '15-Minute HIIT - 4w 4x/wk',
    'quick_workout',
    4,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '15-Minute HIIT'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Start: build the habit, learn the format',
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 4w 4x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
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
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 4w 4x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
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
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 4w 4x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
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
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 4w 4x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: 15-Minute HIIT - 4w 5x/wk
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
    '15-Minute HIIT - 4w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Maximize calorie burn', 'Preserve lean muscle']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '15-Minute HIIT'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Start: build the habit, learn the format',
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 4w 5x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
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
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 4w 5x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
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
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 4w 5x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
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
    '[{"workout_name": "15-Minute HIIT", "type": "hiit", "duration_minutes": 15, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump high, keep moving", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Squat deep, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Fast feet, hips level, drive knees", "substitution": "Plank March"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max height", "substitution": "March in Place"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Keep pace up, full ROM", "substitution": "Knee Push-Up"}, {"name": "Tuck Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest, soft land", "substitution": "Jump Squat"}]}]'::jsonb,
    '15-Minute HIIT',
    '15-Minute HIIT - 4w 5x/wk',
    'High',
    false,
    'Quick high-intensity interval training for maximum calorie burn',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '15-Minute HIIT'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
