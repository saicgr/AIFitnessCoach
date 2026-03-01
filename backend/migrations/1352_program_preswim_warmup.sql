-- Program: Pre-Swim Warmup
-- Category: Warmup & Cooldown -> warmup_cooldown
-- Priority: High
-- Durations: [1, 2], Sessions: [7]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Pre-Swim Warmup',
    'Shoulder and full body warmup before swimming',
    'warmup_cooldown',
    'all_levels',
    2,
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

-- Variant: Pre-Swim Warmup - 1w 7x/wk
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
    'Pre-Swim Warmup - 1w 7x/wk',
    'warmup_cooldown',
    7,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Pre-Swim Warmup'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: refine technique and increase range',
    '[{"workout_name": "Pre-Swim Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Arm Circles", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff"], "difficulty": "beginner", "form_cue": "Progressive range, warm up shoulder joint", "substitution": "Shoulder Rolls"}, {"name": "Shoulder Pass-Through", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "With band or towel", "equipment": "Resistance Band", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Wide grip, full overhead rotation", "substitution": "Arm Circles"}, {"name": "Trunk Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Feet planted, rotate upper body", "substitution": "Seated Twist"}, {"name": "Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Reach overhead, lean to side, feel lat", "substitution": "Child''s Pose Stretch"}, {"name": "Ankle Circles", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction, each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Ankle Joint", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full circles for kick preparation", "substitution": "Calf Raises"}, {"name": "Streamline Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Lats"], "difficulty": "beginner", "form_cue": "Arms overhead, biceps by ears, elongate body", "substitution": "Overhead Reach"}]}, {"workout_name": "Pre-Swim Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Arm Circles", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff"], "difficulty": "beginner", "form_cue": "Progressive range, warm up shoulder joint", "substitution": "Shoulder Rolls"}, {"name": "Shoulder Pass-Through", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "With band or towel", "equipment": "Resistance Band", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Wide grip, full overhead rotation", "substitution": "Arm Circles"}, {"name": "Trunk Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Feet planted, rotate upper body", "substitution": "Seated Twist"}, {"name": "Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Reach overhead, lean to side, feel lat", "substitution": "Child''s Pose Stretch"}, {"name": "Ankle Circles", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction, each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Ankle Joint", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full circles for kick preparation", "substitution": "Calf Raises"}, {"name": "Streamline Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Lats"], "difficulty": "beginner", "form_cue": "Arms overhead, biceps by ears, elongate body", "substitution": "Overhead Reach"}]}, {"workout_name": "Pre-Swim Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Arm Circles", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff"], "difficulty": "beginner", "form_cue": "Progressive range, warm up shoulder joint", "substitution": "Shoulder Rolls"}, {"name": "Shoulder Pass-Through", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "With band or towel", "equipment": "Resistance Band", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Wide grip, full overhead rotation", "substitution": "Arm Circles"}, {"name": "Trunk Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Feet planted, rotate upper body", "substitution": "Seated Twist"}, {"name": "Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Reach overhead, lean to side, feel lat", "substitution": "Child''s Pose Stretch"}, {"name": "Ankle Circles", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction, each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Ankle Joint", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full circles for kick preparation", "substitution": "Calf Raises"}, {"name": "Streamline Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Lats"], "difficulty": "beginner", "form_cue": "Arms overhead, biceps by ears, elongate body", "substitution": "Overhead Reach"}]}]'::jsonb,
    'Pre-Swim Warmup',
    'Pre-Swim Warmup - 1w 7x/wk',
    'High',
    false,
    'Shoulder and full body warmup before swimming',
    'Warmup & Cooldown'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pre-Swim Warmup'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

