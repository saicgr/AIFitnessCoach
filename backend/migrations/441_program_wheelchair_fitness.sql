-- Program: Wheelchair Fitness
-- Category: Body-Specific -> body_specific
-- Priority: low
-- Durations: [2, 4, 8], Sessions: [4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Wheelchair Fitness',
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'body_specific',
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

-- Variant: Wheelchair Fitness - 2w 4x/wk
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
    'Wheelchair Fitness - 2w 4x/wk',
    'body_specific',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Wheelchair Fitness'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 2w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 2w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Wheelchair Fitness - 2w 5x/wk
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
    'Wheelchair Fitness - 2w 5x/wk',
    'body_specific',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Wheelchair Fitness'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 2w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 2w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Wheelchair Fitness - 4w 4x/wk
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
    'Wheelchair Fitness - 4w 4x/wk',
    'body_specific',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Wheelchair Fitness'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 4w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 4w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 4w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 4w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Wheelchair Fitness - 4w 5x/wk
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
    'Wheelchair Fitness - 4w 5x/wk',
    'body_specific',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Wheelchair Fitness'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 4w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 4w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 4w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 4w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Wheelchair Fitness - 8w 4x/wk
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
    'Wheelchair Fitness - 8w 4x/wk',
    'body_specific',
    4,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Wheelchair Fitness'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 4x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Wheelchair Fitness - 8w 5x/wk
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
    'Wheelchair Fitness - 8w 5x/wk',
    'body_specific',
    5,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Wheelchair Fitness'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
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
    '[{"workout_name": "Day 1 - Upper Body Push", "type": "strength", "exercises": [{"name": "Seated Dumbbell Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light-moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Lateral Deltoid", "Triceps"], "difficulty": "beginner", "form_cue": "Press from shoulders, seated position", "substitution": "Band Overhead Press"}, {"name": "Seated Chest Press", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Press forward from chest level", "substitution": "Band Chest Press"}, {"name": "Seated Tricep Extension", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps Brachii", "secondary_muscles": ["Anconeus"], "difficulty": "beginner", "form_cue": "Behind head extension", "substitution": "Band Tricep Pushdown"}, {"name": "Seated Lateral Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Very light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Raise to shoulder only", "substitution": "Band Lateral Raise"}, {"name": "Wheelchair Push-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Wheelchair", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Push up from armrests", "substitution": "Seated Chest Press"}]}, {"workout_name": "Day 2 - Upper Body Pull", "type": "strength", "exercises": [{"name": "Seated Dumbbell Row", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Lean forward, pull to hip", "substitution": "Band Row"}, {"name": "Seated Band Pull-Apart", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Back", "primary_muscle": "Rear Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Band Face Pull"}, {"name": "Seated Bicep Curl", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps Brachii", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Controlled curl", "substitution": "Band Curl"}, {"name": "Seated Shrug", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Elevate shoulders, hold briefly", "substitution": "Band Shrug"}, {"name": "Seated Core Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light DB", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate torso side to side", "substitution": "Seated Twist"}]}]'::jsonb,
    'Wheelchair Fitness',
    'Wheelchair Fitness - 8w 5x/wk',
    'low',
    false,
    'Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.',
    'Body-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Wheelchair Fitness'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
