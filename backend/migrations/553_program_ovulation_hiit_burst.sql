-- Program: Ovulation HIIT Burst
-- Category: Menstrual Cycle Synced -> menstrual_cycle
-- Priority: High
-- Durations: [1, 2], Sessions: [4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Ovulation HIIT Burst',
    'Maximum intensity HIIT during fertile window when energy peaks',
    'menstrual_cycle',
    'all_levels',
    2,
    5,
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

-- Variant: Ovulation HIIT Burst - 1w 4x/wk
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
    'Ovulation HIIT Burst - 1w 4x/wk',
    'menstrual_cycle',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Ovulation HIIT Burst'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Ovulation HIIT Burst", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up and jump", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Plank position, rapid knee drives", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip hinge, snap hips, squeeze glutes at top", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate height box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Two-foot takeoff, soft landing, step down", "substitution": "Squat Jump"}]}, {"workout_name": "Cycle-Synced Strength", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Goblet Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Full depth, chest up, elbows inside knees", "substitution": "Bodyweight Squat"}, {"name": "Dumbbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Full range, controlled", "substitution": "Push-Up"}, {"name": "Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Pull to ribcage, squeeze back", "substitution": "Cable Row"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, weights close to shins", "substitution": "Glute Bridge"}, {"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Press overhead, brace core", "substitution": "Pike Push-Up"}]}, {"workout_name": "Ovulation HIIT Burst", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up and jump", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Plank position, rapid knee drives", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip hinge, snap hips, squeeze glutes at top", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate height box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Two-foot takeoff, soft landing, step down", "substitution": "Squat Jump"}]}]'::jsonb,
    'Ovulation HIIT Burst',
    'Ovulation HIIT Burst - 1w 4x/wk',
    'High',
    false,
    'Maximum intensity HIIT during fertile window when energy peaks',
    'Menstrual Cycle Synced'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Ovulation HIIT Burst'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Ovulation HIIT Burst - 1w 5x/wk
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
    'Ovulation HIIT Burst - 1w 5x/wk',
    'menstrual_cycle',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Ovulation HIIT Burst'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Ovulation HIIT Burst", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up and jump", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Plank position, rapid knee drives", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip hinge, snap hips, squeeze glutes at top", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate height box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Two-foot takeoff, soft landing, step down", "substitution": "Squat Jump"}]}, {"workout_name": "Cycle-Synced Strength", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Goblet Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Full depth, chest up, elbows inside knees", "substitution": "Bodyweight Squat"}, {"name": "Dumbbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Full range, controlled", "substitution": "Push-Up"}, {"name": "Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Pull to ribcage, squeeze back", "substitution": "Cable Row"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, weights close to shins", "substitution": "Glute Bridge"}, {"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Press overhead, brace core", "substitution": "Pike Push-Up"}]}, {"workout_name": "Ovulation HIIT Burst", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up and jump", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Plank position, rapid knee drives", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip hinge, snap hips, squeeze glutes at top", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate height box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Two-foot takeoff, soft landing, step down", "substitution": "Squat Jump"}]}]'::jsonb,
    'Ovulation HIIT Burst',
    'Ovulation HIIT Burst - 1w 5x/wk',
    'High',
    false,
    'Maximum intensity HIIT during fertile window when energy peaks',
    'Menstrual Cycle Synced'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Ovulation HIIT Burst'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Ovulation HIIT Burst - 2w 4x/wk
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
    'Ovulation HIIT Burst - 2w 4x/wk',
    'menstrual_cycle',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Ovulation HIIT Burst'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Ovulation HIIT Burst", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up and jump", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Plank position, rapid knee drives", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip hinge, snap hips, squeeze glutes at top", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate height box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Two-foot takeoff, soft landing, step down", "substitution": "Squat Jump"}]}, {"workout_name": "Cycle-Synced Strength", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Goblet Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Full depth, chest up, elbows inside knees", "substitution": "Bodyweight Squat"}, {"name": "Dumbbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Full range, controlled", "substitution": "Push-Up"}, {"name": "Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Pull to ribcage, squeeze back", "substitution": "Cable Row"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, weights close to shins", "substitution": "Glute Bridge"}, {"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Press overhead, brace core", "substitution": "Pike Push-Up"}]}, {"workout_name": "Ovulation HIIT Burst", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up and jump", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Plank position, rapid knee drives", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip hinge, snap hips, squeeze glutes at top", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate height box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Two-foot takeoff, soft landing, step down", "substitution": "Squat Jump"}]}]'::jsonb,
    'Ovulation HIIT Burst',
    'Ovulation HIIT Burst - 2w 4x/wk',
    'High',
    false,
    'Maximum intensity HIIT during fertile window when energy peaks',
    'Menstrual Cycle Synced'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Ovulation HIIT Burst'
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
    'Week 2 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Ovulation HIIT Burst", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up and jump", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Plank position, rapid knee drives", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip hinge, snap hips, squeeze glutes at top", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate height box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Two-foot takeoff, soft landing, step down", "substitution": "Squat Jump"}]}, {"workout_name": "Cycle-Synced Strength", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Goblet Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Full depth, chest up, elbows inside knees", "substitution": "Bodyweight Squat"}, {"name": "Dumbbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Full range, controlled", "substitution": "Push-Up"}, {"name": "Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Pull to ribcage, squeeze back", "substitution": "Cable Row"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, weights close to shins", "substitution": "Glute Bridge"}, {"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Press overhead, brace core", "substitution": "Pike Push-Up"}]}, {"workout_name": "Ovulation HIIT Burst", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up and jump", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Plank position, rapid knee drives", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip hinge, snap hips, squeeze glutes at top", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate height box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Two-foot takeoff, soft landing, step down", "substitution": "Squat Jump"}]}]'::jsonb,
    'Ovulation HIIT Burst',
    'Ovulation HIIT Burst - 2w 4x/wk',
    'High',
    false,
    'Maximum intensity HIIT during fertile window when energy peaks',
    'Menstrual Cycle Synced'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Ovulation HIIT Burst'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Ovulation HIIT Burst - 2w 5x/wk
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
    'Ovulation HIIT Burst - 2w 5x/wk',
    'menstrual_cycle',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Ovulation HIIT Burst'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Ovulation HIIT Burst", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up and jump", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Plank position, rapid knee drives", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip hinge, snap hips, squeeze glutes at top", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate height box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Two-foot takeoff, soft landing, step down", "substitution": "Squat Jump"}]}, {"workout_name": "Cycle-Synced Strength", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Goblet Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Full depth, chest up, elbows inside knees", "substitution": "Bodyweight Squat"}, {"name": "Dumbbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Full range, controlled", "substitution": "Push-Up"}, {"name": "Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Pull to ribcage, squeeze back", "substitution": "Cable Row"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, weights close to shins", "substitution": "Glute Bridge"}, {"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Press overhead, brace core", "substitution": "Pike Push-Up"}]}, {"workout_name": "Ovulation HIIT Burst", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up and jump", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Plank position, rapid knee drives", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip hinge, snap hips, squeeze glutes at top", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate height box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Two-foot takeoff, soft landing, step down", "substitution": "Squat Jump"}]}]'::jsonb,
    'Ovulation HIIT Burst',
    'Ovulation HIIT Burst - 2w 5x/wk',
    'High',
    false,
    'Maximum intensity HIIT during fertile window when energy peaks',
    'Menstrual Cycle Synced'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Ovulation HIIT Burst'
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
    'Week 2 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Ovulation HIIT Burst", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up and jump", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Plank position, rapid knee drives", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip hinge, snap hips, squeeze glutes at top", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate height box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Two-foot takeoff, soft landing, step down", "substitution": "Squat Jump"}]}, {"workout_name": "Cycle-Synced Strength", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Goblet Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Full depth, chest up, elbows inside knees", "substitution": "Bodyweight Squat"}, {"name": "Dumbbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Full range, controlled", "substitution": "Push-Up"}, {"name": "Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Pull to ribcage, squeeze back", "substitution": "Cable Row"}, {"name": "Romanian Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, weights close to shins", "substitution": "Glute Bridge"}, {"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light to moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Press overhead, brace core", "substitution": "Pike Push-Up"}]}, {"workout_name": "Ovulation HIIT Burst", "type": "hiit", "duration_minutes": 35, "exercises": [{"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, max effort", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Chest to floor, explode up and jump", "substitution": "Squat Thrust"}, {"name": "Jump Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squat"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Fast pace", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "intermediate", "form_cue": "Plank position, rapid knee drives", "substitution": "High Knees"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip hinge, snap hips, squeeze glutes at top", "substitution": "Dumbbell Swing"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate height box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Two-foot takeoff, soft landing, step down", "substitution": "Squat Jump"}]}]'::jsonb,
    'Ovulation HIIT Burst',
    'Ovulation HIIT Burst - 2w 5x/wk',
    'High',
    false,
    'Maximum intensity HIIT during fertile window when energy peaks',
    'Menstrual Cycle Synced'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Ovulation HIIT Burst'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
