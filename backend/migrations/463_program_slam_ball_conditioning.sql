-- Program: Slam Ball Conditioning
-- Category: Equipment-Specific -> equipment_specific
-- Priority: low
-- Durations: [1, 2, 4], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Slam Ball Conditioning',
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'equipment_specific',
    'all_levels',
    4,
    4,
    'full_body',
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
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

-- Variant: Slam Ball Conditioning - 1w 3x/wk
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
    'Slam Ball Conditioning - 1w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Slam Ball Conditioning'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 1w 3x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Slam Ball Conditioning - 1w 4x/wk
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
    'Slam Ball Conditioning - 1w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Slam Ball Conditioning'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 1w 4x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Slam Ball Conditioning - 2w 3x/wk
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
    'Slam Ball Conditioning - 2w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Slam Ball Conditioning'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 2w 3x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
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
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 2w 3x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Slam Ball Conditioning - 2w 4x/wk
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
    'Slam Ball Conditioning - 2w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Slam Ball Conditioning'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 2w 4x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
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
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 2w 4x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Slam Ball Conditioning - 4w 3x/wk
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
    'Slam Ball Conditioning - 4w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Slam Ball Conditioning'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 4w 3x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
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
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 4w 3x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
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
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 4w 3x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
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
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 4w 3x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Slam Ball Conditioning - 4w 4x/wk
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
    'Slam Ball Conditioning - 4w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Slam Ball Conditioning'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 4w 4x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
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
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 4w 4x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
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
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 4w 4x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
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
    '[{"workout_name": "Day 1 - Slam Ball Explosive Power", "type": "hiit", "exercises": [{"name": "Slam Ball Overhead Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate slam ball", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Lift overhead, slam to floor with max force", "substitution": "Slam Ball Side Slam"}, {"name": "Slam Ball Side Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate - 4/side", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hip Rotators"], "difficulty": "intermediate", "form_cue": "Rotate and slam to one side", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Squat Throw", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Squat with ball, explode up throwing ball high", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass forcefully against wall", "substitution": "Slam Ball Overhead Slam"}, {"name": "Slam Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Slam Ball Woodchop"}, {"name": "Slam Ball Burpee", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Slam Ball", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Core", "Legs"], "difficulty": "intermediate", "form_cue": "Slam, burpee, pick up, repeat", "substitution": "Slam Ball Overhead Slam"}]}]'::jsonb,
    'Slam Ball Conditioning',
    'Slam Ball Conditioning - 4w 4x/wk',
    'low',
    true,
    'Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Slam Ball Conditioning'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
