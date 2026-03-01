-- Program: GSLP
-- Category: Reddit-Famous Programs -> reddit_famous
-- Priority: Med
-- Durations: [4, 8, 12], Sessions: [3]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'GSLP',
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'reddit_famous',
    'all_levels',
    12,
    3,
    'circuit',
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

-- Variant: GSLP - 4w 3x/wk
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
    'GSLP - 4w 3x/wk',
    'reddit_famous',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'GSLP'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Learn: establish lifts, practice form, start light',
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 4w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 4w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 4w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 4w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: GSLP - 8w 3x/wk
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
    'GSLP - 8w 3x/wk',
    'reddit_famous',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'GSLP'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Learn: establish lifts, practice form, start light',
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 8w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 8w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 8w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 8w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 8w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 8w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 8w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 8w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: GSLP - 12w 3x/wk
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
    12,
    'GSLP - 12w 3x/wk',
    'reddit_famous',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'GSLP'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Learn: establish lifts, practice form, start light',
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 12w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 12w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 12w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 12w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 12w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 12w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 12w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 12w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 12w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 12w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 12w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
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
    '[{"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}, {"workout_name": "Greyskull LP Day A", "type": "strength", "duration_minutes": 40, "exercises": [{"name": "Overhead Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, deload if fail", "substitution": "Dumbbell Shoulder Press"}, {"name": "Barbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 120, "weight_guidance": "Last set AMRAP", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP", "substitution": "Dumbbell Row"}, {"name": "Barbell Back Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 180, "weight_guidance": "Last set AMRAP, add 2.5lb/session", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "2x5 + 1x5+ AMRAP, every session", "substitution": "Goblet Squat"}]}]'::jsonb,
    'GSLP',
    'GSLP - 12w 3x/wk',
    'Med',
    false,
    'Greyskull LP original: simple A/B alternating with AMRAP finishers',
    'Reddit-Famous Programs'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'GSLP'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;
