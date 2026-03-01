-- Program: Cycling Recovery
-- Category: Cycling & Biking -> cycling
-- Priority: Low
-- Durations: [1], Sessions: [1]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Cycling Recovery',
    'Post-ride stretching, foam rolling, and mobility',
    'cycling',
    'all_levels',
    1,
    1,
    'flow',
    ARRAY['Improve flexibility', 'Enhance body awareness', 'Promote active recovery', 'Reduce injury risk']::text[],
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

-- Variant: Cycling Recovery - 1w 1x/wk
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
    'Cycling Recovery - 1w 1x/wk',
    'cycling',
    1,
    60,
    ARRAY['Improve flexibility', 'Enhance body awareness', 'Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Cycling Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Cyclist''s Flexibility", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Hip Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Psoas"], "difficulty": "beginner", "form_cue": "Half-kneeling, push hips forward", "substitution": "Standing Quad Stretch"}, {"name": "Hamstring Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Straight leg on bench, hinge forward", "substitution": "Seated Forward Fold"}, {"name": "Pigeon Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis", "Hip Rotators"], "difficulty": "beginner", "form_cue": "Square hips, fold forward", "substitution": "Figure-4 Stretch"}, {"name": "Quad Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Pull heel to glute, keep knees together", "substitution": "Lying Quad Stretch"}, {"name": "Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arms behind back, open chest", "substitution": "Doorway Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Flow with breath", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round, gentle flow", "substitution": "Seated Cat-Cow"}, {"name": "Thoracic Spine Extension", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Over foam roller", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Hands behind head, extend over roller", "substitution": "Cat-Cow"}]}]'::jsonb,
    'Cycling Recovery',
    'Cycling Recovery - 1w 1x/wk',
    'Low',
    false,
    'Post-ride stretching, foam rolling, and mobility',
    'Cycling & Biking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Cycling Recovery'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 1
ON CONFLICT DO NOTHING;