-- Variant: Pre-Swim Warmup - 2w 7x/wk
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
    'Pre-Swim Warmup - 2w 7x/wk',
    'warmup_cooldown',
    7,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Pre-Swim Warmup'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: refine technique and increase range',
    '[{"workout_name": "Pre-Swim Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Arm Circles", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff"], "difficulty": "beginner", "form_cue": "Progressive range, warm up shoulder joint", "substitution": "Shoulder Rolls"}, {"name": "Shoulder Pass-Through", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "With band or towel", "equipment": "Resistance Band", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Wide grip, full overhead rotation", "substitution": "Arm Circles"}, {"name": "Trunk Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Feet planted, rotate upper body", "substitution": "Seated Twist"}, {"name": "Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Reach overhead, lean to side, feel lat", "substitution": "Child''s Pose Stretch"}, {"name": "Ankle Circles", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction, each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Ankle Joint", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full circles for kick preparation", "substitution": "Calf Raises"}, {"name": "Streamline Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Lats"], "difficulty": "beginner", "form_cue": "Arms overhead, biceps by ears, elongate body", "substitution": "Overhead Reach"}]}, {"workout_name": "Pre-Swim Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Arm Circles", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff"], "difficulty": "beginner", "form_cue": "Progressive range, warm up shoulder joint", "substitution": "Shoulder Rolls"}, {"name": "Shoulder Pass-Through", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "With band or towel", "equipment": "Resistance Band", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Wide grip, full overhead rotation", "substitution": "Arm Circles"}, {"name": "Trunk Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Feet planted, rotate upper body", "substitution": "Seated Twist"}, {"name": "Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Reach overhead, lean to side, feel lat", "substitution": "Child''s Pose Stretch"}, {"name": "Ankle Circles", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction, each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Ankle Joint", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full circles for kick preparation", "substitution": "Calf Raises"}, {"name": "Streamline Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Lats"], "difficulty": "beginner", "form_cue": "Arms overhead, biceps by ears, elongate body", "substitution": "Overhead Reach"}]}, {"workout_name": "Pre-Swim Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Arm Circles", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff"], "difficulty": "beginner", "form_cue": "Progressive range, warm up shoulder joint", "substitution": "Shoulder Rolls"}, {"name": "Shoulder Pass-Through", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "With band or towel", "equipment": "Resistance Band", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Wide grip, full overhead rotation", "substitution": "Arm Circles"}, {"name": "Trunk Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Feet planted, rotate upper body", "substitution": "Seated Twist"}, {"name": "Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Reach overhead, lean to side, feel lat", "substitution": "Child''s Pose Stretch"}, {"name": "Ankle Circles", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction, each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Ankle Joint", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full circles for kick preparation", "substitution": "Calf Raises"}, {"name": "Streamline Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Lats"], "difficulty": "beginner", "form_cue": "Arms overhead, biceps by ears, elongate body", "substitution": "Overhead Reach"}]}]'::jsonb,
    'Pre-Swim Warmup',
    'Pre-Swim Warmup - 2w 7x/wk',
    'High',
    false,
    'Shoulder and full body warmup before swimming',
    'Warmup & Cooldown'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pre-Swim Warmup'
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
    'Week 2 - Peak: full routine mastery, self-directed',
    '[{"workout_name": "Pre-Swim Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Arm Circles", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff"], "difficulty": "beginner", "form_cue": "Progressive range, warm up shoulder joint", "substitution": "Shoulder Rolls"}, {"name": "Shoulder Pass-Through", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "With band or towel", "equipment": "Resistance Band", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Wide grip, full overhead rotation", "substitution": "Arm Circles"}, {"name": "Trunk Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Feet planted, rotate upper body", "substitution": "Seated Twist"}, {"name": "Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Reach overhead, lean to side, feel lat", "substitution": "Child''s Pose Stretch"}, {"name": "Ankle Circles", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction, each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Ankle Joint", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full circles for kick preparation", "substitution": "Calf Raises"}, {"name": "Streamline Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Lats"], "difficulty": "beginner", "form_cue": "Arms overhead, biceps by ears, elongate body", "substitution": "Overhead Reach"}]}, {"workout_name": "Pre-Swim Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Arm Circles", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff"], "difficulty": "beginner", "form_cue": "Progressive range, warm up shoulder joint", "substitution": "Shoulder Rolls"}, {"name": "Shoulder Pass-Through", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "With band or towel", "equipment": "Resistance Band", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Wide grip, full overhead rotation", "substitution": "Arm Circles"}, {"name": "Trunk Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Feet planted, rotate upper body", "substitution": "Seated Twist"}, {"name": "Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Reach overhead, lean to side, feel lat", "substitution": "Child''s Pose Stretch"}, {"name": "Ankle Circles", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction, each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Ankle Joint", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full circles for kick preparation", "substitution": "Calf Raises"}, {"name": "Streamline Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Lats"], "difficulty": "beginner", "form_cue": "Arms overhead, biceps by ears, elongate body", "substitution": "Overhead Reach"}]}, {"workout_name": "Pre-Swim Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Arm Circles", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff"], "difficulty": "beginner", "form_cue": "Progressive range, warm up shoulder joint", "substitution": "Shoulder Rolls"}, {"name": "Shoulder Pass-Through", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "With band or towel", "equipment": "Resistance Band", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Chest", "Rotator Cuff"], "difficulty": "beginner", "form_cue": "Wide grip, full overhead rotation", "substitution": "Arm Circles"}, {"name": "Trunk Rotation", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Feet planted, rotate upper body", "substitution": "Seated Twist"}, {"name": "Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Reach overhead, lean to side, feel lat", "substitution": "Child''s Pose Stretch"}, {"name": "Ankle Circles", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction, each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Ankle Joint", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full circles for kick preparation", "substitution": "Calf Raises"}, {"name": "Streamline Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 15 seconds", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Lats"], "difficulty": "beginner", "form_cue": "Arms overhead, biceps by ears, elongate body", "substitution": "Overhead Reach"}]}]'::jsonb,
    'Pre-Swim Warmup',
    'Pre-Swim Warmup - 2w 7x/wk',
    'High',
    false,
    'Shoulder and full body warmup before swimming',
    'Warmup & Cooldown'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pre-Swim Warmup'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;
