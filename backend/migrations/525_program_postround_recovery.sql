-- Program: Post-Round Recovery
-- Category: Golf Fitness -> golf
-- Priority: Low
-- Durations: [1], Sessions: [1]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Post-Round Recovery',
    'Cool down stretches and mobility after 18 holes',
    'golf',
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

-- Variant: Post-Round Recovery - 1w 1x/wk
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
    'Post-Round Recovery - 1w 1x/wk',
    'golf',
    1,
    60,
    ARRAY['Improve flexibility', 'Enhance body awareness', 'Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Post-Round Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'Post-Round Recovery',
    'Post-Round Recovery - 1w 1x/wk',
    'Low',
    false,
    'Cool down stretches and mobility after 18 holes',
    'Golf Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Round Recovery'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 1
ON CONFLICT DO NOTHING;
