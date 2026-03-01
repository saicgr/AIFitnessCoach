-- Program: 7-Minute Scientific
-- Category: Quick Workouts -> quick_workout
-- Priority: High
-- Durations: [1, 2, 4], Sessions: [5, 6, 7]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    '7-Minute Scientific',
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'quick_workout',
    'all_levels',
    4,
    7,
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

-- Variant: 7-Minute Scientific - 1w 5x/wk
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
    '7-Minute Scientific - 1w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '7-Minute Scientific'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 1w 5x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: 7-Minute Scientific - 1w 6x/wk
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
    '7-Minute Scientific - 1w 6x/wk',
    'quick_workout',
    6,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '7-Minute Scientific'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 1w 6x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

-- Variant: 7-Minute Scientific - 1w 7x/wk
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
    '7-Minute Scientific - 1w 7x/wk',
    'quick_workout',
    7,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '7-Minute Scientific'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 1w 7x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

-- Variant: 7-Minute Scientific - 2w 5x/wk
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
    '7-Minute Scientific - 2w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '7-Minute Scientific'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 2w 5x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
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
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 2w 5x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: 7-Minute Scientific - 2w 6x/wk
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
    '7-Minute Scientific - 2w 6x/wk',
    'quick_workout',
    6,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '7-Minute Scientific'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 2w 6x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
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
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 2w 6x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

-- Variant: 7-Minute Scientific - 2w 7x/wk
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
    '7-Minute Scientific - 2w 7x/wk',
    'quick_workout',
    7,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '7-Minute Scientific'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 2w 7x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
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
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 2w 7x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

-- Variant: 7-Minute Scientific - 4w 5x/wk
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
    '7-Minute Scientific - 4w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '7-Minute Scientific'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Start: build the habit, learn the format',
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 4w 5x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
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
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 4w 5x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
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
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 4w 5x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
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
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 4w 5x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: 7-Minute Scientific - 4w 6x/wk
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
    '7-Minute Scientific - 4w 6x/wk',
    'quick_workout',
    6,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '7-Minute Scientific'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Start: build the habit, learn the format',
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 4w 6x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
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
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 4w 6x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
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
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 4w 6x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
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
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 4w 6x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

-- Variant: 7-Minute Scientific - 4w 7x/wk
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
    '7-Minute Scientific - 4w 7x/wk',
    'quick_workout',
    7,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '7-Minute Scientific'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Start: build the habit, learn the format',
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 4w 7x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
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
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 4w 7x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
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
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 4w 7x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
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
    '[{"workout_name": "7-Minute Scientific", "type": "hiit", "duration_minutes": 7, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Full extension, rhythmic pace, 30 seconds", "substitution": "Step Jack"}, {"name": "Wall Sit", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Back on wall, thighs parallel, hold", "substitution": "Bodyweight Squat"}, {"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Max reps in 30 seconds, good form", "substitution": "Knee Push-Up"}, {"name": "Crunch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Continuous crunches for 30 seconds", "substitution": "Dead Bug"}, {"name": "Step-Up", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "beginner", "form_cue": "Alternate legs on chair, brisk pace", "substitution": "March in Place"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Continuous squats for 30 seconds", "substitution": "Wall Sit"}, {"name": "Tricep Dip (Chair)", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Hands on chair, dip for 30 seconds", "substitution": "Floor Dip"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Hold solid plank 30 seconds", "substitution": "Forearm Plank"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Run in place with high knees 30 seconds", "substitution": "March in Place"}, {"name": "Lunge", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Alternating lunges 30 seconds", "substitution": "Split Squat"}, {"name": "Push-Up with Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "intermediate", "form_cue": "Push-up then rotate to side plank", "substitution": "Push-Up"}, {"name": "Side Plank", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 10, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "beginner", "form_cue": "Stack feet, lift hips, hold each side", "substitution": "Forearm Side Plank"}]}]'::jsonb,
    '7-Minute Scientific',
    '7-Minute Scientific - 4w 7x/wk',
    'High',
    false,
    'Original science-backed high-intensity circuit training in just 7 minutes',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '7-Minute Scientific'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;
