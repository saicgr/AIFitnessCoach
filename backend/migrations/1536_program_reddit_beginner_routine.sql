-- Program: Reddit Beginner Routine
-- Category: Reddit-Famous Programs -> reddit_famous
-- Priority: High
-- Durations: [4, 8, 12], Sessions: [3]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Reddit Beginner Routine',
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'reddit_famous',
    'beginner',
    12,
    3,
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

-- Variant: Reddit Beginner Routine - 4w 3x/wk
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
    'Easy',
    4,
    'Reddit Beginner Routine - 4w 3x/wk',
    'reddit_famous',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Reddit Beginner Routine'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Learn: establish lifts, practice form, start light',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 4w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
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
    'Week 2 - Progress: linear progression, add weight each session',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 4w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
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
    'Week 3 - Push: handle heavier loads, test AMRAP sets',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 4w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
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
    'Week 4 - Peak: test maxes, deload if needed, maintain gains',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 4w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Reddit Beginner Routine - 8w 3x/wk
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
    'Easy',
    8,
    'Reddit Beginner Routine - 8w 3x/wk',
    'reddit_famous',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Reddit Beginner Routine'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Learn: establish lifts, practice form, start light',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 8w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
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
    'Week 2 - Learn: establish lifts, practice form, start light',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 8w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
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
    'Week 3 - Progress: linear progression, add weight each session',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 8w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
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
    'Week 4 - Progress: linear progression, add weight each session',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 8w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
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
    'Week 5 - Push: handle heavier loads, test AMRAP sets',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 8w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
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
    'Week 6 - Push: handle heavier loads, test AMRAP sets',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 8w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
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
    'Week 7 - Peak: test maxes, deload if needed, maintain gains',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 8w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
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
    'Week 8 - Peak: test maxes, deload if needed, maintain gains',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 8w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Reddit Beginner Routine - 12w 3x/wk
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
    'Easy',
    12,
    'Reddit Beginner Routine - 12w 3x/wk',
    'reddit_famous',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Reddit Beginner Routine'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Learn: establish lifts, practice form, start light',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 12w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Learn: establish lifts, practice form, start light',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 12w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Foundation (Base Building)',
    'Week 3 - Learn: establish lifts, practice form, start light',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 12w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Progress: linear progression, add weight each session',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 12w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Build (Progressive Overload)',
    'Week 5 - Progress: linear progression, add weight each session',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 12w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Build (Progressive Overload)',
    'Week 6 - Progress: linear progression, add weight each session',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 12w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Peak (Intensification)',
    'Week 7 - Push: handle heavier loads, test AMRAP sets',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 12w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Peak (Intensification)',
    'Week 8 - Push: handle heavier loads, test AMRAP sets',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 12w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    9,
    'Peak (Intensification)',
    'Week 9 - Push: handle heavier loads, test AMRAP sets',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 12w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    10,
    'Taper (Deload)',
    'Week 10 - Peak: test maxes, deload if needed, maintain gains',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 12w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    11,
    'Test/Maintenance',
    'Week 11 - Peak: test maxes, deload if needed, maintain gains',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 12w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    12,
    'Test/Maintenance',
    'Week 12 - Peak: test maxes, deload if needed, maintain gains',
    '[{"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}, {"workout_name": "Reddit Beginner Routine A", "type": "strength", "duration_minutes": 45, "exercises": [{"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Start with bar, add 5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "beginner", "form_cue": "Learn form first, linear progression", "substitution": "Goblet Squat"}, {"name": "Barbell Bench Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Touch chest, press up, linear progress", "substitution": "Dumbbell Bench Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Start light, add 2.5lb/session", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "45 degree torso, pull to belly", "substitution": "Dumbbell Row"}]}]'::jsonb,
    'Reddit Beginner Routine',
    'Reddit Beginner Routine - 12w 3x/wk',
    'High',
    false,
    'The r/Fitness basic beginner routine: simple 3x5 linear progression for novices',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Reddit Beginner Routine'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;
