-- Program: EZ Curl Bar Program
-- Category: Equipment-Specific -> equipment_specific
-- Priority: low
-- Durations: [2, 4, 8], Sessions: [4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'EZ Curl Bar Program',
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'equipment_specific',
    'all_levels',
    8,
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

-- Variant: EZ Curl Bar Program - 2w 4x/wk
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
    'EZ Curl Bar Program - 2w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'EZ Curl Bar Program'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 2w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 2w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: EZ Curl Bar Program - 2w 5x/wk
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
    'EZ Curl Bar Program - 2w 5x/wk',
    'equipment_specific',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'EZ Curl Bar Program'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 2w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    'Week 2 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 2w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: EZ Curl Bar Program - 4w 4x/wk
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
    'EZ Curl Bar Program - 4w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'EZ Curl Bar Program'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 4w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 4w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 4w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 4w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: EZ Curl Bar Program - 4w 5x/wk
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
    'EZ Curl Bar Program - 4w 5x/wk',
    'equipment_specific',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'EZ Curl Bar Program'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 4w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    'Week 2 - Progressive overload',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 4w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    'Week 3 - Peak intensity',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 4w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    'Week 4 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 4w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: EZ Curl Bar Program - 8w 4x/wk
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
    'EZ Curl Bar Program - 8w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'EZ Curl Bar Program'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
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
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 4x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: EZ Curl Bar Program - 8w 5x/wk
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
    'EZ Curl Bar Program - 8w 5x/wk',
    'equipment_specific',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'EZ Curl Bar Program'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Build (Progressive Overload)',
    'Week 3 - Progressive overload',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Progressive overload',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Peak (Intensification)',
    'Week 5 - Peak intensity',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Peak (Intensification)',
    'Week 6 - Peak intensity',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Taper (Deload)',
    'Week 7 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Test/Maintenance',
    'Week 8 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - EZ Bar Full Body", "type": "strength", "exercises": [{"name": "EZ Bar Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "intermediate", "form_cue": "Angled grip reduces wrist strain", "substitution": "EZ Bar Preacher Curl"}, {"name": "EZ Bar Skull Crusher", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend up", "substitution": "EZ Bar Close Grip Press"}, {"name": "EZ Bar Close Grip Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Chest", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Pectoralis Major"], "difficulty": "intermediate", "form_cue": "Narrow grip, press from chest", "substitution": "EZ Bar Skull Crusher"}, {"name": "EZ Bar Upright Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Trapezius"], "difficulty": "intermediate", "form_cue": "Pull to chin, elbows high", "substitution": "EZ Bar Front Raise"}, {"name": "EZ Bar Bent-Over Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "EZ Curl Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Hinge forward, pull to navel", "substitution": "EZ Bar High Row"}, {"name": "EZ Bar Front Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light-moderate", "equipment": "EZ Curl Bar", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Gluteus Maximus", "Core"], "difficulty": "intermediate", "form_cue": "Bar in front rack, squat deep", "substitution": "EZ Bar Goblet Hold Squat"}]}]'::jsonb,
    'EZ Curl Bar Program',
    'EZ Curl Bar Program - 8w 5x/wk',
    'low',
    true,
    'Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EZ Curl Bar Program'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
