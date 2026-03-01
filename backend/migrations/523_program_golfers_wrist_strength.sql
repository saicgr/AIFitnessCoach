-- Program: Golfer's Wrist Strength
-- Category: Golf Fitness -> golf
-- Priority: Low
-- Durations: [1, 2], Sessions: [5, 7]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Golfer''s Wrist Strength',
    'Grip strength and wrist stability for consistent shots',
    'golf',
    'all_levels',
    2,
    7,
    'custom',
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

-- Variant: Golfer's Wrist Strength - 1w 5x/wk
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
    'Golfer''s Wrist Strength - 1w 5x/wk',
    'golf',
    5,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Golfer''s Wrist Strength'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}, {"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'Golfer''s Wrist Strength',
    'Golfer''s Wrist Strength - 1w 5x/wk',
    'Low',
    false,
    'Grip strength and wrist stability for consistent shots',
    'Golf Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Golfer''s Wrist Strength'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Golfer's Wrist Strength - 1w 7x/wk
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
    'Golfer''s Wrist Strength - 1w 7x/wk',
    'golf',
    7,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Golfer''s Wrist Strength'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}, {"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'Golfer''s Wrist Strength',
    'Golfer''s Wrist Strength - 1w 7x/wk',
    'Low',
    false,
    'Grip strength and wrist stability for consistent shots',
    'Golf Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Golfer''s Wrist Strength'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

-- Variant: Golfer's Wrist Strength - 2w 5x/wk
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
    'Golfer''s Wrist Strength - 2w 5x/wk',
    'golf',
    5,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Golfer''s Wrist Strength'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}, {"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'Golfer''s Wrist Strength',
    'Golfer''s Wrist Strength - 2w 5x/wk',
    'Low',
    false,
    'Grip strength and wrist stability for consistent shots',
    'Golf Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Golfer''s Wrist Strength'
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
    'Week 2 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}, {"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'Golfer''s Wrist Strength',
    'Golfer''s Wrist Strength - 2w 5x/wk',
    'Low',
    false,
    'Grip strength and wrist stability for consistent shots',
    'Golf Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Golfer''s Wrist Strength'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Golfer's Wrist Strength - 2w 7x/wk
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
    'Golfer''s Wrist Strength - 2w 7x/wk',
    'golf',
    7,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Golfer''s Wrist Strength'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}, {"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'Golfer''s Wrist Strength',
    'Golfer''s Wrist Strength - 2w 7x/wk',
    'Low',
    false,
    'Grip strength and wrist stability for consistent shots',
    'Golf Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Golfer''s Wrist Strength'
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
    'Week 2 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}, {"workout_name": "Golf Mobility & Flexibility", "type": "flexibility", "duration_minutes": 35, "exercises": [{"name": "Thoracic Spine Rotation", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side-lying, top arm opens, follow with eyes", "substitution": "Seated Twist"}, {"name": "Hip 90/90 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Rotators", "secondary_muscles": ["Glutes", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Sit tall, both knees at 90 degrees", "substitution": "Pigeon Stretch"}, {"name": "Shoulder Sleeper Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Rotator Cuff", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Side-lying, gently press forearm down", "substitution": "Cross-Body Shoulder Stretch"}, {"name": "World''s Greatest Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings", "Shoulders"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach - full mobility chain", "substitution": "Spiderman Stretch"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow and controlled", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round", "substitution": "Seated Cat-Cow"}, {"name": "Standing Lat Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "beginner", "form_cue": "Side bend with overhead arm", "substitution": "Doorway Lat Stretch"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds each arm", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrist Flexors"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Wrist Circle"}]}]'::jsonb,
    'Golfer''s Wrist Strength',
    'Golfer''s Wrist Strength - 2w 7x/wk',
    'Low',
    false,
    'Grip strength and wrist stability for consistent shots',
    'Golf Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Golfer''s Wrist Strength'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;
