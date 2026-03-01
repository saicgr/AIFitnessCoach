-- Program: EXHAUST ME - Core
-- Category: Hell Mode -> hell_mode
-- Priority: High
-- Durations: [1], Sessions: [6, 7]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'EXHAUST ME - Core',
    'Your core will question your life choices',
    'hell_mode',
    'advanced',
    1,
    7,
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

-- Variant: EXHAUST ME - Core - 1w 6x/wk
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
    'EXHAUST ME - Core - 1w 6x/wk',
    'hell_mode',
    6,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'EXHAUST ME - Core'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Endure: push beyond previous limits',
    '[{"workout_name": "EXHAUST ME - Core", "type": "hell_mode", "duration_minutes": 35, "exercises": [{"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 20, "weight_guidance": "Toes to bar", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Obliques"], "difficulty": "advanced", "form_cue": "Full range, toes to bar, controlled descent", "substitution": "Knee Raise"}, {"name": "Ab Roller", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 20, "weight_guidance": "Full extension", "equipment": "Ab Wheel", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders", "Lats"], "difficulty": "advanced", "form_cue": "Extend all the way out, roll back with abs", "substitution": "Plank Walkout"}, {"name": "Dragon Flag", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Slow eccentric", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Lower body as one unit, resist gravity, do not bend at hips", "substitution": "Lying Leg Raise"}, {"name": "L-Sit Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 20 seconds", "equipment": "Dip Bar", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis", "Quadriceps"], "difficulty": "advanced", "form_cue": "Straight legs, body at L-shape, squeeze everything", "substitution": "Tuck L-Sit"}, {"name": "Weighted Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 60 seconds with plate on back", "equipment": "Weight Plate", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "advanced", "form_cue": "Plate on back, tight core, breathe through it", "substitution": "Plank Hold"}, {"name": "Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 30, "rest_seconds": 20, "weight_guidance": "With medicine ball", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Feet off ground, rotate fully each side, 15 per side", "substitution": "Bicycle Crunch"}]}, {"workout_name": "EXHAUST ME - Core", "type": "hell_mode", "duration_minutes": 35, "exercises": [{"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 20, "weight_guidance": "Toes to bar", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Obliques"], "difficulty": "advanced", "form_cue": "Full range, toes to bar, controlled descent", "substitution": "Knee Raise"}, {"name": "Ab Roller", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 20, "weight_guidance": "Full extension", "equipment": "Ab Wheel", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders", "Lats"], "difficulty": "advanced", "form_cue": "Extend all the way out, roll back with abs", "substitution": "Plank Walkout"}, {"name": "Dragon Flag", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Slow eccentric", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Lower body as one unit, resist gravity, do not bend at hips", "substitution": "Lying Leg Raise"}, {"name": "L-Sit Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 20 seconds", "equipment": "Dip Bar", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis", "Quadriceps"], "difficulty": "advanced", "form_cue": "Straight legs, body at L-shape, squeeze everything", "substitution": "Tuck L-Sit"}, {"name": "Weighted Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 60 seconds with plate on back", "equipment": "Weight Plate", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "advanced", "form_cue": "Plate on back, tight core, breathe through it", "substitution": "Plank Hold"}, {"name": "Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 30, "rest_seconds": 20, "weight_guidance": "With medicine ball", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Feet off ground, rotate fully each side, 15 per side", "substitution": "Bicycle Crunch"}]}, {"workout_name": "EXHAUST ME - Core", "type": "hell_mode", "duration_minutes": 35, "exercises": [{"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 20, "weight_guidance": "Toes to bar", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Obliques"], "difficulty": "advanced", "form_cue": "Full range, toes to bar, controlled descent", "substitution": "Knee Raise"}, {"name": "Ab Roller", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 20, "weight_guidance": "Full extension", "equipment": "Ab Wheel", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders", "Lats"], "difficulty": "advanced", "form_cue": "Extend all the way out, roll back with abs", "substitution": "Plank Walkout"}, {"name": "Dragon Flag", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Slow eccentric", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Lower body as one unit, resist gravity, do not bend at hips", "substitution": "Lying Leg Raise"}, {"name": "L-Sit Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 20 seconds", "equipment": "Dip Bar", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis", "Quadriceps"], "difficulty": "advanced", "form_cue": "Straight legs, body at L-shape, squeeze everything", "substitution": "Tuck L-Sit"}, {"name": "Weighted Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 60 seconds with plate on back", "equipment": "Weight Plate", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "advanced", "form_cue": "Plate on back, tight core, breathe through it", "substitution": "Plank Hold"}, {"name": "Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 30, "rest_seconds": 20, "weight_guidance": "With medicine ball", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Feet off ground, rotate fully each side, 15 per side", "substitution": "Bicycle Crunch"}]}]'::jsonb,
    'EXHAUST ME - Core',
    'EXHAUST ME - Core - 1w 6x/wk',
    'High',
    false,
    'Your core will question your life choices',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EXHAUST ME - Core'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

