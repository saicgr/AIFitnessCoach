-- Program: Medicine Ball Training
-- Category: Equipment-Specific -> equipment_specific
-- Priority: low
-- Durations: [2, 4], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Medicine Ball Training',
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'equipment_specific',
    'all_levels',
    4,
    4,
    'full_body',
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
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

-- Variant: Medicine Ball Training - 2w 3x/wk
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
    'Medicine Ball Training - 2w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Medicine Ball Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Med Ball Power", "type": "strength", "exercises": [{"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate med ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Overhead slam with force", "substitution": "Med Ball Chest Pass"}, {"name": "Medicine Ball Squat to Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Squat with ball at chest, press overhead", "substitution": "Med Ball Goblet Squat"}, {"name": "Medicine Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Med Ball Woodchop"}, {"name": "Medicine Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass against wall explosively", "substitution": "Med Ball Slam"}, {"name": "Medicine Ball Lunge with Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "Medicine Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Obliques", "Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lunge forward, rotate over front leg", "substitution": "Med Ball Squat"}, {"name": "Medicine Ball Plank Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Plank, hands on ball, alternate taps", "substitution": "Plank Hold"}]}]'::jsonb,
    'Medicine Ball Training',
    'Medicine Ball Training - 2w 3x/wk',
    'low',
    true,
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Medicine Ball Training'
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
    '[{"workout_name": "Day 1 - Med Ball Power", "type": "strength", "exercises": [{"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate med ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Overhead slam with force", "substitution": "Med Ball Chest Pass"}, {"name": "Medicine Ball Squat to Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Squat with ball at chest, press overhead", "substitution": "Med Ball Goblet Squat"}, {"name": "Medicine Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Med Ball Woodchop"}, {"name": "Medicine Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass against wall explosively", "substitution": "Med Ball Slam"}, {"name": "Medicine Ball Lunge with Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "Medicine Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Obliques", "Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lunge forward, rotate over front leg", "substitution": "Med Ball Squat"}, {"name": "Medicine Ball Plank Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Plank, hands on ball, alternate taps", "substitution": "Plank Hold"}]}]'::jsonb,
    'Medicine Ball Training',
    'Medicine Ball Training - 2w 3x/wk',
    'low',
    true,
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Medicine Ball Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Medicine Ball Training - 2w 4x/wk
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
    'Medicine Ball Training - 2w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Medicine Ball Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Med Ball Power", "type": "strength", "exercises": [{"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate med ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Overhead slam with force", "substitution": "Med Ball Chest Pass"}, {"name": "Medicine Ball Squat to Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Squat with ball at chest, press overhead", "substitution": "Med Ball Goblet Squat"}, {"name": "Medicine Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Med Ball Woodchop"}, {"name": "Medicine Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass against wall explosively", "substitution": "Med Ball Slam"}, {"name": "Medicine Ball Lunge with Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "Medicine Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Obliques", "Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lunge forward, rotate over front leg", "substitution": "Med Ball Squat"}, {"name": "Medicine Ball Plank Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Plank, hands on ball, alternate taps", "substitution": "Plank Hold"}]}]'::jsonb,
    'Medicine Ball Training',
    'Medicine Ball Training - 2w 4x/wk',
    'low',
    true,
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Medicine Ball Training'
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
    '[{"workout_name": "Day 1 - Med Ball Power", "type": "strength", "exercises": [{"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate med ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Overhead slam with force", "substitution": "Med Ball Chest Pass"}, {"name": "Medicine Ball Squat to Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Squat with ball at chest, press overhead", "substitution": "Med Ball Goblet Squat"}, {"name": "Medicine Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Med Ball Woodchop"}, {"name": "Medicine Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass against wall explosively", "substitution": "Med Ball Slam"}, {"name": "Medicine Ball Lunge with Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "Medicine Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Obliques", "Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lunge forward, rotate over front leg", "substitution": "Med Ball Squat"}, {"name": "Medicine Ball Plank Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Plank, hands on ball, alternate taps", "substitution": "Plank Hold"}]}]'::jsonb,
    'Medicine Ball Training',
    'Medicine Ball Training - 2w 4x/wk',
    'low',
    true,
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Medicine Ball Training'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Medicine Ball Training - 4w 3x/wk
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
    'Medicine Ball Training - 4w 3x/wk',
    'equipment_specific',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Medicine Ball Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Med Ball Power", "type": "strength", "exercises": [{"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate med ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Overhead slam with force", "substitution": "Med Ball Chest Pass"}, {"name": "Medicine Ball Squat to Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Squat with ball at chest, press overhead", "substitution": "Med Ball Goblet Squat"}, {"name": "Medicine Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Med Ball Woodchop"}, {"name": "Medicine Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass against wall explosively", "substitution": "Med Ball Slam"}, {"name": "Medicine Ball Lunge with Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "Medicine Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Obliques", "Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lunge forward, rotate over front leg", "substitution": "Med Ball Squat"}, {"name": "Medicine Ball Plank Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Plank, hands on ball, alternate taps", "substitution": "Plank Hold"}]}]'::jsonb,
    'Medicine Ball Training',
    'Medicine Ball Training - 4w 3x/wk',
    'low',
    true,
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Medicine Ball Training'
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
    '[{"workout_name": "Day 1 - Med Ball Power", "type": "strength", "exercises": [{"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate med ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Overhead slam with force", "substitution": "Med Ball Chest Pass"}, {"name": "Medicine Ball Squat to Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Squat with ball at chest, press overhead", "substitution": "Med Ball Goblet Squat"}, {"name": "Medicine Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Med Ball Woodchop"}, {"name": "Medicine Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass against wall explosively", "substitution": "Med Ball Slam"}, {"name": "Medicine Ball Lunge with Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "Medicine Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Obliques", "Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lunge forward, rotate over front leg", "substitution": "Med Ball Squat"}, {"name": "Medicine Ball Plank Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Plank, hands on ball, alternate taps", "substitution": "Plank Hold"}]}]'::jsonb,
    'Medicine Ball Training',
    'Medicine Ball Training - 4w 3x/wk',
    'low',
    true,
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Medicine Ball Training'
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
    '[{"workout_name": "Day 1 - Med Ball Power", "type": "strength", "exercises": [{"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate med ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Overhead slam with force", "substitution": "Med Ball Chest Pass"}, {"name": "Medicine Ball Squat to Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Squat with ball at chest, press overhead", "substitution": "Med Ball Goblet Squat"}, {"name": "Medicine Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Med Ball Woodchop"}, {"name": "Medicine Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass against wall explosively", "substitution": "Med Ball Slam"}, {"name": "Medicine Ball Lunge with Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "Medicine Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Obliques", "Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lunge forward, rotate over front leg", "substitution": "Med Ball Squat"}, {"name": "Medicine Ball Plank Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Plank, hands on ball, alternate taps", "substitution": "Plank Hold"}]}]'::jsonb,
    'Medicine Ball Training',
    'Medicine Ball Training - 4w 3x/wk',
    'low',
    true,
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Medicine Ball Training'
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
    '[{"workout_name": "Day 1 - Med Ball Power", "type": "strength", "exercises": [{"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate med ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Overhead slam with force", "substitution": "Med Ball Chest Pass"}, {"name": "Medicine Ball Squat to Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Squat with ball at chest, press overhead", "substitution": "Med Ball Goblet Squat"}, {"name": "Medicine Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Med Ball Woodchop"}, {"name": "Medicine Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass against wall explosively", "substitution": "Med Ball Slam"}, {"name": "Medicine Ball Lunge with Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "Medicine Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Obliques", "Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lunge forward, rotate over front leg", "substitution": "Med Ball Squat"}, {"name": "Medicine Ball Plank Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Plank, hands on ball, alternate taps", "substitution": "Plank Hold"}]}]'::jsonb,
    'Medicine Ball Training',
    'Medicine Ball Training - 4w 3x/wk',
    'low',
    true,
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Medicine Ball Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Medicine Ball Training - 4w 4x/wk
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
    'Medicine Ball Training - 4w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Medicine Ball Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Med Ball Power", "type": "strength", "exercises": [{"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate med ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Overhead slam with force", "substitution": "Med Ball Chest Pass"}, {"name": "Medicine Ball Squat to Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Squat with ball at chest, press overhead", "substitution": "Med Ball Goblet Squat"}, {"name": "Medicine Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Med Ball Woodchop"}, {"name": "Medicine Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass against wall explosively", "substitution": "Med Ball Slam"}, {"name": "Medicine Ball Lunge with Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "Medicine Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Obliques", "Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lunge forward, rotate over front leg", "substitution": "Med Ball Squat"}, {"name": "Medicine Ball Plank Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Plank, hands on ball, alternate taps", "substitution": "Plank Hold"}]}]'::jsonb,
    'Medicine Ball Training',
    'Medicine Ball Training - 4w 4x/wk',
    'low',
    true,
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Medicine Ball Training'
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
    '[{"workout_name": "Day 1 - Med Ball Power", "type": "strength", "exercises": [{"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate med ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Overhead slam with force", "substitution": "Med Ball Chest Pass"}, {"name": "Medicine Ball Squat to Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Squat with ball at chest, press overhead", "substitution": "Med Ball Goblet Squat"}, {"name": "Medicine Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Med Ball Woodchop"}, {"name": "Medicine Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass against wall explosively", "substitution": "Med Ball Slam"}, {"name": "Medicine Ball Lunge with Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "Medicine Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Obliques", "Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lunge forward, rotate over front leg", "substitution": "Med Ball Squat"}, {"name": "Medicine Ball Plank Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Plank, hands on ball, alternate taps", "substitution": "Plank Hold"}]}]'::jsonb,
    'Medicine Ball Training',
    'Medicine Ball Training - 4w 4x/wk',
    'low',
    true,
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Medicine Ball Training'
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
    '[{"workout_name": "Day 1 - Med Ball Power", "type": "strength", "exercises": [{"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate med ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Overhead slam with force", "substitution": "Med Ball Chest Pass"}, {"name": "Medicine Ball Squat to Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Squat with ball at chest, press overhead", "substitution": "Med Ball Goblet Squat"}, {"name": "Medicine Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Med Ball Woodchop"}, {"name": "Medicine Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass against wall explosively", "substitution": "Med Ball Slam"}, {"name": "Medicine Ball Lunge with Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "Medicine Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Obliques", "Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lunge forward, rotate over front leg", "substitution": "Med Ball Squat"}, {"name": "Medicine Ball Plank Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Plank, hands on ball, alternate taps", "substitution": "Plank Hold"}]}]'::jsonb,
    'Medicine Ball Training',
    'Medicine Ball Training - 4w 4x/wk',
    'low',
    true,
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Medicine Ball Training'
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
    '[{"workout_name": "Day 1 - Med Ball Power", "type": "strength", "exercises": [{"name": "Medicine Ball Slam", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate med ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Latissimus Dorsi"], "difficulty": "intermediate", "form_cue": "Overhead slam with force", "substitution": "Med Ball Chest Pass"}, {"name": "Medicine Ball Squat to Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Squat with ball at chest, press overhead", "substitution": "Med Ball Goblet Squat"}, {"name": "Medicine Ball Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "intermediate", "form_cue": "Lean back, rotate with ball", "substitution": "Med Ball Woodchop"}, {"name": "Medicine Ball Chest Pass", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Pass against wall explosively", "substitution": "Med Ball Slam"}, {"name": "Medicine Ball Lunge with Twist", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light-moderate", "equipment": "Medicine Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Obliques", "Gluteus Maximus"], "difficulty": "intermediate", "form_cue": "Lunge forward, rotate over front leg", "substitution": "Med Ball Squat"}, {"name": "Medicine Ball Plank Tap", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Plank, hands on ball, alternate taps", "substitution": "Plank Hold"}]}]'::jsonb,
    'Medicine Ball Training',
    'Medicine Ball Training - 4w 4x/wk',
    'low',
    true,
    'Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Medicine Ball Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
