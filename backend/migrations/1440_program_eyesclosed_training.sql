-- Program: Eyes-Closed Training
-- Category: Balance & Proprioception -> balance
-- Priority: Low
-- Durations: [2, 4], Sessions: [4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Eyes-Closed Training',
    'Visual-free proprioception and balance training',
    'balance',
    'all_levels',
    4,
    5,
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

-- Variant: Eyes-Closed Training - 2w 4x/wk
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
    'Eyes-Closed Training - 2w 4x/wk',
    'balance',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Eyes-Closed Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Challenge: add complexity and reduce support',
    '[{"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}]'::jsonb,
    'Eyes-Closed Training',
    'Eyes-Closed Training - 2w 4x/wk',
    'Low',
    false,
    'Visual-free proprioception and balance training',
    'Balance & Proprioception'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Eyes-Closed Training'
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
    'Week 2 - Mastery: eyes closed, single-leg, dynamic challenges',
    '[{"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}]'::jsonb,
    'Eyes-Closed Training',
    'Eyes-Closed Training - 2w 4x/wk',
    'Low',
    false,
    'Visual-free proprioception and balance training',
    'Balance & Proprioception'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Eyes-Closed Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Eyes-Closed Training - 2w 5x/wk
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
    'Eyes-Closed Training - 2w 5x/wk',
    'balance',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Eyes-Closed Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Challenge: add complexity and reduce support',
    '[{"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}]'::jsonb,
    'Eyes-Closed Training',
    'Eyes-Closed Training - 2w 5x/wk',
    'Low',
    false,
    'Visual-free proprioception and balance training',
    'Balance & Proprioception'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Eyes-Closed Training'
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
    'Week 2 - Mastery: eyes closed, single-leg, dynamic challenges',
    '[{"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}]'::jsonb,
    'Eyes-Closed Training',
    'Eyes-Closed Training - 2w 5x/wk',
    'Low',
    false,
    'Visual-free proprioception and balance training',
    'Balance & Proprioception'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Eyes-Closed Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Eyes-Closed Training - 4w 4x/wk
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
    'Eyes-Closed Training - 4w 4x/wk',
    'balance',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Eyes-Closed Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Awareness: establish balance baseline and proprioception',
    '[{"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}]'::jsonb,
    'Eyes-Closed Training',
    'Eyes-Closed Training - 4w 4x/wk',
    'Low',
    false,
    'Visual-free proprioception and balance training',
    'Balance & Proprioception'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Eyes-Closed Training'
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
    'Week 2 - Challenge: add complexity and reduce support',
    '[{"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}]'::jsonb,
    'Eyes-Closed Training',
    'Eyes-Closed Training - 4w 4x/wk',
    'Low',
    false,
    'Visual-free proprioception and balance training',
    'Balance & Proprioception'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Eyes-Closed Training'
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
    'Week 3 - Mastery: eyes closed, single-leg, dynamic challenges',
    '[{"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}]'::jsonb,
    'Eyes-Closed Training',
    'Eyes-Closed Training - 4w 4x/wk',
    'Low',
    false,
    'Visual-free proprioception and balance training',
    'Balance & Proprioception'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Eyes-Closed Training'
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
    'Week 4 - Mastery: eyes closed, single-leg, dynamic challenges',
    '[{"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}]'::jsonb,
    'Eyes-Closed Training',
    'Eyes-Closed Training - 4w 4x/wk',
    'Low',
    false,
    'Visual-free proprioception and balance training',
    'Balance & Proprioception'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Eyes-Closed Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Eyes-Closed Training - 4w 5x/wk
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
    'Eyes-Closed Training - 4w 5x/wk',
    'balance',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Eyes-Closed Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Awareness: establish balance baseline and proprioception',
    '[{"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}]'::jsonb,
    'Eyes-Closed Training',
    'Eyes-Closed Training - 4w 5x/wk',
    'Low',
    false,
    'Visual-free proprioception and balance training',
    'Balance & Proprioception'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Eyes-Closed Training'
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
    'Week 2 - Challenge: add complexity and reduce support',
    '[{"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}]'::jsonb,
    'Eyes-Closed Training',
    'Eyes-Closed Training - 4w 5x/wk',
    'Low',
    false,
    'Visual-free proprioception and balance training',
    'Balance & Proprioception'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Eyes-Closed Training'
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
    'Week 3 - Mastery: eyes closed, single-leg, dynamic challenges',
    '[{"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}]'::jsonb,
    'Eyes-Closed Training',
    'Eyes-Closed Training - 4w 5x/wk',
    'Low',
    false,
    'Visual-free proprioception and balance training',
    'Balance & Proprioception'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Eyes-Closed Training'
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
    'Week 4 - Mastery: eyes closed, single-leg, dynamic challenges',
    '[{"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}, {"workout_name": "Eyes-Closed Training", "type": "balance", "duration_minutes": 20, "exercises": [{"name": "Eyes-Closed Double-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Stand with eyes closed, feel proprioception", "substitution": "Standing Balance"}, {"name": "Eyes-Closed Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 15 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Gluteus Medius", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Close eyes, balance on one foot", "substitution": "Single-Leg Stand"}, {"name": "Eyes-Closed Tandem Walk", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 steps forward", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Core", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Heel-to-toe with eyes closed, arms out", "substitution": "Tandem Walk"}, {"name": "Eyes-Closed Weight Shift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Abductors", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Shift weight left and right with no vision", "substitution": "Weight Shift"}]}]'::jsonb,
    'Eyes-Closed Training',
    'Eyes-Closed Training - 4w 5x/wk',
    'Low',
    false,
    'Visual-free proprioception and balance training',
    'Balance & Proprioception'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Eyes-Closed Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