-- Variant: EXHAUST ME - Core - 1w 7x/wk
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
    'EXHAUST ME - Core - 1w 7x/wk',
    'hell_mode',
    7,
    60,
    ARRAY['Improve overall fitness', 'Build strength and endurance']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'EXHAUST ME - Core'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Endure: push beyond previous limits',
    '[{"workout_name": "EXHAUST ME - Core", "type": "hell_mode", "duration_minutes": 35, "exercises": [{"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 20, "weight_guidance": "Toes to bar", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Obliques"], "difficulty": "advanced", "form_cue": "Full range, toes to bar, controlled descent", "substitution": "Knee Raise"}, {"name": "Ab Roller", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 20, "weight_guidance": "Full extension", "equipment": "Ab Wheel", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders", "Lats"], "difficulty": "advanced", "form_cue": "Extend all the way out, roll back with abs", "substitution": "Plank Walkout"}, {"name": "Dragon Flag", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Slow eccentric", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Lower body as one unit, resist gravity, do not bend at hips", "substitution": "Lying Leg Raise"}, {"name": "L-Sit Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 20 seconds", "equipment": "Dip Bar", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis", "Quadriceps"], "difficulty": "advanced", "form_cue": "Straight legs, body at L-shape, squeeze everything", "substitution": "Tuck L-Sit"}, {"name": "Weighted Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 60 seconds with plate on back", "equipment": "Weight Plate", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "advanced", "form_cue": "Plate on back, tight core, breathe through it", "substitution": "Plank Hold"}, {"name": "Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 30, "rest_seconds": 20, "weight_guidance": "With medicine ball", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Feet off ground, rotate fully each side, 15 per side", "substitution": "Bicycle Crunch"}]}, {"workout_name": "EXHAUST ME - Core", "type": "hell_mode", "duration_minutes": 35, "exercises": [{"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 20, "weight_guidance": "Toes to bar", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Obliques"], "difficulty": "advanced", "form_cue": "Full range, toes to bar, controlled descent", "substitution": "Knee Raise"}, {"name": "Ab Roller", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 20, "weight_guidance": "Full extension", "equipment": "Ab Wheel", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders", "Lats"], "difficulty": "advanced", "form_cue": "Extend all the way out, roll back with abs", "substitution": "Plank Walkout"}, {"name": "Dragon Flag", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Slow eccentric", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Lower body as one unit, resist gravity, do not bend at hips", "substitution": "Lying Leg Raise"}, {"name": "L-Sit Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 20 seconds", "equipment": "Dip Bar", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis", "Quadriceps"], "difficulty": "advanced", "form_cue": "Straight legs, body at L-shape, squeeze everything", "substitution": "Tuck L-Sit"}, {"name": "Weighted Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 60 seconds with plate on back", "equipment": "Weight Plate", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "advanced", "form_cue": "Plate on back, tight core, breathe through it", "substitution": "Plank Hold"}, {"name": "Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 30, "rest_seconds": 20, "weight_guidance": "With medicine ball", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Feet off ground, rotate fully each side, 15 per side", "substitution": "Bicycle Crunch"}]}, {"workout_name": "EXHAUST ME - Core", "type": "hell_mode", "duration_minutes": 35, "exercises": [{"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 20, "weight_guidance": "Toes to bar", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Obliques"], "difficulty": "advanced", "form_cue": "Full range, toes to bar, controlled descent", "substitution": "Knee Raise"}, {"name": "Ab Roller", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 20, "weight_guidance": "Full extension", "equipment": "Ab Wheel", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders", "Lats"], "difficulty": "advanced", "form_cue": "Extend all the way out, roll back with abs", "substitution": "Plank Walkout"}, {"name": "Dragon Flag", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Slow eccentric", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Lower body as one unit, resist gravity, do not bend at hips", "substitution": "Lying Leg Raise"}, {"name": "L-Sit Hold", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 20 seconds", "equipment": "Dip Bar", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis", "Quadriceps"], "difficulty": "advanced", "form_cue": "Straight legs, body at L-shape, squeeze everything", "substitution": "Tuck L-Sit"}, {"name": "Weighted Plank", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 20, "weight_guidance": "Hold 60 seconds with plate on back", "equipment": "Weight Plate", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques", "Shoulders"], "difficulty": "advanced", "form_cue": "Plate on back, tight core, breathe through it", "substitution": "Plank Hold"}, {"name": "Russian Twist", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 30, "rest_seconds": 20, "weight_guidance": "With medicine ball", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Feet off ground, rotate fully each side, 15 per side", "substitution": "Bicycle Crunch"}]}]'::jsonb,
    'EXHAUST ME - Core',
    'EXHAUST ME - Core - 1w 7x/wk',
    'High',
    false,
    'Your core will question your life choices',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'EXHAUST ME - Core'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;
