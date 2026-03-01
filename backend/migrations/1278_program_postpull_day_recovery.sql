-- Program: Post-Pull Day Recovery
-- Category: Lift Mobility -> mobility
-- Priority: Med
-- Durations: [1, 2], Sessions: [3]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Post-Pull Day Recovery',
    'Recovery work after back and bicep sessions targeting lats, biceps, and forearms',
    'mobility',
    'all_levels',
    2,
    3,
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

-- Variant: Post-Pull Day Recovery - 1w 3x/wk
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
    'Post-Pull Day Recovery - 1w 3x/wk',
    'mobility',
    3,
    60,
    ARRAY['Improve flexibility', 'Enhance body awareness', 'Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Post-Pull Day Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build',
    '[{"workout_name": "Post-Pull Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Lats", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Lie on side, arm overhead, roll lat area", "substitution": "Lacrosse Ball Lat"}, {"name": "Cross-Body Shoulder Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Posterior Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull arm across chest, feel back of shoulder stretch", "substitution": "Doorway Rear Delt Stretch"}, {"name": "Bicep Wall Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Biceps", "secondary_muscles": ["Forearms"], "difficulty": "beginner", "form_cue": "Place palm on wall behind you, turn body away", "substitution": "Doorway Bicep Stretch"}, {"name": "Foam Roll Upper Back", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow rolls", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Arms crossed, roll upper back area", "substitution": "Lacrosse Ball Upper Back"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearm Flexors", "secondary_muscles": ["Wrist"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Prayer Stretch"}, {"name": "Child''s Pose with Side Reach", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Walk hands to each side for lateral lat stretch", "substitution": "Lat Stretch on Rack"}]}]'::jsonb,
    'Post-Pull Day Recovery',
    'Post-Pull Day Recovery - 1w 3x/wk',
    'Med',
    false,
    'Recovery work after back and bicep sessions targeting lats, biceps, and forearms',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Pull Day Recovery'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Post-Pull Day Recovery - 2w 3x/wk
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
    'Post-Pull Day Recovery - 2w 3x/wk',
    'mobility',
    3,
    60,
    ARRAY['Improve flexibility', 'Enhance body awareness', 'Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Post-Pull Day Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build',
    '[{"workout_name": "Post-Pull Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Lats", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Lie on side, arm overhead, roll lat area", "substitution": "Lacrosse Ball Lat"}, {"name": "Cross-Body Shoulder Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Posterior Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull arm across chest, feel back of shoulder stretch", "substitution": "Doorway Rear Delt Stretch"}, {"name": "Bicep Wall Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Biceps", "secondary_muscles": ["Forearms"], "difficulty": "beginner", "form_cue": "Place palm on wall behind you, turn body away", "substitution": "Doorway Bicep Stretch"}, {"name": "Foam Roll Upper Back", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow rolls", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Arms crossed, roll upper back area", "substitution": "Lacrosse Ball Upper Back"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearm Flexors", "secondary_muscles": ["Wrist"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Prayer Stretch"}, {"name": "Child''s Pose with Side Reach", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Walk hands to each side for lateral lat stretch", "substitution": "Lat Stretch on Rack"}]}, {"workout_name": "Post-Pull Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Lats", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Lie on side, arm overhead, roll lat area", "substitution": "Lacrosse Ball Lat"}, {"name": "Cross-Body Shoulder Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Posterior Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull arm across chest, feel back of shoulder stretch", "substitution": "Doorway Rear Delt Stretch"}, {"name": "Bicep Wall Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Biceps", "secondary_muscles": ["Forearms"], "difficulty": "beginner", "form_cue": "Place palm on wall behind you, turn body away", "substitution": "Doorway Bicep Stretch"}, {"name": "Foam Roll Upper Back", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow rolls", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Arms crossed, roll upper back area", "substitution": "Lacrosse Ball Upper Back"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearm Flexors", "secondary_muscles": ["Wrist"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Prayer Stretch"}, {"name": "Child''s Pose with Side Reach", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Walk hands to each side for lateral lat stretch", "substitution": "Lat Stretch on Rack"}]}]'::jsonb,
    'Post-Pull Day Recovery',
    'Post-Pull Day Recovery - 2w 3x/wk',
    'Med',
    false,
    'Recovery work after back and bicep sessions targeting lats, biceps, and forearms',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Pull Day Recovery'
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
    'Week 2 - Peak',
    '[{"workout_name": "Post-Pull Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Lats", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Lie on side, arm overhead, roll lat area", "substitution": "Lacrosse Ball Lat"}, {"name": "Cross-Body Shoulder Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Posterior Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull arm across chest, feel back of shoulder stretch", "substitution": "Doorway Rear Delt Stretch"}, {"name": "Bicep Wall Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Biceps", "secondary_muscles": ["Forearms"], "difficulty": "beginner", "form_cue": "Place palm on wall behind you, turn body away", "substitution": "Doorway Bicep Stretch"}, {"name": "Foam Roll Upper Back", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow rolls", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Arms crossed, roll upper back area", "substitution": "Lacrosse Ball Upper Back"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearm Flexors", "secondary_muscles": ["Wrist"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Prayer Stretch"}, {"name": "Child''s Pose with Side Reach", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Walk hands to each side for lateral lat stretch", "substitution": "Lat Stretch on Rack"}]}, {"workout_name": "Post-Pull Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Lats", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major"], "difficulty": "beginner", "form_cue": "Lie on side, arm overhead, roll lat area", "substitution": "Lacrosse Ball Lat"}, {"name": "Cross-Body Shoulder Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Posterior Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull arm across chest, feel back of shoulder stretch", "substitution": "Doorway Rear Delt Stretch"}, {"name": "Bicep Wall Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Biceps", "secondary_muscles": ["Forearms"], "difficulty": "beginner", "form_cue": "Place palm on wall behind you, turn body away", "substitution": "Doorway Bicep Stretch"}, {"name": "Foam Roll Upper Back", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow rolls", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Trapezius"], "difficulty": "beginner", "form_cue": "Arms crossed, roll upper back area", "substitution": "Lacrosse Ball Upper Back"}, {"name": "Wrist Flexor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Arms", "primary_muscle": "Forearm Flexors", "secondary_muscles": ["Wrist"], "difficulty": "beginner", "form_cue": "Extend arm, pull fingers back gently", "substitution": "Prayer Stretch"}, {"name": "Child''s Pose with Side Reach", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Walk hands to each side for lateral lat stretch", "substitution": "Lat Stretch on Rack"}]}]'::jsonb,
    'Post-Pull Day Recovery',
    'Post-Pull Day Recovery - 2w 3x/wk',
    'Med',
    false,
    'Recovery work after back and bicep sessions targeting lats, biceps, and forearms',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Pull Day Recovery'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;
