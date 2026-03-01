-- Program: TRX/Suspension
-- Category: Equipment-Specific -> equipment_specific
-- Priority: low
-- Durations: [2, 4, 8], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'TRX/Suspension',
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'equipment_specific',
    'all_levels',
    8,
    4,
    'full_body',
    ARRAY['Build functional strength', 'Improve body control']::text[],
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

-- Variant: TRX/Suspension - 2w 3x/wk
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
    'TRX/Suspension - 2w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'TRX/Suspension'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 2w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 2w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: TRX/Suspension - 2w 4x/wk
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
    'TRX/Suspension - 2w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'TRX/Suspension'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 2w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 2w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: TRX/Suspension - 4w 3x/wk
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
    'TRX/Suspension - 4w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'TRX/Suspension'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 4w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 4w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 4w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 4w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: TRX/Suspension - 4w 4x/wk
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
    'TRX/Suspension - 4w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'TRX/Suspension'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 4w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 4w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 4w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 4w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: TRX/Suspension - 8w 3x/wk
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
    'TRX/Suspension - 8w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'TRX/Suspension'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 3x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: TRX/Suspension - 8w 4x/wk
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
    'TRX/Suspension - 8w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'TRX/Suspension'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
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
    '[{"workout_name": "Day 1 - TRX Full Body", "type": "strength", "exercises": [{"name": "TRX Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight - adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Lean back, pull chest to handles", "substitution": "TRX Single Arm Row"}, {"name": "TRX Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Face away, press forward", "substitution": "TRX Push-Up"}, {"name": "TRX Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight with TRX assist", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "beginner", "form_cue": "Hold handles, sit back deep", "substitution": "TRX Lunge"}, {"name": "TRX Pike", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Feet in straps, pike hips up", "substitution": "TRX Knee Tuck"}, {"name": "TRX Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Face anchor, curl body up", "substitution": "TRX Row"}, {"name": "TRX Hamstring Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "TRX", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lie on back, heels in straps, curl", "substitution": "TRX Single Leg Curl"}]}]'::jsonb,
    'TRX/Suspension',
    'TRX/Suspension - 8w 4x/wk',
    'low',
    true,
    'Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'TRX/Suspension'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
