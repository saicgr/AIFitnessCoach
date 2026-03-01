-- Program: Adaptive Fitness
-- Category: Body-Specific -> body_specific
-- Priority: low
-- Durations: [2, 4, 8], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Adaptive Fitness',
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'body_specific',
    'all_levels',
    8,
    4,
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

-- Variant: Adaptive Fitness - 2w 3x/wk
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
    'Adaptive Fitness - 2w 3x/wk',
    'body_specific',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Adaptive Fitness'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 2w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 2 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 2w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Adaptive Fitness - 2w 4x/wk
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
    'Adaptive Fitness - 2w 4x/wk',
    'body_specific',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Adaptive Fitness'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 2w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 2 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 2w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Adaptive Fitness - 4w 3x/wk
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
    'Adaptive Fitness - 4w 3x/wk',
    'body_specific',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Adaptive Fitness'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 4w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 2 - Progressive overload',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 4w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 3 - Peak intensity',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 4w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 4 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 4w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Adaptive Fitness - 4w 4x/wk
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
    'Adaptive Fitness - 4w 4x/wk',
    'body_specific',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Adaptive Fitness'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 4w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 2 - Progressive overload',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 4w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 3 - Peak intensity',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 4w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 4 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 4w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Adaptive Fitness - 8w 3x/wk
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
    'Adaptive Fitness - 8w 3x/wk',
    'body_specific',
    3,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Adaptive Fitness'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 2 - Foundation',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 3 - Progressive overload',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 4 - Progressive overload',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 5 - Peak intensity',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 6 - Peak intensity',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 7 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 8 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 3x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Adaptive Fitness - 8w 4x/wk
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
    'Adaptive Fitness - 8w 4x/wk',
    'body_specific',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Adaptive Fitness'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 2 - Foundation',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 3 - Progressive overload',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 4 - Progressive overload',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 5 - Peak intensity',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 6 - Peak intensity',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 7 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
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
    'Week 8 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Customizable Strength", "type": "strength", "exercises": [{"name": "Chair Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Chair", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Sit and stand, use arms if needed", "substitution": "Wall Sit"}, {"name": "Wall Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Adjustable difficulty by distance", "substitution": "Counter Push-Up"}, {"name": "Seated Row with Band", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Seated or standing option", "substitution": "Dumbbell Row"}, {"name": "Modified Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 15-20 sec", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Knees down, or wall plank", "substitution": "Wall Plank"}, {"name": "Gentle Walking or Marching", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 min", "equipment": "None", "body_part": "Cardio", "primary_muscle": "Full Body", "secondary_muscles": ["Cardiovascular System"], "difficulty": "beginner", "form_cue": "Seated marching if standing not possible", "substitution": "Seated Marching"}]}]'::jsonb,
    'Adaptive Fitness',
    'Adaptive Fitness - 8w 4x/wk',
    'low',
    false,
    'Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Adaptive Fitness'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
